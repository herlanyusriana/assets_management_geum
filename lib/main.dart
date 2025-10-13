import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
