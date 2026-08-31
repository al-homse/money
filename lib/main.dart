import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'views/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. تهيئة Firebase في التطبيق
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCeTkG9y_J4f_eAw9f-s2mtfCWYbIAPK2w",
      authDomain: "money-7eb69.firebaseapp.com",
      projectId: "money-7eb69",
      storageBucket: "money-7eb69.firebasestorage.app",
      messagingSenderId: "609160171719",
      appId: "1:609160171719:web:d0c37479729a30190a6ee2",
    ),
  );

  // 2. إعدادات Firestore للويب للعمل بدون انقطاع
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'سجل المشتريات اليومي',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}