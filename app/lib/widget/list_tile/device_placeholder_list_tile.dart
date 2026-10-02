import 'package:flutter/material.dart';
import 'package:localsend_app/widget/list_tile/custom_list_tile.dart';

class DevicePlaceholderListTile extends StatelessWidget {
  const DevicePlaceholderListTile();
  @override
  Widget build(BuildContext context) => const CustomListTile(
    icon: Icon(Icons.devices, size: 46),
    title: Text('No devices found yet', style: TextStyle(fontSize: 20)),
    subTitle: Text('Connect devices to the same local network.'),
  );
}
