import 'package:ace/features/home/home_screen.dart';
import 'package:ace/features/matches/match_screen.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreenPage()),
    // router.dart
    GoRoute(
      path: '/match/:name/:preset',
      builder: (context, state) {
        // Extract parameters from the URL path
        final name = state.pathParameters['name'] ?? "Opponent";
        final preset = state.pathParameters['preset'] ?? "Default";

        return MatchScreenPage(opponentName: name, matchPreset: preset);
      },
    ),
  ],
);
