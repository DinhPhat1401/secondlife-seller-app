import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/responsive/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../orders/presentation/screens/seller_orders_screen.dart';
import '../../profile/presentation/screens/seller_profile_screen.dart';
import '../../listings/presentation/screens/seller_listings_screen.dart';
import 'dashboard_tab.dart';

class MainShellScreen extends ConsumerStatefulWidget {
  const MainShellScreen({super.key});

  @override
  ConsumerState<MainShellScreen> createState() => _MainShellScreenState();
}

class _MainShellScreenState extends ConsumerState<MainShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const SellerListingsScreen(),
    const SellerOrdersScreen(),
    const SellerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return ResponsiveNavigationScaffold(
      body: IndexedStack(index: _currentIndex, children: _tabs),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-listing'),
        backgroundColor: AppColors.primary,
        elevation: 3,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      mobileFabLocation: FloatingActionButtonLocation.centerDocked,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.storefront_outlined),
          selectedIcon: Icon(Icons.storefront_rounded),
          label: 'Tổng quan',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2_rounded),
          label: 'Tin đăng',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long_rounded),
          label: 'Đơn bán',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Tài khoản',
        ),
      ],
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      backgroundColor: Colors.white,
      mobileNavigationBar: (context, selected, onSelected) => BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 8,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              Expanded(
                child: _buildNavItem(
                  0,
                  Icons.storefront_outlined,
                  Icons.storefront_rounded,
                  'Tổng quan',
                  onSelected,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  1,
                  Icons.inventory_2_outlined,
                  Icons.inventory_2_rounded,
                  'Tin đăng',
                  onSelected,
                ),
              ),
              const SizedBox(width: 44), // Space for notched FAB
              Expanded(
                child: _buildNavItem(
                  2,
                  Icons.receipt_long_outlined,
                  Icons.receipt_long_rounded,
                  'Đơn bán',
                  onSelected,
                ),
              ),
              Expanded(
                child: _buildNavItem(
                  3,
                  Icons.person_outline_rounded,
                  Icons.person_rounded,
                  'Tài khoản',
                  onSelected,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    int index,
    IconData unselectedIcon,
    IconData selectedIcon,
    String label,
    ValueChanged<int> onSelected,
  ) {
    final isSelected = _currentIndex == index;
    final color = isSelected ? AppColors.primary : AppColors.textMuted;

    return InkWell(
      onTap: () => onSelected(index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
