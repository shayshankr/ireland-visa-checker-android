import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/embassy_info.dart';
import '../theme/status_colors.dart';

class EmbassyCard extends StatelessWidget {
  final EmbassyInfo embassy;
  const EmbassyCard({super.key, required this.embassy});

  Future<void> _openSource() async {
    final uri = Uri.parse(embassy.source);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = embassy.available;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _openSource,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: available
                    ? StatusColors.approved(context).background
                    : StatusColors.neutral(context).background,
                child: Icon(
                  Icons.location_city,
                  color: available
                      ? StatusColors.approved(context).foreground
                      : StatusColors.neutral(context).foreground,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      embassy.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.update,
                            size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Updates ${embassy.cadence}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatusChip(available: available),
                  const SizedBox(height: 4),
                  Text(
                    '${embassy.recordCount} records',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(Icons.open_in_new,
                  size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool available;
  const _StatusChip({required this.available});

  @override
  Widget build(BuildContext context) {
    final colors =
        available ? StatusColors.approved(context) : StatusColors.neutral(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        available ? 'Live' : 'Unavailable',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: colors.foreground,
        ),
      ),
    );
  }
}
