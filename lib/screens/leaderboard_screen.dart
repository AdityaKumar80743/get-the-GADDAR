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
                      friendsWon ? '🛡️ LOYAL FRIENDS WIN!' : '🕵️ GADDAR WINS THE MATCH!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        room.winReason ?? (friendsWon ? 'Friends caught the Gaddar!' : 'The Gaddar fooled everyone!'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                    if (room.secretImageUrl != null && room.secretImageUrl!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          height: 120,
                          width: 170,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: GaddarColors.ink, width: 2),
                          ),
                          child: Image.network(
                            room.secretImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: GaddarColors.bgDeep,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GaddarColors.cyan.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        'Secret Word: "${room.secretWord ?? ""}" • Hint: "${room.secretHint ?? ""}"',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '🏆 FINAL SCORES & TRUE ROLES',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: GaddarColors.gold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: GaddarColors.bgDeep,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            'Ranked by Score',
                            style: GoogleFonts.spaceGrotesk(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Secret bonus: +50 pts for voting Gaddar, +100 pts for winning team, +150 for Gaddar Last-Chance.',
                      style: TextStyle(color: Colors.white60, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(sortedPlayers.length, (i) {
                      final p = sortedPlayers[i];
                      final isWinner = (p.isGaddar && !friendsWon) || (!p.isGaddar && friendsWon);
                      final isScoreMvp = i == 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: GaddarColors.bgDeep,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isWinner
                                ? GaddarColors.gold
                                : (p.isGaddar ? GaddarColors.crimson : GaddarColors.emerald),
                            width: isWinner ? 3 : 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#${i + 1}',
                              style: GoogleFonts.fredoka(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: isScoreMvp ? GaddarColors.gold : Colors.white70,
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
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          '${p.nickname}${p.id == me?.id ? " (You)" : ""}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.fredoka(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if (isWinner) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: GaddarColors.gold,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            '🏆 WINNER',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: GaddarColors.ink,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    p.isGaddar
                                        ? '🕵️ THE GADDAR • Survived ${p.roundsSurvivedAsGaddar} round(s)'
                                        : '🛡️ LOYAL FRIEND • Voted Gaddar ${p.correctGaddarVotes}x (+${p.correctGaddarVotes * 50} pts)',
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${p.secretScore} PTS',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: GaddarColors.gold,
                                  ),
                                ),
                                if (isScoreMvp)
                                  Text(
                                    '👑 SCORE MVP',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: GaddarColors.cyan,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (me?.isHost == true) ...[
                CartoonButton(
                  label: 'PLAY ANOTHER MATCH (BACK TO LOBBY)',
                  icon: Icons.replay_rounded,
                  color: GaddarColors.emerald,
                  onPressed: service.returnRoomToLobby,
                ),
                const SizedBox(height: 12),
              ],
              CartoonButton(
                label: 'LEAVE TO MAIN MENU',
                icon: Icons.home_rounded,
                color: GaddarColors.crimson,
                textColor: Colors.white,
                onPressed: () async {
                  final shouldLeave = await GaddarDialogs.showLeaveMatchDialog(
                    context,
                    roomCode: room.roomCode,
                  );
                  if (shouldLeave && context.mounted) {
                    await service.leaveRoom();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
