import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/embassy_info.dart';
import '../theme/status_colors.dart';

class StatsRow extends StatelessWidget {
  final VisaStats stats;
  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0');
    final rate = stats.approvalRate;
    final primary = Theme.of(context).colorScheme.primary;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          children: [
            Row(
              children: [
                _StatCell(
                    label: 'Total',
                    value: fmt.format(stats.total),
                    color: primary),
                _StatCell(
                    label: 'Approved',
                    value: fmt.format(stats.approved),
                    color: StatusColors.approved(context).foreground),
                _StatCell(
                    label: 'Refused',
                    value: fmt.format(stats.refused),
                    color: StatusColors.refused(context).foreground),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Approval Rate',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  '${rate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: rate >= 50
                        ? StatusColors.approved(context).foreground
                        : StatusColors.refused(context).foreground,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: rate / 100,
                backgroundColor: StatusColors.refused(context).background,
                valueColor: AlwaysStoppedAnimation<Color>(
                    StatusColors.approved(context).foreground),
                minHeight: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
