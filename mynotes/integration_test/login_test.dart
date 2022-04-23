import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mynotes/main.dart' as importedApp;
import 'package:mynotes/views/notes/notes_view.dart';

void main() {
  group('LoginTest', () {
    IntegrationTestWidgetsFlutterBinding.ensureInitialized();

    testWidgets(
      'in this test it should try to login with a wrong password and it will pop a dialog in the screen',
      (tester) async {
        importedApp.main();

        await tester.pumpAndSettle();
        final _emailtxt = find.byKey(const Key('emailTextField'));
        final _passwordtxt = find.byKey(const Key('passwordTextField'));
        final _loginBtn = find.byKey(const Key('loginButton'));

        await tester.enterText(_emailtxt, 'andrei.morais@outlook.com');
        await tester.enterText(_passwordtxt, '123456789'); //wrong password
        await tester.tap(_loginBtn);

        await tester.pumpAndSettle();

        expect(find.byType(AlertDialog), findsOneWidget);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('OK')));
        await tester.pumpAndSettle();
      },
    );

  });
}
