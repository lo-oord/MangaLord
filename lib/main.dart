import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:event/event.dart';
import 'package:manga_lord/configs/app_theme.dart';
import 'configs/app_locale.dart';
import 'package:manga_lord/src/rust/frb_generated.dart';
import 'services/notification_service.dart';
import 'package:manga_lord/screens/components/router.dart';
import 'screens/init_screen.dart';
import 'services/auth_service.dart';

const _accent = Color(0xFF3DDC97);
const _darkSurface = Color(0xFF14231F);
const _darkBackground = Color(0xFF0B1714);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await AuthService.instance.initialize();
  await MangaNotificationService.instance.initialize();
  await loadAppLocale();
  runApp(const BootstrapApp());
}

class BootstrapApp extends StatefulWidget { const BootstrapApp({super.key}); @override State<BootstrapApp> createState() => _BootstrapAppState(); }
class _BootstrapAppState extends State<BootstrapApp> {
  late Future<void> _rustInitialization;
  @override void initState() { super.initState(); _rustInitialization = RustLib.init().timeout(const Duration(seconds: 30)); }
  @override Widget build(BuildContext context) => FutureBuilder<void>(future: _rustInitialization, builder: (context, snapshot) { if (snapshot.connectionState != ConnectionState.done) return const MaterialApp(home: StartupStatusScreen()); if (snapshot.hasError) return MaterialApp(home: StartupErrorScreen(error: snapshot.error!, onRetry: () => setState(() => _rustInitialization = RustLib.init().timeout(const Duration(seconds: 30))))); return const MyApp(); });
}
class StartupStatusScreen extends StatelessWidget {
  const StartupStatusScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: _darkBackground,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('lib/assets/manga_lord_logo.png', width: 76, height: 52, fit: BoxFit.contain),
              SizedBox(height: 18),
              CircularProgressIndicator(color: _accent),
              SizedBox(height: 18),
              Text('Starting MangaLord...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error, required this.onRetry});
  final Object error;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _darkBackground,
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
	          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 16),
              Text('MangaLord could not start', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('$error', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              SizedBox(height: 20),
              FilledButton(onPressed: onRetry, child: Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget { const MyApp({super.key}); @override State<MyApp> createState() => _MyAppState(); }
class _MyAppState extends State<MyApp> {
  @override void initState() { super.initState(); appThemeEvent.subscribe(_onThemeChange); appLocale.addListener(_onLocaleChange); }
  @override void dispose() { appThemeEvent.unsubscribe(_onThemeChange); appLocale.removeListener(_onLocaleChange); super.dispose(); }
  void _onThemeChange(AppThemeEventArgs? args) { if (args != null) setState(() {}); }
  void _onLocaleChange() { setState(() {}); }
  @override Widget build(BuildContext context) => MaterialApp(navigatorObservers: [routeObserver], debugShowCheckedModeBanner: false, theme: _lightTheme, darkTheme: _darkTheme, themeMode: _getThemeMode(), locale: appLocale.value, supportedLocales: const [Locale('en'), Locale('ar')], themeAnimationDuration: const Duration(milliseconds: 250), home: const InitScreen());
  ThemeMode _getThemeMode() { switch (currentAppTheme) { case AppTheme.system: return ThemeMode.system; case AppTheme.light: return ThemeMode.light; case AppTheme.dark: return ThemeMode.dark; } }
}

ThemeData _base(Brightness brightness) { final dark = brightness == Brightness.dark; final scheme = ColorScheme.fromSeed(seedColor: _accent, brightness: brightness).copyWith(primary: _accent, secondary: _accent, surface: dark ? _darkSurface : const Color(0xFFF5F8F6)); return ThemeData(useMaterial3: true, brightness: brightness, colorScheme: scheme, scaffoldBackgroundColor: dark ? _darkBackground : const Color(0xFFF8FBF9), fontFamily: 'sans', appBarTheme: AppBarTheme(backgroundColor: dark ? _darkBackground : const Color(0xFFF8FBF9), foregroundColor: dark ? Colors.white : const Color(0xFF15231F), elevation: 0, surfaceTintColor: Colors.transparent), inputDecorationTheme: InputDecorationTheme(hintStyle: TextStyle(color: dark ? Colors.white38 : Colors.black38), prefixIconColor: dark ? Colors.white60 : Colors.black54), filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(backgroundColor: _accent, foregroundColor: _darkBackground, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)))), cardTheme: CardThemeData(color: dark ? _darkSurface : Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)))); }
final _lightTheme = _base(Brightness.light);
final _darkTheme = _base(Brightness.dark);
