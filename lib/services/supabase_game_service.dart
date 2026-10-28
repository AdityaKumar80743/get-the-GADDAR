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
  List<WordPair> _remoteWords = [];
  Map<String, String> _currentRoundVotes = {};
  bool _isLoading = false;
  String? _errorMessage;
  String? _savedRoomCode;

  StreamSubscription<List<Map<String, dynamic>>>? _roomSub;
  StreamSubscription<List<Map<String, dynamic>>>? _playersSub;
  StreamSubscription<List<Map<String, dynamic>>>? _customWordsSub;
  StreamSubscription<List<Map<String, dynamic>>>? _votesSub;

  String get deviceId => _deviceId;
  String? get currentPlayerId => _currentPlayerId;
  GameRoom? get currentRoom => _currentRoom;
  List<Player> get players => _players;
  List<CustomWordItem> get customWords => _customWords;
  List<WordPair> get remoteWords => _remoteWords;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get savedRoomCode => _savedRoomCode;

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
    _savedRoomCode = prefs.getString('gaddar_active_room_code');
    notifyListeners();
    unawaited(loadGlobalWords());
  }

  Future<void> loadGlobalWords() async {
    try {
      final rows = await _supabase
          .from('global_words')
          .select()
          .order('category', ascending: true);
      _remoteWords = rows.map((r) => WordPair.fromMap(r)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Global words load info: $e (using offline packs)');
    }
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
      _players = [
        Player(
          id: hostPlayerUuid,
          roomId: roomId,
          deviceId: _deviceId,
          nickname: nickname.trim(),
          avatarIndex: avatarIndex,
          isHost: true,
          role: 'friend',
          isEliminated: false,
          hasReady: false,
          hasVotedCurrentRound: false,
          secretScore: 0,
          correctGaddarVotes: 0,
          roundsSurvivedAsGaddar: 0,
        )
      ];
      await _saveSession(roomId, roomCode);
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
          await _saveSession(room.id, room.roomCode);
          _subscribeToRoomStreams(room.id);
          _isLoading = false;
          notifyListeners();
          return true;
        }

        // Mid-match join: allow rejoining/joining as Spectator without breaking barriers!
        final spectatorPlayer = await _supabase
            .from('players')
            .insert({
              'room_id': room.id,
              'device_id': _deviceId,
              'nickname': nickname.trim(),
              'avatar_index': avatarIndex,
              'is_host': false,
              'role': 'friend',
              'is_eliminated': true,
            })
            .select()
            .single();

        _currentPlayerId = spectatorPlayer['id'] as String;
        _currentRoom = room;
        await _saveSession(room.id, room.roomCode);
        _subscribeToRoomStreams(room.id);
        _isLoading = false;
        notifyListeners();
        return true;
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
      await _saveSession(room.id, room.roomCode);
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
            final prevStatus = _currentRoom?.status;
            _currentRoom = GameRoom.fromMap(rows.first);

            // Phase cleanup: wipe old votes whenever room is not in voting phase
            if (_currentRoom!.status != RoomStatus.voting) {
              _currentRoundVotes = {};
            }

            final isEnteringVoting = _currentRoom!.status == RoomStatus.voting &&
                prevStatus != RoomStatus.voting;
            final isRoundChangedInVoting =
                _currentRoom!.status == RoomStatus.voting &&
                    prevRound != _currentRoom!.currentRound;

            if (isEnteringVoting || isRoundChangedInVoting) {
              _subscribeToVotesForRound(roomId, _currentRoom!.currentRound);
            }
            notifyListeners();
          } else {
            // Room was closed or deleted
            _cancelSubscriptions();
            unawaited(_clearSession());
            _currentRoom = null;
            _currentPlayerId = null;
            _players = [];
            _errorMessage = 'The match has ended or the room was closed.';
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
    _currentRoundVotes = {};
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

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final pool = <WordPair>[];
      for (final cat in room.selectedCategories) {
        if (cat == 'Custom Words') {
          for (final cw in _customWords) {
            pool.add(WordPair(
              word: cw.word,
              hints: [cw.hint],
              category: 'Custom Words',
            ));
          }
        } else {
          final matchingRemote = _remoteWords
              .where((w) => w.category.trim().toLowerCase() == cat.trim().toLowerCase())
              .toList();

          if (matchingRemote.isNotEmpty) {
            pool.addAll(matchingRemote);
          } else {
            final list = GaddarWordPacks.builtInPacks[cat] ?? const [];
            for (final item in list) {
              pool.add(WordPair(
                word: item['word']!,
                hints: [item['hint']!],
                category: cat,
              ));
            }
          }
        }
      }

      if (pool.isEmpty) {
        for (final item in GaddarWordPacks.builtInPacks['Movies']!) {
          pool.add(WordPair(
            word: item['word']!,
            hints: [item['hint']!],
            category: 'Movies',
          ));
        }
      }

      final chosen = pool[_random.nextInt(pool.length)];
      final pickedHint = chosen.pickRandomHint(_random);
      final shuffledIds = _players.map((p) => p.id).toList()..shuffle(_random);
      final gaddarCount = min(room.impostorCount, max(1, _players.length - 2));
      final gaddarIds = shuffledIds.take(gaddarCount).toList();

      _currentRoundVotes = {};
      await _supabase.rpc('start_match', params: {
        'p_room_id': room.id,
        'p_secret_word': chosen.word,
        'p_secret_hint': pickedHint,
        'p_secret_category': chosen.category,
        'p_gaddar_ids': gaddarIds,
        'p_secret_image_url': (chosen.imageUrl != null && chosen.imageUrl!.isNotEmpty)
            ? chosen.imageUrl
            : null,
      });
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to start match: $e';
      notifyListeners();
      return false;
    }
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

    _currentRoundVotes = {};
    await _supabase.from('votes').delete().eq('room_id', room.id);
    await _supabase.from('players').update({
      'is_eliminated': false,
      'has_ready': false,
      'has_voted_current_round': false,
      'role': 'friend',
    }).eq('room_id', room.id);

    await _supabase.from('rooms').update({
      'status': 'lobby',
      'current_round': 1,
      'secret_word': null,
      'secret_hint': null,
      'secret_category': null,
      'secret_image_url': null,
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
    await _clearSession();
    if (room != null && me != null) {
      try {
        await _supabase.rpc('leave_room', params: {
          'p_room_id': room.id,
          'p_player_id': me.id,
        });
      } catch (_) {
        // Fallback if RPC is not yet executed in database
        try {
          await _supabase.from('players').delete().eq('id', me.id);
          final remaining = await _supabase
              .from('players')
              .select('id')
              .eq('room_id', room.id)
              .order('joined_at', ascending: true);
          if (remaining.isEmpty) {
            await _supabase.from('rooms').delete().eq('id', room.id);
          } else if (me.isHost) {
            final nextHostId = remaining.first['id'] as String;
            await _supabase.from('players').update({'is_host': true}).eq('id', nextHostId);
            await _supabase.from('rooms').update({'host_player_id': nextHostId}).eq('id', room.id);
          }
        } catch (_) {}
      }
    }
    _currentRoom = null;
    _currentPlayerId = null;
    _players = [];
    _customWords = [];
    _currentRoundVotes = {};
    notifyListeners();
  }

  Future<void> forceAdvancePhase(RoomStatus targetPhase) async {
    final room = _currentRoom;
    if (room == null || myPlayer?.isHost != true) return;
    try {
      await _supabase.rpc('force_advance_phase', params: {
        'p_room_id': room.id,
        'p_target_status': targetPhase.toDbString(),
      });
    } catch (_) {
      // Fallback
      await _supabase.from('players').update({'has_ready': true}).eq('room_id', room.id);
      await markReadyForPhase(targetPhase);
    }
  }

  Future<void> forceResolveVoting() async {
    final room = _currentRoom;
    if (room == null || myPlayer?.isHost != true) return;
    try {
      await _supabase.rpc('force_resolve_round_votes', params: {
        'p_room_id': room.id,
        'p_round': room.currentRound,
      });
    } catch (_) {}
  }

  Future<bool> kickPlayer(String targetPlayerId) async {
    final room = _currentRoom;
    final me = myPlayer;
    if (room == null || me == null || !me.isHost || targetPlayerId == me.id) {
      return false;
    }

    try {
      await _supabase.rpc('kick_player', params: {
        'p_room_id': room.id,
        'p_player_id': targetPlayerId,
        'p_host_id': me.id,
      });
      return true;
    } catch (_) {
      // Client-side fallback if RPC not yet run in database
      try {
        final kickedList = _players.where((p) => p.id == targetPlayerId).toList();
        final kicked = kickedList.isNotEmpty ? kickedList.first : null;
        await _supabase.from('votes').delete().eq('room_id', room.id).eq('voter_id', targetPlayerId);
        await _supabase.from('players').delete().eq('id', targetPlayerId);

        if (room.status != RoomStatus.lobby && room.status != RoomStatus.gameOver && kicked != null) {
          final remaining = _players.where((p) => p.id != targetPlayerId).toList();
          final remainingGaddars = remaining.where((p) => p.isGaddar && !p.isEliminated).length;
          if (remainingGaddars == 0) {
            await _supabase.from('rooms').update({
              'status': 'game_over',
              'winner_team': 'friends',
              'win_reason': '${kicked.nickname} was removed. Friends Win!',
            }).eq('id', room.id);
          } else if (room.status == RoomStatus.voting) {
            await forceResolveVoting();
          }
        }
        return true;
      } catch (e) {
        _errorMessage = 'Could not kick player: $e';
        notifyListeners();
        return false;
      }
    }
  }

  Future<void> _saveSession(String roomId, String roomCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('gaddar_active_room_id', roomId);
      await prefs.setString('gaddar_active_room_code', roomCode);
      _savedRoomCode = roomCode;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gaddar_active_room_id');
      await prefs.remove('gaddar_active_room_code');
      _savedRoomCode = null;
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> restoreActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRoomId = prefs.getString('gaddar_active_room_id');
      if (savedRoomId == null || savedRoomId.isEmpty) return false;
      if (_deviceId.isEmpty) await initDeviceIdentity();

      final roomRow = await _supabase
          .from('rooms')
          .select()
          .eq('id', savedRoomId)
          .maybeSingle();

      if (roomRow == null) {
        await _clearSession();
        return false;
      }

      final room = GameRoom.fromMap(roomRow);
      final playerRow = await _supabase
          .from('players')
          .select()
          .eq('room_id', room.id)
          .eq('device_id', _deviceId)
          .maybeSingle();

      if (playerRow == null) {
        await _clearSession();
        return false;
      }

      final playersRows = await _supabase
          .from('players')
          .select()
          .eq('room_id', room.id)
          .order('joined_at', ascending: true);

      _players = playersRows.map(Player.fromMap).toList();
      _currentPlayerId = playerRow['id'] as String;
      _currentRoom = room;
      _subscribeToRoomStreams(room.id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to restore active session: $e');
      return false;
    }
  }

  Future<void> refreshRoomOnResume() async {
    final room = _currentRoom;
    if (room == null) return;
    try {
      final roomRow = await _supabase
          .from('rooms')
          .select()
          .eq('id', room.id)
          .maybeSingle();

      if (roomRow != null) {
        final updatedRoom = GameRoom.fromMap(roomRow);
        final playersRows = await _supabase
            .from('players')
            .select()
            .eq('room_id', room.id)
            .order('joined_at', ascending: true);

        _currentRoom = updatedRoom;
        _players = playersRows.map(Player.fromMap).toList();

        if (updatedRoom.status == RoomStatus.voting) {
          _subscribeToVotesForRound(room.id, updatedRoom.currentRound);
        } else {
          _currentRoundVotes = {};
        }

        notifyListeners();
        unawaited(loadGlobalWords());
      }
    } catch (e) {
      debugPrint('Refresh on resume error: $e');
    }
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
