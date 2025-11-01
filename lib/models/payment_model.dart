import 'package:foundervers/models/application_status.dart';

class PaymentModel {
  final String id;
  final int applicationId;
  final String userId;
  final double amount;
  final String currency;
  final String? paymentMethod;
  final String? paymentIntentId;
  final PaymentStatus status;
  final String? errorMessage;
  final String? receiptUrl;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.applicationId,
    required this.userId,
    required this.amount,
    this.currency = 'USD',
    this.paymentMethod,
    this.paymentIntentId,
    required this.status,
    this.errorMessage,
    this.receiptUrl,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as String,
      applicationId: json['application_id'] as int,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentMethod: json['payment_method'] as String?,
      paymentIntentId: json['payment_intent_id'] as String?,
      status: PaymentStatus.fromString(json['status'] as String? ?? 'pending'),
      errorMessage: json['error_message'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'application_id': applicationId,
      'user_id': userId,
      'amount': amount,
      'currency': currency,
      'payment_method': paymentMethod,
      'payment_intent_id': paymentIntentId,
      'status': status.value,
      'error_message': errorMessage,
      'receipt_url': receiptUrl,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PaymentModel copyWith({
    String? id,
    int? applicationId,
    String? userId,
    double? amount,
    String? currency,
    String? paymentMethod,
    String? paymentIntentId,
    PaymentStatus? status,
    String? errorMessage,
    String? receiptUrl,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      applicationId: applicationId ?? this.applicationId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentIntentId: paymentIntentId ?? this.paymentIntentId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      receiptUrl: receiptUrl ?? this.receiptUrl,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
