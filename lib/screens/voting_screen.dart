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
    final isEliminated = me?.isEliminated ?? false;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '🗳️ SECRET BALLOT (${me?.nickname ?? "Player"}\'S PHONE)',
                            style: GoogleFonts.fredoka(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: GaddarColors.gold,
                            ),
                          ),
                        ),
                        const HostControlsHeaderButton(),
                      ],
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
                      onTap: (myConfirmedVote != null || isEliminated)
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
                              isEliminated
                                  ? 'Active Suspect'
                                  : (isSelected ? '🎯 SUSPECT SELECTED' : 'Tap to Suspect'),
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

              if (isEliminated)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: GaddarColors.crimson.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: GaddarColors.crimson, width: 2.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('👻', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          'SPECTATOR MODE: You are eliminated. Spectating remaining votes ($votesCast/$totalVoters)...',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
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

              if (me?.isHost == true && votesCast < totalVoters) ...[
                const SizedBox(height: 8),
                Center(
                  child: TextButton.icon(
                    onPressed: service.forceResolveVoting,
                    icon: const Icon(Icons.flash_on_rounded, color: GaddarColors.gold, size: 18),
                    label: Text(
                      '👑 Host: Force Resolve Votes ($votesCast/$totalVoters Voted)',
                      style: GoogleFonts.spaceGrotesk(
                        color: GaddarColors.gold,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
