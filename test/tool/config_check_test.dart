import 'package:flutter_test/flutter_test.dart';

import '../../tool/release/config_check.dart';

void main() {
  test('accepts an https base URL', () {
    expect(apiBaseUrlProblem('https://anuvaad-web.vercel.app'), isNull);
  });

  test('rejects URLs the app would refuse at runtime', () {
    for (final bad in ['', 'http://anuvaad-web.vercel.app', 'anuvaad-web.vercel.app', 'https://', 'ftp://x.dev']) {
      expect(apiBaseUrlProblem(bad), isNotNull, reason: bad);
    }
  });
}
