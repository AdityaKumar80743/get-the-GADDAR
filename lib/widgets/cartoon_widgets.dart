import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_models.dart';

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

  const ReadyBarrierBanner({
    super.key,
    required this.actionLabel,
    required this.activePlayers,
    required this.myPlayer,
    required this.onPressReady,
  });

  @override
  Widget build(BuildContext context) {
    final readyCount = activePlayers.where((p) => p.hasReady).length;
    final total = activePlayers.length;
    final iAmReady = myPlayer?.hasReady ?? false;
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
          CartoonButton(
            label: iAmReady
                ? '✓ Waiting for Everyone Else ($readyCount/$total)...'
                : '$actionLabel ($readyCount/$total)',
            icon: iAmReady ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
            color: iAmReady ? GaddarColors.emerald : GaddarColors.gold,
            onPressed: iAmReady ? null : onPressReady,
          ),
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
}
