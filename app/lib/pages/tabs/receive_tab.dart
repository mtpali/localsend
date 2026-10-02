import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/pages/receive_history_page.dart';
import 'package:localsend_app/pages/web_share_page.dart';
import 'package:localsend_app/provider/local_ip_provider.dart';
import 'package:localsend_app/provider/network/server/server_provider.dart';
import 'package:localsend_app/provider/settings_provider.dart';
import 'package:localsend_app/widget/custom_icon_button.dart';
import 'package:localsend_app/widget/responsive_list_view.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:routerino/routerino.dart';

class ReceiveTab extends StatefulWidget {
  const ReceiveTab();
  @override
  State<ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends State<ReceiveTab> {
  bool _showAdvanced = false;
  @override
  Widget build(BuildContext context) {
    final alias = context.watch(settingsProvider.select((s) => s.alias));
    final server = context.watch(serverProvider);
    final localIps = context.watch(localIpProvider.select((s) => s.localIps));
    return Stack(
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ResponsiveListView.defaultMaxWidth),
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(server?.alias ?? alias, style: const TextStyle(fontSize: 48)),
                  ),
                  if (server == null) Text(t.general.offline, style: const TextStyle(fontSize: 24)),
                  const SizedBox(height: 30),
                  OutlinedButton.icon(
                    onPressed: () async => await context.push(() => const WebSharePage()),
                    icon: const Icon(Icons.language),
                    label: Text(t.receiveTab.link),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showAdvanced)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 75, left: 15, right: 15),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${t.receiveTab.infoBox.alias}: ${server?.alias ?? alias}'),
                      ...localIps.map((ip) => SelectableText('${t.receiveTab.infoBox.ip}: $ip')),
                      if (localIps.isEmpty) Text(t.general.unknown),
                      Text('${t.receiveTab.infoBox.port}: ${server?.port ?? '-'}'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CustomIconButton(onPressed: () async => await context.push(() => const ReceiveHistoryPage()), child: const Icon(Icons.history)),
                CustomIconButton(onPressed: () => setState(() => _showAdvanced = !_showAdvanced), child: const Icon(Icons.info_outline)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
