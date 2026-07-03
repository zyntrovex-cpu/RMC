import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'services/auth_service.dart';
import 'services/localization_service.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalizationService.instance.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => LocalizationService.instance),
      ],
      child: Consumer<LocalizationService>(
        builder: (context, localization, _) {
          return MaterialApp(
            title: 'PNWHS RMC',
            theme: ThemeData(
              primaryColor: const Color(0xFF1A5276),
              useMaterial3: true,
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1A5276),
                foregroundColor: Colors.white,
              ),
            ),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ur'),
            ],
            locale: Locale(localization.currentLanguage),
            home: Consumer<AuthService>(
              builder: (context, authService, _) {
                if (authService.isLoading) {
                  return const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1A5276),
                      ),
                    ),
                  );
                }

                return authService.isLoggedIn
                    ? const DashboardScreen()
                    : const LoginScreen();
              },
            ),
          );
        },
      ),
    );
  }
}
