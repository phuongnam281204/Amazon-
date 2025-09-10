import 'package:amazon_clone/constants/theme.dart';
import 'package:amazon_clone/models/notification.dart' as model;
import 'package:amazon_clone/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class NotificationScreen extends StatefulWidget {
  static const String routeName = '/notifications';
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  void fetchNotifications() async {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    await notificationProvider.fetchNotifications(context);
    setState(() {
      isLoading = false;
    });
  }

  void markAsRead(String notificationId) {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    notificationProvider.markAsRead(notificationId, context);
  }

  void markAllAsRead() {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );
    notificationProvider.markAllAsRead(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: Colors.green,
      ),
    );
  }

  IconData getNotificationIcon(String type) {
    switch (type) {
      case 'order_cancel_request':
        return Icons.cancel_outlined;
      case 'order_cancel_approved':
        return Icons.check_circle_outline;
      case 'order_cancel_rejected':
        return Icons.error_outline;
      case 'add_to_cart':
        return Icons.shopping_cart_outlined;
      case 'payment_success':
        return Icons.payment;
      case 'order_status_update':
        return Icons.local_shipping_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color getNotificationColor(String type) {
    switch (type) {
      case 'order_cancel_request':
        return Colors.orange;
      case 'order_cancel_approved':
        return Colors.green;
      case 'order_cancel_rejected':
        return Colors.red;
      case 'add_to_cart':
        return Colors.blue;
      case 'payment_success':
        return Colors.green;
      case 'order_status_update':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, NotificationProvider>(
      builder: (context, themeProvider, notificationProvider, child) {
        final notifications = notificationProvider.notifications;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifications'),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: themeProvider.getAppBarGradient(context),
              ),
            ),
            actions: [
              if (notifications.isNotEmpty &&
                  notifications.any((n) => !n.isRead))
                TextButton(
                  onPressed: markAllAsRead,
                  child: const Text(
                    'Mark all read',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : notifications.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationItem(notification);
                  },
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 60,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'You\'ll receive notifications about your orders and updates here',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(model.Notification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            getNotificationIcon(notification.type),
            color: getNotificationColor(notification.type),
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TextStyle(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('MMM dd, yyyy • hh:mm a').format(
                DateTime.fromMillisecondsSinceEpoch(notification.createdAt),
              ),
              style: TextStyle(
                color: Theme.of(
                  context,
                ).textTheme.bodySmall?.color?.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!notification.isRead) {
            markAsRead(notification.id);
          }

          // Navigate to order details if it's an order-related notification
          if (notification.data != null &&
              notification.data!['orderId'] != null) {
            // You can add navigation to order details here
            // Navigator.pushNamed(context, OrderDetailScreen.routeName,
            //   arguments: orderId);
          }
        },
      ),
    );
  }
}
