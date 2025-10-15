import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'data/repositories/asset_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'presentation/bloc/asset/asset_cubit.dart';
import 'presentation/bloc/auth/auth_cubit.dart';
import 'presentation/bloc/auth/auth_state.dart';
import 'presentation/bloc/navigation/navigation_cubit.dart';
import 'presentation/bloc/settings/settings_cubit.dart';
import 'presentation/bloc/settings/settings_state.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/dashboard/dashboard_screen.dart';
import 'presentation/screens/reports/reports_screen.dart';
import 'presentation/screens/scan/scan_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  runApp(const AssetApp());
}

class AssetApp extends StatelessWidget {
  const AssetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository();
    final assetRepository = AssetRepository(
      tokenProvider: authRepository.getToken,
    );
    final settingsRepository = SettingsRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => SettingsCubit(settingsRepository)..initialize(),
        ),
        BlocProvider(create: (_) => AuthCubit(authRepository)..checkStatus()),
        BlocProvider(create: (_) => AssetCubit(assetRepository)),
        BlocProvider(create: (_) => NavigationCubit()),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final themeMode = settingsState.darkMode
              ? ThemeMode.dark
              : ThemeMode.light;

          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (previous, current) =>
                previous.status != current.status &&
                current.status == AuthStatus.authenticated,
            listener: (context, state) {
              context.read<AssetCubit>().initialize();
            },
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                Widget home;
                switch (authState.status) {
                  case AuthStatus.loading:
                  case AuthStatus.unknown:
                    home = const _SplashScreen();
                    break;
                  case AuthStatus.authenticated:
                    home = const RootShell();
                    break;
                  case AuthStatus.failure:
                  case AuthStatus.unauthenticated:
                    home = const LoginScreen();
                    break;
                }

                return MaterialApp(
                  title: 'Asset Management',
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.light(),
                  darkTheme: AppTheme.dark(),
                  themeMode: themeMode,
                  home: home,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class RootShell extends StatelessWidget {
  const RootShell({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NavigationCubit, int>(
      builder: (context, index) {
        switch (index) {
          case 0:
            return const DashboardScreen();
          case 1:
            return const ReportsScreen();
          case 2:
            return const ScanScreen();
          case 3:
            return const SettingsScreen();
          default:
            return const DashboardScreen();
        }
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.85),
              colorScheme.secondary.withOpacity(0.75),
              colorScheme.surfaceVariant.withOpacity(0.90),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: colorScheme.surface.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/logo-big.jpg',
                        width: 180,
                        height: 180,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Geumcheon Asset Manager',
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Menyiapkan data dan keamanan aplikasi…',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onPrimary.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final oscillatingValue =
                        (math.sin(_controller.value * 2 * math.pi) + 1) / 2;
                    return Container(
                      width: 220,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: colorScheme.onPrimary.withOpacity(0.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: oscillatingValue.clamp(0.05, 0.95),
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
