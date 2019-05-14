import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'util/singletons.dart';
import 'lang/index.dart';

import "views/welcome.dart";
import "views/welcome-identity.dart";
import "views/welcome-identity-create.dart";
import "views/welcome-identity-recover.dart";
import "views/home.dart";

void main() async {
  // RESTORE DATA
  await appStateBloc.restore();
  await identitiesBloc.restore();
  await electionsBloc.restore();

  // DETERMINE THE FIRST SCREEN
  Widget home;
  if (identitiesBloc?.current?.length > 0) {
    home = HomeScreen();
  } else {
    home = WelcomeScreen();
  }

  // RUN THE APP
  runApp(MaterialApp(
    title: 'Vocdoni',
    localizationsDelegates: [
      LangDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate
    ],
    supportedLocales: [Locale("en"), Locale("fr"), Locale("ca"), Locale("es")],
    onGenerateTitle: (BuildContext context) => Lang.of(context).title,
    home: home,
    routes: {
      // NO IDENTITIES YET
      "/welcome": (context) => WelcomeScreen(),
      "/welcome/identity": (context) => WelcomeIdentityScreen(),
      "/welcome/identity/create": (context) => WelcomeIdentityCreateScreen(),
      "/welcome/identity/recover": (context) => WelcomeIdentityRecoverScreen(),

      // IDENTITY/IES AVAILABLE
      "/home": (context) => HomeScreen()
    },
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
  ));
}