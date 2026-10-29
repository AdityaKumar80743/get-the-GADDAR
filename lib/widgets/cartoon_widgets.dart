import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_models.dart';
import '../services/supabase_game_service.dart';

class GaddarColors {
  static const Color bgDeep = Color(0xFF1A0938);
  static const Color bgCard = Color(0xFF2B125A);
  static const Color gold = Color(0xFFFFCA28);
  static const Color crimson = Color(0xFFFF2E55);
  static const Color emerald = Color(0xFF00E676);
  static const Color cyan = Color(0xFF00E5FF);
  static const Color violet = Color(0xFF9C27B0);
  static const Color ink = Color(0xFF0D041C);

  static const List<String> avatarEmojis = [
    '🕵️', '🦊', '🐯', '🐼', '🦁', '🐸', '🐵', '🦄', '🐲', '🦉', '🥷', '👑'
  ];
}

class CartoonButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final Color textColor;
  final VoidCallback? onPressed;
  final bool isFullWidth;

  const CartoonButton({
    super.key,
    required this.label,
    this.icon,
    this.color = GaddarColors.gold,
    this.textColor = GaddarColors.ink,
    this.onPressed,
    this.isFullWidth = true,
  });

  @override
  State<CartoonButton> createState() => _CartoonButtonState();
}

