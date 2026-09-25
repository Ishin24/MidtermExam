class DotaHero {
  final int? id;
  final String name;
  final String localizedName;
  final String primaryAttr;
  final String attackType;
  final String roles;
  final String imgUrl;
  final String lore;

  DotaHero({
    this.id,
    required this.name,
    required this.localizedName,
    required this.primaryAttr,
    required this.attackType,
    this.roles = '',
    this.imgUrl = '',
    this.lore = '',
  });

  factory DotaHero.fromJson(Map<String, dynamic> json) {
    return DotaHero(
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}'),
      name: json['name'] ?? '',
      localizedName: json['localized_name'] ?? '',
      primaryAttr: json['primary_attr'] ?? '',
      attackType: json['attack_type'] ?? '',
      roles: json['roles'] ?? '',
      imgUrl: json['img_url'] ?? '',
      lore: json['lore'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'localized_name': localizedName,
      'primary_attr': primaryAttr,
      'attack_type': attackType,
      'roles': roles,
      'img_url': imgUrl,
      'lore': lore,
    };
  }

  List<String> get roleList =>
      roles.split(',').map((r) => r.trim()).where((r) => r.isNotEmpty).toList();
}
