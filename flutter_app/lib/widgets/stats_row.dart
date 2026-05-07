import 'package:flutter/material.dart';

import '../models/embassy_info.dart';

class StatsRow extends StatelessWidget {
  final VisaStats stats;
  const StatsRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Row(
          children: [
            _StatCell(
                label: 'Total',
                value: stats.total,
                color: Theme.of(context).colorScheme.primary),
            _StatCell(
                label: 'Approved', value: stats.approved, color: Colors.green),
            _StatCell(
                label: 'Refused', value: stats.refused, color: Colors.red),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCell(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value.toString(),
            style: TextStyle(
                fontSize: 26, fontWeight: FontWeight.bold, color: color),
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
