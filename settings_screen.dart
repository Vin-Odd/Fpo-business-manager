import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../database/app_database.dart';
import '../../../database/database_provider.dart';
import '../services/export_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _invoicePrefixController = TextEditingController();
  final _nextInvoiceNumberController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  // One-off fetch (first emission of the stream), not a live watch —
  // same reasoning as ProductFormScreen's edit mode: populate the form
  // once, then let the user's in-progress edits be the source of truth
  // until they save, rather than the row changing under them mid-edit.
  Future<void> _load() async {
    final settings = await ref.read(settingsDaoProvider).watchSettings().first;
    if (!mounted) return;
    _businessNameController.text = settings.businessName;
    _addressController.text = settings.address;
    _gstController.text = settings.gstOrTaxId ?? '';
    _taxRateController.text = settings.taxRatePercent.toStringAsFixed(2);
    _invoicePrefixController.text = settings.invoicePrefix;
    _nextInvoiceNumberController.text = settings.nextInvoiceNumber.toString();
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _taxRateController.dispose();
    _invoicePrefixController.dispose();
    _nextInvoiceNumberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final gst = _gstController.text.trim();
      await ref.read(settingsDaoProvider).updateSettings(
            BusinessSettingsCompanion(
              businessName: Value(_businessNameController.text.trim()),
              address: Value(_addressController.text.trim()),
              gstOrTaxId: Value(gst.isEmpty ? null : gst),
              taxRatePercent: Value(double.parse(_taxRateController.text)),
              invoicePrefix: Value(_invoicePrefixController.text.trim()),
              nextInvoiceNumber:
                  Value(int.parse(_nextInvoiceNumberController.text)),
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Settings saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save settings.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    try {
      await ref.read(exportServiceProvider).exportAll();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export data.')),
        );
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Business Details', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business Name'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _gstController,
              decoration:
                  const InputDecoration(labelText: 'GST / Tax ID (optional)'),
            ),
            const SizedBox(height: 24),
            Text('Tax', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _taxRateController,
              decoration: const InputDecoration(labelText: 'Tax Rate (%)'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final parsed = double.tryParse(v ?? '');
                if (parsed == null || parsed < 0 || parsed > 100) {
                  return 'Enter a value between 0 and 100';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Invoicing', style: theme.textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              child: Text(
                'Used once PDF invoice generation is added — not built yet.',
                style: theme.textTheme.bodySmall,
              ),
            ),
            TextFormField(
              controller: _invoicePrefixController,
              decoration: const InputDecoration(labelText: 'Invoice Prefix'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nextInvoiceNumberController,
              decoration:
                  const InputDecoration(labelText: 'Next Invoice Number'),
              keyboardType: TextInputType.number,
              validator: (v) {
                final parsed = int.tryParse(v ?? '');
                if (parsed == null || parsed < 1) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save Settings'),
            ),
            const SizedBox(height: 32),
            Text('Data Export', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Exports Products and Sales as CSV files you can save or share.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _exporting ? null : _export,
              icon: _exporting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share),
              label: const Text('Export Data (CSV)'),
            ),
          ],
        ),
      ),
    );
  }
}
