/// 原材料数据模型
class MaterialModel {
  final String id;
  final String name;
  final String unit;
  final String category;
  final double? latestPrice;
  final double? changePct;
  final double? change7d;
  final List<MaterialCompany> linkedCompanies;

  MaterialModel({
    required this.id,
    required this.name,
    required this.unit,
    required this.category,
    this.latestPrice,
    this.changePct,
    this.change7d,
    this.linkedCompanies = const [],
  });

  factory MaterialModel.fromJson(Map<String, dynamic> json) {
    final prices = json['material_prices'] as List<dynamic>?;
    final latest = (prices != null && prices.isNotEmpty) ? prices[0] : null;

    return MaterialModel(
      id: json['id'],
      name: json['name'] ?? '',
      unit: json['unit'] ?? '',
      category: json['category'] ?? '',
      latestPrice: latest?['price']?.toDouble(),
      changePct: latest?['change_pct']?.toDouble(),
      change7d: latest?['change_7d']?.toDouble(),
      linkedCompanies: (json['material_companies'] as List<dynamic>?)
              ?.map((mc) => MaterialCompany.fromJson(mc))
              .toList() ??
          [],
    );
  }
}

class MaterialCompany {
  final String companyId;
  final String impactType;
  final double impactScore;
  final String? companyCode;
  final String? companyName;

  MaterialCompany({
    required this.companyId,
    required this.impactType,
    this.impactScore = 0,
    this.companyCode,
    this.companyName,
  });

  factory MaterialCompany.fromJson(Map<String, dynamic> json) {
    return MaterialCompany(
      companyId: json['company_id'] ?? '',
      impactType: json['impact_type'] ?? '',
      impactScore: (json['impact_score'] ?? 0).toDouble(),
      companyCode: json['companies']?['code'],
      companyName: json['companies']?['name'],
    );
  }
}
