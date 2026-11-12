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
  static String historyDetail(String id) => '/history/$id';
}
