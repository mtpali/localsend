import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/model/persistence/quick_save_mode.dart';
import 'package:localsend_app/model/persistence/receive_history_entry.dart';
import 'package:localsend_app/model/send_mode.dart';
import 'package:localsend_app/provider/window_dimensions_provider.dart';
import 'package:localsend_app/util/alias_generator.dart';
import 'package:localsend_app/util/native/autostart_helper.dart';
import 'package:localsend_app/util/native/context_menu_helper.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/security_helper.dart';
import 'package:localsend_app/util/shared_preferences/shared_preferences_file.dart';
import 'package:localsend_app/util/shared_preferences/shared_preferences_portable.dart';
import 'package:localsend_isolates/constants.dart';
import 'package:localsend_isolates/model/device.dart';
import 'package:localsend_isolates/model/stored_security_context.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:uuid/uuid.dart';

part 'persistence_provider_migrations.dart';

final _logger = Logger('PersistenceService');

String get _windowsFile {
  final appData = Platform.environment['APPDATA'];
  return '$appData\\LocalSend\\settings.json';
}

String get _windowsLegacyFile {
  final appData = Platform.environment['APPDATA'];
  return '$appData\\org.localsend\\localsend_app\\shared_preferences.json';
}

// Version of the storage
const _version = 'ls_version';

// Security keys (generated on first app start)
const _securityContext = 'ls_security_context';

// WebRTC
const _signalingServers = 'ls_signaling_servers';
const _stunServers = 'ls_stun_servers';

// Received file history
const _receiveHistory = 'ls_receive_history';

// App Window Offset and Size info
const _windowOffsetX = 'ls_window_offset_x';
const _windowOffsetY = 'ls_window_offset_y';
const _windowWidth = 'ls_window_width';
const _windowHeight = 'ls_window_height';
const _saveWindowPlacement = 'ls_save_window_placement';

// Settings
const _showToken = 'ls_show_token';
const _aliasKey = 'ls_alias';
const _portKey = 'ls_port';
const _networkWhitelistKey = 'ls_network_whitelist';
const _networkBlacklistKey = 'ls_network_blacklist';
const _timeoutKey = 'ls_timeout';
const _multicastGroupKey = 'ls_multicast_group';
const _destinationKey = 'ls_destination';
const _saveToGallery = 'ls_save_to_gallery';
const _saveToHistory = 'ls_save_to_history';
const _quickSave = 'ls_quick_save';
const _receivePin = 'ls_receive_pin';
const _autoFinish = 'ls_auto_finish';
const _minimizeToTray = 'ls_minimize_to_tray';
const _https = 'ls_https';
const _sendMode = 'ls_send_mode';
const _deviceType = 'ls_device_type';
const _deviceModel = 'ls_device_model';
const _shareViaLinkAutoAccept = 'ls_share_via_link_auto_accept';
const _receiveViaLinkAutoAccept = 'ls_receive_via_link_auto_accept';
const _createChecksums = 'ls_create_checksums';
const _verifyChecksums = 'ls_verify_checksums';
const _advancedSettingsKey = 'ls_advanced_settings';

final persistenceProvider = Provider<PersistenceService>((ref) {
  throw Exception('persistenceProvider not initialized');
});

/// This service abstracts the persistence layer.
class PersistenceService {
  final SharedPreferences _prefs;
  final bool isFirstAppStart;

  PersistenceService._(this._prefs, this.isFirstAppStart);

