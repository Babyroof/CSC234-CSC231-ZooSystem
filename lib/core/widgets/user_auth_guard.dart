import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';

class UserAuthGuard extends StatefulWidget {
  final Widget child;

  const UserAuthGuard({super.key, required this.child});

  @override
  State<UserAuthGuard> createState() => _UserAuthGuardState();
}

class _UserAuthGuardState extends State<UserAuthGuard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (FirebaseAuth.instance.currentUser == null) {
        context.go(AppRoute.login);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return widget.child;
  }
}
