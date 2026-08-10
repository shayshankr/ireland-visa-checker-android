import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

void showAboutSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const _AboutSheet(),
  );
}

class _AboutSheet extends StatelessWidget {
  const _AboutSheet();

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // App identity
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF169B62),
                  radius: 24,
                  child: Text(
                    'IE',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ireland Visa Checker',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold)),
                    Text('Version 1.1.0',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(),

            // Info rows
            const _InfoRow(
              icon: Icons.info_outline,
              text:
                  'Checks visa decisions published by Irish embassies in New Delhi, Beijing, Abu Dhabi, and Abuja.',
            ),
            const _InfoRow(
              icon: Icons.schedule_outlined,
              text:
                  'Embassy data refreshes every 5–15 minutes from official ireland.ie pages.',
            ),
            const _InfoRow(
              icon: Icons.notifications_active_outlined,
              text:
                  'Enable "Notify" on a saved number to receive a push notification when your decision is published.',
            ),
            _InfoRow(
              icon: Icons.warning_amber_outlined,
              color: Colors.orange.shade700,
              text:
                  'Unofficial tool. Not affiliated with INIS or the Irish government.',
            ),

            const Divider(),

            // Actions
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading:
                  const Icon(Icons.share_outlined, color: Color(0xFF169B62)),
              title: const Text('Share this app'),
              onTap: () => Share.share(
                'Check your Ireland visa decision with the Ireland Visa Checker app.',
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.open_in_browser_outlined,
                  color: Color(0xFF169B62)),
              title: const Text('Data source: ireland.ie'),
              onTap: () => _openUrl('https://www.ireland.ie'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  const _InfoRow({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: c),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
