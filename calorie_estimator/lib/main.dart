// main.dart
// Calorie Estimator — UI-first scaffold
// Single-file Flutter app to start iterating quickly.
// - Paste or type foods, tap Estimate to see a mock total and per-item chips
// - Optional image button reserved for future OCR flow (disabled for now)
// - Simple in-memory history list
//
// Next steps (non-UI): wire up lightweight AI/ML for parsing + estimation.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalorieEstimatorApp());
}

class CalorieEstimatorApp extends StatelessWidget {
  const CalorieEstimatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB));
    return MaterialApp(
      title: 'Calorie Estimator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _inputFocus = FocusNode();

  // In-memory history of queries
  final List<_HistoryItem> _history = [];

  _EstimateResult? _result;
  bool _isEstimating = false;

  @override
  void dispose() {
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null && data.text != null && data.text!.trim().isNotEmpty) {
      setState(() => _controller.text = data.text!.trim());
    }
  }

  Future<void> _estimate() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      _shakeField();
      return;
    }

    setState(() {
      _isEstimating = true;
      _result = null;
    });

    // Simulate parsing + estimation. Replace with real AI later.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final result = _MockEstimator.estimate(raw);

    setState(() {
      _isEstimating = false;
      _result = result;
      _history.insert(0, _HistoryItem(input: raw, result: result, at: DateTime.now()));
    });

    // Move focus off the text field so result is visible
    _inputFocus.unfocus();
  }

  void _clear() {
    setState(() {
      _controller.clear();
      _result = null;
    });
    _inputFocus.requestFocus();
  }

  // Simple attention cue when input is empty
  void _shakeField() {
    // A lightweight visual cue: temporarily change the hint text color by rebuilding
    // (Alternatively you can add an animated shake; keeping it minimal here.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add some foods first (e.g., "2 eggs, toast with butter, black coffee")')),
    );
    _inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Estimator'),
        actions: [
          IconButton(
            tooltip: 'Paste',
            onPressed: _pasteFromClipboard,
            icon: const Icon(Icons.content_paste_go_rounded),
          ),
          IconButton(
            tooltip: 'Clear',
            onPressed: _controller.text.isEmpty && _result == null ? null : _clear,
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _InputCard(
              controller: _controller,
              focusNode: _inputFocus,
              onEstimate: _isEstimating ? null : _estimate,
            ),
            const SizedBox(height: 16),
            if (_isEstimating)
              const _LoadingCard()
            else if (_result != null)
              _ResultCard(result: _result!),
            const SizedBox(height: 16),
            _HistorySection(history: _history, onReRun: (item) {
              setState(() => _controller.text = item.input);
              _estimate();
            }),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isEstimating ? null : _estimate,
        icon: const Icon(Icons.local_fire_department),
        label: const Text('Estimate'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null, // reserved for future OCR flow
                  icon: const Icon(Icons.photo_camera_back_outlined),
                  label: const Text('Scan Label (soon)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null, // reserved for barcode flow
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Text('Scan Barcode (soon)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InputCard extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEstimate;

  const _InputCard({
    required this.controller,
    required this.focusNode,
    required this.onEstimate,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('What did you eat?', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              focusNode: focusNode,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              minLines: 3,
              maxLines: 8,
              decoration: const InputDecoration(
                hintText: 'e.g., 2 eggs, 1 slice whole-wheat toast with butter, 1 banana, 8 oz orange juice',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onEstimate,
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Estimate'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => controller.clear(),
                  icon: const Icon(Icons.backspace_outlined),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Tip: Paste a menu description or grocery list. The app will parse items and estimate calories.',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: const [
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.6)),
            SizedBox(width: 12),
            Expanded(child: Text('Estimating…')),
          ],
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final _EstimateResult result;
  const _ResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: cs.primary),
                const SizedBox(width: 8),
                Text('Estimated Calories', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${result.totalCalories} kcal',
                    style: TextStyle(color: cs.onPrimaryContainer, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.items.map((e) => _CalorieChip(item: e)).toList(),
            ),
            const SizedBox(height: 12),
            Divider(color: cs.outlineVariant),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Mock estimation for UI. Replace with your AI-powered parser/model next.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _CalorieChip extends StatelessWidget {
  final _CalorieItem item;
  const _CalorieChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Text('· ${item.calories} kcal', style: TextStyle(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<_HistoryItem> history;
  final ValueChanged<_HistoryItem> onReRun;
  const _HistorySection({required this.history, required this.onReRun});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...history.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => onReRun(h),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.history_rounded),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                h.input,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(_formatTime(h.at), style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: h.result.items.take(4).map((e) => _CalorieChip(item: e)).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )),
      ],
    );
  }
}

String _formatTime(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(dt.year, dt.month, dt.day);
  if (d == today) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ampm';
  }
  return '${dt.month}/${dt.day}/${dt.year}';
}

// ——— Mock estimation engine ———
class _MockEstimator {
  static _EstimateResult estimate(String raw) {
    // Split by commas and newlines; very naive tokenizer
    final parts = raw
        .split(RegExp(r'[\n,]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // Fake calorie dictionary. Replace via your model later.
    const baseCalories = <String, int>{
      'egg': 78,
      'eggs': 78,
      'banana': 105,
      'toast': 75,
      'butter': 102, // per tbsp
      'coffee': 2,
      'orange juice': 112, // 8 oz
      'milk': 122, // 8 oz whole milk
      'chicken breast': 165, // per 100g cooked
      'rice': 206, // 1 cup cooked
      'apple': 95,
      'yogurt': 150,
      'oatmeal': 158,
    };

    final items = <_CalorieItem>[];

    for (final p in parts) {
      final label = p;
      final lower = p.toLowerCase();

      // Try to match known keys; quick heuristic for quantity like "2 eggs"
      int cals = 0;
      bool matched = false;
      for (final entry in baseCalories.entries) {
        if (lower.contains(entry.key)) {
          matched = true;
          final qtyMatch = RegExp(r'(^|\s)(\d{1,2})\s').firstMatch(lower);
          final qty = qtyMatch != null ? int.parse(qtyMatch.group(2)!) : 1;
          cals = entry.value * qty;
          break;
        }
      }

      if (!matched) {
        // Fallback: average 120 kcal per item
        cals = 120;
      }

      items.add(_CalorieItem(label: label, calories: cals));
    }

    final total = items.fold<int>(0, (sum, e) => sum + e.calories);
    return _EstimateResult(totalCalories: total, items: items);
  }
}

class _EstimateResult {
  final int totalCalories;
  final List<_CalorieItem> items;
  const _EstimateResult({required this.totalCalories, required this.items});
}

class _CalorieItem {
  final String label;
  final int calories;
  const _CalorieItem({required this.label, required this.calories});
}

class _HistoryItem {
  final String input;
  final _EstimateResult result;
  final DateTime at;
  _HistoryItem({required this.input, required this.result, required this.at});
}
