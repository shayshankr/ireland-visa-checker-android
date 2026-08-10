import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/visa_provider.dart';
import 'embassy_card.dart';
import 'stats_row.dart';

class EmbassiesTab extends StatelessWidget {
  const EmbassiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VisaProvider>(
      builder: (context, provider, _) {
        if (provider.dashboardState == LoadState.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.dashboardState == LoadState.error) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.wifi_off, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    provider.error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => provider.loadDashboard(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => provider.loadDashboard(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.dashboardFromCache &&
                  provider.cacheTimestamp != null)
                _CacheIndicator(timestamp: provider.cacheTimestamp!),
              if (provider.stats != null) ...[
                StatsRow(stats: provider.stats!),
                const SizedBox(height: 16),
              ],
              const Text(
                'Embassy Status',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...provider.embassies.map((e) => EmbassyCard(embassy: e)),
              const SizedBox(height: 8),
              Text(
                'Pull down to refresh  •  Tap a card to view official page',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                'Data sourced from ireland.ie',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CacheIndicator extends StatelessWidget {
  final DateTime timestamp;
  const _CacheIndicator({required this.timestamp});

  String _age() {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d, HH:mm').format(timestamp);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Cached ${_age()}  •  Refreshing…',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
