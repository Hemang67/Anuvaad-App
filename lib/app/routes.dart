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
  static String historyDetail(String id) => '/history/$id';
}
