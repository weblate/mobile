import 'package:eventual/eventual.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/i18n.dart';

class LanguageSelect extends StatelessWidget {
  @override
  Widget build(ctx) {
    return Scaffold(
      appBar: TopNavigation(
        title: getText(ctx, "title.language"),
      ),
      body: Builder(
          builder: (BuildContext context) => ListView(
                children: <Widget>[
                  // Section(text: getText(context, "main.availableLanguages")),
                  bulidLanguageItem(context, "English", "en"),
                  bulidLanguageItem(context, "French", "fr"),
                  bulidLanguageItem(context, "Español", "es"),
                  // bulidLanguageItem(context, "Portugues", "pt"),
                  bulidLanguageItem(context, "Català", "ca"),
                  bulidLanguageItem(context, "Norsk", "nb"),
                  // bulidLanguageItem(context, "Esperanto", "eo"),
                ],
              )),
    );
  }

  Widget bulidLanguageItem(
      BuildContext context, String langName, String langCode) {
    return EventualBuilder(
        notifier: Globals.appState.locale,
        builder: (context, notifiers, widget) {
          final currentLanguageCode =
              Globals.appState.locale.value?.languageCode ?? DEFAULT_LANGUAGE;
          return ListItem(
              mainText: langName,
              rightIcon: currentLanguageCode == langCode
                  ? FeatherIcons.check
                  : FeatherIcons.globe,
              onTap: () {
                Globals.appState
                    .selectLocale(Locale(langCode))
                    .then((_) => Navigator.of(context).pop(true));
              });
        });
  }
}
