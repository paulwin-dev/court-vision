import 'package:ace/features/home/home_screen.dart';
import 'package:ace/features/matches/match_screen.dart';
import 'package:ace/features/settings/preset_editor.dart';
import 'package:ace/features/settings/settings_page.dart';
import 'package:ace/features/stats/stats_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreenPage()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsPage()),
    GoRoute(path: '/presets', builder: (context, state) => const PresetEditorPage()),

    GoRoute(
      path: '/stats/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id'] as String);

        return MatchStatsPage(matchId: id);
      },
    ),
    GoRoute(
      path: '/match/:player/:opponent/:preset',
      builder: (context, state) {
        final player = state.pathParameters['player'] ?? "Player";
        final opponent = state.pathParameters['opponent'] ?? "Opponent";
        final preset = state.pathParameters['preset'] ?? "Default";

        return MatchScreenPage(localPlayerName: player, opponentName: opponent, matchPreset: preset);
      },
    ),
  ],
);
