// ignore_for_file: discarded_futures, unawaited_futures

import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/util/native/platform_check.dart';
import 'package:localsend_isolates/util/file_path_helper.dart';
import 'package:localsend_isolates/util/logger.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_foundation/path_provider_foundation.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('ClearCacheAction');
Future<void> _pickerCacheCleanup = Future<void>.value();

/// Don't resolve new gallery files while startup is deleting old export files.
Future<void> waitForPickerCacheCleanup() => _pickerCacheCleanup;

/// Clears the cache.
/// It runs on a separate isolate to avoid blocking the UI.
class ClearCacheAction extends AsyncGlobalAction {
  @override
  Future<void> reduce() async {
    // The token statement must be outside the lambda because it must be executed on the root isolate.
    final token = ServicesBinding.rootIsolateToken!;
    final cleanup = Isolate.run(() => _clear(token));
    _pickerCacheCleanup = cleanup;
    await cleanup;
  }
}

Future<void> _clear(RootIsolateToken token) async {
  initLogger(Level.ALL);
  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final futures = (
    FilePicker.clearTemporaryFiles(),
    checkPlatform([TargetPlatform.iOS, TargetPlatform.android])
        ? getTemporaryDirectory().then((cacheDir) async {
            // Gallery's bounded native thumbnail cache is in a subdirectory;
            // keep it warm and remove only old exported temporary files.
            await for (final event in cacheDir.list(followLinks: false)) {
              if (event is File) {
                try {
                  await event.delete();
                } catch (error) {
                  _logger.warning('Failed to delete file: $error');
                }
              }
            }
          })
        : Future.value(),
    checkPlatform([TargetPlatform.iOS])
        ? PathProviderFoundation().getContainerPath(appGroupIdentifier: 'group.org.localsend.localsendApp').then((directoryPath) async {
            if (directoryPath == null) {
              _logger.warning('Failed to get app group directory');
              return;
            }

            final directory = Directory(directoryPath);

            // delete contents of the directory (only files, not directories)
            await for (final entry in directory.list(recursive: false, followLinks: false)) {
              if (entry is File && !entry.path.fileName.startsWith('.')) {
                _logger.info('Deleting ${entry.path}');
                entry.deleteSync();
              }
            }
          })
        : Future.value(),
  ).wait;

  try {
    await futures;
  } catch (e) {
    _logger.warning('Failed to clear cache: $e');
  }
}