  static Future<PersistenceService> initialize() async {
    SharedPreferences prefs;

    final portableStore = SharedPreferencesPortable();
    bool usingLegacyStore = false;
    if (checkPlatform(const [TargetPlatform.windows, TargetPlatform.linux, TargetPlatform.macOS]) && portableStore.exists()) {
      _logger.info('Using portable settings.');
      SharedPreferencesStorePlatform.instance = portableStore;
    } else if (defaultTargetPlatform == TargetPlatform.windows) {
      final legacyStore = SharedPreferencesFile(filePath: _windowsLegacyFile);
      if (legacyStore.exists()) {
        _logger.info('Using legacy settings. Will migrate in the next step.');
        SharedPreferencesStorePlatform.instance = legacyStore;
        usingLegacyStore = true;
      } else {
        SharedPreferencesStorePlatform.instance = SharedPreferencesFile(filePath: _windowsFile);
      }
    }

    final bool isFirstAppStart;
    final existingVersion = (await SharedPreferencesStorePlatform.instance.getAll())['flutter.$_version'] as int?;
    _logger.info('Existing version: $existingVersion');
    if (existingVersion == null && !usingLegacyStore) {
      isFirstAppStart = true;
      await SharedPreferencesStorePlatform.instance.setValue('Int', 'flutter.$_version', _latestVersion);
    } else {
      isFirstAppStart = false;
      final fromVersion = existingVersion ?? 1;
      if (fromVersion < _latestVersion) {
        await _runMigrations(fromVersion);
      }
    }

    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      if (checkPlatform([TargetPlatform.windows])) {
        _logger.info('Could not initialize SharedPreferences, trying to delete corrupted settings file', e);
        File(_windowsFile).deleteSync();
        prefs = await SharedPreferences.getInstance();
      } else {
        throw Exception('Could not initialize SharedPreferences');
      }
    }

    await LocaleSettings.setLocale(AppLocale.en);

    if (prefs.getString(_showToken) == null) {
      await prefs.setString(_showToken, const Uuid().v4());
    }

    if (prefs.getString(_aliasKey) == null) {
      await prefs.setString(_aliasKey, generateRandomAlias());
    }

    if (prefs.getString(_securityContext) == null) {
      await prefs.setString(_securityContext, jsonEncode(await generateSecurityContext()));
    }

    // migrate legacy auto start settings (current implementation is stateless and relies on the Windows registry / file system)
    const launchAtStartupLegacyKey = 'ls_launch_at_startup';
    const launchMinimizedLegacyKey = 'ls_auto_start_launch_minimized';
    if (prefs.getBool(launchAtStartupLegacyKey) == true) {
      _logger.info('Enable auto start on legacy settings');
      await prefs.remove(launchAtStartupLegacyKey);
      await enableAutoStart(startHidden: prefs.getBool(launchMinimizedLegacyKey) == true);
      await prefs.remove(launchMinimizedLegacyKey);
    }

