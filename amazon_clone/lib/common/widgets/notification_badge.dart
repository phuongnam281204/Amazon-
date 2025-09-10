import 'package:amazon_clone/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? badgeColor;
  final Color? textColor;
  final double? size;

  const NotificationBadge({
    super.key,
    required this.child,
    this.onTap,
    this.badgeColor,
    this.textColor,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Consumer<NotificationProvider>(
        builder: (context, notificationProvider, _) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              child,
              if (notificationProvider.unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    padding: EdgeInsets.all(size != null ? size! * 0.15 : 4),
                    decoration: BoxDecoration(
                      color: badgeColor ?? Colors.red,
                      borderRadius: BorderRadius.circular(
                        size != null ? size! * 0.5 : 10,
                      ),
                      border: Border.all(color: Colors.white, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: (badgeColor ?? Colors.red).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: size ?? 20,
                      minHeight: size ?? 20,
                    ),
                    child: Text(
                      notificationProvider.unreadCount > 99
                          ? '99+'
                          : notificationProvider.unreadCount.toString(),
                      style: TextStyle(
                        color: textColor ?? Colors.white,
                        fontSize: size != null ? size! * 0.6 : 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class AnimatedNotificationIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? size;

  const AnimatedNotificationIcon({
    super.key,
    this.onTap,
    this.iconColor,
    this.size,
  });

  @override
  State<AnimatedNotificationIcon> createState() =>
      _AnimatedNotificationIconState();
}

class _AnimatedNotificationIconState extends State<AnimatedNotificationIcon>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;
  int _lastUnreadCount = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _triggerShakeAnimation(int newCount) {
    if (newCount > _lastUnreadCount && newCount > 0) {
      _shakeController.reset();
      _shakeController.forward();
    }
    _lastUnreadCount = newCount;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        // Trigger shake animation when count increases
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _triggerShakeAnimation(notificationProvider.unreadCount);
        });

        return AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final offset =
                _shakeAnimation.value * 0.1 * (1 - _shakeAnimation.value);
            return Transform.translate(
              offset: Offset(offset * 10, 0),
              child: NotificationBadge(
                onTap: widget.onTap,
                size: widget.size,
                child: Icon(
                  notificationProvider.unreadCount > 0
                      ? Icons.notifications_active
                      : Icons.notifications_outlined,
                  color: widget.iconColor ?? Theme.of(context).iconTheme.color,
                  size: widget.size,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
