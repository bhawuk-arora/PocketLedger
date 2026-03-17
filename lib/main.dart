import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocket_ledger/core/constants.dart';
import 'package:pocket_ledger/features/expenses/data/models/expense_model.dart';
import 'package:pocket_ledger/features/expenses/presentation/screens/dashboard_screen.dart';
import 'package:pocket_ledger/features/auth/presentation/auth_notifier.dart';
import 'package:pocket_ledger/features/auth/presentation/screens/auth_screen.dart';
import 'package:pocket_ledger/core/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ExpenseAdapter());
  }
  final expenseBox = await Hive.openBox<Expense>('expenses');

  // Initialize Supabase
  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  // Initialize Notifications
  await NotificationService().initialize();

  runApp(
    ProviderScope(
      overrides: [
        expenseBoxProvider.overrideWithValue(expenseBox),
      ],
      child: const BhawukKharchaApp(),
    ),
  );
}

final expenseBoxProvider = Provider<Box<Expense>>((ref) => throw UnimplementedError());

class BhawukKharchaApp extends ConsumerWidget {
  const BhawukKharchaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Cheeky color palette — warm, vibrant, fun
    const accentOrange = Color(0xFFFF6B35);
    const accentYellow = Color(0xFFFFD166);
    const surfaceDark = Color(0xFF0F0F14);
    const cardDark = Color(0xFF1A1A24);

    return MaterialApp(
      title: "Bhawuk's Kharcha",
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: surfaceDark,
        colorScheme: ColorScheme.dark(
          primary: accentOrange,
          secondary: accentYellow,
          surface: cardDark,
          onSurface: Colors.white,
          outline: Colors.white.withValues(alpha: 0.06),
          tertiary: const Color(0xFF4ADE80),
          error: const Color(0xFFFF6B6B),
        ),
        textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
        cardTheme: CardThemeData(
          color: cardDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: cardDark,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: accentOrange, width: 1.5),
          ),
        ),
      ),
      themeMode: ThemeMode.dark,
      home: authState.isAuthenticated ? const DashboardScreen() : const AuthScreen(),
    );
  }
}
