import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:to_do_list/views/home_screen.dart';
import 'package:to_do_list/viewmodels/item_viewmodel.dart';
import 'package:to_do_list/viewmodels/settings_viewmodel.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(null, [
    NotificationChannel(
      channelKey: 'basic_channel',
      channelName: 'Basic Notifications',
      channelDescription: 'Task reminders',
      defaultColor: Colors.teal,
      ledColor: Colors.white,
      importance: NotificationImportance.High,
    ),
  ], debug: true);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ItemViewModel()..loadItems()),
        ChangeNotifierProvider(create: (_) => SettingsViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsViewModel>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.accentColor,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: settings.accentColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
