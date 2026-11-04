import 'package:anuvaad/shared/utils/join_list.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('joinList formats one, two and three items', () {
    expect(joinList(['English'], lastSeparator: ' or '), 'English');
    expect(joinList(['English', 'Hindi'], lastSeparator: ' or '), 'English or Hindi');
    expect(joinList(['English', 'Hindi', 'Gujarati'], lastSeparator: ' or '), 'English, Hindi or Gujarati');
    expect(joinList(['English', 'Hindi', 'Gujarati'], lastSeparator: ' and '), 'English, Hindi and Gujarati');
  });

  test('joinList of nothing is empty', () => expect(joinList([], lastSeparator: ' or '), ''));
}
