import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_style/app/app.dart';

void main() {
  testWidgets('app builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const StitchStyleApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
