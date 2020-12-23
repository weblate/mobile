import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/navButton.dart';
import 'package:dvote_common/widgets/text-input.dart' as TextInput;
import 'package:flutter/services.dart';
import 'package:vocdoni/app-config.dart';
import 'package:vocdoni/lib/extensions.dart';
import 'package:flutter/material.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/views/onboarding/onboarding-features.dart';

class OnboardingBackupInput extends StatefulWidget {
  @override
  _OnboardingBackupInputState createState() => _OnboardingBackupInputState();
}

class _OnboardingBackupInputState extends State<OnboardingBackupInput> {
  int firstQuestionIndex;
  int secondQuestionIndex;
  String firstQuestionAnswer;
  String secondQuestionAnswer;

  @override
  void initState() {
    firstQuestionIndex = 0;
    secondQuestionIndex = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Builder(
          builder: (context) => Column(
            children: [
              Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        getText(context, "main.backup"),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: fontWeightLight,
                        ),
                      ).withPadding(spaceCard))
                  .withTopPadding(spaceCard),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  getText(context,
                      "main.ifYouLoseYourPhoneOrUninstallTheAppYouWontBeAbleToVoteLetsCreateASecureBackup"),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: fontWeightLight,
                  ),
                ).withHPadding(spaceCard),
              ).withBottomPadding(spaceCard),
              _buildBackupQuestion(firstQuestionIndex, 1, context),
              _buildBackupQuestion(secondQuestionIndex, 2, context),
              TextInput.TextInput(
                hintText: getText(context, "main.yourEmail").toLowerCase(),
                textCapitalization: TextCapitalization.none,
                inputFormatter: FilteringTextInputFormatter.allow(""),
                onChanged: (name) {},
              ).withHPadding(paddingPage),
              Spacer(),
              Row(
                children: [
                  NavButton(
                    style: NavButtonStyle.BASIC,
                    text: getText(context, "action.illDoItLater"),
                    onTap: () => Navigator.pushNamedAndRemoveUntil(
                        context, "/home", (route) => false),
                  ),
                  Spacer(),
                  NavButton(
                    isDisabled: firstQuestionIndex == 0 ||
                        secondQuestionIndex == 0 ||
                        firstQuestionAnswer?.length == 0 ||
                        secondQuestionAnswer?.length == 0,
                    style: NavButtonStyle.NEXT,
                    text: getText(context, "action.verifyBackup"),
                    onTap: () => {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OnboardingFeaturesPage()),
                      )
                    },
                  ),
                ],
              ).withPadding(spaceCard),
            ],
          ),
        ),
      ),
    );
  }

  _buildBackupQuestion(int questionIndex, int position, BuildContext ctx) {
    return Column(
      children: [
        ListItem(
          mainText: position.toString() +
              ". " +
              getText(
                  ctx, "main." + AppConfig.backupQuestionTexts[questionIndex]),
        ),
        TextInput.TextInput(
          hintText: getText(context, "main.answer").toLowerCase(),
          textCapitalization: TextCapitalization.sentences,
          inputFormatter:
              questionIndex == 0 ? FilteringTextInputFormatter.allow("") : null,
          onChanged: (name) {},
        ).withHPadding(paddingPage),
      ],
    ).withHPadding(8);
  }
}
