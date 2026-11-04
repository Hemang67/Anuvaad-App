import 'package:anuvaad/app/router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const cases = [
    // (bootstrapped, onboarded, location, expected redirect)
    (false, false, Routes.home, Routes.splash),
    (false, true, Routes.splash, null),
    (true, true, Routes.splash, Routes.home),
    (true, false, Routes.splash, Routes.onboarding),
    (true, false, Routes.languages, Routes.onboarding),
    (true, false, Routes.onboarding, null),
    (true, true, Routes.onboarding, Routes.home),
    (true, true, Routes.languages, null),
    (true, true, Routes.releaseNotes, null),
  ];

  for (final (bootstrapped, onboarded, location, expected) in cases) {
    test('bootstrapped=$bootstrapped onboarded=$onboarded at $location -> $expected', () {
      expect(appRedirect(bootstrapped: bootstrapped, onboardingComplete: onboarded, location: location), expected);
    });
  }
}
