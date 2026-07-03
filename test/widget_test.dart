import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formai/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('FORMAI login screen renders without seeded credentials', (
    tester,
  ) async {
    await pumpFormai(tester);

    expect(find.text('FORMAI'), findsOneWidget);
    expect(find.text('Train Smarter'), findsOneWidget);
    expect(find.text('SIGN IN'), findsOneWidget);
    expect(find.text('START TRAINING'), findsNothing);
  });

  testWidgets('sign up creates an account and enters the app', (tester) async {
    await pumpFormai(tester);

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

  testWidgets('saved account can sign out and sign back in', (tester) async {
    await pumpFormai(tester);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Ava Coach');
    await tester.enterText(find.byType(TextField).at(1), 'ava@formai.app');
    await tester.enterText(find.byType(TextField).at(2), 'strongform');
    await tester.enterText(find.byType(TextField).at(3), 'strongform');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('PROFILE').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('SIGN OUT'));
    await tester.tap(find.text('SIGN OUT'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'ava@formai.app');
    await tester.enterText(find.byType(TextField).at(1), 'strongform');
    await tester.tap(find.text('SIGN IN'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR TRAINING'), findsOneWidget);
    expect(find.text('WELCOME, AVA'), findsOneWidget);
  });

  testWidgets('AI plan builder saves user workouts', (tester) async {
    await pumpFormai(tester);

    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Ava Coach');
    await tester.enterText(find.byType(TextField).at(1), 'ava@formai.app');
    await tester.enterText(find.byType(TextField).at(2), 'strongform');
    await tester.enterText(find.byType(TextField).at(3), 'strongform');
    await tester.tap(find.text('CREATE ACCOUNT'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('WORKOUTS').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('GENERATE AI PLAN'));
    await tester.pumpAndSettle();

    expect(find.text('PLAN CALENDAR'), findsOneWidget);
    expect(find.text("Today's Workout"), findsOneWidget);
    expect(find.textContaining('Plan saved with'), findsOneWidget);
    expect(find.text('MOVEMENT LIBRARY'), findsOneWidget);
  });
}

Future<void> pumpFormai(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(430, 1000));
  addTearDown(() async => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const FormaiApp());
  await tester.pumpAndSettle();
}
