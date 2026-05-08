import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/supabase_service.dart';

/// 预警设置页
class AlertsPage extends ConsumerStatefulWidget {
  const AlertsPage({super.key});

  @override
  ConsumerState<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends ConsumerState<AlertsPage> {
  final _keywordController = TextEditingController();
  double _minHeat = 100;

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('智能预警'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 添加关键词监控
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('关键词监控', style: theme.textTheme.titleSmall),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _keywordController,
                    decoration: InputDecoration(
                      hintText: '输入监控关键词，如"关税"、"芯片"',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_circle),
                        onPressed: _addAlert,
                      ),
                    ),
                    onSubmitted: (_) => _addAlert(),
                  ),
                  const SizedBox(height: 12),
                  Text('最低热度阈值', style: theme.textTheme.bodySmall),
                  Slider(
                    value: _minHeat,
                    min: 50,
                    max: 500,
                    divisions: 9,
                    label: _minHeat.toInt().toString(),
                    onChanged: (v) => setState(() => _minHeat = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 活跃预警列表
          Text('当前预警规则', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          _buildAlertList(),
        ],
      ),
    );
  }

  void _addAlert() async {
    final keyword = _keywordController.text.trim();
    if (keyword.isEmpty) return;

    final supabase = ref.read(supabaseProvider);
    await supabase.from('alerts').insert({
      'keyword': keyword,
      'min_heat': _minHeat,
      'enabled': true,
    });

    _keywordController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已添加监控: $keyword')),
      );
    }
  }

  Widget _buildAlertList() {
    final supabase = ref.watch(supabaseProvider);

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: supabase.from('alerts').select('*').eq('enabled', true),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  '暂无预警规则\n添加关键词开始监控',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          children: alerts.map((alert) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.search),
                title: Text(alert['keyword'] ?? ''),
                subtitle: Text('热度阈值: ${alert['min_heat']}'),
                trailing: Switch(
                  value: alert['enabled'] ?? true,
                  onChanged: (v) async {
                    await supabase
                        .from('alerts')
                        .update({'enabled': v})
                        .eq('id', alert['id']);
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
