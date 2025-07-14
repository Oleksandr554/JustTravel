import 'package:flutter/material.dart';

class JourneyChip extends StatelessWidget {
  final String label;
  final bool selected;

  const JourneyChip({super.key, required this.label, this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFA8D5BA) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}