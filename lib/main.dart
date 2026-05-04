import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:auratime/screens/main_navigation.dart';
import 'package:auratime/services/app_settings_service.dart';
import 'package:auratime/services/time_record_service.dart';
import 'package:auratime/services/widget_service.dart';
import 'package:auratime/theme/app_theme.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  Intl.defaultLocale = 'pt_BR';
  await Future.wait<void>([
    AppSettingsService.initialize(),
    TimeRecordService.initialize(),
  ]);
  runApp(const AuraTimeApp());
  HomeWidget.registerInteractivityCallback(backgroundCallback);
  syncHomeWidgetStatus();
}

class AuraTimeApp extends StatelessWidget {
  const AuraTimeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AuraTime',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      theme: AppTheme.premiumDark,
      home: const MainNavigation(),
    );
  }
}
