import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/state/server/server_state.dart';
import 'package:localsend_app/model/state/settings_state.dart';
import 'package:localsend_isolates/model/device_info_result.dart';

part 'settings_tab_vm.mapper.dart';

@MappableClass()
class SettingsTabVm with SettingsTabVmMappable {
  final bool advanced;
  final TextEditingController aliasController;
  final TextEditingController deviceModelController;
  final TextEditingController portController;
  final TextEditingController timeoutController;
  final TextEditingController multicastController;

  final SettingsState settings;
  final ServerState? serverState;
  final DeviceInfoResult deviceInfo;
  final bool autoStart;
  final bool autoStartLaunchHidden;
  final bool showInContextMenu;
  final void Function(BuildContext context) onToggleAutoStart;
  final void Function(BuildContext context) onToggleAutoStartLaunchHidden;
  final void Function(BuildContext context) onToggleShowInContextMenu;
  final void Function(BuildContext context) onTapRestartServer;
  final void Function(BuildContext context) onTapStartServer;
  final void Function() onTapStopServer;
  final void Function(bool advanced) onTapAdvanced;

  SettingsTabVm({
    required this.advanced,
    required this.aliasController,
    required this.deviceModelController,
    required this.portController,
    required this.timeoutController,
    required this.multicastController,
    required this.settings,
    required this.serverState,
    required this.deviceInfo,
    required this.autoStart,
    required this.autoStartLaunchHidden,
    required this.showInContextMenu,
    required this.onToggleAutoStart,
    required this.onToggleAutoStartLaunchHidden,
    required this.onToggleShowInContextMenu,
    required this.onTapRestartServer,
    required this.onTapStartServer,
    required this.onTapStopServer,
    required this.onTapAdvanced,
  });
}
