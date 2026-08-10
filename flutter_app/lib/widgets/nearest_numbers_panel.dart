import 'package:flutter/material.dart';
import '../models/visa_result.dart';
import '../theme/status_colors.dart';

class NearestNumbersPanel extends StatelessWidget {
  final Map<String, NearestResult>? nearest;
  final String applicationNumber;

  const NearestNumbersPanel({
    super.key,
    required this.nearest,
    required this.applicationNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (nearest == null || nearest!.isEmpty) return const SizedBox.shrink();

    final minDelta = [nearest!['before']?.difference, nearest!['after']?.difference]
        .whereType<int>()
        .fold<int?>(null, (m, d) => m == null || d < m ? d : m);

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            minDelta != null
                ? 'IRL$applicationNumber is $minDelta numbers from the nearest published decision.'
                : 'No nearest numbers found.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          if (nearest != null && nearest!.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Nearest:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (nearest!['before'] != null)
              _NearestRow(label: 'Before', entry: nearest!['before']!),
            if (nearest!['after'] != null)
              _NearestRow(label: 'After', entry: nearest!['after']!),
          ],
        ],
      ),
    );
  }
}

class _NearestRow extends StatelessWidget {
  final String label;
  final NearestResult entry;

  const _NearestRow({required this.label, required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(entry.number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Builder(builder: (context) {
            final colors = entry.isApproved
                ? StatusColors.approved(context)
                : StatusColors.refused(context);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                entry.decision,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: colors.foreground,
                ),
              ),
            );
          }),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '(${entry.embassy})',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (entry.difference != null) ...[
            const SizedBox(width: 6),
            Text(
              'Δ${entry.difference}',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}
