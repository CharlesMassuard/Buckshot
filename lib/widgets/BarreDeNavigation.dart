import 'package:flutter/material.dart';

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

class Barredenavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemSelected;
  final List<NavItem> items;

  const Barredenavigation({
    super.key,
    required this.currentIndex,
    required this.onItemSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
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
    );
  }

  Widget _buildNavItem({
    required int index,
    required NavItem item,
  }) {
    final isSelected = currentIndex == index;

    final activeColor = Colors.white;
    final inactiveColor = Colors.grey[600];

    return Expanded(
      child: InkWell(
        onTap: () {
          onItemSelected(index);

          // Action personnalisée
          item.onTap();
        },
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: 
          Icon(
            item.icon,
            color: isSelected ? activeColor : inactiveColor,
            size: 36,
        ),
      ),
    );
  }
}