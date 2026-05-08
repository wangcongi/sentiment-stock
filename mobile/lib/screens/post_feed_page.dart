import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../services/supabase_service.dart';
import '../models/post.dart';

/// 舆情Feed页 — 名人帖子流
class PostFeedPage extends ConsumerWidget {
  const PostFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('实时舆情'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: 筛选名人/平台
            },
          ),
        ],
      ),
      body: postsAsync.when(
        data: (data) {
          final posts = data.map((j) => PostModel.fromJson(j)).toList();
          if (posts.isEmpty) {
            return const Center(child: Text('暂无数据，等待爬虫采集...'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(postsStreamProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: posts.length,
              itemBuilder: (_, i) => _PostCard(post: posts[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentimentColor = switch (post.sentiment) {
      'positive' => Colors.green,
      'negative' => Colors.red,
      _ => Colors.grey,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // TODO: 详情页
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头部：头像 + 名人 + 平台 + 时间
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Text(
                      (post.celebrityName ?? 'U')[0],
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.celebrityName ?? 'Unknown',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '@${post.celebrityHandle} · ${_platformLabel(post.platform)} · ${timeago.format(post.postedAt, locale: 'zh')}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 情感标签
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sentimentColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _sentimentLabel(post.sentiment),
                      style: TextStyle(fontSize: 12, color: sentimentColor, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // 正文
              Text(
                post.content,
                style: theme.textTheme.bodyMedium,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
              // 关联A股标签
              if (post.linkedCompanies.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: post.linkedCompanies.map((lc) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${lc.companyName ?? lc.companyCode} \$${lc.companyCode}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              // 底部互动数据
              const SizedBox(height: 10),
              Row(
                children: [
                  _StatChip(icon: Icons.favorite_border, value: post.likes),
                  const SizedBox(width: 16),
                  _StatChip(icon: Icons.repeat, value: post.shares),
                  const SizedBox(width: 16),
                  _StatChip(icon: Icons.chat_bubble_outline, value: post.comments),
                  const Spacer(),
                  Icon(Icons.open_in_new, size: 16, color: theme.colorScheme.onSurfaceVariant),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _platformLabel(String platform) => platform == 'x' ? 'X' : 'Truth Social';

  String _sentimentLabel(String? sentiment) => switch (sentiment) {
    'positive' => '利多',
    'negative' => '利空',
    _ => '中性',
  };
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final int value;
  const _StatChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 3),
        Text(
          value > 999 ? '${(value / 1000).toStringAsFixed(1)}K' : value.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
