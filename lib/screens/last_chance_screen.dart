import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class LastChanceScreen extends StatefulWidget {
  const LastChanceScreen({super.key});

  @override
  State<LastChanceScreen> createState() => _LastChanceScreenState();
}

class _LastChanceScreenState extends State<LastChanceScreen> {
  final TextEditingController _guessCtrl = TextEditingController();

  @override
  void dispose() {
    _guessCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom!;
    final me = service.myPlayer;
    final iAmCaughtGaddar = me != null && me.id == room.caughtGaddarId;

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
                color: const Color(0xFF4F0B24),
                borderColor: GaddarColors.crimson,
                child: Column(
                  children: [
                    const Text('🚨', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'GADDAR CAUGHT BY MAJORITY VOTE!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.winReason ??
                          '${room.caughtGaddarName ?? "Gaddar"} lost -50 pts, but gets ONE Last-Chance guess at the Secret Word to steal the win (+150 pts)!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (iAmCaughtGaddar)
                CartoonCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'YOUR LAST-CHANCE STEAL GUESS (${me.nickname})',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: GaddarColors.gold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _guessCtrl,
                        style: GoogleFonts.fredoka(fontSize: 20, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type the exact Secret Word...',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: GaddarColors.bgDeep,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      CartoonButton(
                        label: 'LOCK IN LAST-CHANCE GUESS (+150 PTS)',
                        icon: Icons.bolt_rounded,
                        color: GaddarColors.gold,
                        onPressed: () =>
                            service.submitLastChanceGuess(_guessCtrl.text),
                      ),
                    ],
                  ),
                )
              else
                CartoonCard(
                  child: Column(
                    children: [
                      const CircularProgressIndicator(color: GaddarColors.gold),
                      const SizedBox(height: 14),
                      Text(
                        'Waiting for ${room.caughtGaddarName ?? "the caught Gaddar"} to type their Last-Chance Secret Word guess on their phone...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.fredoka(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      if (me?.isHost == true) ...[
                        const SizedBox(height: 14),
                        TextButton.icon(
                          onPressed: () => service.submitLastChanceGuess('(Time Expired)'),
                          icon: const Icon(Icons.timer_off_rounded, color: GaddarColors.crimson, size: 18),
                          label: Text(
                            "👑 Host: Time's Up — Skip Guess",
                            style: GoogleFonts.spaceGrotesk(
                              color: GaddarColors.crimson,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
