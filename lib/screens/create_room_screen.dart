import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../data/word_packs.dart';
import '../models/game_models.dart';
import '../services/supabase_game_service.dart';
import '../widgets/cartoon_widgets.dart';

class CreateRoomScreen extends StatefulWidget {
  final String hostNickname;
  final int hostAvatarIndex;

  const CreateRoomScreen({
    super.key,
    required this.hostNickname,
    required this.hostAvatarIndex,
  });

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  int _impostorCount = 1;
  int _discussionTimerSec = 90;
  int _maxRounds = 4;
  bool _impostorGetsHint = true;
  ClueRule _clueRule = ClueRule.oneWord;
  final Set<String> _selectedCategories = Set.from(GaddarWordPacks.allCategories);

  Future<void> _submitCreateRoom() async {
    final service = context.read<SupabaseGameService>();
    final ok = await service.createRoom(
      nickname: widget.hostNickname,
      avatarIndex: widget.hostAvatarIndex,
      impostorCount: _impostorCount,
      discussionTimerSec: _discussionTimerSec,
      maxRounds: _maxRounds,
      impostorGetsHint: _impostorGetsHint,
      clueRule: _clueRule,
      selectedCategories: _selectedCategories.toList(),
    );
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GaddarColors.bgDeep,
      appBar: AppBar(
        backgroundColor: GaddarColors.bgDeep,
        elevation: 0,
        title: Text(
          'CUSTOM GAME SETTINGS',
          style: GoogleFonts.fredoka(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CartoonCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'NUMBER OF GADDARS (IMPOSTORS)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 1, label: Text('1 Gaddar')),
                        ButtonSegment(value: 2, label: Text('2 Gaddars')),
                        ButtonSegment(value: 3, label: Text('3 Gaddars')),
                      ],
                      selected: {_impostorCount},
                      onSelectionChanged: (s) => setState(() => _impostorCount = s.first),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'DISCUSSION TIMER (SECONDS)',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.cyan,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 60, label: Text('60s')),
                        ButtonSegment(value: 90, label: Text('90s')),
                        ButtonSegment(value: 120, label: Text('120s')),
                      ],
                      selected: {_discussionTimerSec},
                      onSelectionChanged: (s) => setState(() => _discussionTimerSec = s.first),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MAX ROUNDS',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.emerald,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(value: 3, label: Text('3 Rounds')),
                        ButtonSegment(value: 4, label: Text('4 Rounds')),
                        ButtonSegment(value: 6, label: Text('6 Rounds')),
                      ],
                      selected: {_maxRounds},
                      onSelectionChanged: (s) => setState(() => _maxRounds = s.first),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Gaddar Gets Secret Word Hint',
                        style: GoogleFonts.fredoka(color: Colors.white, fontSize: 16),
                      ),
                      subtitle: const Text(
                        'If disabled, Gaddar plays in Hardcore Blind Bluff mode!',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      value: _impostorGetsHint,
                      activeThumbColor: GaddarColors.emerald,
                      onChanged: (v) => setState(() => _impostorGetsHint = v),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<ClueRule>(
                      initialValue: _clueRule,
                      dropdownColor: GaddarColors.bgCard,
                      style: GoogleFonts.fredoka(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        labelText: 'Physical Spoken Clue Rule',
                        labelStyle: TextStyle(color: Colors.white70),
                      ),
                      items: ClueRule.values
                          .map((r) => DropdownMenuItem(value: r, child: Text(r.label)))
                          .toList(),
                      onChanged: (r) {
                        if (r != null) setState(() => _clueRule = r);
                      },
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
                      'WORD PACK CATEGORIES',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GaddarColors.gold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: GaddarWordPacks.allCategories.map((cat) {
                        final active = _selectedCategories.contains(cat);
                        return FilterChip(
                          label: Text(cat),
                          selected: active,
                          selectedColor: GaddarColors.gold,
                          checkmarkColor: GaddarColors.ink,
                          labelStyle: TextStyle(
                            color: active ? GaddarColors.ink : Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedCategories.add(cat);
                              } else if (_selectedCategories.length > 1) {
                                _selectedCategories.remove(cat);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              CartoonButton(
                label: 'GENERATE 6-DIGIT ROOM CODE',
                icon: Icons.rocket_launch_rounded,
                color: GaddarColors.emerald,
                onPressed: _submitCreateRoom,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
