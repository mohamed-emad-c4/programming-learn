import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeState { light, dark, system }

class ThemeCubit extends Cubit<ThemeState> {
  final SharedPreferences _prefs;
  static const String _themeKey = 'theme_mode';

  ThemeCubit(this._prefs) : super(_loadInitialTheme(_prefs));

  static ThemeState _loadInitialTheme(SharedPreferences prefs) {
    final String? themeString = prefs.getString(_themeKey);
    return ThemeState.values.firstWhere(
      (e) => e.toString() == themeString,
      orElse: () => ThemeState.system,
    );
  }

  Future<void> setTheme(ThemeState theme) async {
    await _prefs.setString(_themeKey, theme.toString());
    emit(theme);
  }

  Future<void> toggleTheme() async {
    final newTheme = state == ThemeState.light
        ? ThemeState.dark
        : state == ThemeState.dark
            ? ThemeState.system
            : ThemeState.light;
    await setTheme(newTheme);
  }
}
