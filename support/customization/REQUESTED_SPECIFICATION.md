# LocalSend Android Customization and Optimization Project Specification

## Purpose

This document summarizes all requested modifications, optimizations, bug
fixes, and customization requirements for creating a customized Android
build of LocalSend.

The goal is to analyze the complete source code, improve stability and
performance, remove unnecessary Android features, reduce application
size, optimize the build process, and create optimized ARM APK builds.

------------------------------------------------------------------------

# 1. Source Code Analysis Requirements

Perform a complete review of the LocalSend source code.

Areas requiring special attention:

-   Flutter architecture
-   Android native integration
-   Network discovery system
-   Device discovery lifecycle
-   File sharing Intent handling
-   Application lifecycle management
-   Memory usage
-   Unused dependencies
-   Asset optimization
-   Build configuration

------------------------------------------------------------------------

# 2. Bug Fix Requirements

## Device Discovery Problems

Current issues:

-   Sometimes LocalSend cannot find other devices until the application
    is closed and reopened.
-   Network discovery sometimes stops after application
    background/foreground transitions.

Required improvements:

-   Improve discovery service lifecycle management.
-   Restart discovery automatically after:
    -   WiFi changes
    -   Network changes
    -   Application resume
    -   IP address changes
-   Improve socket lifecycle handling.
-   Improve device cache management.
-   Prevent stale discovery states.

------------------------------------------------------------------------

## Android Share Intent Problem

Current issue:

When selecting a file from Android File Manager:

File Manager → Share → LocalSend

LocalSend opens but does not discover devices.

The problem disappears after:

-   Restarting LocalSend
-   Selecting files directly inside LocalSend

Required improvements:

-   Fix Android Intent handling.
-   Ensure discovery starts correctly when the application is launched
    from Share Intent.
-   Handle Android activity lifecycle correctly.
-   Initialize networking before displaying available devices.

------------------------------------------------------------------------

# 3. Performance Optimization

Optimize the source code as much as possible.

Required:

-   Remove unused code.
-   Remove unused dependencies.
-   Optimize Flutter assets.
-   Reduce application startup time.
-   Improve memory usage.
-   Improve network discovery performance.
-   Improve transfer reliability.

------------------------------------------------------------------------

# 4. UI and Feature Removal

## Remove Startup Image

Remove the image displayed when opening the application.

Requirements:

-   Remove splash/startup image.
-   Remove related unused assets.

------------------------------------------------------------------------

## Remove All Animations

Remove all animations from the source code.

Required:

-   Remove animated widgets.
-   Remove transition animations.
-   Remove unnecessary motion effects.

Goal:

A simple and fast OLED-friendly interface.

------------------------------------------------------------------------

## Remove Troubleshoot Section

The Troubleshoot section should be completely removed from Android.

Remove:

-   UI elements
-   Navigation entries
-   Related source code
-   Assets
-   Dependencies if unused

------------------------------------------------------------------------

## Remove Favorite Feature

Completely remove Favorite functionality.

Remove:

-   Favorite section
-   Favorite icons
-   Favorite logic
-   Related storage
-   Related source files

------------------------------------------------------------------------

## Remove Quick Save For Favorite

Remove:

-   Quick Save for Favorite option
-   Related settings
-   Related source code

------------------------------------------------------------------------

# 5. Theme Changes

Create a simple OLED Dark Mode.

Requirements:

-   Pure dark interface.
-   Minimal design.
-   Optimized for OLED screens.
-   Remove unnecessary visual effects.

------------------------------------------------------------------------

# 6. Language Optimization

Keep only:

-   English language

Remove:

-   All other translations.
-   Unused localization files.
-   Related language assets.

------------------------------------------------------------------------

# 7. Default Settings Changes

Set default application behavior:

## Quick Save

Default:

Enabled

------------------------------------------------------------------------

## Require PIN

Default:

Disabled

------------------------------------------------------------------------

## Auto Finish

Default:

Enabled

------------------------------------------------------------------------

# 8. Settings Page Cleanup

Remove completely from source code:

-   LocalSend image shown in settings page
-   Text below LocalSend image
-   Changelog section
-   Privacy Policy button
-   Support LocalSend button

------------------------------------------------------------------------

# 9. About Section Modification

Replace:

About LocalSend

with:

t.me/VPN963

Behavior:

When user clicks Open:

Open Telegram channel:

t.me/VPN963

Implementation should avoid exposing unnecessary configuration strings
directly inside easily editable resources.

------------------------------------------------------------------------

# 10. Code Protection and Obfuscation

Apply Android build security improvements.

Requirements:

-   Enable R8 optimization.
-   Enable code shrinking.
-   Enable resource shrinking.
-   Obfuscate release build.
-   Make reverse engineering and simple modification harder.

Note:

Obfuscation should focus on protecting application logic and reducing
unnecessary exposure of implementation details.

------------------------------------------------------------------------

# 11. Build Requirements

Final APK outputs:

Only:

-   ARMv7 APK
-   ARMv8 APK

Do not create unnecessary architectures.

Optimize:

-   APK size
-   Startup performance
-   Runtime performance

Required build configuration:

-   Release mode
-   R8 enabled
-   Minification enabled
-   Resource shrinking enabled

------------------------------------------------------------------------

# 12. Final Quality Checks

Before final delivery test:

## Network Tests

-   Device discovery after fresh installation
-   Device discovery after WiFi reconnect
-   Device discovery after app resume
-   Device discovery from Share Intent

## Transfer Tests

-   Small files
-   Large files
-   Multiple files
-   Background transfer

## Compatibility Tests

-   ARMv7 devices
-   ARMv8 devices
-   Modern Android versions

------------------------------------------------------------------------

# Final Goal

Create a lightweight, fast, stable, minimal Android version of LocalSend
with:

-   Improved device discovery reliability
-   Fixed Android sharing workflow
-   Smaller APK size
-   OLED dark interface
-   English-only localization
-   Removed unnecessary features
-   Optimized release build
-   R8 obfuscation
-   ARMv7 and ARMv8 APK outputs
