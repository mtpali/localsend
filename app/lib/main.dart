import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show DefaultCupertinoLocalizations;
import 'package:localsend_app/config/init.dart';
import 'package:localsend_app/config/init_error.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/home_page.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/discovery_lifecycle_provider.dart';
import 'package:localsend_app/widget/watcher/life_cycle_watcher.dart';
import 'package:localsend_app/widget/watcher/shortcut_watcher.dart';
import 'package:localsend_app/widget/watcher/tray_watcher.dart';
import 'package:localsend_app/widget/watcher/window_watcher.dart';
import 'package:localsend_isolates/isolate.dart';
import 'package:refena_flutter/addons.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

Future<void> main(List<String> args) async {
  final RefenaContainer container;
  try {
    container = await preInit(args);
  } catch (e, stackTrace) {
    showInitErrorApp(error: e, stackTrace: stackTrace);
    return;
  }
  runApp(
    RefenaScope.withContainer(
      container: container,
      child: TranslationProvider(child: const LocalSendApp()),
    ),
  );
}

class LocalSendApp extends StatelessWidget {
  const LocalSendApp();
  @override
  Widget build(BuildContext context) {
    final ref = context.ref;
    return TrayWatcher(
      child: WindowWatcher(
        child: LifeCycleWatcher(
          onChangedState: (state) {
            switch (state) {
              case AppLifecycleState.resumed:
                ref.redux(localIpProvider).dispatch(InitLocalIpAction());
                unawaited(ref.read(discoveryLifecycleProvider).refresh());
                break;
              case AppLifecycleState.detached:
                ref.redux(parentIsolateProvider).dispatch(IsolateDisposeAction());
                break;
              default:
                break;
            }
          },
          child: ShortcutWatcher(
            child: MaterialApp(
              title: t.appName,
              locale: const Locale('en'),
              supportedLocales: const [Locale('en')],
              localizationsDelegates: const [
                DefaultMaterialLocalizations.delegate,
                DefaultWidgetsLocalizations.delegate,
                DefaultCupertinoLocalizations.delegate,
              ],
              debugShowCheckedModeBanner: false,
              theme: getOledTheme(),
              themeMode: ThemeMode.dark,
              themeAnimationDuration: Duration.zero,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: TooltipVisibility(visible: false, child: HeroControllerScope.none(child: child!)),
              ),
              navigatorKey: context.read(navigationProvider).key,
              home: RouterinoHome(builder: () => const HomePage(initialTab: HomeTab.receive, appStart: true)),
            ),
          ),
        ),
      ),
    );
  }
}
