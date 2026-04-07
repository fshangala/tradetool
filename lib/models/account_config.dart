class AccountConfig {
  final bool dualSidePosition; // true: Hedge Mode; false: One-way Mode
  final bool multiAssetsMargin;

  AccountConfig({
    required this.dualSidePosition,
    required this.multiAssetsMargin,
  });

  factory AccountConfig.fromJson(Map<String, dynamic> json) {
    return AccountConfig(
      dualSidePosition: json['dualSidePosition'] as bool? ?? false,
      multiAssetsMargin: json['multiAssetsMargin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dualSidePosition': dualSidePosition,
      'multiAssetsMargin': multiAssetsMargin,
    };
  }
}
