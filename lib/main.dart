import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_state.dart';
import 'config.dart';
import 'models.dart';
import 'screens/auth.dart';
import 'screens/chat_detail.dart';
import 'screens/create_ride.dart';
import 'screens/home_shell.dart';
import 'screens/notifications_screen.dart';
import 'screens/ride_detail.dart';
import 'screens/signup.dart';
import 'screens/welcome.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!AppConfig.isDemoMode) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
    );
  }
  final state = AppState.create();
  await state.init();
  runApp(HopAlongApp(state: state));
}

class HopAlongApp extends StatelessWidget {
  const HopAlongApp({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HopAlong',
      theme: hopTheme(),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final args = settings.arguments;
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
                builder: (_) => WelcomeScreen(state: state));
          case '/auth':
            return MaterialPageRoute(
                builder: (_) => AuthScreen(
                    state: state, startMode: (args as String?) ?? 'member'));
          case '/signup':
            return MaterialPageRoute(
                builder: (_) => SignupScreen(
                    state: state,
                    prefill: (args as Map<String, dynamic>?) ?? const {}));
          case '/home':
            return MaterialPageRoute(
                builder: (_) => HomeShell(state: state));
          case '/ride':
            return MaterialPageRoute(
                builder: (_) =>
                    RideDetailScreen(state: state, rideId: args as String));
          case '/create-ride':
            return MaterialPageRoute(
                builder: (_) => CreateRideScreen(
                    state: state, existing: args as Ride?));
          case '/chat':
            return MaterialPageRoute(
                builder: (_) => ChatDetailScreen(
                    state: state, conversationId: args as String));
          case '/notifications':
            return MaterialPageRoute(
                builder: (_) => NotificationsScreen(state: state));
          default:
            return MaterialPageRoute(
                builder: (_) => WelcomeScreen(state: state));
        }
      },
    );
  }
}
