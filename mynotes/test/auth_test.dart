import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:test/test.dart';

class MockAuthUser extends Mock implements AuthUser {}

void main() {
  //para rodar os testes no terminal: flutter test "diretorio"(exemplo: flutter teste test/auth_test.dat)
  group('Mock Authentication', () {
    final provider = MockAuthProvider();
    test('should not be initializedto begin with', () {
      expect(provider.isInitialized, false);
    });

    test('Cannot log out if not initialized', () {
      expect(provider.logout(),
          throwsA(const TypeMatcher<NoteInitializedException>())
          //a funçao throwsA espera um exception
          );
    });

    test('Should be able to be initialized', () async {
      await provider.initialize();
      expect(provider.isInitialized, true);
    });

    test('User should be null after initialization', () {
      expect(provider.currentUser, null);
    });

    test(
      'should be able to initialize in less than 2 seconds',
      () async {
        await provider.initialize();
        expect(provider.isInitialized, true);
      },
      timeout: const Timeout(Duration(seconds: 2)),
      //timeout diz que esse teste deve falhar se levar mais do que 2 segundos para executar a funçao,  serve para testar requisiçoes de API
    );

    test('Create user should delegate to login function', () async {
      final badEmailUser = provider.createUser(
        email: 'foo@bar.com',
        password: 'anypassword',
      );
      expect(
        badEmailUser,
        throwsA(const TypeMatcher<UserNotFoundAuthException>()),
      );

      final badPasswordUser = provider.createUser(
        email: 'someone@bar.com',
        password: 'foobar',
      );
      expect(
        badPasswordUser,
        throwsA(const TypeMatcher<WrongPasswordAuthException>()),
      );

      final user = await provider.createUser(
        email: 'foo',
        password: 'bar',
      );
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('Logged in user should be able to be verified', () {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    });

    test('Should be able to log out and log in again', () async {
      await provider.logout();
      await provider.logIn(
        email: 'user',
        password: 'password',
      );
      final user = provider.currentUser;
      expect(user, isNotNull);
    });

    final bloc = AuthBloc(provider);
    const user = AuthUser(
      id: 'My_id',
      isEmailVerified: true,
      email: 'teste@teste.com',
    );

    blocTest<AuthBloc, AuthState>(
      'bloc test',
      setUp: () async {
        await provider.initialize();
        // when<Future<AuthUser>>(() =>
        //         provider.logIn(email: 'teste@teste.com', password: '12345'))
        //     .thenAnswer((realInvocation) => Future.value(user));
      },
      build: () {
        return bloc;
      },
      act: (bloc) => [
        bloc.add(const AuthEventInitialize()),
        bloc.add(const AuthEventLogIn('teste@teste.com', '123456')),
      ],
      expect: () => [
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while i log you in',
        ),
        const AuthStateLoggedOut(
          exception: null,
          isLoading: false,
        ),
        const AuthStateLoggedIn(user: user, isLoading: false)
      ],
    );
  });
}

class NoteInitializedException implements Exception {}

class MockAuthProvider extends Mock implements AuthProvider {
  //esse mock serve para 'simular' a funçao do firebase
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser({
    required String email,
    required String password,
  }) async {
    //verifica se esta inicializado, joga um fake delay, e chama o login fake
    if (!isInitialized) throw NoteInitializedException();
    await Future.delayed(const Duration(seconds: 1));
    return logIn(
      email: email,
      password: password,
    );
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    //aqui está apenas simulando uma inicialização
    await Future.delayed(const Duration(seconds: 1));
    _isInitialized = true;
  }

  @override
  Future<AuthUser> logIn({
    required String email,
    required String password,
  }) {
    if (!isInitialized) throw NoteInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(
      id: 'My_id',
      isEmailVerified: true,
      email: 'teste@teste.com',
    );
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> logout() async {
    if (!isInitialized) throw NoteInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<void> sendEmailVerification() async {
    if (!isInitialized) throw NoteInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();
    const newUser = AuthUser(
      id: 'My_id',
      isEmailVerified: true,
      email: 'foo@bar.com',
    );
    _user = newUser;
  }

  @override
  Future<void> sendPasswordReset({required String toEmail}) {
    throw UnimplementedError();
  }
}
