import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';

import 'providers/saved_numbers_provider.dart';
import 'providers/visa_provider.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/watcher_service.dart';

// Must be a top-level function — workmanager runs it in a separate isolate.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    await WatcherService.checkWatchedNumbers();
    return true;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
  await Workmanager().initialize(callbackDispatcher);
  await WatcherService.registerPeriodicTask();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => VisaProvider()),
        ChangeNotifierProvider(create: (_) => SavedNumbersProvider()),
      ],
      child: const IrelandVisaApp(),
    ),
  );
}

class IrelandVisaApp extends StatelessWidget {
  const IrelandVisaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ireland Visa Checker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF169B62),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF169B62),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF169B62),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B3A2D),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
