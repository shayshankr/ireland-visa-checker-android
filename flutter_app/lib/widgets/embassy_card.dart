import 'package:flutter/material.dart';

import '../models/embassy_info.dart';

class EmbassyCard extends StatelessWidget {
  final EmbassyInfo embassy;
  const EmbassyCard({super.key, required this.embassy});

  @override
  Widget build(BuildContext context) {
    final available = embassy.available;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
                  available ? Colors.green.shade100 : Colors.grey.shade100,
              child: Icon(
                Icons.location_city,
                color: available ? Colors.green.shade700 : Colors.grey,
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
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ],
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: available ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: available ? Colors.green.shade300 : Colors.grey.shade300),
      ),
      child: Text(
        available ? 'Live' : 'Unavailable',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: available ? Colors.green.shade700 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
