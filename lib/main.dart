import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as prod_options;
import 'firebase_options_dev.dart' as dev_options;

// Build-time flavor switch. Pass `--dart-define=FLAVOR=dev` for the dev project.
const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final firebaseOptions = _flavor == 'dev'
      ? dev_options.DefaultFirebaseOptions.currentPlatform
      : prod_options.DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(options: firebaseOptions);
  runApp(const ProviderScope(child: MyApp()));
}
