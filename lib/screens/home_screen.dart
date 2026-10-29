import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';
import 'create_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _nicknameCtrl = TextEditingController();
  final TextEditingController _roomCodeCtrl = TextEditingController();
  int _selectedAvatar = 0;

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    _roomCodeCtrl.dispose();
    super.dispose();
  }

  void _openCreateRoomSheet() {
    if (_nicknameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your player nickname first!')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateRoomScreen(
          hostNickname: _nicknameCtrl.text.trim(),
          hostAvatarIndex: _selectedAvatar,
        ),
      ),
    );
  }

  Future<void> _handleJoinRoom() async {
    final service = context.read<SupabaseGameService>();
    await service.joinRoom(
      roomCode: _roomCodeCtrl.text.trim(),
      nickname: _nicknameCtrl.text.trim(),
      avatarIndex: _selectedAvatar,
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();

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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: GaddarColors.crimson,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: GaddarColors.ink, width: 2.5),
                    ),
                    child: Text(
                      '🕵️ SOCIAL DEDUCTION PARTY GAME',
                      style: GoogleFonts.fredoka(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: GaddarColors.emerald,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: GaddarColors.ink, width: 2.5),
                    ),
                    child: Text(
                      'NO ACCOUNT',
                      style: GoogleFonts.fredoka(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              CartoonCard(
                color: const Color(0xFF34146E),
                child: Column(
                  children: [
                    Text(
                      'GET THE GADDAR',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.fredoka(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Every friend plays on their own phone! Speak 1-word clues IRL, blend in, and vote out the Gaddar.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              InkWell(
                onTap: () => GaddarDialogs.showHowToPlayDialog(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: GaddarColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: GaddarColors.gold, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: GaddarColors.ink,
                        offset: Offset(0, 3.5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: GaddarColors.gold.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: GaddarColors.gold, width: 1.5),
                        ),
                        child: const Text('📖', style: TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'HOW TO PLAY & RULES',
                              style: GoogleFonts.fredoka(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: GaddarColors.gold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'New to the game? See 3 easy steps & scoring',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: GaddarColors.gold, size: 16),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),

              if (service.errorMessage != null) ...[
                CartoonCard(
                  color: GaddarColors.crimson,
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          service.errorMessage!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: service.clearError,
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              CartoonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '1. YOUR PLAYER PROFILE (THIS PHONE)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.gold,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nicknameCtrl,
                      maxLength: 18,
                      style: GoogleFonts.fredoka(fontSize: 18, color: Colors.white),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: 'Enter your nickname...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: GaddarColors.bgDeep,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GaddarColors.ink, width: 2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: GaddarColors.avatarEmojis.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final selected = _selectedAvatar == index;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedAvatar = index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 52,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? GaddarColors.gold : GaddarColors.bgDeep,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: GaddarColors.ink, width: 2.5),
                              ),
                              child: Text(
                                GaddarColors.avatarEmojis[index],
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              CartoonButton(
                label: 'CREATE ROOM (HOST)',
                icon: Icons.add_reaction_rounded,
                color: GaddarColors.gold,
                onPressed: service.isLoading ? null : _openCreateRoomSheet,
              ),
              const SizedBox(height: 18),

              if (service.savedRoomCode != null && service.savedRoomCode!.isNotEmpty) ...[
                CartoonCard(
                  color: const Color(0xFF0F3D35),
                  borderColor: GaddarColors.emerald,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.sync_rounded, color: GaddarColors.emerald),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'ACTIVE SESSION DETECTED: #${service.savedRoomCode}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: GaddarColors.emerald,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      CartoonButton(
                        label: 'RECONNECT TO ROOM #${service.savedRoomCode}',
                        icon: Icons.login_rounded,
                        color: GaddarColors.emerald,
                        onPressed: service.isLoading
                            ? null
                            : () {
                                _roomCodeCtrl.text = service.savedRoomCode!;
                                _handleJoinRoom();
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              CartoonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "JOIN FRIEND'S ROOM (6-DIGIT CODE)",
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.cyan,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _roomCodeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8,
                        color: GaddarColors.cyan,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText: '••••••',
                        hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                        filled: true,
                        fillColor: GaddarColors.bgDeep,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: GaddarColors.ink, width: 2.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    CartoonButton(
                      label: service.isLoading ? 'CONNECTING...' : 'JOIN ROOM WITH CODE',
                      icon: Icons.login_rounded,
                      color: GaddarColors.cyan,
                      onPressed: service.isLoading ? null : _handleJoinRoom,
                    ),
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
