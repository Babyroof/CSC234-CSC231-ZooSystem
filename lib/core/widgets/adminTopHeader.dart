import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/core/constants/app_colors.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';

class AdminTopHeader extends StatelessWidget {
  const AdminTopHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.push(AppRoute.adminProfile),
            child: Row(
              children: const [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Admin',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Super Administrator',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.adminTextMuted,
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 10),
                CircleAvatar(radius: 18, child: Icon(Icons.person, size: 20)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
