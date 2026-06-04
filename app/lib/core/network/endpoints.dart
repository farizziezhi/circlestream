library circlestream.core.network.endpoints;

class Endpoints {
  static const String register      = '/auth/register';
  static const String login         = '/auth/login';
  static const String refresh       = '/auth/refresh';
  static const String logout        = '/auth/logout';
  static const String ablyToken     = '/ably/token';

  static const String circles       = '/circles';
  static const String joinCircle    = '/circles/join';
  static String circleDetail(int id)   => '/circles/$id';
  static String circleMembers(int id)  => '/circles/$id/members';
  static String leaveCircle(int id)    => '/circles/$id/leave';
  static String inviteCodes(int id)    => '/circles/$id/invite-codes';

  static const String presignUpload = '/media/presign-upload';
  static const String finalizeUpload = '/media/finalize';

  static String circlePosts(int id)    => '/circles/$id/posts';
  static String postDetail(int id)     => '/posts/$id';
  static String postReactions(int id)  => '/posts/$id/reactions';
}
