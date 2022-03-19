import 'package:firebase_auth/firebase_auth.dart' show User;
import 'package:flutter/foundation.dart';
//da pra usar o 'as' para rename

//immutable diz q a classe, e todas as que herdam ela serão imutaveis depois de inicializadas.
@immutable
class AuthUser {
  final String id;
  //como nao tem autenticação por google ou facebook nos assumimos que o usuário sempre vai ter um email, por isso ele passou a ser "nao nullable"
  final String email;
  final bool isEmailVerified;
  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
  });

  factory AuthUser.fromFirebase(User user) => AuthUser(
        id: user.uid,
        email: user.email!,
        isEmailVerified: user.emailVerified,
      );
}
