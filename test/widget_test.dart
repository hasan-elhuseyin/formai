import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formai/main.dart';

void main() {
  testWidgets('FORMAI login screen renders', (tester) async {
    await tester.pumpWidget(const FormaiApp());

    expect(find.text('FORMAI'), findsOneWidget);
    expect(find.text('Train Smarter'), findsOneWidget);
    expect(find.text('START TRAINING'), findsOneWidget);
  });

  testWidgets('default sign in opens the working app tabs', (tester) async {
    await tester.pumpWidget(const FormaiApp());

    await tester.tap(find.text('START TRAINING'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR TRAINING'), findsOneWidget);

    await tester.tap(find.text('WORKOUTS').last);
    await tester.pumpAndSettle();
    expect(
      find.text('CHOOSE AN EXERCISE FOR AI FORM ANALYSIS'),
      findsOneWidget,
    );

    await tester.tap(find.text('PROFILE').last);
    await tester.pumpAndSettle();
    expect(
      find.text('ACCOUNT, SESSION PREFERENCES, AND PROGRESS'),
      findsOneWidget,
    );
  });

  testWidgets('sign up creates an account and enters the app', (tester) async {
    await tester.pumpWidget(const FormaiApp());

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Ava Coach');
    await tester.enterText(find.byType(TextField).at(1), 'ava@formai.app');
    await tester.enterText(find.byType(TextField).at(2), 'strongform');
    await tester.enterText(find.byType(TextField).at(3), 'strongform');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR TRAINING'), findsOneWidget);
    expect(find.text('WELCOME, AVA'), findsOneWidget);
  });
}
