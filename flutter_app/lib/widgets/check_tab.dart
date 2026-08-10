import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/saved_number.dart';
import '../models/visa_result.dart';
import '../providers/saved_numbers_provider.dart';
import '../providers/visa_provider.dart';
import '../theme/status_colors.dart';
import '../services/saved_numbers_service.dart';
import 'decision_badge.dart';
import 'nearest_numbers_panel.dart';

class CheckTab extends StatefulWidget {
  const CheckTab({super.key});

  @override
  State<CheckTab> createState() => _CheckTabState();
}

class _CheckTabState extends State<CheckTab> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  LoadState _prevState = LoadState.idle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VisaProvider>().addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    final provider = context.read<VisaProvider>();
    if (_prevState == LoadState.loading) {
      if (provider.checkState == LoadState.success) {
        HapticFeedback.mediumImpact();
      } else if (provider.checkState == LoadState.error) {
        HapticFeedback.heavyImpact();
      }
    }
    _prevState = provider.checkState;
  }

  @override
  void dispose() {
    context.read<VisaProvider>().removeListener(_onProviderChange);
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<VisaProvider>().checkApplication(_controller.text.trim());
  }

  void _onClear() {
    _controller.clear();
    context.read<VisaProvider>().resetCheck();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<VisaProvider, SavedNumbersProvider>(
      builder: (context, provider, savedProvider, _) {
        final normalized =
            SavedNumbersService.normalize(_controller.text.trim());
        return RefreshIndicator(
          onRefresh: () async {
            final last = provider.lastCheckedNumber;
            if (last.isNotEmpty) {
              _controller.text = last;
              await provider.checkApplication(last);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SearchCard(
                  formKey: _formKey,
                  controller: _controller,
                  onSubmit: _submit,
                  onClear: _onClear,
                ),
                const SizedBox(height: 16),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.06),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOut,
                      )),
                      child: child,
                    ),
                  ),
                  child: _buildResult(provider, normalized, savedProvider),
                ),
                const SizedBox(height: 8),
                const _InfoExpansionTile(
                  icon: Icons.help_outline,
                  title: 'How to use this tool',
                  iconColor: Colors.blueGrey,
                  children: [
                    _BulletItem(
                        'Enter your 8-digit Ireland visa application number '
                        '(e.g. 63690452) or with IRL prefix (e.g. IRL63690452).'),
                    _BulletItem(
                        'Tap "Check Status" to search across all Irish embassy decision lists.'),
                    _BulletItem(
                        'If found, the embassy name and decision (Approved / Refused) will be shown.'),
                    _BulletItem(
                        'If not found yet, the two nearest published numbers are shown so you can estimate when yours will appear.'),
                    _BulletItem(
                        'Pull down to re-check the same number instantly.'),
                    _BulletItem(
                        'Data refreshes automatically every 5–15 minutes from official embassy pages.'),
                  ],
                ),
                const SizedBox(height: 8),
                const _EmbassyLinksExpansionTile(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildResult(
    VisaProvider provider,
    String normalized,
    SavedNumbersProvider savedProvider,
  ) {
    if (provider.checkState == LoadState.loading) {
      return const Padding(
        key: ValueKey('loading'),
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.checkState == LoadState.error) {
      return _ErrorCard(
        key: ValueKey('err_${provider.error}'),
        message: provider.error,
      );
    }
    if (provider.checkState == LoadState.success &&
        provider.checkResult != null) {
      return Column(
        key: ValueKey('res_${provider.checkResult!.applicationNumber}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ResultSection(result: provider.checkResult!),
          const SizedBox(height: 6),
          _SaveButton(
            normalizedNumber: normalized,
            checkResult: provider.checkResult!,
            savedProvider: savedProvider,
          ),
        ],
      );
    }
    return const SizedBox.shrink(key: ValueKey('idle'));
  }
}

// ── Search card ───────────────────────────────────────────────────────────────

class _SearchCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final VoidCallback onSubmit;
  final VoidCallback onClear;

  const _SearchCard({
    required this.formKey,
    required this.controller,
    required this.onSubmit,
    required this.onClear,
  });

  String? _validate(String? v) {
    if (v == null || v.trim().isEmpty) return 'Enter an application number';
    final digits = v
        .trim()
        .replaceAll(RegExp(r'^[Ii][Rr][Ll]'), '')
        .replaceAll(RegExp(r'\D'), '');
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
                decoration: InputDecoration(
                  labelText: 'Application number',
                  hintText: 'e.g. 63690452',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: const OutlineInputBorder(),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) => value.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Clear',
                            onPressed: onClear,
                          )
                        : const SizedBox.shrink(),
                  ),
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
            .map((r) => _FoundCard(
                  result: r,
                  applicationNumber: result.applicationNumber,
                ))
            .toList(),
      );
    }
    return _NotFoundCard(response: result);
  }
}

class _FoundCard extends StatelessWidget {
  final VisaResult result;
  final String applicationNumber;

