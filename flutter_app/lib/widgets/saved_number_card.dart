import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_number.dart';
import '../theme/status_colors.dart';
import 'decision_banner.dart';
import 'nearest_numbers_panel.dart';

class SavedNumberCard extends StatelessWidget {
  final SavedNumber saved;
  final bool isChecking;
  final VoidCallback onDelete;
  final VoidCallback onEditLabel;
  final ValueChanged<bool> onToggleWatch;
  final VoidCallback onCheckNow;

  const SavedNumberCard({
    super.key,
    required this.saved,
    required this.isChecking,
    required this.onDelete,
    required this.onEditLabel,
    required this.onToggleWatch,
    required this.onCheckNow,
  });

  void _share() {
    final foundLine = saved.foundAt != null
        ? ' on ${DateFormat('MMM d').format(saved.foundAt!)}'
        : '';
    Share.share(
      'My Ireland visa application ${saved.displayNumber} was '
      '${saved.lastDecision}$foundLine at '
      '${saved.lastEmbassy ?? "an Irish embassy"}.\n\n'
      'Track your own decision with the Ireland Visa Checker app '
      '(search "Ireland Visa Checker" on Play Store).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFound = saved.isFound;
    final borderColor = isFound
        ? (saved.isApproved
            ? StatusColors.approved(context).border
            : StatusColors.refused(context).border)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: isFound ? 3 : 2,
      shape: borderColor != null
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: borderColor, width: 2),
            )
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isFound && saved.lastDecision != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DecisionBanner(
                  decision: saved.lastDecision!,
                  embassy: saved.lastEmbassy,
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            saved.displayNumber,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: onEditLabel,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (saved.label != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            saved.label!,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: Colors.grey.shade600),
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: onEditLabel,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              'Add label…',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusChip(saved: saved),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (isFound && saved.foundAt != null) ...[
                  Icon(Icons.event_available,
                      size: 13, color: StatusColors.approved(context).foreground),
                  const SizedBox(width: 4),
                  Text(
                    'Found ${_formatAbsolute(saved.foundAt!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: StatusColors.approved(context).foreground,
                        fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  Icon(Icons.access_time,
                      size: 13, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatChecked(saved.lastChecked),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
                const Spacer(),
                _WatchToggle(
                    enabled: saved.watchEnabled,
                    onChanged: onToggleWatch),
                if (isFound)
                  IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    color: Colors.grey.shade500,
                    tooltip: 'Share result',
                    onPressed: _share,
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.grey.shade500,
                  tooltip: 'Remove',
                  onPressed: onDelete,
                ),
              ],
            ),
            if (!isFound && saved.lastNearest != null && saved.lastNearest!.isNotEmpty)
              NearestNumbersPanel(
                nearest: saved.lastNearest,
                applicationNumber: saved.number,
              ),
            if (saved.submittedDate != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _getWaitingText(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            const Divider(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: isChecking
                  ? const Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: 6, horizontal: 12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2),
                      ),
                    )
                  : TextButton.icon(
                      onPressed: onCheckNow,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Check Now'),
                      style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatChecked(DateTime? time) {
    if (time == null) return 'Never checked';
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(time);
  }

  String _formatAbsolute(DateTime time) =>
      DateFormat('MMM d, HH:mm').format(time);

  String _getWaitingText() {
    if (saved.submittedDate == null) return '';
    if (saved.isFound && saved.foundAt != null) {
      final days = saved.foundAt!.difference(saved.submittedDate!).inDays;
      return 'Decided after $days days';
    } else if (!saved.isFound) {
      final days = DateTime.now().difference(saved.submittedDate!).inDays;
      return 'Waiting $days days';
    }
    return '';
  }
}

class _StatusChip extends StatelessWidget {
  final SavedNumber saved;
  const _StatusChip({required this.saved});

  @override
  Widget build(BuildContext context) {
    StatusColors colors;
    IconData icon;
    final text = saved.statusText;

    if (saved.lastFound == null) {
      colors = StatusColors.notCheckedYet(context);
      icon = Icons.help_outline;
    } else if (saved.isFound && saved.isApproved) {
      colors = StatusColors.approved(context);
      icon = Icons.check_circle_outline;
    } else if (saved.isFound && saved.isRefused) {
      colors = StatusColors.refused(context);
      icon = Icons.cancel_outlined;
    } else {
      colors = StatusColors.notPublishedYet(context);
      icon = Icons.hourglass_empty;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.foreground),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: colors.foreground),
          ),
        ],
      ),
    );
  }
}

class _WatchToggle extends StatelessWidget {
  final bool enabled;
  final ValueChanged<bool> onChanged;
  const _WatchToggle(
      {required this.enabled, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          enabled
              ? Icons.notifications_active
              : Icons.notifications_none,
          size: 16,
          color: enabled
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade400,
        ),
        const SizedBox(width: 2),
        Text(
          'Notify',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: Colors.grey.shade600),
        ),
        Transform.scale(
          scale: 0.8,
          child: Switch(
            value: enabled,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }
}
