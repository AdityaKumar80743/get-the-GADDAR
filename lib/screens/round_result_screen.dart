import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class RoundResultScreen extends StatelessWidget {
  const RoundResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom!;
    final me = service.myPlayer;
    final activePlayers = service.activePlayers;
    final threshold = room.gaddarSurvivalThreshold(service.players.length);

    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartoonCard(
                color: const Color(0xFF34146E),
                child: Column(
                  children: [
                    const Text('🎭', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 10),
                    Text(
                      'ROUND ${room.currentRound} COMPLETE — GADDAR SURVIVED!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      room.winReason ??
                          'The Gaddar blended in and survived Round ${room.currentRound}!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GaddarColors.bgDeep,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '🔒 Hidden Leaderboard Update: Any Friend who secretly voted for the real Gaddar this round just earned +50 bonus points! Gaddar wins if they survive > $threshold rounds.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: GaddarColors.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              ReadyBarrierBanner(
                actionLabel: 'Ready for Round ${room.currentRound + 1}',
                activePlayers: activePlayers,
                myPlayer: me,
                onPressReady: () => service.markReadyForPhase(RoomStatus.discussion),
                onForceAdvance: () => service.forceAdvancePhase(RoomStatus.discussion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
