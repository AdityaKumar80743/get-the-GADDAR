import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}

class _VotingScreenState extends State<VotingScreen> {
  String? _selectedSuspectId;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final me = service.myPlayer;
    final activePlayers = service.activePlayers;
    final myConfirmedVote = service.myVotedSuspectId;
    final votesCast = service.votesCastCount;
    final totalVoters = activePlayers.length;

    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartoonCard(
                color: const Color(0xFF3A0F49),
                child: Column(
                  children: [
                    Text(
                      '🗳️ SECRET BALLOT BOX (${me?.nickname ?? "Player"}\'S PHONE)',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Voter names are 100% hidden! Even the Gaddar votes. The round resolves automatically as soon as every player locks in their vote on their phone.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '$votesCast / $totalVoters PHONES HAVE VOTED',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemCount: activePlayers.length,
                  itemBuilder: (context, index) {
                    final suspect = activePlayers[index];
                    final isSelected = (myConfirmedVote ?? _selectedSuspectId) == suspect.id;
                    return GestureDetector(
                      onTap: myConfirmedVote != null
                          ? null
                          : () => setState(() => _selectedSuspectId = suspect.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF5A1032)
                              : GaddarColors.bgCard,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? GaddarColors.crimson : GaddarColors.ink,
                            width: 3.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              GaddarColors.avatarEmojis[
                                  suspect.avatarIndex % GaddarColors.avatarEmojis.length],
                              style: const TextStyle(fontSize: 32),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${suspect.nickname}${suspect.id == me?.id ? " (You)" : ""}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.fredoka(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isSelected ? '🎯 SUSPECT SELECTED' : 'Tap to Suspect',
                              style: TextStyle(
                                color: isSelected ? GaddarColors.gold : Colors.white54,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              CartoonButton(
                label: myConfirmedVote != null
                    ? '✓ VOTE LOCKED IN ($votesCast/$totalVoters VOTED)'
                    : 'CAST ANONYMOUS VOTE',
                icon: Icons.how_to_vote_rounded,
                color: myConfirmedVote != null
                    ? GaddarColors.emerald
                    : GaddarColors.crimson,
                textColor: myConfirmedVote != null ? GaddarColors.ink : Colors.white,
                onPressed: (myConfirmedVote != null || _selectedSuspectId == null)
                    ? null
                    : () => service.castAnonymousVote(_selectedSuspectId!),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
