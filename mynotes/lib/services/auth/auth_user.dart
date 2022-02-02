import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
//da pra usar o 'as' para rename

//immutable diz q a classe, e todas as que herdam ela serão imutaveis depois de inicializadas.
@immutable
class AuthUser {
  final bool isEmailVerified;
  const AuthUser({required this.isEmailVerified});

  factory AuthUser.fromFirebase(User user) =>
      AuthUser(isEmailVerified: user.emailVerified);
}
