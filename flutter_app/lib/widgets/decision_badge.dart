import 'package:flutter/material.dart';
import '../theme/status_colors.dart';

class DecisionBadge extends StatelessWidget {
  final String decision;
  const DecisionBadge({super.key, required this.decision});

  @override
  Widget build(BuildContext context) {
    final upper = decision.toUpperCase();
    final Color color;
    final IconData icon;

    if (upper == 'APPROVED') {
      color = StatusColors.approved(context).foreground;
      icon = Icons.check_circle;
    } else if (upper == 'REFUSED') {
      color = StatusColors.refused(context).foreground;
      icon = Icons.cancel;
    } else {
      color = StatusColors.neutral(context).foreground;
      icon = Icons.help_outline;
    }

    return Icon(icon, color: color, size: 34);
  }
}
