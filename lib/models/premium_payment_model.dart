/// Premium Payment Model
/// Represents a premium subscription payment transaction
class PremiumPaymentModel {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String subscriptionType; // 'monthly' or 'annual'
  final String paymentMethod;
  final String? paymentIntentId;
  final String status;
  final DateTime startedAt;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  PremiumPaymentModel({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.subscriptionType,
    required this.paymentMethod,
    this.paymentIntentId,
    required this.status,
    required this.startedAt,
    this.completedAt,
    required this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PremiumPaymentModel.fromJson(Map<String, dynamic> json) {
    return PremiumPaymentModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      subscriptionType: json['subscription_type'] as String,
      paymentMethod: json['payment_method'] as String? ?? 'stripe',
      paymentIntentId: json['payment_intent_id'] as String?,
      status: json['status'] as String? ?? 'pending',
      startedAt: DateTime.parse(json['started_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'subscription_type': subscriptionType,
      'payment_method': paymentMethod,
      'payment_intent_id': paymentIntentId,
      'status': status,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isActive => isCompleted && DateTime.now().isBefore(expiresAt);

  @override
  String toString() {
    return 'PremiumPayment(id: $id, amount: \$$amount, type: $subscriptionType, status: $status, expires: $expiresAt)';
  }
}
