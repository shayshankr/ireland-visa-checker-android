import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/visa_result.dart';
import '../providers/visa_provider.dart';
import 'decision_badge.dart';

class CheckTab extends StatefulWidget {
  const CheckTab({super.key});

  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<VisaProvider>().checkApplication(_controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VisaProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchCard(
                formKey: _formKey,
                controller: _controller,
                onSubmit: _submit,
              ),
              const SizedBox(height: 16),
              if (provider.checkState == LoadState.loading)
                const Center(child: CircularProgressIndicator()),
              if (provider.checkState == LoadState.error)
                _ErrorCard(message: provider.error),
              if (provider.checkState == LoadState.success &&
                  provider.checkResult != null)
                _ResultSection(result: provider.checkResult!),
              const SizedBox(height: 8),
              const _InfoExpansionTile(
                icon: Icons.help_outline,
                title: 'How to use this tool',
                iconColor: Colors.blueGrey,
                children: [
                  _BulletItem('Enter your 8-digit Ireland visa application number (e.g. 63690452) or with IRL prefix (e.g. IRL63690452).'),
                  _BulletItem('Tap "Check Status" to search across all 5 Irish embassy decision lists.'),
                  _BulletItem('If your number is found, the embassy name and decision (Approved / Refused) will be shown.'),
                  _BulletItem('If not found yet, two nearest published numbers are shown as a reference — your decision may be published soon.'),
                  _BulletItem('Data refreshes automatically every 5–15 minutes from official embassy pages.'),
                ],
              ),
              const SizedBox(height: 8),
              _EmbassyLinksExpansionTile(),
            ],
          ),
        );
      },
    );
  }
}

// ── Search input card ─────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const _SearchCard({
    required this.formKey,
    required this.controller,
    required this.onSubmit,
  });

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter an application number';
    final digits = v.trim().replaceAll(RegExp(r'^[Ii][Rr][Ll]'), '').replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) return 'Must be 8 digits — e.g. 63690452';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Check your visa decision',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Accepted formats: 63690452  or  IRL63690452',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  labelText: 'Application number',
                  hintText: 'e.g. 63690452',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: _validate,
                onFieldSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onSubmit,
                icon: const Icon(Icons.search),
                label: const Text('Check Status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Result section ────────────────────────────────────────────────────────────

class _ResultSection extends StatelessWidget {
  final CheckResponse result;
  const _ResultSection({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result.found) {
      return Column(
        children: result.results
            .map((r) => _FoundCard(result: r))
            .toList(),
      );
    }
    return _NotFoundCard(response: result);
  }
}

class _FoundCard extends StatelessWidget {
  final VisaResult result;
  const _FoundCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: DecisionBadge(decision: result.decision),
        title: Text(
          result.embassy,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(result.source, maxLines: 1, overflow: TextOverflow.ellipsis),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: result.isApproved
                ? Colors.green.shade100
                : Colors.red.shade100,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            result.decision,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: result.isApproved
                  ? Colors.green.shade800
                  : Colors.red.shade800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  final CheckResponse response;
  const _NotFoundCard({required this.response});

  @override
  Widget build(BuildContext context) {
    final nearest = response.nearest;
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.info_outline, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Text(
                'Not found',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade800,
                  fontSize: 16,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Text(
              'Application ${response.applicationNumber} is not in current published records.',
            ),
            if (nearest != null && nearest.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'Nearest published numbers:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (nearest['before'] != null)
                _NearestRow(label: 'Before', entry: nearest['before']!),
              if (nearest['after'] != null)
                _NearestRow(label: 'After', entry: nearest['after']!),
            ],
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.grey)),
          Text(
            entry.number,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: entry.isApproved
                  ? Colors.green.shade100
                  : Colors.red.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              entry.decision,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: entry.isApproved
                    ? Colors.green.shade800
                    : Colors.red.shade800,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '(${entry.embassy})',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          if (entry.difference != null) ...[
            const SizedBox(width: 6),
            Text(
              'Δ ${entry.difference}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── How to use / Embassy links expansion tiles ────────────────────────────────

class _InfoExpansionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final List<Widget> children;

  const _InfoExpansionTile({
    required this.icon,
    required this.title,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: iconColor),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: children,
      ),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final String text;
  const _BulletItem(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('>> ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

// ── Embassy links expansion tile ──────────────────────────────────────────────

class _EmbassyLinksExpansionTile extends StatelessWidget {
  static const _embassies = [
    {'name': 'New Delhi (India)',   'url': 'https://www.ireland.ie/en/india/newdelhi/services/visas/processing-times-and-decisions/'},
    {'name': 'Beijing (China)',     'url': 'https://www.ireland.ie/en/china/beijing/services/visas/visa-decisions/'},
    {'name': 'Abu Dhabi (UAE)',     'url': 'https://www.ireland.ie/en/uae/abudhabi/services/visas/weekly-decision-reports/'},
    {'name': 'Abuja (Nigeria)',     'url': 'https://www.ireland.ie/en/nigeria/abuja/services/visas/weekly-decision-reports/'},
  ];

  const _EmbassyLinksExpansionTile();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
        title: const Text(
          'If any error, tap here',
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.orange),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              'Check decisions directly on the official embassy pages:',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          ..._embassies.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                side: BorderSide(color: Colors.orange.shade200),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.open_in_browser, size: 18, color: Colors.orange),
              label: Text(
                e['name']!,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              onPressed: () => _open(e['url']!),
            ),
          )),
        ],
      ),
    );
  }
}
