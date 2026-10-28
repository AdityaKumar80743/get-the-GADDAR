import 'dart:math';

enum RoomStatus {
  lobby,
  roleReveal,
  discussion,
  voting,
  lastChance,
  roundResult,
  gameOver;

  static RoomStatus fromString(String value) {
    switch (value) {
      case 'role_reveal':
        return RoomStatus.roleReveal;
      case 'discussion':
        return RoomStatus.discussion;
      case 'voting':
        return RoomStatus.voting;
      case 'last_chance':
        return RoomStatus.lastChance;
      case 'round_result':
        return RoomStatus.roundResult;
      case 'game_over':
        return RoomStatus.gameOver;
      case 'lobby':
      default:
        return RoomStatus.lobby;
    }
  }

  String toDbString() {
    switch (this) {
      case RoomStatus.lobby:
        return 'lobby';
      case RoomStatus.roleReveal:
        return 'role_reveal';
      case RoomStatus.discussion:
        return 'discussion';
      case RoomStatus.voting:
        return 'voting';
      case RoomStatus.lastChance:
        return 'last_chance';
      case RoomStatus.roundResult:
        return 'round_result';
      case RoomStatus.gameOver:
        return 'game_over';
    }
  }
}

enum ClueRule {
  oneWord('one_word', 'Strictly 1 Word Spoken IRL'),
  twoWords('two_words', 'Max 2 Words Spoken IRL'),
  noGestures('no_gestures', '1 Word + Poker Face (No Gestures)'),
  rhymeOnly('rhyme_only', 'Spoken Clue Must Rhyme');

  final String dbValue;
  final String label;
  const ClueRule(this.dbValue, this.label);

  static ClueRule fromString(String value) {
    return ClueRule.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ClueRule.oneWord,
    );
  }
}

class GameRoom {
  final String id;
  final String roomCode;
  final String hostPlayerId;
  final RoomStatus status;
  final int currentRound;
  final int maxRounds;
  final int impostorCount;
  final int discussionTimerSec;
  final bool impostorGetsHint;
  final ClueRule clueRule;
  final List<String> selectedCategories;
  final String? secretWord;
  final String? secretHint;
  final String? secretCategory;
  final String? secretImageUrl;
  final String? caughtGaddarId;
  final String? caughtGaddarName;
  final String? lastChanceGuess;
  final String? winnerTeam;
  final String? winReason;
  final DateTime phaseStartedAt;

  const GameRoom({
    required this.id,
    required this.roomCode,
    required this.hostPlayerId,
    required this.status,
    required this.currentRound,
    required this.maxRounds,
    required this.impostorCount,
    required this.discussionTimerSec,
    required this.impostorGetsHint,
    required this.clueRule,
    required this.selectedCategories,
    this.secretWord,
    this.secretHint,
    this.secretCategory,
    this.secretImageUrl,
    this.caughtGaddarId,
    this.caughtGaddarName,
    this.lastChanceGuess,
    this.winnerTeam,
    this.winReason,
    required this.phaseStartedAt,
  });

  int gaddarSurvivalThreshold(int totalPlayers) {
    return max(1, (totalPlayers / 3).floor());
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      id: map['id'] as String,
      roomCode: map['room_code'] as String,
      hostPlayerId: map['host_player_id'] as String,
      status: RoomStatus.fromString(map['status'] as String? ?? 'lobby'),
      currentRound: (map['current_round'] as num?)?.toInt() ?? 1,
      maxRounds: (map['max_rounds'] as num?)?.toInt() ?? 4,
      impostorCount: (map['impostor_count'] as num?)?.toInt() ?? 1,
      discussionTimerSec: (map['discussion_timer_sec'] as num?)?.toInt() ?? 90,
      impostorGetsHint: map['impostor_gets_hint'] as bool? ?? true,
      clueRule: ClueRule.fromString(map['clue_rule'] as String? ?? 'one_word'),
      selectedCategories: List<String>.from(map['selected_categories'] ?? const [
        'Movies', 'Cricket', 'Anime', 'Celebrities', 'Indian Food', 'Gaming', 'Memes', 'Custom Words'
      ]),
      secretWord: map['secret_word'] as String?,
      secretHint: map['secret_hint'] as String?,
      secretCategory: map['secret_category'] as String?,
      secretImageUrl: map['secret_image_url'] as String?,
      caughtGaddarId: map['caught_gaddar_id'] as String?,
      caughtGaddarName: map['caught_gaddar_name'] as String?,
      lastChanceGuess: map['last_chance_guess'] as String?,
      winnerTeam: map['winner_team'] as String?,
      winReason: map['win_reason'] as String?,
      phaseStartedAt: map['phase_started_at'] != null
          ? DateTime.tryParse(map['phase_started_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class Player {
  final String id;
  final String roomId;
  final String deviceId;
  final String nickname;
  final int avatarIndex;
  final bool isHost;
  final String role;
  final bool isEliminated;
  final bool hasReady;
  final bool hasVotedCurrentRound;
  final int secretScore;
  final int correctGaddarVotes;
  final int roundsSurvivedAsGaddar;

  const Player({
    required this.id,
    required this.roomId,
    required this.deviceId,
    required this.nickname,
    required this.avatarIndex,
    required this.isHost,
    required this.role,
    required this.isEliminated,
    required this.hasReady,
    required this.hasVotedCurrentRound,
    required this.secretScore,
    required this.correctGaddarVotes,
    required this.roundsSurvivedAsGaddar,
  });

  bool get isGaddar => role == 'gaddar';

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      deviceId: map['device_id'] as String? ?? '',
      nickname: map['nickname'] as String,
      avatarIndex: (map['avatar_index'] as num?)?.toInt() ?? 0,
      isHost: map['is_host'] as bool? ?? false,
      role: map['role'] as String? ?? 'friend',
      isEliminated: map['is_eliminated'] as bool? ?? false,
      hasReady: map['has_ready'] as bool? ?? false,
      hasVotedCurrentRound: map['has_voted_current_round'] as bool? ?? false,
      secretScore: (map['secret_score'] as num?)?.toInt() ?? 0,
      correctGaddarVotes: (map['correct_gaddar_votes'] as num?)?.toInt() ?? 0,
      roundsSurvivedAsGaddar: (map['rounds_survived_as_gaddar'] as num?)?.toInt() ?? 0,
    );
  }
}

class CustomWordItem {
  final String id;
  final String roomId;
  final String word;
  final String hint;
  final String authorNickname;

  const CustomWordItem({
    required this.id,
    required this.roomId,
    required this.word,
    required this.hint,
    required this.authorNickname,
  });

  factory CustomWordItem.fromMap(Map<String, dynamic> map) {
    return CustomWordItem(
      id: map['id'] as String,
      roomId: map['room_id'] as String,
      word: map['word'] as String,
      hint: map['hint'] as String,
      authorNickname: map['author_nickname'] as String? ?? 'Player',
    );
  }
}
