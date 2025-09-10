import 'dart:convert';
import 'package:amazon_clone/constants/error_handling.dart';
import 'package:amazon_clone/constants/global_variables.dart';
import 'package:amazon_clone/constants/utils.dart';
import 'package:amazon_clone/models/notification.dart' as model;
import 'package:amazon_clone/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class NotificationService {
  // Get all notifications for user
  Future<List<model.Notification>> fetchNotifications(
    BuildContext context,
  ) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    List<model.Notification> notifications = [];

    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/notifications'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
      );

      httpErrorHand(
        response: res,
        context: context,
        onSuccess: () {
          for (int i = 0; i < jsonDecode(res.body).length; i++) {
            notifications.add(
              model.Notification.fromJson(jsonEncode(jsonDecode(res.body)[i])),
            );
          }
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    return notifications;
  }

  // Get unread notifications count
  Future<int> getUnreadCount(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    int count = 0;

    try {
      http.Response res = await http.get(
        Uri.parse('$uri/api/notifications/unread-count'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
      );

      httpErrorHand(
        response: res,
        context: context,
        onSuccess: () {
          count = jsonDecode(res.body)['count'];
        },
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
    return count;
  }

  // Mark notification as read
  void markAsRead({
    required BuildContext context,
    required String notificationId,
    VoidCallback? onSuccess,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      http.Response res = await http.patch(
        Uri.parse('$uri/api/notifications/$notificationId/read'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
      );

      httpErrorHand(
        response: res,
        context: context,
        onSuccess: onSuccess ?? () {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Mark all notifications as read
  void markAllAsRead({
    required BuildContext context,
    VoidCallback? onSuccess,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      http.Response res = await http.patch(
        Uri.parse('$uri/api/notifications/mark-all-read'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
      );

      httpErrorHand(
        response: res,
        context: context,
        onSuccess: onSuccess ?? () {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Request order cancellation
  void requestOrderCancellation({
    required BuildContext context,
    required String orderId,
    required String reason,
    VoidCallback? onSuccess,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      http.Response res = await http.post(
        Uri.parse('$uri/api/orders/request-cancel'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
        body: jsonEncode({'orderId': orderId, 'reason': reason}),
      );

      httpErrorHand(
        response: res,
        context: context,
        onSuccess: onSuccess ?? () {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }

  // Admin approve/reject cancellation request
  void handleCancellationRequest({
    required BuildContext context,
    required String orderId,
    required bool approve,
    VoidCallback? onSuccess,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      http.Response res = await http.post(
        Uri.parse('$uri/admin/handle-cancel-request'),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': userProvider.user.token,
        },
        body: jsonEncode({'orderId': orderId, 'approve': approve}),
      );

      httpErrorHand(
        response: res,
        context: context,
        onSuccess: onSuccess ?? () {},
      );
    } catch (e) {
      showSnackBar(context, e.toString());
    }
  }
}
