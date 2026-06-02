import 'package:flutter/material.dart';
import 'dart:ui'; 
import 'package:buckshot/buckshot_theme.dart';

class NavItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  NavItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

class BarreDeNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final List<NavItem> items;

  const BarreDeNavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect( // Empêche le flou de déborder
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0), // Intensité du flou en arrière-plan
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.transparent, // Transparence totale !
            // J'ai retiré le BoxShadow pour éviter d'avoir une ligne noire ou grise sous le flou
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(
                items.length,
                (index) => _buildNavItem(
                  index: index,
                  item: items[index],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required NavItem item,
  }) {
    final isSelected = currentIndex == index;

    final activeColor = BuckshotTheme.navigationBarItemColorActive;
    final inactiveColor = BuckshotTheme.navigationBarItemColorInactive;

    return Expanded(
      child: InkWell(
        onTap: () {
          onItemSelected(index);
          item.onTap();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Icon(
          item.icon,
          color: isSelected ? activeColor : inactiveColor,
          size: 36,
        ),
      ),
    );
  }
}