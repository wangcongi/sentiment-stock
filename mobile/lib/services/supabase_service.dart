import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// 帖子实时订阅
final postsStreamProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return supabase
      .from('posts')
      .stream(primaryKey: ['id'])
      .order('posted_at', ascending: false)
      .limit(50);
});

/// 监听新帖插入事件
final postsRealtimeProvider = StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final supabase = ref.watch(supabaseProvider);
  final controller = StreamController<List<Map<String, dynamic>>>();

  final channel = supabase.channel('posts-changes');
  channel.onPostgresChanges(
    event: PostgresChangeEvent.insert,
    schema: 'public',
    table: 'posts',
    callback: (payload) {
      controller.add([payload.newRecord]);
    },
  );
  channel.subscribe();

  ref.onDispose(() {
    supabase.removeChannel(channel);
    controller.close();
  });

  return controller.stream;
});
