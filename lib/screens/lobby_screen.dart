import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final TextEditingController _wordCtrl = TextEditingController();
  final TextEditingController _hintCtrl = TextEditingController();

  @override
  void dispose() {
    _wordCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCustomWord() async {
    if (_wordCtrl.text.trim().isEmpty || _hintCtrl.text.trim().isEmpty) return;
    await context.read<SupabaseGameService>().addCustomWord(
          _wordCtrl.text.trim(),
          _hintCtrl.text.trim(),
        );
    _wordCtrl.clear();
    _hintCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom!;
    final players = service.players;
    final me = service.myPlayer;
    final isHost = me?.isHost ?? false;

    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartoonCard(
                color: const Color(0xFF34146E),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SHARE 6-DIGIT ROOM CODE',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: GaddarColors.cyan,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () async {
                            final shouldLeave = await GaddarDialogs.showLeaveMatchDialog(
                              context,
                              roomCode: room.roomCode,
                            );
                            if (shouldLeave && context.mounted) {
                              await service.leaveRoom();
                            }
                          },
                          icon: const Icon(Icons.exit_to_app, color: Colors.white70, size: 18),
                          label: const Text('Leave', style: TextStyle(color: Colors.white70)),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: room.roomCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Copied Room Code #${room.roomCode}!')),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: GaddarColors.bgDeep,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: GaddarColors.gold, width: 3),
                        ),
                        child: Text(
                          room.roomCode,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 38,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 10,
                            color: GaddarColors.gold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Friends join from their own phones using this code • Gaddar survives > ${room.gaddarSurvivalThreshold(players.length)} rounds to win!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
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
                      'CONNECTED PHONES (${players.length} PLAYERS)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: players.map((p) {
                        final isMe = p.id == me?.id;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? const Color(0xFF421987) : GaddarColors.bgDeep,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isMe ? GaddarColors.gold : GaddarColors.ink,
                              width: 2.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                GaddarColors.avatarEmojis[
                                    p.avatarIndex % GaddarColors.avatarEmojis.length],
                                style: const TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${p.nickname}${isMe ? " (You)" : ""}${p.isHost ? " 👑" : ""}',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              CartoonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'ADD CUSTOM SECRET WORDS (${service.customWords.length} ADDED)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _wordCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Secret Word (e.g. Maggi)',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _hintCtrl,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Gaddar Hint (2-Min Hostel)',
                              hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _addCustomWord,
                          icon: const Icon(Icons.add_circle, color: GaddarColors.gold, size: 32),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (service.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: GaddarColors.crimson.withValues(alpha: 0.2),
                    border: Border.all(color: GaddarColors.crimson, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: GaddarColors.crimson),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          service.errorMessage!,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                        onPressed: service.clearError,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              if (isHost)
                CartoonButton(
                  label: service.isLoading
                      ? 'STARTING MATCH...'
                      : (players.length < 3
                          ? 'WAITING FOR AT LEAST 3 PLAYERS (${players.length}/3)...'
                          : 'START MATCH FOR ALL ${players.length} PHONES'),
                  icon: service.isLoading ? Icons.hourglass_top : Icons.play_arrow_rounded,
                  color: GaddarColors.emerald,
                  onPressed: (players.length < 3 || service.isLoading)
                      ? null
                      : () => service.startMatch(),
                )
              else
                CartoonCard(
                  color: const Color(0xFF220D46),
                  child: Text(
                    'Waiting for Host to start the match... Keep this screen open on your phone!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.fredoka(color: GaddarColors.gold, fontSize: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
