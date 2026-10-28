import 'dart:math';

class WordPair {
  final String word;
  final List<String> hints;
  final String category;
  final String? imageUrl;

  const WordPair({
    required this.word,
    required this.hints,
    required this.category,
    this.imageUrl,
  });

  /// Single hint convenience getter for backward compatibility
  String get hint => hints.isNotEmpty ? hints.first : '';

  /// Picks a random hint from the word's hint pool
  String pickRandomHint(Random random) {
    if (hints.isEmpty) return '';
    return hints[random.nextInt(hints.length)];
  }

  factory WordPair.fromMap(Map<String, dynamic> map) {
    List<String> parsedHints = [];
    if (map['hints'] is List) {
      parsedHints = (map['hints'] as List)
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (map['hint'] != null && map['hint'].toString().trim().isNotEmpty) {
      parsedHints = [map['hint'].toString().trim()];
    }

    return WordPair(
      word: map['word'] as String? ?? '',
      hints: parsedHints,
      category: map['category'] as String? ?? 'General',
      imageUrl: map['image_url'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'word': word,
      'hints': hints,
      'category': category,
      if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
    };
  }
}

class GaddarWordPacks {
  static const List<String> allCategories = [
    'Movies',
    'Cricket',
    'Anime',
    'Celebrities',
    'Indian Food',
    'Gaming',
    'Memes',
    'Custom Words',
  ];

  static const Map<String, List<Map<String, String>>> builtInPacks = {
    'Movies': [
      {'word': 'Sholay', 'hint': 'Classic Coin Toss & Gabbar'},
      {'word': '3 Idiots', 'hint': 'Engineering Hostel & All Is Well'},
      {'word': 'Bahubali', 'hint': 'Royal Waterfall & Katappa Betrayal'},
      {'word': 'Dangal', 'hint': 'Gold Medal Wrestling Mat'},
      {'word': 'Inception', 'hint': 'Spinning Top Inside a Dream'},
      {'word': 'Lagaan', 'hint': 'Village Tax Match Under the Sun'},
      {'word': 'Gangs of Wasseypur', 'hint': 'Coal Mafia Generational Revenge'},
      {'word': 'Zindagi Na Milegi Dobara', 'hint': 'Spain Skydiving Roadtrip'},
    ],
    'Cricket': [
      {'word': 'MS Dhoni', 'hint': 'Helicopter Finisher Behind Stumps'},
      {'word': 'Virat Kohli', 'hint': 'King of Run Chases & Cover Drive'},
      {'word': 'Yorker', 'hint': 'Toe-Crushing Fast Delivery'},
      {'word': 'IPL Auction', 'hint': 'Franchise Bidding Paddle War'},
      {'word': 'Wankhede Stadium', 'hint': 'Mumbai Sea Breeze & 2011 Six'},
      {'word': 'Super Over', 'hint': 'Six-Ball Tiebreaker Thriller'},
      {'word': 'Jasprit Bumrah', 'hint': 'Unorthodox Sling Action Spearhead'},
      {'word': 'Duckworth Lewis', 'hint': 'Rain-Adjusted Target Math'},
    ],
    'Anime': [
      {'word': 'Naruto Uzumaki', 'hint': 'Orange Ninja & Ramen Bowl'},
      {'word': 'Attack on Titan', 'hint': 'ODM Gear & Giant Wall Breakers'},
      {'word': 'Demon Slayer', 'hint': 'Breathing Styles & Checkered Haori'},
      {'word': 'Death Note', 'hint': 'Black Notebook & Shinigami Apples'},
      {'word': 'One Piece', 'hint': 'Straw Hat Pirate Grand Line'},
      {'word': 'Gojo Satoru', 'hint': 'Blindfolded Six Eyes Sorcerer'},
      {'word': 'Dragon Ball Z', 'hint': 'Golden Hair Saiyan Energy Wave'},
      {'word': 'Spy x Family', 'hint': 'Telepath Kid & Fake Marriage Mission'},
    ],
    'Celebrities': [
      {'word': 'Shah Rukh Khan', 'hint': 'Open Arms Signature Romance Pose'},
      {'word': 'Rajinikanth', 'hint': 'Sunglasses Flip & Thalaiva Style'},
      {'word': 'Diljit Dosanjh', 'hint': 'Coachella Turban & Punjabi Beats'},
      {'word': 'Neeraj Chopra', 'hint': 'Golden Javelin Olympic Throw'},
      {'word': 'Arijit Singh', 'hint': 'Soulful Heartbreak Concert Voice'},
      {'word': 'Amitabh Bachchan', 'hint': 'Baritone Quiz Host & Shahenshah'},
      {'word': 'Deepika Padukone', 'hint': 'Global Red Carpet & Padmaavat'},
      {'word': 'Allu Arjun', 'hint': 'Pushpa Shoulder Brush Swagger'},
    ],
    'Indian Food': [
      {'word': 'Pani Puri', 'hint': 'Crispy Hollow Sphere & Spicy Water'},
      {'word': 'Hyderabadi Biryani', 'hint': 'Slow-Cooked Dum Basmati Handi'},
      {'word': 'Masala Dosa', 'hint': 'Crispy Fermented Crepe & Sambhar'},
      {'word': 'Butter Chicken', 'hint': 'Creamy Orange Tandoori Gravy'},
      {'word': 'Vada Pav', 'hint': 'Mumbai Street Bun & Fried Chilli'},
      {'word': 'Chole Bhature', 'hint': 'Fluffy Fried Bread & Chickpea Curry'},
      {'word': 'Gulab Jamun', 'hint': 'Warm Cardamom Sugar Syrup Sphere'},
      {'word': 'Filter Kaapi', 'hint': 'Frothy Steel Davara Tumbler'},
    ],
    'Gaming': [
      {'word': 'BGMI Pochinki', 'hint': 'Hot-Drop Roof Parachute Chaos'},
      {'word': 'GTA Vice City', 'hint': 'Pink Neon Miami Scooter Mission'},
      {'word': 'Minecraft Creeper', 'hint': 'Green Pixel Hiss Before Boom'},
      {'word': 'Valorant Spike', 'hint': 'Tactical Site Plant & Defuse'},
      {'word': 'Clash of Clans', 'hint': 'Village Wall Upgrade & Clan War'},
      {'word': 'Ludo King', 'hint': 'Four-Color Dice Home Token Race'},
      {'word': 'Among Us', 'hint': 'Spaceship Vent Emergency Meeting'},
      {'word': 'Elden Ring', 'hint': 'Golden Erdtree & Brutal Boss Roll'},
    ],
    'Memes': [
      {'word': 'Bhupendra Jogi', 'hint': 'US Travel Question Loop'},
      {'word': 'Binod', 'hint': 'Single Name Comment Section Flood'},
      {'word': 'Moye Moye', 'hint': 'Melodramatic Sad Chorus Trend'},
      {'word': 'Panchayat Phulera', 'hint': 'Bottle Gourd Gift & Sachiv Ji'},
      {'word': 'Shark Tank Ashneer', 'hint': 'Blunt Pitch Roast & Doglapan'},
      {'word': 'Jethalal Trouble', 'hint': 'Gada Electronics Morning Chaos'},
      {'word': 'Mirzapur Munna', 'hint': 'King of the Carpet Throne'},
      {'word': 'Hera Pheri Baburao', 'hint': 'Star Garage Wrong Number Call'},
    ],
  };
}
