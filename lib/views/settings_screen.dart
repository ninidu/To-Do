import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:to_do_list/viewmodels/settings_viewmodel.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ThemeMode _selectedTheme;
  late Color _selectedColor;
  bool _notificationsEnabled = true;
  String _version = '';

  final List<Color> _presetColors = [
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.green,
    Colors.brown,
  ];

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<SettingsViewModel>(context, listen: false);
    _selectedTheme = settings.themeMode;
    _selectedColor = settings.accentColor;
    _loadNotificationPreference();
    _loadVersionInfo();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });
  }

  Future<void> _loadVersionInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version;
    });
  }

  void _onThemeChanged(ThemeMode? mode) {
    if (mode == null) return;
    setState(() => _selectedTheme = mode);
    Provider.of<SettingsViewModel>(context, listen: false).setThemeMode(mode);
  }

  void _onColorSelected(Color color) {
    setState(() => _selectedColor = color);
    Provider.of<SettingsViewModel>(
      context,
      listen: false,
    ).setAccentColor(color);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          // 🔹 Header
          Container(
            height: 100, // Your desired reduced height
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_selectedColor.withOpacity(0.9), Colors.black12],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment:
                  MainAxisAlignment.end, // 👈 Push content to bottom
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'To-Do',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    'Your daily planner',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),

          // 🎨 Accent Color
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: const Text(
              "Accent Color",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              children: _presetColors.map((color) {
                final isSelected = _selectedColor.value == color.value;
                return GestureDetector(
                  onTap: () => _onColorSelected(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: Colors.black, width: 3)
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 32),

          // 🌗 Theme Mode
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              "Theme Mode",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<ThemeMode>(
            title: const Text("System Default"),
            value: ThemeMode.system,
            groupValue: _selectedTheme,
            onChanged: _onThemeChanged,
          ),
          RadioListTile<ThemeMode>(
            title: const Text("Light"),
            value: ThemeMode.light,
            groupValue: _selectedTheme,
            onChanged: _onThemeChanged,
          ),
          RadioListTile<ThemeMode>(
            title: const Text("Dark"),
            value: ThemeMode.dark,
            groupValue: _selectedTheme,
            onChanged: _onThemeChanged,
          ),

          const SizedBox(height: 32),

          // 🔔 Reminders
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              "Reminders",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text("Enable Reminders"),
            subtitle: const Text("Turn task notifications on or off"),
            value: _notificationsEnabled,
            onChanged: _toggleNotifications,
          ),

          const SizedBox(height: 32),

          // ℹ️ About
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Text(
              "About",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("To-Do App"),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.info_outline, color: _selectedColor),
                        const SizedBox(width: 8),
                        const Text("About"),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "This app helps you organize your tasks, set reminders, and stay productive.",
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Version: $_version", // ✅ runtime value allowed now
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          showLicensePage(
                            context: context,
                            applicationName: "To-Do App",
                            applicationVersion: "1.0.0",
                          );
                        },
                        child: const Text("VIEW LICENSES"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text("CLOSE"),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
