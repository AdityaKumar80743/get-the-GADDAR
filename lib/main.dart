import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/game_models.dart';
import 'screens/discussion_screen.dart';
import 'screens/home_screen.dart';
import 'screens/last_chance_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/lobby_screen.dart';
import 'screens/role_reveal_screen.dart';
import 'screens/round_result_screen.dart';
import 'screens/voting_screen.dart';
import 'services/supabase_game_service.dart';
import 'widgets/cartoon_widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://hrkdyopytppbcntgwayo.supabase.co',
  );
  const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhya2R5b3B5dHBwYmNudGd3YXlvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMwMzA2MzAsImV4cCI6MjEwODYwNjYzMH0.85YmrswlLpvgcz08JdwWfgr5iztfWS4DPuHf15D_q1M',
  );

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  final gameService = SupabaseGameService();
  await gameService.initDeviceIdentity();

  runApp(
    ChangeNotifierProvider.value(
      value: gameService,
      child: const GetTheGaddarApp(),
    ),
  );
}

class GetTheGaddarApp extends StatelessWidget {
  const GetTheGaddarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Get the GADDAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: GaddarColors.bgDeep,
        colorScheme: ColorScheme.fromSeed(
          seedColor: GaddarColors.gold,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RealtimePhaseRouter(),
    );
  }
}

class RealtimePhaseRouter extends StatelessWidget {
  const RealtimePhaseRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom;

    if (room == null) {
      return const HomeScreen();
    }

    switch (room.status) {
      case RoomStatus.lobby:
        return const LobbyScreen();
      case RoomStatus.roleReveal:
        return const RoleRevealScreen();
      case RoomStatus.discussion:
        return const DiscussionScreen();
      case RoomStatus.voting:
        return const VotingScreen();
      case RoomStatus.lastChance:
        return const LastChanceScreen();
      case RoomStatus.roundResult:
        return const RoundResultScreen();
      case RoomStatus.gameOver:
        return const LeaderboardScreen();
    }
  }
}
