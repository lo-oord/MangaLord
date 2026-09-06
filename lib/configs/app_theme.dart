import 'package:flutter/material.dart';
import 'package:event/event.dart';
import '../src/rust/api/api.dart' as api;

enum AppTheme {
  system, // Follow system
  light, // Light theme
  dark, // Dark theme
}

const _propertyName = "app_theme";

late AppTheme _appTheme = AppTheme.system;

AppTheme get currentAppTheme => _appTheme;

class AppThemeEventArgs extends EventArgs {
  final AppTheme theme;

  AppThemeEventArgs(this.theme);
}

final Event<AppThemeEventArgs> appThemeEvent = Event<AppThemeEventArgs>();

Future initAppTheme() async {
  var value = await api.loadProperty(k: _propertyName);
  if (value == null) {
    await api.saveProperty(k: _propertyName, v: AppTheme.system.name);
    _appTheme = AppTheme.system;
  } else {
    _appTheme = AppTheme.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppTheme.system,
    );
  }
  appThemeEvent.broadcast(AppThemeEventArgs(_appTheme));
}

Future chooseAppTheme(BuildContext context) async {
  var result = await showDialog<AppTheme>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: const Color(0xAA000000),
        title: const Text(
          "Choose app theme",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                "Follow system",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop(AppTheme.system);
              },
            ),
            ListTile(
              title: const Text(
                "Light theme",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop(AppTheme.light);
              },
            ),
            ListTile(
              title: const Text(
                "Dark theme",
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.of(context).pop(AppTheme.dark);
              },
            ),
          ],
        ),
      );
    },
  );
  if (result != null) {
    await api.saveProperty(k: _propertyName, v: result.name);
    _appTheme = result;
    appThemeEvent.broadcast(AppThemeEventArgs(_appTheme));
  }
}

String appThemeName(AppTheme theme, BuildContext context) {
  switch (theme) {
    case AppTheme.system:
      return "Follow system";
    case AppTheme.light:
      return "Light theme";
    case AppTheme.dark:
      return "Dark theme";
  }
}

Widget appThemeSetting(BuildContext context) {
  return StatefulBuilder(
    builder: (BuildContext context, void Function(void Function()) setState) {
      return ListTile(
        title: const Text(
          "App theme",
        ),
        subtitle: Text(
          appThemeName(currentAppTheme, context),
        ),
        onTap: () async {
          await chooseAppTheme(context);
          setState(() {}); // Update state to reflect the new theme
        },
      );
    },
  );
}
