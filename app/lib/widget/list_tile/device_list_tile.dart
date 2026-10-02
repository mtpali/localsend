import 'package:flutter/material.dart';
import 'package:localsend_app/util/device_type_ext.dart';
import 'package:localsend_app/widget/custom_progress_bar.dart';
import 'package:localsend_app/widget/device_bage.dart';
import 'package:localsend_app/widget/list_tile/custom_list_tile.dart';
import 'package:localsend_isolates/model/device.dart';

class DeviceListTile extends StatelessWidget {
  final Device device;

  final String? info;
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onDetailsTap;

  const DeviceListTile({required this.device, this.info, this.progress, this.onTap, this.onDetailsTap});

  @override
  Widget build(BuildContext context) {
    final badgeColor = Colors.black;
    return CustomListTile(
      icon: Icon(device.deviceType.icon, size: 46),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(device.alias, style: const TextStyle(fontSize: 20))],
      ),
      trailing: onDetailsTap != null ? IconButton(icon: const Icon(Icons.info_outline), onPressed: onDetailsTap) : null,
      subTitle: Wrap(
        runSpacing: 10,
        spacing: 10,
        children: [
          if (info != null)
            Text(info!, style: const TextStyle(color: Colors.white))
          else if (progress != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: CustomProgressBar(progress: progress!),
            )
          else ...[
            if (device.ip != null)
              DeviceBadge(backgroundColor: badgeColor, foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer, label: 'HTTP')
            else
              DeviceBadge(backgroundColor: badgeColor, foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer, label: 'WebRTC'),
            if (device.deviceModel != null)
              DeviceBadge(
                backgroundColor: badgeColor,
                foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                label: device.deviceModel!,
              ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}
