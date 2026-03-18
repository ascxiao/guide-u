import 'package:flutter/material.dart';

class _NavBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final bool prominent;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.prominent = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = prominent
        ? (selected ? Colors.green.shade700 : Colors.green.shade200)
        : (selected ? Colors.green.shade800 : Colors.grey.shade500!);
    final double iconSize = prominent ? (selected ? 36 : 32) : 26;
    final BoxDecoration? decoration = prominent
        ? BoxDecoration(
            color: selected ? Colors.green.shade100 : Colors.green.shade50,
            shape: BoxShape.circle,
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: Colors.green.shade200.withOpacity(0.5),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 2),
                ),
            ],
          )
        : null;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: decoration,
        padding: prominent
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Icon(
          icon,
          color: selectedColor,
          size: iconSize,
        ),
      ),
    );
  }
}

class _NavBarLabel extends StatelessWidget {
  final String label;
  const _NavBarLabel(this.label, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black54,
          fontWeight: FontWeight.w400,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}