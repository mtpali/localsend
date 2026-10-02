import 'package:flutter/material.dart';

/// Instant state changes without animated checkboxes or switches.
class StaticToggle extends StatelessWidget {
  final bool? value;
  final ValueChanged<bool>? onChanged;
  const StaticToggle({required this.value, required this.onChanged, super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    checked: value == true,
    enabled: onChanged != null,
    child: IconButton(
      onPressed: onChanged == null ? null : () => onChanged!(!(value ?? false)),
      icon: Icon(value == true ? Icons.check_box : Icons.check_box_outline_blank),
    ),
  );
}

class StaticBusyIndicator extends StatelessWidget {
  const StaticBusyIndicator({super.key});
  @override
  Widget build(BuildContext context) => const Icon(Icons.hourglass_top, semanticLabel: 'Working');
}

Future<T?> showStaticDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color? barrierColor,
}) => showGeneralDialog<T>(
  context: context,
  pageBuilder: (context, _, _) => SafeArea(child: builder(context)),
  barrierDismissible: barrierDismissible,
  barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  barrierColor: barrierColor ?? Colors.black,
  useRootNavigator: useRootNavigator,
  transitionDuration: Duration.zero,
);

Future<T?> showStaticBottomSheet<T>({required BuildContext context, required Widget Function() builder}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  backgroundColor: Colors.black,
  barrierColor: Colors.black,
  sheetAnimationStyle: AnimationStyle.noAnimation,
  builder: (_) => builder(),
);
