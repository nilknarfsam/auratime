import 'package:flutter/material.dart';
import 'package:auratime/screens/main_navigation.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:auratime/theme/app_theme.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  await TimeRecordService.initialize();
  runApp(const AuraTimeApp());
}

class AuraTimeApp extends StatelessWidget {
  const AuraTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraTime',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.premiumDark,
      home: const MainNavigation(),
    );
  }
}
