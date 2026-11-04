import 'package:anuvaad/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AnuvaadApp builds a MaterialApp.router titled Anuvaad', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AnuvaadApp()));
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).title, 'Anuvaad');
  });
}
