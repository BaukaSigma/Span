import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_data.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/client/shop_screen.dart';
import '../screens/client/orders_screen.dart';
import '../screens/manager/manager_orders_screen.dart';
import '../screens/manager/manager_products_screen.dart';
import '../screens/trainer/trainer_reports_screen.dart';
import '../screens/director/staff_management_screen.dart';
import '../screens/common/reports_overview_screen.dart';
import '../screens/client/client_bookings_screen.dart';
import '../screens/trainer/trainer_bookings_screen.dart';
import '../utils/constants.dart';

class AppNavigator extends StatefulWidget {
  const AppNavigator({super.key});

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isCheckingAuth) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        final user = auth.user;
        if (user == null) {
          return const LoginScreen();
        }

        final tabs = _buildTabs(user);
        if (_currentIndex >= tabs.length) {
          _currentIndex = 0;
        }

        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: tabs.map((tab) => tab.widget).toList(),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.grey,
            type: BottomNavigationBarType.fixed,
            items: tabs
                .map(
                  (tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon),
                    label: tab.label,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }

  List<_TabItem> _buildTabs(UserData user) {
    if (user.isClient) {
      return [
        _TabItem('Магазин', Icons.storefront, const ShopScreen()),
        _TabItem('Запись', Icons.calendar_month, const ClientBookingsScreen()),
        _TabItem('Заказы', Icons.receipt_long, const ClientOrdersScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.isManager) {
      return [
        _TabItem('Заказы', Icons.receipt_long, const ManagerOrdersScreen()),
        _TabItem('Товары', Icons.inventory_2, const ManagerProductsScreen()),
        _TabItem('Отчёты', Icons.fact_check, const ReportsOverviewScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.isTrainer) {
      return [
        _TabItem('Записи', Icons.calendar_month, const TrainerBookingsScreen()),
        _TabItem('Отчёты', Icons.fact_check, const TrainerReportsScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    if (user.isDirector) {
      return [
        _TabItem('Сотрудники', Icons.people_alt, const StaffManagementScreen()),
        _TabItem('Отчёты', Icons.fact_check, const ReportsOverviewScreen()),
        _TabItem('Профиль', Icons.person, _profileScreen()),
      ];
    }

    return [
      _TabItem('Профиль', Icons.person, _profileScreen()),
    ];
  }

  Widget _profileScreen() {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.black,
        title: const Text('Профиль', style: TextStyle(color: AppColors.white)),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: ProfileScreen(),
    );
  }
}

class _TabItem {
  final String label;
  final IconData icon;
  final Widget widget;

  const _TabItem(this.label, this.icon, this.widget);
}
