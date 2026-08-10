import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/saved_number.dart';
import '../providers/saved_numbers_provider.dart';
import '../services/notification_service.dart';
import '../services/saved_numbers_service.dart';
import '../theme/status_colors.dart';
import 'saved_number_card.dart';

class SavedNumbersTab extends StatelessWidget {
  const SavedNumbersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SavedNumbersProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return Stack(
          children: [
            provider.numbers.isEmpty
                ? _EmptyState(
                    onAdd: () => _showAddDialog(context, provider))
                : _NumberList(provider: provider),
            Positioned(
              bottom: 20,
              right: 20,
              child: FloatingActionButton(
                heroTag: 'saved_numbers_fab',
                onPressed: () => _showAddDialog(context, provider),
                tooltip: 'Add number',
                child: const Icon(Icons.add),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(
      BuildContext context, SavedNumbersProvider provider) {
    final numberController = TextEditingController();
    final labelController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    DateTime? submittedDate;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Application Number'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: numberController,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Application number',
                    hintText: 'e.g. 63690452 or IRL63690452',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Enter an application number';
                    }
                    final digits = SavedNumbersService.normalize(v);
                    if (digits.length != 8) return 'Must be 8 digits';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: labelController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 40,
                  decoration: const InputDecoration(
                    labelText: 'Label (optional)',
                    hintText: 'e.g. My visa, Spouse\'s application',
                    prefixIcon: Icon(Icons.label_outline),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: submittedDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => submittedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date submitted (optional)',
                      prefixIcon: const Icon(Icons.calendar_today),
                      border: const OutlineInputBorder(),
                      suffixIcon: submittedDate != null
                          ? GestureDetector(
                              onTap: () => setState(() => submittedDate = null),
                              child: const Icon(Icons.close, size: 20),
                            )
                          : null,
                    ),
                    child: Text(
                      submittedDate != null
                          ? 'Submitted ${submittedDate!.day}/${submittedDate!.month}/${submittedDate!.year}'
                          : 'Not set',
                      style: TextStyle(
                        color: submittedDate != null ? Colors.grey.shade800 : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final normalized = SavedNumbersService.normalize(
                      numberController.text.trim());
                  final label = labelController.text.trim();
                  if (!provider.contains(normalized)) {
                    provider.add(SavedNumber(
                      number: normalized,
                      label: label.isNotEmpty ? label : null,
                      submittedDate: submittedDate,
                    ));
                  }
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

}

class _NumberList extends StatelessWidget {
  final SavedNumbersProvider provider;
  const _NumberList({required this.provider});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: provider.numbers.length + 1, // +1 for the header button
      itemBuilder: (context, i) {
        if (i == 0) return _RefreshAllButton(provider: provider);
        final saved = provider.numbers[i - 1];
        return Dismissible(
          key: Key(saved.number),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: StatusColors.refused(context).foreground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline,
                color: Colors.white, size: 26),
          ),
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            provider.remove(saved.number);
          },
          child: SavedNumberCard(
            saved: saved,
            isChecking: provider.isChecking(saved.number),
            onDelete: () => _confirmDelete(context, provider, saved.number),
            onEditLabel: () =>
                _showEditLabelDialog(context, provider, saved),
            onToggleWatch: (enabled) =>
                _handleToggleWatch(context, provider, saved.number, enabled),
            onCheckNow: () => provider.checkNow(saved.number),
          ),
        );
      },
    );
  }

  Future<void> _handleToggleWatch(
    BuildContext context,
    SavedNumbersProvider provider,
    String number,
    bool enabled,
  ) async {
    if (enabled) {
      final granted = await NotificationService.requestPermission();
      if (!granted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Notification permission denied. Enable it in Settings.'),
            ),
          );
        }
        return;
      }
      HapticFeedback.selectionClick();
    }
    await provider.toggleWatch(number, enabled);
  }

  void _showEditLabelDialog(
      BuildContext context, SavedNumbersProvider provider, SavedNumber saved) {
    final controller = TextEditingController(text: saved.label ?? '');
    DateTime? submittedDate = saved.submittedDate;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Details for ${saved.displayNumber}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLength: 40,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Label (optional)',
                  hintText: 'e.g. My visa, Spouse\'s application',
                  prefixIcon: Icon(Icons.label_outline),
                  border: OutlineInputBorder(),
                  counterText: '',
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: submittedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => submittedDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Date submitted (optional)',
                    prefixIcon: const Icon(Icons.calendar_today),
                    border: const OutlineInputBorder(),
                    suffixIcon: submittedDate != null
                        ? GestureDetector(
                            onTap: () => setState(() => submittedDate = null),
                            child: const Icon(Icons.close, size: 20),
                          )
                        : null,
                  ),
                  child: Text(
                    submittedDate != null
                        ? 'Submitted ${submittedDate!.day}/${submittedDate!.month}/${submittedDate!.year}'
                        : 'Not set',
                    style: TextStyle(
                      color: submittedDate != null ? Colors.grey.shade800 : Colors.grey.shade500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            if (saved.label != null)
              TextButton(
                onPressed: () {
                  provider.updateLabel(saved.number, null);
                  if (submittedDate != saved.submittedDate) {
                    provider.updateSubmittedDate(saved.number, submittedDate);
                  }
                  Navigator.pop(ctx);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Remove label'),
              ),
            FilledButton(
              onPressed: () {
                final label = controller.text.trim();
                provider.updateLabel(
                    saved.number, label.isNotEmpty ? label : null);
                if (submittedDate != saved.submittedDate) {
                  provider.updateSubmittedDate(saved.number, submittedDate);
                }
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, SavedNumbersProvider provider, String number) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove number?'),
        content: Text('IRL$number will be removed from My Numbers.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              provider.remove(number);
            },
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _RefreshAllButton extends StatelessWidget {
  final SavedNumbersProvider provider;
  const _RefreshAllButton({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton.icon(
        onPressed: provider.isAnyChecking ? null : provider.checkAll,
        icon: provider.isAnyChecking
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.refresh, size: 18),
        label: Text(
            provider.isAnyChecking ? 'Checking…' : 'Refresh All'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bookmarks_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No saved numbers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Save your application number here to track it.\n'
              'Enable "Notify" on a saved number to get a push\n'
              'notification the moment your decision is published.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade500, height: 1.6),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add a number'),
            ),
          ],
        ),
      ),
    );
  }
}
