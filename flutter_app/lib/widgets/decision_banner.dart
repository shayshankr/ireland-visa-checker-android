import 'package:flutter/material.dart';
import '../theme/status_colors.dart';

class DecisionBanner extends StatelessWidget {
  final String decision;
  final String? embassy;

  const DecisionBanner({
    super.key,
    required this.decision,
    this.embassy,
  });

  @override
  Widget build(BuildContext context) {
    final colors = decision.toUpperCase() == 'APPROVED'
        ? StatusColors.approved(context)
        : decision.toUpperCase() == 'REFUSED'
            ? StatusColors.refused(context)
            : StatusColors.neutral(context);

    final icon = decision.toUpperCase() == 'APPROVED'
        ? Icons.check_circle
        : decision.toUpperCase() == 'REFUSED'
            ? Icons.cancel
            : Icons.help_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.background,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: colors.foreground, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Decision: ${decision.toUpperCase()}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.foreground,
                      ),
                ),
                if (embassy != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      embassy!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.foreground.withAlpha(179),
                          ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
