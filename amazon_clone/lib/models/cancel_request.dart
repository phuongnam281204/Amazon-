import 'dart:convert';

class CancelRequest {
  final String id;
  final String orderId;
  final String userId;
  final String reason;
  final String status; // 'pending', 'approved', 'rejected'
  final String adminResponse;
  final int createdAt;
  final int? reviewedAt;
  final String? reviewedBy;

  CancelRequest({
    required this.id,
    required this.orderId,
    required this.userId,
    required this.reason,
    required this.status,
    this.adminResponse = '',
    required this.createdAt,
    this.reviewedAt,
    this.reviewedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'orderId': orderId,
      'userId': userId,
      'reason': reason,
      'status': status,
      'adminResponse': adminResponse,
      'createdAt': createdAt,
      'reviewedAt': reviewedAt,
      'reviewedBy': reviewedBy,
    };
  }

  factory CancelRequest.fromMap(Map<String, dynamic> map) {
    return CancelRequest(
      id: map['_id'] ?? '',
      orderId: map['orderId'] ?? '',
      userId: map['userId'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? '',
      adminResponse: map['adminResponse'] ?? '',
      createdAt: map['createdAt']?.toInt() ?? 0,
      reviewedAt: map['reviewedAt']?.toInt(),
      reviewedBy: map['reviewedBy'],
    );
  }

  String toJson() => json.encode(toMap());

  factory CancelRequest.fromJson(String source) =>
      CancelRequest.fromMap(json.decode(source));
}
