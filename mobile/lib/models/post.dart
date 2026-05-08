/// 帖子数据模型
class PostModel {
  final String id;
  final String content;
  final String platform; // 'x' | 'truth_social'
  final String? originalUrl;
  final DateTime postedAt;
  final int likes;
  final int shares;
  final int comments;
  final double heatScore;
  final String? sentiment;
  final String? celebrityName;
  final String? celebrityHandle;
  final String? celebrityAvatar;
  final List<LinkedCompany> linkedCompanies;

  PostModel({
    required this.id,
    required this.content,
    required this.platform,
    this.originalUrl,
    required this.postedAt,
    this.likes = 0,
    this.shares = 0,
    this.comments = 0,
    this.heatScore = 0,
    this.sentiment,
    this.celebrityName,
    this.celebrityHandle,
    this.celebrityAvatar,
    this.linkedCompanies = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      content: json['content'] ?? '',
      platform: json['platform'] ?? 'x',
      originalUrl: json['original_url'],
      postedAt: DateTime.parse(json['posted_at']),
      likes: json['likes'] ?? 0,
      shares: json['shares'] ?? 0,
      comments: json['comments'] ?? 0,
      heatScore: (json['heat_score'] ?? 0).toDouble(),
      sentiment: json['sentiment'],
      celebrityName: json['celebrities']?['name'],
      celebrityHandle: json['celebrities']?['handle'],
      celebrityAvatar: json['celebrities']?['avatar_url'],
      linkedCompanies: (json['post_companies'] as List<dynamic>?)
              ?.map((pc) => LinkedCompany.fromJson(pc))
              .toList() ??
          [],
    );
  }
}

/// 关联公司
class LinkedCompany {
  final String companyId;
  final double relevanceScore;
  final List<String> keywordsMatched;
  final String? companyCode;
  final String? companyName;
  final String? sector;

  LinkedCompany({
    required this.companyId,
    this.relevanceScore = 0,
    this.keywordsMatched = const [],
    this.companyCode,
    this.companyName,
    this.sector,
  });

  factory LinkedCompany.fromJson(Map<String, dynamic> json) {
    return LinkedCompany(
      companyId: json['company_id'] ?? json['companies']?['id'] ?? '',
      relevanceScore: (json['relevance_score'] ?? 0).toDouble(),
      keywordsMatched: List<String>.from(json['keywords_matched'] ?? []),
      companyCode: json['companies']?['code'],
      companyName: json['companies']?['name'],
      sector: json['companies']?['sector'],
    );
  }
}
