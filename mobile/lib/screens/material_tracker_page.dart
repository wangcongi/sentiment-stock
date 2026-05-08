import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/material.dart';
import '../services/supabase_service.dart';

/// 原材料价格跟踪页
class MaterialTrackerPage extends ConsumerWidget {
  const MaterialTrackerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final supabase = ref.watch(supabaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('原材料跟踪'),
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: supabase
            .from('materials')
            .select('*, material_prices(price, change_pct, change_7d, recorded_at)')
            .order('recorded_at', referencedTable: 'material_prices', ascending: false)
            .limit(1, referencedTable: 'material_prices'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('加载失败: ${snapshot.error}'));
          }
          final materials =
              snapshot.data?.map((j) => MaterialModel.fromJson(j)).toList() ?? [];

          return RefreshIndicator(
            onRefresh: () async {
              // 触发刷新
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: materials.length,
              itemBuilder: (_, i) => _MaterialCard(material: materials[i]),
            ),
          );
        },
      ),
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final MaterialModel material;
  const _MaterialCard({required this.material});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: 价格详情/走势图页面
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：名称 + 类别 + 价格
              Row(
                children: [
                  Icon(
                    _categoryIcon(material.category),
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    material.name,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _categoryLabel(material.category),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${material.latestPrice ?? "-"}',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(material.unit, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 涨跌幅
              Row(
                children: [
                  _ChangeChip(label: '日涨跌', value: material.changePct),
                  const SizedBox(width: 12),
                  _ChangeChip(label: '7日涨跌', value: material.change7d),
                  const Spacer(),
                  // 关联公司数量
                  if (material.linkedCompanies.isNotEmpty)
                    Text(
                      '${material.linkedCompanies.length}家关联公司',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String cat) => switch (cat) {
    'energy' => Icons.local_fire_department,
    'chemical' => Icons.science,
    'metal' => Icons.diamond,
    'fiber' => Icons.cable,
    _ => Icons.inventory,
  };

  String _categoryLabel(String cat) => switch (cat) {
    'energy' => '能源',
    'chemical' => '化工',
    'metal' => '金属',
    'fiber' => '光纤',
    _ => '其他',
  };
}

class _ChangeChip extends StatelessWidget {
  final String label;
  final double? value;
  const _ChangeChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value ?? 0;
    final isUp = v >= 0;
    final color = isUp ? Colors.red : Colors.green;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: theme.textTheme.bodySmall),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '${isUp ? '+' : ''}${v.toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
