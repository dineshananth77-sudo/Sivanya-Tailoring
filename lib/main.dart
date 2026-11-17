import 'package:flutter/material.dart';
import 'app/app.dart';
import 'core/service/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore authenticated session from persistent secure storage
  await ApiClient.restoreSession();

  runApp(const StitchStyleApp());
}
