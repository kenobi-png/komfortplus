import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthServices {
  // google вход

  signInWithGoogle() async {
    // интерактивная авторизация
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

    // получение данных авторизации из запроса
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;

    // создание новых учетных данных для пользователя
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    // использование учетных данных для входа в систему
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
