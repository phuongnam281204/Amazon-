import 'package:amazon_clone/constants/theme.dart';
import 'package:amazon_clone/features/account/widgets/account_stats.dart';
import 'package:amazon_clone/features/account/widgets/below_app_bar.dart';
// import 'package:amazon_clone/features/account/widgets/live_stream_button.dart';
import 'package:amazon_clone/features/account/widgets/orders.dart';
import 'package:amazon_clone/features/account/widgets/top_buttons.dart';
import 'package:amazon_clone/features/notifications/screens/notification_screen.dart';
import 'package:amazon_clone/providers/notification_provider.dart';
import 'package:amazon_clone/common/widgets/theme_toggle.dart';
import 'package:amazon_clone/common/widgets/notification_badge.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch unread notifications count when screen loads and start periodic refresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notificationProvider = Provider.of<NotificationProvider>(
        context,
        listen: false,
      );
      notificationProvider.fetchUnreadCount(context);
      notificationProvider.startPeriodicRefresh(context);
    });
  }

  @override
  void dispose() {
    // Stop periodic refresh when leaving the screen
    Provider.of<NotificationProvider>(
      context,
      listen: false,
    ).stopPeriodicRefresh();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: AppBar(
              flexibleSpace: Container(
                decoration: BoxDecoration(
                  gradient: themeProvider.getAppBarGradient(context),
                ),
              ),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    alignment: Alignment.topLeft,
                    child: Image.asset(
                      'assets/images/amazon_in.png',
                      width: 120,
                      height: 45,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedNotificationIcon(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          NotificationScreen.routeName,
                        );
                      },
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const BelowAppBar(),
                const SizedBox(height: 10),
                const AccountStats(),
                const SizedBox(height: 10),
                const TopButtons(),
                const SizedBox(height: 10),
                const ThemeSettingTile(),
                const SizedBox(height: 10),
                const SizedBox(height: 20),
                const Orders(),
                const SizedBox(
                  height: 80,
                ), // Extra padding để không bị che bởi bottom nav
              ],
            ),
          ),
        );
      },
    );
  }
}
