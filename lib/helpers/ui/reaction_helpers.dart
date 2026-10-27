import 'package:bluebubbles/database/models.dart' hide Entity;
import 'package:bluebubbles/helpers/types/constants.dart';
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';

class ReactionTypes {
  // ignore: non_constant_identifier_names
  static const String LOVE = "love";
  // ignore: non_constant_identifier_names
  static const String LIKE = "like";
  // ignore: non_constant_identifier_names
  static const String DISLIKE = "dislike";
  // ignore: non_constant_identifier_names
  static const String LAUGH = "laugh";
  // ignore: non_constant_identifier_names
  static const String EMPHASIZE = "emphasize";
  // ignore: non_constant_identifier_names
  static const String QUESTION = "question";

  static List<String> toList() {
    return [
      LOVE,
      LIKE,
      DISLIKE,
      LAUGH,
      EMPHASIZE,
      QUESTION,
    ];
  }

  static final Map<String, String> reactionToVerb = {
    LOVE: "loved",
    LIKE: "liked",
    DISLIKE: "disliked",
    LAUGH: "laughed at",
    EMPHASIZE: "emphasized",
    QUESTION: "questioned",
    "-$LOVE": "removed a heart from",
    "-$LIKE": "removed a like from",
    "-$DISLIKE": "removed a dislike from",
    "-$LAUGH": "removed a laugh from",
    "-$EMPHASIZE": "removed an exclamation from",
    "-$QUESTION": "removed a question mark from",
  };

  static final Map<String, String> reactionToEmoji = {
    LOVE: "❤️",
    LIKE: "👍",
    DISLIKE: "👎",
    LAUGH: "😂",
    EMPHASIZE: "❗",
    QUESTION: "❓",
  };

  static final Map<String, String> emojiToReaction = {
    "❤️": LOVE,
    "👍": LIKE,
    "👎": DISLIKE,
    "😂": LAUGH,
    "❗": EMPHASIZE,
    "❓": QUESTION,
  };

  /// Tapback row entries. On Sequoia my current custom emoji sits before "+",
  /// like iOS, so tapping it again removes it, followed by up to two recently
  /// used emoji that aren't already in the row.
  static List<String> pickerTypes(
      {required bool allowCustomEmoji, String? selfReaction, List<String> recentEmojis = const []}) {
    final custom = allowCustomEmoji && selfReaction != null && !toList().contains(selfReaction) &&
        checkReactionType(selfReaction) && !selfReaction.startsWith("-");
    final shown = {...toList(), ...reactionToEmoji.values, if (custom) selfReaction};
    final recents = allowCustomEmoji
        ? recentEmojis.where((e) => checkReactionType(e) && !e.startsWith("-") && shown.add(e)).take(2)
        : const <String>[];
    return [...toList(), if (custom) selfReaction, ...recents, if (allowCustomEmoji) "+"];
  }

  /// Whether the Tapback row wraps onto a second line. On Sequoia it stays one
  /// row that scrolls sideways, like iOS.
  static bool pickerWrapsToTwoRows(
      {required bool allowCustomEmoji, required double contentWidth, required double availableWidth}) {
    return !allowCustomEmoji && contentWidth > availableWidth;
  }

  static bool checkReactionType(String? type) {
    if (type == null || type.isEmpty) return false;
    final clean = type.startsWith("-") ? type.substring(1) : type;
    if (clean.isEmpty) return false;
    if (toList().contains(clean)) return true;
    return clean.characters.length == 1 && emojiRegex.hasMatch(clean);
  }

  static String emojiForReaction(String? type) {
    if (type == null) return "X";
    String clean = type.replaceAll("-", "");
    if (reactionToEmoji.containsKey(clean)) return reactionToEmoji[clean]!;
    if (checkReactionType(clean)) return clean;
    return "X";
  }

  static String verbForReaction(String? type) {
    if (type == null) return "reacted to";
    if (reactionToVerb.containsKey(type)) return reactionToVerb[type]!;
    bool isRemoval = type.startsWith("-");
    String emoji = type.replaceAll("-", "");
    return isRemoval ? "removed $emoji from" : "reacted with $emoji to";
  }
}

List<Message> getUniqueReactionMessages(List<Message> messages) {
  List<int> handleCache = [];
  List<Message> output = [];
  // Sort the messages, putting the latest at the top
  final ids = messages.map((e) => e.guid).toSet();
  messages.retainWhere((element) => ids.remove(element.guid));
  messages.sort(Message.sort);
  // Iterate over the messages and insert the latest reaction for each user
  for (Message msg in messages) {
    int cache = msg.isFromMe! ? 0 : msg.handleId ?? 0;
    if (!handleCache.contains(cache) && !kIsWeb) {
      handleCache.add(cache);
      // Only add the reaction if it's not a "negative"
      if (!msg.associatedMessageType!.startsWith("-")) {
        output.add(msg);
      }
    } else if (kIsWeb && !msg.associatedMessageType!.startsWith("-")) {
      output.add(msg);
    }
  }

  return output;
}
