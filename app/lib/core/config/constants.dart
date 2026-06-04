library circlestream.lib.core.config.constants;

class AppConstants {
  // API
  static const String baseUrl = 'http://192.168.1.9:8080/v1';

  // Image
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10MB
  static const int targetFileSizeBytes = 3 * 1024 * 1024; // 3MB

  // Circle
  static const int maxCircleMembers = 10;

  // Feed
  static const int feedPageSize = 20;

  // Emoji presets
  static const List<String> emojiPresets = [
    '❤️', '😂', '😮', '🔥', '👏', '😢', '🤩', '💀'
  ];

  // Token keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
}
