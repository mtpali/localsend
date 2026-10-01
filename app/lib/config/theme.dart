import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localsend_app/util/native/platform_check.dart';

final _borderRadius = BorderRadius.circular(5);

// No seed generation, platform palettes, surface tints, or theme variants.
const oledColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Colors.white,
  onPrimary: Colors.black,
  primaryContainer: Colors.black,
  onPrimaryContainer: Colors.white,
  secondary: Colors.white,
  onSecondary: Colors.black,
  secondaryContainer: Colors.black,
  onSecondaryContainer: Colors.white,
  tertiary: Colors.white,
  onTertiary: Colors.black,
  tertiaryContainer: Colors.black,
  onTertiaryContainer: Colors.white,
  error: Colors.white,
  onError: Colors.black,
  errorContainer: Colors.black,
  onErrorContainer: Colors.white,
  surface: Colors.black,
  onSurface: Colors.white,
  onSurfaceVariant: Colors.white,
  outline: Colors.white,
  outlineVariant: Colors.white,
  shadow: Colors.transparent,
  scrim: Colors.black,
  inverseSurface: Colors.white,
  onInverseSurface: Colors.black,
  inversePrimary: Colors.black,
  surfaceTint: Colors.transparent,
  surfaceDim: Colors.black,
  surfaceBright: Colors.black,
  surfaceContainerLowest: Colors.black,
  surfaceContainerLow: Colors.black,
  surfaceContainer: Colors.black,
  surfaceContainerHigh: Colors.black,
  surfaceContainerHighest: Colors.black,
  primaryFixed: Colors.white,
  primaryFixedDim: Colors.white,
  onPrimaryFixed: Colors.black,
  onPrimaryFixedVariant: Colors.black,
  secondaryFixed: Colors.white,
  secondaryFixedDim: Colors.white,
  onSecondaryFixed: Colors.black,
  onSecondaryFixedVariant: Colors.black,
  tertiaryFixed: Colors.white,
  tertiaryFixedDim: Colors.white,
  onTertiaryFixed: Colors.black,
  onTertiaryFixedVariant: Colors.black,
);

ThemeData getOledTheme() {
  final border = OutlineInputBorder(
    borderSide: const BorderSide(color: Colors.white),
    borderRadius: _borderRadius,
  );
  final buttonStyle = ButtonStyle(
    animationDuration: Duration.zero,
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    elevation: const WidgetStatePropertyAll(0),
    foregroundColor: const WidgetStatePropertyAll(Colors.white),
    backgroundColor: const WidgetStatePropertyAll(Colors.black),
    side: const WidgetStatePropertyAll(BorderSide(color: Colors.white)),
  );
  return ThemeData(
    colorScheme: oledColorScheme,
    useMaterial3: true,
    visualDensity: VisualDensity.standard,
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    cardColor: Colors.black,
    dividerColor: Colors.white,
    disabledColor: Colors.white,
    splashFactory: NoSplash.splashFactory,
    splashColor: Colors.transparent,
    highlightColor: Colors.transparent,
    hoverColor: Colors.transparent,
    focusColor: Colors.transparent,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _InstantPageTransitionsBuilder(),
        TargetPlatform.iOS: _InstantPageTransitionsBuilder(),
        TargetPlatform.linux: _InstantPageTransitionsBuilder(),
        TargetPlatform.macOS: _InstantPageTransitionsBuilder(),
        TargetPlatform.windows: _InstantPageTransitionsBuilder(),
      },
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white, elevation: 0, scrolledUnderElevation: 0),
    cardTheme: const CardThemeData(
      color: Colors.black,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.white),
        borderRadius: BorderRadius.all(Radius.circular(5)),
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.black, surfaceTintColor: Colors.transparent, elevation: 0),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: Colors.black, modalBackgroundColor: Colors.black, elevation: 0, modalElevation: 0),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.black,
      surfaceTintColor: Colors.transparent,
      indicatorColor: Colors.white,
      elevation: 0,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(color: states.contains(WidgetState.selected) ? Colors.black : Colors.white),
      ),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: Colors.white)),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: Colors.black,
      indicatorColor: Colors.white,
      selectedIconTheme: IconThemeData(color: Colors.black),
      unselectedIconTheme: IconThemeData(color: Colors.white),
      selectedLabelTextStyle: TextStyle(color: Colors.white),
      unselectedLabelTextStyle: TextStyle(color: Colors.white),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.black,
      border: border,
      focusedBorder: border,
      enabledBorder: border,
      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(style: buttonStyle),
    outlinedButtonTheme: OutlinedButtonThemeData(style: buttonStyle),
    filledButtonTheme: FilledButtonThemeData(style: buttonStyle),
    textButtonTheme: TextButtonThemeData(style: buttonStyle.copyWith(side: const WidgetStatePropertyAll(BorderSide.none))),
    tooltipTheme: const TooltipThemeData(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.fromBorderSide(BorderSide(color: Colors.white)),
      ),
      textStyle: TextStyle(color: Colors.white),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Colors.black,
      contentTextStyle: TextStyle(color: Colors.white),
      actionTextColor: Colors.white,
    ),
    popupMenuTheme: const PopupMenuThemeData(color: Colors.black, surfaceTintColor: Colors.transparent, elevation: 0),
  );
}

class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

Future<void> updateSystemOverlayStyle(BuildContext context) async {
  if (checkPlatform([TargetPlatform.android])) {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
}

extension ThemeDataExt on ThemeData {
  Color get cardColorWithElevation => Colors.black;
}

extension ColorSchemeExt on ColorScheme {
  Color get warning => Colors.white;
  Color get secondaryContainerIfDark => secondaryContainer;
  Color get onSecondaryContainerIfDark => onSecondaryContainer;
}

extension InputDecorationThemeExt on InputDecorationThemeData {
  BorderRadius get borderRadius => _borderRadius;
}
