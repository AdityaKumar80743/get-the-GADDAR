import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom!;
    final me = service.myPlayer;
    final sortedPlayers = [...service.players]
      ..sort((a, b) => b.secretScore.compareTo(a.secretScore));
    final friendsWon = room.winnerTeam == 'friends';

    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartoonCard(
                color: friendsWon ? const Color(0xFF0A3D2E) : const Color(0xFF4F0B24),
                borderColor: friendsWon ? GaddarColors.emerald : GaddarColors.crimson,
                child: Column(
                  children: [
                    Text(
                      friendsWon ? '🎉 FRIENDS WIN THE MATCH!' : '🕵️ GADDAR WINS THE MATCH!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.winReason ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: GaddarColors.bgDeep,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Secret Word: "${room.secretWord}" • Hint: "${room.secretHint}"',
                        style: GoogleFonts.spaceGrotesk(
                          color: GaddarColors.cyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              CartoonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🏆 UNLOCKED FINAL LEADERBOARD & ROLE REVEAL',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Includes +50 secret bonus points for every round a player voted for the real Gaddar!',
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(sortedPlayers.length, (i) {
                      final p = sortedPlayers[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GaddarColors.bgDeep,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: p.isGaddar ? GaddarColors.crimson : GaddarColors.emerald,
                            width: 2.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#${i + 1}',
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: GaddarColors.gold,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              GaddarColors.avatarEmojis[
                                  p.avatarIndex % GaddarColors.avatarEmojis.length],
                              style: const TextStyle(fontSize: 24),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${p.nickname}${p.id == me?.id ? " (You)" : ""}',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    p.isGaddar
                                        ? '🕵️ GADDAR • Survived ${p.roundsSurvivedAsGaddar} round(s)'
                                        : '🛡️ FRIEND • Voted Gaddar ${p.correctGaddarVotes}x (+${p.correctGaddarVotes * 50} pts)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: p.isGaddar
                                          ? GaddarColors.crimson
                                          : GaddarColors.emerald,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${p.secretScore} PTS',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: GaddarColors.gold,
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

              if (me?.isHost == true)
                CartoonButton(
                  label: 'PLAY ANOTHER MATCH (BACK TO LOBBY)',
                  icon: Icons.replay_rounded,
                  color: GaddarColors.emerald,
                  onPressed: service.returnRoomToLobby,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