    return PersistenceService._(prefs, isFirstAppStart);
  }

  bool isPortableMode() {
    return SharedPreferencesStorePlatform.instance is SharedPreferencesPortable;
  }

  StoredSecurityContext getSecurityContext() {
    final contextRaw = _prefs.getString(_securityContext)!;
    return StoredSecurityContext.fromJson(jsonDecode(contextRaw));
  }

  Future<void> setSecurityContext(StoredSecurityContext context) async {
    await _prefs.setString(_securityContext, jsonEncode(context));
  }

  List<String>? getSignalingServers() {
    final serversRaw = _prefs.getString(_signalingServers);
    if (serversRaw == null) {
      return null;
    }

    return (jsonDecode(serversRaw) as List).cast<String>();
  }

  Future<void> setSignalingServers(List<String> servers) async {
    await _prefs.setString(_signalingServers, jsonEncode(servers));
  }

  List<String>? getStunServers() {
    final serversRaw = _prefs.getString(_stunServers);
    if (serversRaw == null) {
      return null;
    }

    return (jsonDecode(serversRaw) as List).cast<String>();
  }

  Future<void> setStunServers(List<String> servers) async {
    await _prefs.setString(_stunServers, jsonEncode(servers));
  }

  List<ReceiveHistoryEntry> getReceiveHistory() {
    final historyRaw = _prefs.getStringList(_receiveHistory) ?? [];
    return historyRaw.map((entry) => ReceiveHistoryEntry.fromJson(jsonDecode(entry))).toList();
  }

  Future<void> setReceiveHistory(List<ReceiveHistoryEntry> entries) async {
    final historyRaw = entries.map((entry) => jsonEncode(entry.toJson())).toList();
    await _prefs.setStringList(_receiveHistory, historyRaw);
  }

  String getShowToken() {
    return _prefs.getString(_showToken)!;
  }

  String getAlias() {
    return _prefs.getString(_aliasKey) ?? generateRandomAlias();
  }

  Future<void> setAlias(String alias) async {
    await _prefs.setString(_aliasKey, alias);
  }

  int getPort() {
    return _prefs.getInt(_portKey) ?? defaultPort;
  }

  Future<void> setPort(int port) async {
    await _prefs.setInt(_portKey, port);
  }

  List<String>? getNetworkWhitelist() {
    return _prefs.getStringList(_networkWhitelistKey);
  }

  Future<void> setNetworkWhitelist(List<String>? whitelist) async {
    if (whitelist == null) {
      await _prefs.remove(_networkWhitelistKey);
    } else {
      await _prefs.setStringList(_networkWhitelistKey, whitelist);
    }
  }

  List<String>? getNetworkBlacklist() {
    return _prefs.getStringList(_networkBlacklistKey);
  }

  Future<void> setNetworkBlacklist(List<String>? blacklist) async {
    if (blacklist == null) {
      await _prefs.remove(_networkBlacklistKey);
    } else {
      await _prefs.setStringList(_networkBlacklistKey, blacklist);
    }
  }

  int getDiscoveryTimeout() {
    return _prefs.getInt(_timeoutKey) ?? defaultDiscoveryTimeout;
  }

  Future<void> setDiscoveryTimeout(int timeout) async {
    await _prefs.setInt(_timeoutKey, timeout);
  }

  bool getShareViaLinkAutoAccept() {
    return _prefs.getBool(_shareViaLinkAutoAccept) ?? false;
  }

  Future<void> setShareViaLinkAutoAccept(bool shareViaLinkAutoAccept) async {
    await _prefs.setBool(_shareViaLinkAutoAccept, shareViaLinkAutoAccept);
  }

  bool getReceiveViaLinkAutoAccept() {
    return _prefs.getBool(_receiveViaLinkAutoAccept) ?? false;
  }

  Future<void> setReceiveViaLinkAutoAccept(bool receiveViaLinkAutoAccept) async {
    await _prefs.setBool(_receiveViaLinkAutoAccept, receiveViaLinkAutoAccept);
  }

  bool getCreateChecksums() {
    return _prefs.getBool(_createChecksums) ?? true;
  }

  Future<void> setCreateChecksums(bool createChecksums) async {
    await _prefs.setBool(_createChecksums, createChecksums);
  }

  bool getVerifyChecksums() {
    return _prefs.getBool(_verifyChecksums) ?? true;
  }

  Future<void> setVerifyChecksums(bool verifyChecksums) async {
    await _prefs.setBool(_verifyChecksums, verifyChecksums);
  }

  String getMulticastGroup() {
    return _prefs.getString(_multicastGroupKey) ?? defaultMulticastGroup;
  }

  Future<void> setMulticastGroup(String group) async {
    await _prefs.setString(_multicastGroupKey, group);
  }

  String? getDestination() {
    return _prefs.getString(_destinationKey);
  }

  Future<void> setDestination(String? destination) async {
    if (destination == null) {
      await _prefs.remove(_destinationKey);
    } else {
      await _prefs.setString(_destinationKey, destination);
    }
  }

  bool isSaveToGallery() {
    return _prefs.getBool(_saveToGallery) ?? true;
  }

  Future<void> setSaveToGallery(bool saveToGallery) async {
    await _prefs.setBool(_saveToGallery, saveToGallery);
  }

  bool isSaveToHistory() {
    return _prefs.getBool(_saveToHistory) ?? true;
  }

  Future<void> setSaveToHistory(bool saveToHistory) async {
    await _prefs.setBool(_saveToHistory, saveToHistory);
  }

  bool getAdvancedSettingsEnabled() {
    return _prefs.getBool(_advancedSettingsKey) ?? false;
  }

  Future<void> setAdvancedSettingsEnabled(bool isEnabled) async {
    await _prefs.setBool(_advancedSettingsKey, isEnabled);
  }

  QuickSaveMode getQuickSave() {
    final value = _prefs.getString(_quickSave);
    return QuickSaveMode.values.firstWhereOrNull((mode) => mode.name == value) ?? QuickSaveMode.on;
  }

  Future<void> setQuickSave(QuickSaveMode mode) async {
    await _prefs.setString(_quickSave, mode.name);
  }

  String? getReceivePin() {
    return _prefs.getString(_receivePin);
  }

  Future<void> setReceivePin(String? pin) async {
    if (pin == null) {
      await _prefs.remove(_receivePin);
    } else {
      await _prefs.setString(_receivePin, pin);
    }
  }

  bool isAutoFinish() {
    return _prefs.getBool(_autoFinish) ?? true;
  }

  Future<void> setAutoFinish(bool autoFinish) async {
    await _prefs.setBool(_autoFinish, autoFinish);
  }

  bool isMinimizeToTray() {
    return _prefs.getBool(_minimizeToTray) ?? false;
  }

  Future<void> setMinimizeToTray(bool minimizeToTray) async {
    await _prefs.setBool(_minimizeToTray, minimizeToTray);
  }

  bool isHttps() {
    return _prefs.getBool(_https) ?? true;
  }

  Future<void> setHttps(bool https) async {
    await _prefs.setBool(_https, https);
  }

  SendMode getSendMode() {
    return SendMode.values.firstWhereOrNull((m) => m.name == _prefs.getString(_sendMode)) ?? SendMode.single;
  }

  Future<void> setSendMode(SendMode mode) async {
    await _prefs.setString(_sendMode, mode.name);
  }

  Future<void> setWindowOffsetX(double x) async {
    await _prefs.setDouble(_windowOffsetX, x);
  }

  Future<void> setWindowOffsetY(double y) async {
    await _prefs.setDouble(_windowOffsetY, y);
  }

  Future<void> setWindowHeight(double height) async {
    await _prefs.setDouble(_windowHeight, height);
  }

  Future<void> setWindowWidth(double width) async {
    await _prefs.setDouble(_windowWidth, width);
  }

  WindowDimensions? getWindowLastDimensions() {
    Size? size;
    Offset? position;
    final offsetX = _prefs.getDouble(_windowOffsetX);
    final offsetY = _prefs.getDouble(_windowOffsetY);
    final width = _prefs.getDouble(_windowWidth);
    final height = _prefs.getDouble(_windowHeight);

    if (width != null && height != null) {
      size = Size(width, height);
    }

    if (offsetX != null && offsetY != null) {
      position = Offset(offsetX, offsetY);
    }

    if (size == null || position == null) {
      return null;
    }

    return WindowDimensions(position: position, size: size);
  }

  Future<void> setSaveWindowPlacement(bool savePlacement) async {
    await _prefs.setBool(_saveWindowPlacement, savePlacement);
  }

  bool getSaveWindowPlacement() {
    if (!checkPlatformIsNotWaylandDesktop()) return false;
    return _prefs.getBool(_saveWindowPlacement) ?? true;
  }

  DeviceType? getDeviceType() {
    return DeviceType.values.firstWhereOrNull((m) => m.name == _prefs.getString(_deviceType));
  }

  Future<void> setDeviceType(DeviceType deviceType) async {
    await _prefs.setString(_deviceType, deviceType.name);
  }

  String? getDeviceModel() {
    return _prefs.getString(_deviceModel);
  }

  Future<void> setDeviceModel(String deviceModel) async {
    await _prefs.setString(_deviceModel, deviceModel);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }
}
