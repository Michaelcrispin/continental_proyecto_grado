import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class CustomListTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const CustomListTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.iconBgGray,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.textGray, size: 22),
      ),
      title: Text(
        title, 
        style: const TextStyle(color: AppColors.primaryDark, fontSize: 15, fontWeight: FontWeight.w600)
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textLight),
      onTap: onTap,
    );
  }
}
