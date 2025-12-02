import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:front_end_app/http_override.dart';
import 'package:front_end_app/providers/auth_provider.dart';
import 'package:front_end_app/screens/splash_screen.dart';
import 'package:provider/provider.dart';
import 'viewmodels/menu_view_model.dart';

void main() {
  HttpOverrides.global = MyHttpOverrides();
  runApp(
    MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MenuViewModel()),
          ChangeNotifierProvider(create: (_)=>AuthProvider())
        ],
      child:const MyApp() ,
    )

  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B82F6), // Gần với primary indigo trên web
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Quản Lý Nhà Hàng',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: baseColorScheme,
        scaffoldBackgroundColor: baseColorScheme.background,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: baseColorScheme.background,
          foregroundColor: baseColorScheme.onBackground,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: baseColorScheme.primary,
            foregroundColor: baseColorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: baseColorScheme.outline,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: baseColorScheme.outlineVariant,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: baseColorScheme.primary,
              width: 1.6,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      home: SplashScreen(),
    );
  }
}