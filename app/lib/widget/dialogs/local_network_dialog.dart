import 'package:flutter/material.dart';
import 'package:localsend_app/gen/strings.g.dart';
import 'package:localsend_app/widget/dialogs/custom_bottom_sheet.dart';
import 'package:routerino/routerino.dart';
import 'package:localsend_app/util/native/channel/android_channel.dart';

class LocalNetworkDialog extends StatelessWidget {
  const LocalNetworkDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomBottomSheet(
      title: t.dialogs.localNetworkUnauthorized.title,
      description: t.dialogs.localNetworkUnauthorized.description,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(onPressed: () => context.pop(), child: Text(t.general.close)),
          ElevatedButton.icon(
            onPressed: () async => openAppSettingsAndroid(),
            icon: const Icon(Icons.settings),
            label: Text(t.dialogs.localNetworkUnauthorized.gotoSettings),
          ),
        ],
      ),
    );
  }
}
