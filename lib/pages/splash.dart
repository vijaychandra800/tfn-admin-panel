import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../components/app_logo.dart';
import '../configs/assets_config.dart';
import '../models/app_settings_model.dart';
import '../pages/login.dart';
import '../pages/verify.dart';
import '../providers/user_data_provider.dart';
import '../tabs/admin_tabs/app_settings/app_setting_providers.dart';
import '../utils/next_screen.dart';
import '../utils/toasts.dart';
import '../providers/auth_state_provider.dart';
import '../services/auth_service.dart';
import 'home.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _InitialScreen1State();
}

class _InitialScreen1State extends ConsumerState<SplashScreen> {
  late StreamSubscription<User?> _auth;

  @override
  void initState() {
    _auth = FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _checkVerification(user);
      } else {
        if (!mounted) return;
        NextScreen.replaceAnimation(context, const Login());
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _auth.cancel();
    super.dispose();
  }

  _checkVerification(User user) async {
    final UserRoles role = await AuthService().checkUserRole(user.uid);

    if (role == UserRoles.admin || role == UserRoles.author) {
      ref.read(userRoleProvider.notifier).update((state) => role);

      final settings = await ref.read(appSettingsProvider.future);
      final LicenseType license = settings?.license ?? LicenseType.none;
      final bool isVerified = license != LicenseType.none;

      if (isVerified) {
        await ref.read(userDataProvider.notifier).getData();
        if (!mounted) return;
        NextScreen.replaceAnimation(context, const Home());
      } else {
        if (!mounted) return;
        NextScreen.replaceAnimation(context, const VerifyInfo());
      }
    } else {
      // Not ADMIN or AUTHOR
      await AuthService().adminLogout().then((value) {
        if (!mounted) return;
        openFailureToast(context, 'Access Denied');
        NextScreen.replaceAnimation(context, const Login());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: AppLogo(imageString: AssetsConfig.logo, width: MediaQuery.of(context).size.width / 3),
      ),
    );
  }
}
