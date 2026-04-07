class AccountAsset {
  final String asset;
  final double walletBalance;
  final double unrealizedProfit;
  final double marginBalance;
  final double maintMargin;
  final double initialMargin;
  final double positionInitialMargin;
  final double openOrderInitialMargin;
  final double crossWalletBalance;
  final double crossUnrealizedProfit;
  final double availableBalance;
  final double maxWithdrawAmount;
  final bool marginAvailable;
  final int updateTime;

  AccountAsset({
    required this.asset,
    required this.walletBalance,
    required this.unrealizedProfit,
    required this.marginBalance,
    required this.maintMargin,
    required this.initialMargin,
    required this.positionInitialMargin,
    required this.openOrderInitialMargin,
    required this.crossWalletBalance,
    required this.crossUnrealizedProfit,
    required this.availableBalance,
    required this.maxWithdrawAmount,
    required this.marginAvailable,
    required this.updateTime,
  });

  factory AccountAsset.fromJson(Map<String, dynamic> json) {
    return AccountAsset(
      asset: json['asset']?.toString() ?? '',
      walletBalance: double.tryParse(json['walletBalance']?.toString() ?? '0') ?? 0.0,
      unrealizedProfit: double.tryParse(json['unrealizedProfit']?.toString() ?? '0') ?? 0.0,
      marginBalance: double.tryParse(json['marginBalance']?.toString() ?? '0') ?? 0.0,
      maintMargin: double.tryParse(json['maintMargin']?.toString() ?? '0') ?? 0.0,
      initialMargin: double.tryParse(json['initialMargin']?.toString() ?? '0') ?? 0.0,
      positionInitialMargin: double.tryParse(json['positionInitialMargin']?.toString() ?? '0') ?? 0.0,
      openOrderInitialMargin: double.tryParse(json['openOrderInitialMargin']?.toString() ?? '0') ?? 0.0,
      crossWalletBalance: double.tryParse(json['crossWalletBalance']?.toString() ?? '0') ?? 0.0,
      crossUnrealizedProfit: double.tryParse(json['crossUnrealizedProfit']?.toString() ?? '0') ?? 0.0,
      availableBalance: double.tryParse(json['availableBalance']?.toString() ?? '0') ?? 0.0,
      maxWithdrawAmount: double.tryParse(json['maxWithdrawAmount']?.toString() ?? '0') ?? 0.0,
      marginAvailable: json['marginAvailable'] as bool? ?? false,
      updateTime: int.tryParse(json['updateTime']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'asset': asset,
      'walletBalance': walletBalance.toString(),
      'unrealizedProfit': unrealizedProfit.toString(),
      'marginBalance': marginBalance.toString(),
      'maintMargin': maintMargin.toString(),
      'initialMargin': initialMargin.toString(),
      'positionInitialMargin': positionInitialMargin.toString(),
      'openOrderInitialMargin': openOrderInitialMargin.toString(),
      'crossWalletBalance': crossWalletBalance.toString(),
      'crossUnrealizedProfit': crossUnrealizedProfit.toString(),
      'availableBalance': availableBalance.toString(),
      'maxWithdrawAmount': maxWithdrawAmount.toString(),
      'marginAvailable': marginAvailable,
      'updateTime': updateTime,
    };
  }
}

class AccountInformation {
  final int feeTier;
  final bool canTrade;
  final bool canDeposit;
  final bool canWithdraw;
  final int updateTime;
  final double totalInitialMargin;
  final double totalMaintMargin;
  final double totalWalletBalance;
  final double totalUnrealizedProfit;
  final double totalMarginBalance;
  final double totalPositionInitialMargin;
  final double totalOpenOrderInitialMargin;
  final double totalCrossWalletBalance;
  final double totalCrossUnrealizedProfit;
  final double availableBalance;
  final double maxWithdrawAmount;
  final List<AccountAsset> assets;

  AccountInformation({
    required this.feeTier,
    required this.canTrade,
    required this.canDeposit,
    required this.canWithdraw,
    required this.updateTime,
    required this.totalInitialMargin,
    required this.totalMaintMargin,
    required this.totalWalletBalance,
    required this.totalUnrealizedProfit,
    required this.totalMarginBalance,
    required this.totalPositionInitialMargin,
    required this.totalOpenOrderInitialMargin,
    required this.totalCrossWalletBalance,
    required this.totalCrossUnrealizedProfit,
    required this.availableBalance,
    required this.maxWithdrawAmount,
    required this.assets,
  });

  factory AccountInformation.fromJson(Map<String, dynamic> json) {
    return AccountInformation(
      feeTier: int.tryParse(json['feeTier']?.toString() ?? '0') ?? 0,
      canTrade: json['canTrade'] as bool? ?? false,
      canDeposit: json['canDeposit'] as bool? ?? false,
      canWithdraw: json['canWithdraw'] as bool? ?? false,
      updateTime: int.tryParse(json['updateTime']?.toString() ?? '0') ?? 0,
      totalInitialMargin: double.tryParse(json['totalInitialMargin']?.toString() ?? '0') ?? 0.0,
      totalMaintMargin: double.tryParse(json['totalMaintMargin']?.toString() ?? '0') ?? 0.0,
      totalWalletBalance: double.tryParse(json['totalWalletBalance']?.toString() ?? '0') ?? 0.0,
      totalUnrealizedProfit: double.tryParse(json['totalUnrealizedProfit']?.toString() ?? '0') ?? 0.0,
      totalMarginBalance: double.tryParse(json['totalMarginBalance']?.toString() ?? '0') ?? 0.0,
      totalPositionInitialMargin: double.tryParse(json['totalPositionInitialMargin']?.toString() ?? '0') ?? 0.0,
      totalOpenOrderInitialMargin: double.tryParse(json['totalOpenOrderInitialMargin']?.toString() ?? '0') ?? 0.0,
      totalCrossWalletBalance: double.tryParse(json['totalCrossWalletBalance']?.toString() ?? '0') ?? 0.0,
      totalCrossUnrealizedProfit: double.tryParse(json['totalCrossUnrealizedProfit']?.toString() ?? '0') ?? 0.0,
      availableBalance: double.tryParse(json['availableBalance']?.toString() ?? '0') ?? 0.0,
      maxWithdrawAmount: double.tryParse(json['maxWithdrawAmount']?.toString() ?? '0') ?? 0.0,
      assets: (json['assets'] as List<dynamic>?)
              ?.map((e) => AccountAsset.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feeTier': feeTier,
      'canTrade': canTrade,
      'canDeposit': canDeposit,
      'canWithdraw': canWithdraw,
      'updateTime': updateTime,
      'totalInitialMargin': totalInitialMargin.toString(),
      'totalMaintMargin': totalMaintMargin.toString(),
      'totalWalletBalance': totalWalletBalance.toString(),
      'totalUnrealizedProfit': totalUnrealizedProfit.toString(),
      'totalMarginBalance': totalMarginBalance.toString(),
      'totalPositionInitialMargin': totalPositionInitialMargin.toString(),
      'totalOpenOrderInitialMargin': totalOpenOrderInitialMargin.toString(),
      'totalCrossWalletBalance': totalCrossWalletBalance.toString(),
      'totalCrossUnrealizedProfit': totalCrossUnrealizedProfit.toString(),
      'availableBalance': availableBalance.toString(),
      'maxWithdrawAmount': maxWithdrawAmount.toString(),
      'assets': assets.map((e) => e.toJson()).toList(),
    };
  }
}
