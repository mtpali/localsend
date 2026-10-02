import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/nearby_devices_provider.dart';
import 'package:localsend_app/provider/network/scan_facade.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/util/native/channel/android_channel.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_app/util/network_recovery.dart';
import 'package:localsend_isolates/isolate.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('DiscoveryLifecycle');
final discoveryLifecycleProvider = Provider((ref) => DiscoveryLifecycle(ref));

/// Serializes recovery requests so overlapping resume, IP and share events
/// cannot keep stopping each other's sockets.
class DiscoveryLifecycle {
  final Ref _ref;
  late final _recovery = NetworkRecovery(initialize: _initialize, recover: _recover);

  DiscoveryLifecycle(this._ref);

  Future<void> initialize() => _recovery.initialize();
  Future<void> refresh() => _recovery.refresh();

  Future<void> _initialize() async {
    await _acquireLock();
    await _ref.notifier(serverProvider).startServerFromSettings();
    await _ref.redux(localIpProvider).dispatchAsync(FetchLocalIpAction(notifyDiscovery: false));
    unawaited(
      _ref.redux(nearbyDevicesProvider).dispatchAsync(StartDiscoveryListener()).catchError((Object error, StackTrace stack) {
        _logger.warning('Discovery listener failed', error, stack);
        return _ref.read(nearbyDevicesProvider);
      }),
    );
    try {
      await _ref.global.dispatchAsync(StartSmartScan());
    } catch (e) {
      _logger.warning('Initial device scan failed; recovery remains available', e);
    }
  }

  Future<void> _recover() async {
    try {
      await _acquireLock();
      // A live server and its active transfer are preserved.
      await _ref.notifier(serverProvider).ensureRunning();
      await _ref.redux(localIpProvider).dispatchAsync(FetchLocalIpAction(notifyDiscovery: false));
      _ref.redux(nearbyDevicesProvider).dispatch(ClearFoundDevicesAction());
      _ref.redux(parentIsolateProvider).dispatch(IsolateDiscoveryRestartAction());
      await _ref.global.dispatchAsync(StartSmartScan());
    } catch (e, stack) {
      _logger.warning('Network recovery failed; the next event can retry', e, stack);
    }
  }

  Future<void> _acquireLock() async {
    if (checkPlatform([TargetPlatform.android])) {
      try {
        await acquireDiscoveryLockAndroid();
      } catch (e) {
        _logger.warning('Could not acquire Wi-Fi multicast lock; HTTP fallback remains available', e);
      }
    }
  }
}
