import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/storage/session_manager.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_info.dart';
import '../widgets/button_login.dart';
import '../widgets/my_button.dart';

import 'main_navigation_page.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  String versionApp = '';
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String uid = "";
  String username = "";
  String email = "";
  String photo = "";

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _initializeGoogleSignIn();
  }

  Future<void> _initializeGoogleSignIn() async {

    await _googleSignIn.initialize(

      serverClientId:
      dotenv.env['CLIENT_ID_FB'],
    );
  }

  Future<void> _loadVersion() async {
    final version = await AppInfo.getVersion();

    if (!mounted) return;

    setState(() {
      versionApp = "v $version";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
        body: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: Colors.transparent,
          ),
      child: Stack(
        children: <Widget>[

          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 180),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 10, right: 0, left: 0),
                    child: Image.asset(
                      "assets/logo/ic_logo_vertical.png",
                      width: 300,
                      height: 300,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey.withValues(alpha: 0.3),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            size: 80,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 50, right: 30, left: 30),
                    child: Text(
                      "Lorem Ipsum is simply dummy text of the printing and typesetting industry.",
                      style: AppTextStyle.regular16.copyWith(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Center(
            child: Container(
              margin: const EdgeInsets.only(
                top: 620,
                bottom: 100,
                right: 50,
                left: 50,
              ),
              width: 500,
              height: 55,

              child: MyButton(
                  text: "Mulai",
                  backgroundColor: AppColors.primary,
                  textColor: Colors.white,
                  onPressed: () async {
                    if (kDebugMode) {
                      print("BUTTON DIKLIK");
                    }
                    await _saveFirstTimePreference();
                    _showLogin(context);
                  }
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Future<void> toLogin(BuildContext context) async {
    await _saveFirstTimePreference();
    if (!context.mounted) return;
    // Navigator.pushAndRemoveUntil(
    //   context,
    //   MaterialPageRoute(builder: (context) => LoginPage()),
    //       (route) => false,
    // );
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    try {

      final GoogleSignInAccount googleUser =
      await _googleSignIn.authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await _auth.signInWithCredential(
        credential,
      );


      final User? user = userCredential.user;
      debugPrint(
        'Login Success: ${userCredential.user?.email}',
      );
      debugPrint('UID  : ${user?.uid}');
      debugPrint('Nama : ${user?.displayName}');
      debugPrint('Email: ${user?.email}');
      debugPrint('Foto : ${user?.photoURL}');

      uid = '${userCredential.user?.uid}';
      username = '${userCredential.user?.displayName}';
      email = '${userCredential.user?.email}';
      photo = '${userCredential.user?.photoURL}';

      debugPrint('UID1  : $uid');
      debugPrint('Nama1 : $username');
      debugPrint('Email1: $email');
      debugPrint('Foto1 : $photo');

      await SessionManager.setDataUserLogin(
          userId: uid,
          userName: username,
          email: email,
          photoUrl: photo
      );

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const MainNavigationPage(),
        ),
            (route) => false,
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }

      debugPrint('Google Sign In Error: $e');


      if (e.toString().contains('canceled')) {
      }
    }
  }

  Future<void> signInWithApple(BuildContext context) async {
    try {

      final appleCredential =
      await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential =
      OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential =
      await _auth.signInWithCredential(
        oauthCredential,
      );

      final user = userCredential.user;

      final firstName =
          appleCredential.givenName ?? '';

      final lastName =
          appleCredential.familyName ?? '';

      final displayName =
      '$firstName $lastName'.trim();

      uid = user?.uid ?? '';

      username = displayName.isNotEmpty
          ? displayName
          : (user?.displayName ?? '');

      email = user?.email ??
          appleCredential.email ??
          '';

      photo = user?.photoURL ?? '';

      debugPrint('UID   : $uid');
      debugPrint('Nama  : $username');
      debugPrint('Email : $email');

      await SessionManager.setDataUserLogin(
        userId: uid,
        userName: username,
        email: email,
        photoUrl: photo,
      );

      if (!context.mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) =>
          const MainNavigationPage(),
        ),
            (_) => false,
      );

    } catch (e) {

      debugPrint(
        'Apple Sign In Error: $e',
      );

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).maybePop();
      }
    }
  }


  Future<void> _saveFirstTimePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isFirstTime', false);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving preference: $e');
      }
    }
  }

  void _showLogin(BuildContext parentContext) {
  showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primary,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                'Mulai login menggunakan Google',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20
                ),
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: SocialLoginButton(
                text: 'Masuk dengan Google',
                logo: Image.asset(
                  'assets/image/ic_google.png',
                  width: 40,
                  height: 40,
                ),
                  onPressed: () async {
                    Navigator.pop(bottomSheetContext);

                    await Future.delayed(
                      const Duration(milliseconds: 200),
                    );

                    await signInWithGoogle(parentContext);
                  }
              )
            ),
            const SizedBox(height: 20),

            // Container(
            //   margin: EdgeInsets.symmetric(horizontal: 20),
            //   child: SocialLoginButton(
            //     text: 'Masuk dengan Apple',
            //     logo: Image.asset(
            //       'assets/image/ic_apple.png',
            //       width: 40,
            //       height: 40,
            //     ),
            //       onPressed: () async {
            //         Navigator.pop(bottomSheetContext);
            //
            //         await Future.delayed(
            //           const Duration(milliseconds: 200),
            //         );
            //
            //         await signInWithApple(parentContext);
            //       }
            //   )
            // ),

            Container(
              margin: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Text(
                versionApp,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.normal,
                    color: Colors.white
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

}
