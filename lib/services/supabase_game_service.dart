import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../data/word_packs.dart';
import '../models/game_models.dart';

class SupabaseGameService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Random _random = Random();

  String _deviceId = '';
  String? _currentPlayerId;
  GameRoom? _currentRoom;
  List<Player> _players = [];
  List<CustomWordItem> _customWords = [];
  Map<String, String> _currentRoundVotes = {};
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<Map<String, dynamic>>>? _roomSub;
  StreamSubscription<List<Map<String, dynamic>>>? _playersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _customWordsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _votesSub;

  String get deviceId => _deviceId;
  String? get currentPlayerId => _currentPlayerId;
  GameRoom? get currentRoom => _currentRoom;
  List<Player> get players => _players;
  List<CustomWordItem> get customWords => _customWords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Player? get myPlayer {
    if (_currentPlayerId == null) return null;
    try {
      return _players.firstWhere((p) => p.id == _currentPlayerId);
    } catch (_) {
      return null;
    }
  }

  List<Player> get activePlayers =>
      _players.where((p) => !p.isEliminated).toList();

  int get readyCount => activePlayers.where((p) => p.hasReady).length;

  int get votesCastCount => _currentRoundVotes.length;

  String? get myVotedSuspectId =>
      _currentPlayerId != null ? _currentRoundVotes[_currentPlayerId] : null;

  Map<String, int> get anonymousVoteTally {
    final tally = <String, int>{};
    for (final suspectId in _currentRoundVotes.values) {
      tally[suspectId] = (tally[suspectId] ?? 0) + 1;
    }
    return tally;
  }

  Future<void> initDeviceIdentity() async {
    final prefs = await SharedPreferences.getInstance();
    var savedId = prefs.getString('gaddar_device_uuid');
    if (savedId == null || savedId.isEmpty) {
      savedId = const Uuid().v4();
      await prefs.setString('gaddar_device_uuid', savedId);
    }
    _deviceId = savedId;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _generateSixDigitCode() {
    return (100000 + _random.nextInt(900000)).toString();
  }

  Future<bool> createRoom({
    required String nickname,
    required int avatarIndex,
    int impostorCount = 1,
    int discussionTimerSec = 90,
    int maxRounds = 4,
    bool impostorGetsHint = true,
    ClueRule clueRule = ClueRule.oneWord,
    List<String>? selectedCategories,
  }) async {
    if (nickname.trim().isEmpty) {
      _errorMessage = 'Please enter your player nickname.';
      notifyListeners();
      return false;
    }
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_deviceId.isEmpty) await initDeviceIdentity();
      final roomCode = _generateSixDigitCode();
      final hostPlayerUuid = const Uuid().v4();

      final roomInsert = await _supabase
          .from('rooms')
          .insert({
            'room_code': roomCode,
            'host_player_id': hostPlayerUuid,
            'status': 'lobby',
            'current_round': 1,
            'max_rounds': maxRounds,
            'impostor_count': impostorCount,
            'discussion_timer_sec': discussionTimerSec,
            'impostor_gets_hint': impostorGetsHint,
            'clue_rule': clueRule.dbValue,
            'selected_categories': selectedCategories ?? GaddarWordPacks.allCategories,
          })
          .select()
          .single();

      final roomId = roomInsert['id'] as String;

      await _supabase.from('players').insert({
        'id': hostPlayerUuid,
        'room_id': roomId,
        'device_id': _deviceId,
        'nickname': nickname.trim(),
        'avatar_index': avatarIndex,
        'is_host': true,
        'role': 'friend',
      });

      _currentPlayerId = hostPlayerUuid;
      _currentRoom = GameRoom.fromMap(roomInsert);
      _subscribeToRoomStreams(roomId);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to create room: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> joinRoom({
    required String roomCode,
    required String nickname,
    required int avatarIndex,
  }) async {
    final cleanCode = roomCode.trim();
    if (cleanCode.length != 6) {
      _errorMessage = 'Enter a valid 6-digit room code.';
      notifyListeners();
      return false;
    }
    if (nickname.trim().isEmpty) {
      _errorMessage = 'Please enter your player nickname.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_deviceId.isEmpty) await initDeviceIdentity();

      final roomRow = await _supabase
          .from('rooms')
          .select()
          .eq('room_code', cleanCode)
          .maybeSingle();

      if (roomRow == null) {
        _isLoading = false;
        _errorMessage = 'Room #$cleanCode not found. Check the 6-digit code!';
        notifyListeners();
        return false;
      }

      final room = GameRoom.fromMap(roomRow);
      if (room.status != RoomStatus.lobby) {
        final existingPlayer = await _supabase
            .from('players')
            .select()
            .eq('room_id', room.id)
            .eq('device_id', _deviceId)
            .maybeSingle();

        if (existingPlayer != null) {
          _currentPlayerId = existingPlayer['id'] as String;
          _currentRoom = room;
          _subscribeToRoomStreams(room.id);
          _isLoading = false;
          notifyListeners();
          return true;
        }

        _isLoading = false;
        _errorMessage = 'Room #$cleanCode is already in the middle of a match!';
        notifyListeners();
        return false;
      }

      final upsertedPlayer = await _supabase
          .from('players')
          .upsert(
            {
              'room_id': room.id,
              'device_id': _deviceId,
              'nickname': nickname.trim(),
              'avatar_index': avatarIndex,
            },
            onConflict: 'room_id,device_id',
          )
          .select()
          .single();

      _currentPlayerId = upsertedPlayer['id'] as String;
      _currentRoom = room;
      _subscribeToRoomStreams(room.id);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Could not join room: $e';
      notifyListeners();
      return false;
    }
  }

  void _subscribeToRoomStreams(String roomId) {
    _cancelSubscriptions();

    _roomSub = _supabase
        .from('rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .listen((rows) {
          if (rows.isNotEmpty) {
            final prevRound = _currentRoom?.currentRound;
            _currentRoom = GameRoom.fromMap(rows.first);
            if (prevRound != _currentRoom!.currentRound) {
              _subscribeToVotesForRound(roomId, _currentRoom!.currentRound);
            }
            notifyListeners();
          }
        });

    _playersSub = _supabase
        .from('players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('joined_at', ascending: true)
        .listen((rows) {
          _players = rows.map(Player.fromMap).toList();
          notifyListeners();
        });

    _customWordsSub = _supabase
        .from('custom_words')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('created_at', ascending: true)
        .listen((rows) {
          _customWords = rows.map(CustomWordItem.fromMap).toList();
          notifyListeners();
        });

    _subscribeToVotesForRound(roomId, _currentRoom?.currentRound ?? 1);
  }

  void _subscribeToVotesForRound(String roomId, int roundNumber) {
    _votesSub?.cancel();
    _votesSub = _supabase
        .from('votes')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .listen((rows) {
          final map = <String, String>{};
          for (final r in rows) {
            if ((r['round_number'] as num?)?.toInt() == roundNumber) {
              map[r['voter_id'] as String] = r['suspect_id'] as String;
            }
          }
          _currentRoundVotes = map;
          notifyListeners();
        });
  }

  Future<void> updateRoomSettings({
    int? impostorCount,
    int? discussionTimerSec,
    int? maxRounds,
    bool? impostorGetsHint,
    ClueRule? clueRule,
    List<String>? selectedCategories,
  }) async {
    final room = _currentRoom;
    if (room == null || myPlayer?.isHost != true) return;

    final updates = <String, dynamic>{};
    if (impostorCount != null) updates['impostor_count'] = impostorCount;
    if (discussionTimerSec != null) updates['discussion_timer_sec'] = discussionTimerSec;
    if (maxRounds != null) updates['max_rounds'] = maxRounds;
    if (impostorGetsHint != null) updates['impostor_gets_hint'] = impostorGetsHint;
    if (clueRule != null) updates['clue_rule'] = clueRule.dbValue;
    if (selectedCategories != null && selectedCategories.isNotEmpty) {
      updates['selected_categories'] = selectedCategories;
    }

    await _supabase.from('rooms').update(updates).eq('id', room.id);
  }

  Future<void> addCustomWord(String word, String hint) async {
    final room = _currentRoom;
    final me = myPlayer;
    if (room == null || me == null || word.trim().isEmpty || hint.trim().isEmpty) return;

    await _supabase.from('custom_words').insert({
      'room_id': room.id,
      'word': word.trim(),
      'hint': hint.trim(),
      'author_player_id': me.id,
      'author_nickname': me.nickname,
    });
  }

  Future<bool> startMatch() async {
    final room = _currentRoom;
    if (room == null || myPlayer?.isHost != true) return false;
    if (_players.length < 3) {
      _errorMessage = 'At least 3 players on separate phones are required to start!';
      notifyListeners();
      return false;
    }

    final pool = <WordPair>[];
    for (final cat in room.selectedCategories) {
      if (cat == 'Custom Words') {
        for (final cw in _customWords) {
          pool.add(WordPair(word: cw.word, hint: cw.hint, category: 'Custom Words'));
        }
      } else {
        final list = GaddarWordPacks.builtInPacks[cat] ?? const [];
        for (final item in list) {
          pool.add(WordPair(
            word: item['word']!,
            hint: item['hint']!,
            category: cat,
          ));
        }
      }
    }

    if (pool.isEmpty) {
      for (final item in GaddarWordPacks.builtInPacks['Movies']!) {
        pool.add(WordPair(word: item['word']!, hint: item['hint']!, category: 'Movies'));
      }
    }

    final chosen = pool[_random.nextInt(pool.length)];
    final shuffledIds = _players.map((p) => p.id).toList()..shuffle(_random);
    final gaddarCount = min(room.impostorCount, max(1, _players.length - 2));
    final gaddarIds = shuffledIds.take(gaddarCount).toList();

    await _supabase.rpc('start_match', params: {
      'p_room_id': room.id,
      'p_secret_word': chosen.word,
      'p_secret_hint': chosen.hint,
      'p_secret_category': chosen.category,
      'p_gaddar_ids': gaddarIds,
    });
    return true;
  }

  Future<void> markReadyForPhase(RoomStatus targetPhase) async {
    final room = _currentRoom;
    final me = myPlayer;
    if (room == null || me == null || me.isEliminated) return;

    await _supabase.rpc('mark_player_ready', params: {
      'p_room_id': room.id,
      'p_player_id': me.id,
      'p_target_status': targetPhase.toDbString(),
    });
  }

  Future<void> castAnonymousVote(String suspectPlayerId) async {
    final room = _currentRoom;
    final me = myPlayer;
    if (room == null || me == null || me.isEliminated) return;

    await _supabase.rpc('cast_anonymous_vote', params: {
      'p_room_id': room.id,
      'p_round': room.currentRound,
      'p_voter_id': me.id,
      'p_suspect_id': suspectPlayerId,
    });
  }

  Future<void> submitLastChanceGuess(String guess) async {
    final room = _currentRoom;
    final me = myPlayer;
    if (room == null || me == null) return;

    await _supabase.rpc('resolve_last_chance_guess', params: {
      'p_room_id': room.id,
      'p_gaddar_id': room.caughtGaddarId ?? me.id,
      'p_guess': guess.trim(),
    });
  }

  Future<void> returnRoomToLobby() async {
    final room = _currentRoom;
    if (room == null || myPlayer?.isHost != true) return;

    await _supabase.from('votes').delete().eq('room_id', room.id);
    await _supabase.from('players').update({
      'is_eliminated': false,
      'has_ready': false,
      'has_voted_current_round': false,
    }).eq('room_id', room.id);

    await _supabase.from('rooms').update({
      'status': 'lobby',
      'current_round': 1,
      'caught_gaddar_id': null,
      'caught_gaddar_name': null,
      'last_chance_guess': null,
      'winner_team': null,
      'win_reason': null,
    }).eq('id', room.id);
  }

  Future<void> leaveRoom() async {
    final room = _currentRoom;
    final me = myPlayer;
    _cancelSubscriptions();
    if (room != null && me != null) {
      try {
        await _supabase.from('players').delete().eq('id', me.id);
      } catch (_) {}
    }
    _currentRoom = null;
    _currentPlayerId = null;
    _players = [];
    _customWords = [];
    _currentRoundVotes = {};
    notifyListeners();
  }

  void _cancelSubscriptions() {
    _roomSub?.cancel();
    _playersSub?.cancel();
    _customWordsSub?.cancel();
    _votesSub?.cancel();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
