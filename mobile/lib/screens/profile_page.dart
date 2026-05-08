import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 个人页 — 关注管理、设置
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户头像区
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '情报员',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  '监控中: 10位名人 · 10种原材料',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 功能菜单
          _MenuCard(
            title: '关注管理',
            icon: Icons.people,
            children: [
              _MenuTile(
                icon: Icons.person_add,
                title: '已关注名人',
                subtitle: '管理监控账号列表',
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.factory,
                title: '原材料订阅',
                subtitle: '管理原材料监控',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          _MenuCard(
            title: '推送设置',
            icon: Icons.notifications,
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.push_pin),
                title: const Text('推送通知'),
                subtitle: const Text('重要舆情实时推送'),
                value: true,
                onChanged: (_) {},
              ),
              SwitchListTile(
                secondary: const Icon(Icons.vibration),
                title: const Text('震动提醒'),
                subtitle: const Text('热度超过阈值时震动'),
                value: false,
                onChanged: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 12),

          _MenuCard(
            title: '其他',
            icon: Icons.settings,
            children: [
              _MenuTile(
                icon: Icons.dark_mode,
                title: '深色模式',
                subtitle: '跟随系统',
                onTap: () {},
              ),
              _MenuTile(
                icon: Icons.info_outline,
                title: '关于舆股',
                subtitle: 'v1.0.0',
                onTap: () {},
              ),
            ],
          ),
          const SizedBox(height: 24),
          // 订阅状态
          Center(
            child: Text(
              '免费版 · 每日100条推送',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _MenuCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 22),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }
}
