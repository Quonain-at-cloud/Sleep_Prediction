import 'package:flutter/material.dart';
import '../utils/app_constants.dart';

class CustomBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color screenColor;

  const CustomBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.screenColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: screenColor == Colors.white ? Colors.white : Colors.transparent,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: null,
              index: 0,
              isSelected: currentIndex == 0,
              onTap: () {
                onTap(0);
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              imagePath: screenColor == Colors.white ? 'assets/icons/arrow_back_double_purple.png' : 'assets/icons/arrow_back_double.png',
            ),
            _buildNavItem(
              icon: null,
              index: 1,
              isSelected: currentIndex == 1,
              onTap: () {
                onTap(1);
                final currentRoute = ModalRoute.of(context)?.settings.name;
                if (currentRoute != AppConstants.sleepPatternsRoute) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppConstants.sleepPatternsRoute,
                    (route) => false,
                  );
                }
              },
              imagePath: screenColor == Colors.white ? 'assets/icons/home_icon_purple.png' : 'assets/icons/home_icon.png',
            ),
            _buildNavItem(
              icon: null,
              index: 2,
              isSelected: currentIndex == 2,
              onTap: () {
                onTap(2);
                Scaffold.of(context).openEndDrawer();
              },
              imagePath: screenColor == Colors.white ? 'assets/icons/user_circle_purple.png' :  'assets/icons/user_circle.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    IconData? icon,
    required int index,
    required bool isSelected,
    required VoidCallback onTap,
    String? imagePath,
  }) {
    Color selectedColor = screenColor == Colors.white ? const Color(0xFF2D2041) : const Color(0xFF2D2041);
    Color unselectedColor = screenColor == Colors.white ? Colors.black : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 35),
        child: imagePath != null
            ? Image.asset(
                imagePath,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              )
            : Icon(
                icon,
                color: isSelected ? selectedColor : unselectedColor,
                size: 24,
              ),
      ),
    );
  }
} 