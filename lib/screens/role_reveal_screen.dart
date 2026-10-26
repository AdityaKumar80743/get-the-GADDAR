import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class RoleRevealScreen extends StatefulWidget {
  const RoleRevealScreen({super.key});

  @override
  State<RoleRevealScreen> createState() => _RoleRevealScreenState();
}

class _RoleRevealScreenState extends State<RoleRevealScreen> {
  bool _holdingToPeek = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom!;
    final me = service.myPlayer;
    if (me == null) return const SizedBox.shrink();

    final isGaddar = me.isGaddar;

    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "PRIVATE ROLE REVEAL • ${me.nickname.toUpperCase()}'S PHONE",
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: GaddarColors.gold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Shield your phone screen! Press and hold the vault card below to view your secret identity.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),

              Expanded(
                child: GestureDetector(
                  onTapDown: (_) => setState(() => _holdingToPeek = true),
                  onTapUp: (_) => setState(() => _holdingToPeek = false),
                  onTapCancel: () => setState(() => _holdingToPeek = false),
                  child: CartoonCard(
                    color: _holdingToPeek
                        ? (isGaddar ? const Color(0xFF4F0B24) : const Color(0xFF0A3D2E))
                        : const Color(0xFF2B125A),
                    borderColor: _holdingToPeek
                        ? (isGaddar ? GaddarColors.crimson : GaddarColors.emerald)
                        : GaddarColors.gold,
                    child: Center(
                      child: !_holdingToPeek
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.fingerprint_rounded,
                                    size: 76, color: GaddarColors.gold),
                                const SizedBox(height: 14),
                                Text(
                                  'HOLD TO REVEAL YOUR ROLE',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Category: ${room.secretCategory ?? "Mystery"}',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isGaddar
                                        ? GaddarColors.crimson
                                        : GaddarColors.emerald,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(
                                    isGaddar
                                        ? '🕵️ YOU ARE THE GADDAR (IMPOSTOR)!'
                                        : '🛡️ YOU ARE A LOYAL FRIEND',
                                    style: GoogleFonts.fredoka(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isGaddar ? Colors.white : GaddarColors.ink,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  isGaddar ? 'YOUR SECRET HINT:' : 'THE SECRET WORD IS:',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white70,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  isGaddar
                                      ? (room.impostorGetsHint
                                          ? '💡 ${room.secretHint ?? "Blend In!"}'
                                          : '🚫 BLIND BLUFF MODE (NO HINT)')
                                      : (room.secretWord ?? ''),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.fredoka(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: GaddarColors.gold,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  isGaddar
                                      ? "Listen to your friends' spoken clues in real life, say a believable word, and survive > ${room.gaddarSurvivalThreshold(service.players.length)} rounds!"
                                      : 'Speak a subtle related clue out loud in real life without giving the exact Secret Word away to the Gaddar!',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              ReadyBarrierBanner(
                actionLabel: 'I Saw My Role — Ready',
                activePlayers: service.activePlayers,
                myPlayer: me,
                onPressReady: () => service.markReadyForPhase(RoomStatus.discussion),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
