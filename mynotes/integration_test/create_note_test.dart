import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mynotes/main.dart' as app;
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/notes/create_update_notes_view.dart';
import 'package:mynotes/views/notes/notes_view.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'in this test it should login correctly, create a new note, delete the new note and logout',
    (tester) async {
      app.main();
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('emailTextField')),
        'andrei.morais@outlook.com',
      );
      await tester.enterText(
        find.byKey(const Key('passwordTextField')),
        'andrei12345',
      );
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();
      expect(find.byType(NotesView), findsOneWidget);

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      expect(find.byType(CreateUpdateNoteView), findsOneWidget);
      expect(find.byType(NotesView), findsNothing);

      await tester.enterText(
        find.byKey(const Key('create_update_textfield')),
        'New Note',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(NotesView), findsOneWidget);
      expect(find.byType(CreateUpdateNoteView), findsNothing);
      expect(find.text('New Note'), findsOneWidget);

      await tester.tap(find.text('New Note'));
      await tester.pumpAndSettle();
      expect(find.text('New Note'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('Sim')));
      await tester.pumpAndSettle();
      expect(find.text('New Note'), findsNothing);

      await tester.tap(find.byKey(const Key('menu_button')));
      await tester.pumpAndSettle();
      expect(find.text('Sair'), findsOneWidget);
      await tester.tap(find.byKey(const Key('logout_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('Sair')));
      await tester.pumpAndSettle();
      expect(find.byType(LoginView), findsOneWidget);
      await tester.pumpAndSettle();
    },
  );
}