class _CartoonButtonState extends State<CartoonButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return GestureDetector(
      onTapDown: disabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: disabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              HapticFeedback.mediumImpact();
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.isFullWidth ? double.infinity : null,
        transform: Matrix4.translationValues(0, _pressed ? 5 : 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          color: disabled ? Colors.white24 : widget.color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: GaddarColors.ink, width: 3.5),
          boxShadow: [
            BoxShadow(
              color: GaddarColors.ink,
              offset: Offset(0, _pressed ? 1 : 6),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: widget.isFullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: disabled ? Colors.white54 : widget.textColor, size: 22),
              const SizedBox(width: 10),
            ],
            Flexible(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.fredoka(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: disabled ? Colors.white54 : widget.textColor,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CartoonCard extends StatelessWidget {
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const CartoonCard({
    super.key,
    required this.child,
    this.color = GaddarColors.bgCard,
    this.borderColor = GaddarColors.ink,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor, width: 3.5),
        boxShadow: const [
          BoxShadow(
            color: GaddarColors.ink,
            offset: Offset(0, 7),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}

class ReadyBarrierBanner extends StatelessWidget {
  final String actionLabel;
  final List<Player> activePlayers;
  final Player? myPlayer;
  final VoidCallback onPressReady;
  final VoidCallback? onForceAdvance;

  const ReadyBarrierBanner({
    super.key,
    required this.actionLabel,
    required this.activePlayers,
    required this.myPlayer,
    required this.onPressReady,
    this.onForceAdvance,
  });

  @override
  Widget build(BuildContext context) {
    final readyCount = activePlayers.where((p) => p.hasReady).length;
    final total = activePlayers.length;
    final iAmReady = myPlayer?.hasReady ?? false;
    final isEliminated = myPlayer?.isEliminated ?? false;
    final waitingNames = activePlayers
        .where((p) => !p.hasReady)
        .map((p) => p.nickname)
        .toList();

    return CartoonCard(
      color: const Color(0xFF210D47),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ALL PHONES MUST CONFIRM',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: GaddarColors.cyan,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: readyCount == total ? GaddarColors.emerald : GaddarColors.gold,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: GaddarColors.ink, width: 2),
                ),
                child: Text(
                  '$readyCount / $total READY',
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GaddarColors.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : readyCount / total,
              minHeight: 10,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(GaddarColors.emerald),
            ),
          ),
          const SizedBox(height: 10),
          if (waitingNames.isNotEmpty)
            Text(
              'Waiting on: ${waitingNames.join(", ")}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 12),
          if (isEliminated)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: GaddarColors.crimson.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: GaddarColors.crimson, width: 2),
              ),
              child: Row(
                children: [
                  const Text('👻', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'SPECTATOR MODE: You were caught/eliminated! Spectating while friends continue...',
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
              label: iAmReady
                  ? '✓ Waiting for Everyone Else ($readyCount/$total)...'
                  : '$actionLabel ($readyCount/$total)',
              icon: iAmReady ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
              color: iAmReady ? GaddarColors.emerald : GaddarColors.gold,
              onPressed: iAmReady ? null : onPressReady,
            ),
          if (myPlayer?.isHost == true && onForceAdvance != null && readyCount < total) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: onForceAdvance,
              icon: const Icon(Icons.fast_forward_rounded, color: GaddarColors.gold, size: 18),
              label: Text(
                '👑 Host: Force Advance Phase (Skip AFK)',
                style: GoogleFonts.spaceGrotesk(
                  color: GaddarColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class GaddarDialogs {
  static Future<bool> showExitAppDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: GaddarColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: GaddarColors.ink, width: 3.5),
        ),
        title: Text(
          '🚪 EXIT GAME?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: GaddarColors.gold,
          ),
        ),
        content: Text(
          'Are you sure you want to close Get the GADDAR?',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: CartoonButton(
                  label: 'STAY',
                  color: Colors.white24,
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartoonButton(
                  label: 'EXIT',
                  color: GaddarColors.crimson,
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> showLeaveMatchDialog(
    BuildContext context, {
    String? roomCode,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: GaddarColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: GaddarColors.ink, width: 3.5),
        ),
        title: Text(
          '⚠️ LEAVE MATCH?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: GaddarColors.crimson,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              roomCode != null && roomCode.isNotEmpty
                  ? 'You are in Room #$roomCode'
                  : 'You are currently in an active game',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: GaddarColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Leaving will remove you from this session and your friends will continue without you!',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: CartoonButton(
                  label: 'KEEP PLAYING',
                  color: GaddarColors.emerald,
                  textColor: GaddarColors.ink,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartoonButton(
                  label: 'LEAVE ROOM',
                  color: GaddarColors.crimson,
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static Future<bool> showKickPlayerDialog(
    BuildContext context, {
    required String nickname,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: GaddarColors.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: GaddarColors.crimson, width: 3),
        ),
        title: Text(
          '👢 KICK PLAYER?',
          textAlign: TextAlign.center,
          style: GoogleFonts.fredoka(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: GaddarColors.crimson,
          ),
        ),
        content: Text(
          'Remove "$nickname" from the match? If they were the Gaddar, Friends will automatically win.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: CartoonButton(
                  label: 'CANCEL',
                  color: Colors.white24,
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CartoonButton(
                  label: 'KICK',
                  color: GaddarColors.crimson,
                  textColor: Colors.white,
                  onPressed: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  static void showHowToPlayDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GaddarColors.bgDeep,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: GaddarColors.gold, width: 3),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text('📖', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        'HOW TO PLAY GADDAR',
                        style: GoogleFonts.fredoka(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: GaddarColors.gold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _buildHowToPlayStep(
                      stepNum: '1',
                      title: 'LOOK AT YOUR SECRET ROLE',
                      emoji: '🕵️',
                      color: GaddarColors.crimson,
                      description:
                          'Shield your phone! Press and hold the vault card to peek at your secret identity:\n'
                          '• Friends get the exact Secret Word (e.g. "Biryani").\n'
                          '• The Gaddar (Impostor) gets only a subtle clue (e.g. "Clay Pot Rice") or no hint at all!',
                    ),
                    const SizedBox(height: 12),
                    _buildHowToPlayStep(
                      stepNum: '2',
                      title: 'SPEAK 1-WORD CLUES OUT LOUD',
                      emoji: '🗣️',
                      color: GaddarColors.cyan,
                      description:
                          'Go around the room in real life in the order shown on your phone. Each player speaks strictly ONE clue word out loud.\n'
                          '• Friends: Say a clever clue that proves you know the word without giving it away to the Gaddar!\n'
                          '• Gaddar: Listen carefully, fake confidence, and bluff a believable word to blend in!',
                    ),
                    const SizedBox(height: 12),
                    _buildHowToPlayStep(
                      stepNum: '3',
                      title: 'DEBATE & VOTE ANONYMOUSLY',
                      emoji: '🗳️',
                      color: GaddarColors.gold,
                      description:
                          'Argue in real life about whose clue was suspicious. Then lock in your secret vote on your phone!\n'
                          '• Gaddar survives required rounds: Gaddar wins the match!\n'
                          '• Gaddar caught by majority vote: They get 1 Last-Chance guess at the Secret Word to steal the win (+150 pts)!',
                    ),
                    const SizedBox(height: 12),
                    _buildHowToPlayStep(
                      stepNum: '★',
                      title: 'HIDDEN LEADERBOARD & MVP',
                      emoji: '🏆',
                      color: GaddarColors.emerald,
                      description:
                          '• +50 secret points for every round you correctly vote for the real Gaddar!\n'
                          '• +100 bonus victory points for all winning team members.\n'
                          '• Final roles and scores are revealed at the end of the match!',
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              CartoonButton(
                label: 'GOT IT — READY TO PLAY!',
                icon: Icons.check_circle_rounded,
                color: GaddarColors.emerald,
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildHowToPlayStep({
    required String stepNum,
    required String title,
    required String emoji,
    required Color color,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GaddarColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: color,
                child: Text(
                  stepNum,
                  style: GoogleFonts.fredoka(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: GaddarColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$emoji $title',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class HostControlsHeaderButton extends StatelessWidget {
  const HostControlsHeaderButton({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final me = service.myPlayer;
    if (me?.isHost != true) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => HostControlsSheet.show(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: GaddarColors.gold,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: GaddarColors.ink, width: 2),
          boxShadow: const [
            BoxShadow(
              color: GaddarColors.ink,
              offset: Offset(0, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              'HOST',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: GaddarColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HostControlsSheet extends StatelessWidget {
  const HostControlsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: GaddarColors.bgDeep,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: GaddarColors.gold, width: 3),
      ),
      builder: (_) => const HostControlsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SupabaseGameService>();
    final room = service.currentRoom;
    final me = service.myPlayer;
    final players = service.players;

    if (room == null || me?.isHost != true) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text('👑', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Text(
                      'HOST CONTROLS',
                      style: GoogleFonts.fredoka(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: GaddarColors.gold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 10),

            CartoonCard(
              color: const Color(0xFF34146E),
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '⚡ QUICK PHASE OVERRIDES',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: GaddarColors.cyan,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (room.status == RoomStatus.roleReveal)
                    CartoonButton(
                      label: 'Advance to Discussion',
                      icon: Icons.fast_forward_rounded,
                      color: GaddarColors.gold,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await service.forceAdvancePhase(RoomStatus.discussion);
                      },
                    ),
                  if (room.status == RoomStatus.discussion)
                    CartoonButton(
                      label: 'Advance to Voting',
                      icon: Icons.how_to_vote_rounded,
                      color: GaddarColors.cyan,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await service.forceAdvancePhase(RoomStatus.voting);
                      },
                    ),
                  if (room.status == RoomStatus.voting)
                    CartoonButton(
                      label: 'Force Resolve Votes Now',
                      icon: Icons.flash_on_rounded,
                      color: GaddarColors.crimson,
                      textColor: Colors.white,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await service.forceResolveVoting();
                      },
                    ),
                  if (room.status == RoomStatus.roundResult)
                    CartoonButton(
                      label: 'Start Next Round',
                      icon: Icons.play_arrow_rounded,
                      color: GaddarColors.emerald,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await service.forceAdvancePhase(RoomStatus.discussion);
                      },
                    ),
                  if (room.status == RoomStatus.lastChance)
                    CartoonButton(
                      label: "Time's Up — Skip Guess",
                      icon: Icons.timer_off_rounded,
                      color: GaddarColors.crimson,
                      textColor: Colors.white,
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await service.submitLastChanceGuess('(Time Expired)');
                      },
                    ),
                  if (room.status == RoomStatus.lobby)
                    Text(
                      'Match has not started yet. Need 3+ players.',
                      style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 12),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Text(
              'CONNECTED PLAYERS (${players.length}) • KICK AFK / DISCONNECTED',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),

            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (ctx, i) {
                  final p = players[i];
                  final isMe = p.id == me?.id;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: GaddarColors.bgCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: p.isHost ? GaddarColors.gold : GaddarColors.ink,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          GaddarColors.avatarEmojis[p.avatarIndex % GaddarColors.avatarEmojis.length],
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.nickname}${isMe ? " (You)" : ""}',
                                style: GoogleFonts.fredoka(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                p.isHost
                                    ? '👑 Room Host'
                                    : (p.isEliminated ? '👻 Eliminated' : 'Active Player'),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: p.isHost ? GaddarColors.gold : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMe)
                          IconButton(
                            icon: const Icon(Icons.person_remove_rounded, color: GaddarColors.crimson, size: 20),
                            tooltip: 'Kick player',
                            onPressed: () async {
                              final shouldKick = await GaddarDialogs.showKickPlayerDialog(
                                context,
                                nickname: p.nickname,
                              );
                              if (shouldKick) {
                                await service.kickPlayer(p.id);
                              }
                            },
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
