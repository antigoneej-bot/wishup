import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await NotificationService.init();
  runApp(const WishUpApp());
}

class WishUpApp extends StatelessWidget {
  const WishUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'WishUp',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _RootGate(),
      ),
    );
  }
}

class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppState>().load();
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('✦', style: TextStyle(fontSize: 40, color: AppColors.navy)),
              SizedBox(height: 12),
              Text('WishUp', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.navy)),
            ],
          ),
        ),
      );
    }
    final state = context.watch<AppState>();
    return state.onboardingCompleted ? const MainNavigation() : const OnboardingScreen();
  }
}
