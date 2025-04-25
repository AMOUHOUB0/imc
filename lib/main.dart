import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'bmi_history.dart';
import 'home.dart';
import 'firebase_options.dart';
import 'language_provider.dart';
import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'language_switcher.dart';
import 'ImcChartpage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseUIAuth.configureProviders([EmailAuthProvider()]);

    runApp(
      ChangeNotifierProvider(
        create: (_) => LanguageProvider(),
        child: MyApp(),
      ),
    );
  } catch (err) {
    print("Firebase initialization failed: $err");
  }
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Home(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => SignInScreen(
          headerBuilder: (context, constraints, _) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: LanguageSwitcher(),
              ),
            );
          },
          actions: [
            ForgotPasswordAction((context, email) {
              context.push('/forgot-password', extra: email);
            }),
            AuthStateChangeAction((context, state) {
              if (state is SignedIn || state is UserCreated) {
                context.pushReplacement('/');
              }
            }),
          ],
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) {
          final email = state.extra as String?;
          return ForgotPasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => BMIHistoryScreen(),
      ),
      GoRoute(
        path: '/graphique',
        builder: (context, state) => ImcChartPage(),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp.router(
          routerConfig: _router,
          theme: ThemeData(primarySwatch: Colors.green),
          debugShowCheckedModeBanner: false,

          // Configuration des localisations
          locale: languageProvider.locale,
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            // Pour la traduction de l'interface FirebaseUI Auth
            FirebaseUILocalizations.delegate,
          ],
          supportedLocales: [
            Locale('en'), // Anglais
            Locale('fr'), // Français
            Locale('ar'), // Arabe
            Locale('es'), // Espagnol
          ],

          // Pour gérer correctement le RTL (pour l'arabe)
          builder: (context, child) {
            // Créer un TextDirection en fonction de la langue
            TextDirection textDirection =
                languageProvider.locale.languageCode == 'ar'
                    ? TextDirection.rtl
                    : TextDirection.ltr;

            return Directionality(
              textDirection: textDirection,
              child: child!,
            );
          },
        );
      },
    );
  }
}
