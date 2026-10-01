import 'package:flutter/material.dart';
import 'package:localsend_app/widget/static_controls.dart';

class LoadingDialog extends StatelessWidget {
  const LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const PopScope(canPop: false, child: Center(child: StaticBusyIndicator()));
  }
}
