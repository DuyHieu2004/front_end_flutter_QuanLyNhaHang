import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:front_end_app/http_override.dart';
import 'package:front_end_app/providers/auth_provider.dart';
import 'package:front_end_app/screens/dat_ban_screen.dart';
import 'package:front_end_app/screens/home_screen.dart';
import 'package:front_end_app/screens/menu_screen.dart';
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

    return MaterialApp(
        title: 'Quản Lý Nhà Hàng',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
       // home: SplashScreen(),
      home: SplashScreen(),
    );
  }
}