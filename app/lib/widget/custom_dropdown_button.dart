import 'package:flutter/material.dart';
import 'package:localsend_app/config/theme.dart';
import 'package:localsend_app/widget/static_controls.dart';

/// A static selection control with an instant dialog instead of an animated route.
class CustomDropdownButton<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T>? onChanged;
  final bool expanded;
  const CustomDropdownButton({required this.value, required this.items, this.onChanged, this.expanded = true});
  @override
  Widget build(BuildContext context) {
    final selected = items.where((item) => item.value == value).firstOrNull;
    return Material(
      color: Colors.black,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.white),
        borderRadius: Theme.of(context).inputDecorationTheme.borderRadius,
      ),
      child: InkWell(
        onTap: onChanged == null
            ? null
            : () async {
                final result = await showStaticDialog<T>(
                  context: context,
                  builder: (context) => SimpleDialog(
                    children: [
                      for (final item in items)
                        SimpleDialogOption(
                          onPressed: item.enabled ? () => Navigator.of(context).pop(item.value) : null,
                          child: Row(
                            children: [
                              Expanded(child: item.child),
                              if (item.value == value) const Icon(Icons.check),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
                if (result != null) onChanged!(result);
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (expanded) Expanded(child: selected?.child ?? const SizedBox()) else selected?.child ?? const SizedBox(),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }
}
