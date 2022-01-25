import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/views/login_view.dart';
import 'package:mynotes/views/register_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //isso serve para inicializar o firebase antes dos widgets
  //ler "docs.flutter.dev/resourses/architectural-overview#architectural-layers"
  runApp(
    MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(),
      routes: {
        '/login/': (context) => const LoginView(),
        '/register/': (context) => const RegisterView(),
      },
    ),
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          //esse switch eh para apresentar um loading caso demore para iniciar o firebase
          case ConnectionState.done:
            // final user = FirebaseAuth.instance.currentUser;
            // print(user);
            // if (user?.emailVerified ?? false) {
            // } else {
            //   //nao é boa ideia usar push dentro de um futureBuilder, concertaremos.
            //   // Navigator.of(context).push(
            //   //   MaterialPageRoute(
            //   //     builder: (context) => const VerifyEmailView(),
            //   //   ),
            //   // );
            //   return const VerifyEmailView();
            //   //ao inves de retornar a rota, retornamos apenas o conteudo da pagina
            // }

            // return const Text('Done');
            return const LoginView();
          default:
            return const CircularProgressIndicator();
        }
      },
    );
  }
}

