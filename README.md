# LocalSend OLED for Android

Customized from [LocalSend v1.18.2](https://github.com/localsend/localsend/releases/tag/v1.18.2), upstream commit `af0416be50770a97760f7070684bc667b759a15c`.

The Android app uses one black-and-white OLED theme and English only. Favorites, troubleshooting, donation, changelog, startup graphics, and application animations are removed. Fresh installations enable Quick Save and Auto Finish and leave the receive PIN disabled. The requested contact link opens from Settings.

Networking waits for discovery readiness, recovers multicast sockets after resume/network/IP changes, acquires the Android Wi-Fi multicast lock, serializes overlapping recovery requests, and clears old peers after a network rebind. The HTTP listener is probed before recovery so healthy ongoing transfers are preserved.

## Build

Use the Flutter version in `.fvmrc`, the Rust toolchain in `rust-toolchain.toml`, flutter_rust_bridge_codegen 2.12.0, JDK 17, and an Android SDK with platform 36 and the Flutter-pinned NDK.

```sh
bash support/scripts/build_android_release.sh
```

Only `armeabi-v7a` and `arm64-v8a` APKs are built. R8 minification/resource shrinking, Dart AOT obfuscation, and native size optimization are enabled. The experimental, upstream-disabled WebRTC API is excluded from the Android native library; local HTTPS, multicast, and browser sharing are retained. If `app/android/key.properties` is absent, artifacts are unsigned; sign them with your own protected key before installation. Keep Dart symbol files and R8 mappings privately for diagnostics.

Source generators are mandatory after checkout: first run `flutter_rust_bridge_codegen generate` from `packages/localsend_isolates/`, then `dart run slang` and `dart run build_runner build` from `app/`. The CI workflow also regenerates isolate models, runs application/isolate/Rust checks, and retains generated source plus release artifacts.

## Verification

Automated tests cover defaults and migration of removed settings. Physical-device checks remain necessary for Wi-Fi switching, Android Share Intents, background transfer, and both ARM architectures. Passing static or CI checks does not substitute for these hardware tests.

## Attribution and license

Original LocalSend copyright and the Apache-2.0 license are preserved in [LICENSE](LICENSE). This is a user-requested customization and is not an official upstream release.
