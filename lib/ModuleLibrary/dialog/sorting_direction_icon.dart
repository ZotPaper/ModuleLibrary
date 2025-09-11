import 'package:flutter/material.dart';

/// 排序方向图标
class SortingDirectionIcon extends StatefulWidget {

  final bool checked;

  final bool reverse;

  const SortingDirectionIcon({super.key, required this.checked, required this.reverse});

  @override
  State<SortingDirectionIcon> createState() => _SortingDirectionIconState();

}

class _SortingDirectionIconState extends State<SortingDirectionIcon> {
  Color defaultColor = Colors.grey;

  @override
  Widget build(BuildContext context) {
    defaultColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return SizedBox(
      height: 50,
      width: 50,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Icon(Icons.sort_by_alpha_outlined,
                    size: 24,
                    color: widget.checked
                        ? Colors.blue
                        : defaultColor),
                Icon(widget.reverse ? Icons.arrow_downward_outlined : Icons.arrow_upward_outlined,
                    size: 8,
                    color: widget.checked
                        ? Colors.blue
                        : defaultColor),
              ],
            )
          ]),
    );
  }
}