  const _FoundCard({required this.result, required this.applicationNumber});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: 'IRL$applicationNumber'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1)),
    );
  }

  void _share() {
    Share.share(
      'My Ireland visa application IRL$applicationNumber has been '
      '${result.decision} at ${result.embassy}.\n\n'
      'Track your own decision with the Ireland Visa Checker app '
      '(search "Ireland Visa Checker" on Play Store).',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = result.isApproved
        ? StatusColors.approved(context)
        : StatusColors.refused(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colors.border,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 8, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecisionBadge(decision: result.decision),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.embassy,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'IRL$applicationNumber',
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    result.decision,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colors.foreground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.source,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 18),
                  tooltip: 'Copy number',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _copy(context),
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 18),
                  tooltip: 'Share result',
                  visualDensity: VisualDensity.compact,
                  onPressed: _share,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  final CheckResponse response;
  const _NotFoundCard({required this.response});

  void _copy(BuildContext context) {
    Clipboard.setData(
        ClipboardData(text: 'IRL${response.applicationNumber}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Copied to clipboard'),
          duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nearest = response.nearest;
    final beforeDelta = nearest?['before']?.difference;
    final afterDelta = nearest?['after']?.difference;
    final minDelta = [beforeDelta, afterDelta]
        .where((d) => d != null)
        .fold<int?>(null, (m, d) => m == null || d! < m ? d : m);

    final pendingColors = StatusColors.pending(context);
    return Card(
      color: pendingColors.background,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.hourglass_empty, color: pendingColors.foreground),
              const SizedBox(width: 8),
              Text(
                'Not published yet',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: pendingColors.foreground,
                    fontSize: 16),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.copy_outlined, size: 18),
                tooltip: 'Copy number',
                visualDensity: VisualDensity.compact,
                onPressed: () => _copy(context),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              minDelta != null
                  ? 'IRL${response.applicationNumber} is $minDelta numbers away '
                      'from the nearest published decision.'
                  : 'IRL${response.applicationNumber} has not been published yet.',
              style: TextStyle(fontSize: 13, color: pendingColors.foreground),
            ),
            if (nearest != null && nearest.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: NearestNumbersPanel(
                  nearest: nearest,
                  applicationNumber: response.applicationNumber,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Error card ────────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  const _ErrorCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final errorColors = StatusColors.refused(context);
    return Card(
      color: errorColors.background,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: errorColors.foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: TextStyle(color: errorColors.foreground)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  final String normalizedNumber;
  final CheckResponse checkResult;
  final SavedNumbersProvider savedProvider;

  const _SaveButton({
    required this.normalizedNumber,
    required this.checkResult,
    required this.savedProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (normalizedNumber.length != 8) return const SizedBox.shrink();
    final isSaved = savedProvider.contains(normalizedNumber);

    if (isSaved) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.bookmark_added),
        label: const Text('Saved to My Numbers'),
        onPressed: () {
          HapticFeedback.selectionClick();
          savedProvider.remove(normalizedNumber);
        },
      );
    }

    return FilledButton.icon(
      icon: const Icon(Icons.bookmark_add_outlined),
      label: const Text('Save to My Numbers'),
      onPressed: () {
        HapticFeedback.selectionClick();
        savedProvider.add(SavedNumber(
          number: normalizedNumber,
          lastFound: checkResult.found,
          lastDecision:
              checkResult.found && checkResult.results.isNotEmpty
                  ? checkResult.results.first.decision
                  : null,
          lastEmbassy:
              checkResult.found && checkResult.results.isNotEmpty
                  ? checkResult.results.first.embassy
                  : null,
          lastChecked: DateTime.now(),
        ));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Saved! Enable "Notify" in My Numbers to get a decision alert.'),
            duration: Duration(seconds: 3),
          ),
        );
      },
    );
  }
}

// ── Info expansion tiles ──────────────────────────────────────────────────────

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
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: Icon(icon, color: iconColor),
        title: Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w600, color: iconColor)),
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
          const Text('>> ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey)),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 13, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

class _EmbassyLinksExpansionTile extends StatelessWidget {
  static const _embassies = [
    {
      'name': 'New Delhi (India)',
      'url':
          'https://www.ireland.ie/en/india/newdelhi/services/visas/processing-times-and-decisions/'
    },
    {
      'name': 'Beijing (China)',
      'url':
          'https://www.ireland.ie/en/china/beijing/services/visas/visa-decisions/'
    },
    {
      'name': 'Abu Dhabi (UAE)',
      'url':
          'https://www.ireland.ie/en/uae/abudhabi/services/visas/weekly-decision-reports/'
    },
    {
      'name': 'Abuja (Nigeria)',
      'url':
          'https://www.ireland.ie/en/nigeria/abuja/services/visas/weekly-decision-reports/'
    },
  ];

  const _EmbassyLinksExpansionTile();

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ExpansionTile(
        leading: const Icon(Icons.warning_amber_rounded,
            color: Colors.orange),
        title: const Text('If any error, tap here',
            style: TextStyle(
                fontWeight: FontWeight.w600, color: Colors.orange)),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    side: BorderSide(color: Colors.orange.shade200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.open_in_browser,
                      size: 18, color: Colors.orange),
                  label: Text(e['name']!,
                      style: const TextStyle(
                          fontSize: 13, color: Colors.black87)),
                  onPressed: () => _open(e['url']!),
                ),
              )),
        ],
      ),
    );
  }
}
