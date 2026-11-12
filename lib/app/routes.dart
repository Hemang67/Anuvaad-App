abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const languages = '/languages';
  static const settings = '/settings';
  static const releaseNotes = '/settings/release-notes';
  static const conversation = '/conversation';
  static const audioDevices = '/audio-devices';
  static const history = '/history';
  static const voices = '/voices';
  static const privacy = '/privacy';
  static const latency = '/latency';
  static const meeting = '/meeting';

  /// The conversation screen in meeting mode; [language] null keeps the usual language rules.
  static String meetingConversation(String? language) =>
      Uri(path: conversation, queryParameters: {'mode': 'meeting', 'language': ?language}).toString();
  static String historyDetail(String id) => '/history/$id';
}
