import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class DiscussionScreen extends StatefulWidget {
  const DiscussionScreen({super.key});

  @override
  State<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends State<DiscussionScreen> {
  Timer? _timer;
  int _remainingSeconds = 90;

  @override
  void initState() {
    super.initState();
    _syncRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _syncRemainingTime());
  }

  void _syncRemainingTime() {
    final room = context.read<SupabaseGameService>().currentRoom;
    if (room == null) return;
    final elapsed = DateTime.now().difference(room.phaseStartedAt).inSeconds;
    final left = (room.discussionTimerSec - elapsed).clamp(0, room.discussionTimerSec);
    if (mounted) {
      setState(() => _remainingSeconds = left);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom!;
    final me = service.myPlayer;
    final activePlayers = service.activePlayers;

    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: GaddarColors.gold,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: GaddarColors.ink, width: 2.5),
                    ),
                    child: Text(
                      'ROUND ${room.currentRound} OF ${room.maxRounds}',
                      style: GoogleFonts.fredoka(
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.ink,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: GaddarColors.crimson,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: GaddarColors.ink, width: 2.5),
                    ),
                    child: Text(
                      '⏱️ ${_remainingSeconds}s LEFT',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              CartoonCard(
                color: const Color(0xFF34146E),
                child: Column(
                  children: [
                    Text(
                      '🗣️ SPEAK YOUR CLUES IN REAL LIFE!',
                      style: GoogleFonts.fredoka(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Rule: ${room.clueRule.label} • Category: ${room.secretCategory}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Go around the room in the speaking order below. Each player says one clue word out loud IRL. When everyone has spoken and debated, press "Clues Done — Start Voting" on your phone!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              CartoonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REAL-WORLD SPEAKING ORDER & READY STATUS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(activePlayers.length, (index) {
                      final p = activePlayers[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: GaddarColors.bgDeep,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: p.hasReady ? GaddarColors.emerald : GaddarColors.ink,
                            width: 2.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: GaddarColors.gold,
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.fredoka(
                                  color: GaddarColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              GaddarColors.avatarEmojis[
                                  p.avatarIndex % GaddarColors.avatarEmojis.length],
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '${p.nickname}${p.id == me?.id ? " (You)" : ""}',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: p.hasReady
                                    ? GaddarColors.emerald
                                    : Colors.white12,
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Text(
                                p.hasReady ? '✓ CLUE DONE' : 'SPEAKING...',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: p.hasReady
                                      ? GaddarColors.ink
                                      : Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              ReadyBarrierBanner(
                actionLabel: 'Clues Done — Start Voting',
                activePlayers: activePlayers,
                myPlayer: me,
                onPressReady: () => service.markReadyForPhase(RoomStatus.voting),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
