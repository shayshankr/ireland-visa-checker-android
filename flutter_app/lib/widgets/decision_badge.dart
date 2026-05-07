import 'package:flutter/material.dart';

class DecisionBadge extends StatelessWidget {
  final String decision;
  const DecisionBadge({super.key, required this.decision});

  @override
  Widget build(BuildContext context) {
    final upper = decision.toUpperCase();
    final Color color;
    final IconData icon;

    if (upper == 'APPROVED') {
      color = Colors.green;
      icon = Icons.check_circle;
    } else if (upper == 'REFUSED') {
      color = Colors.red;
      icon = Icons.cancel;
    } else {
      color = Colors.grey;
      icon = Icons.help_outline;
    }

    return Icon(icon, color: color, size: 34);
  }
}
