import 'package:dvote/dvote.dart';
import 'package:dvote_crypto/dvote_crypto.dart';
import 'package:dvote_common/widgets/summary.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:dvote_common/widgets/baseButton.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:vocdoni/view-modals/pin-prompt-modal.dart';

enum Steps { READY, AUTHORIZE_ACTION, CONFIRM_TOKEN, DONE }

class RegisterValidationPage extends StatefulWidget {
  final String entityId;
  final String entityName;
  final String backendUri;
  final String backendPublicKey;
  final String validationToken;

  RegisterValidationPage(
      {@required this.entityId,
      @required this.entityName,
      @required this.backendUri,
      this.backendPublicKey,
      @required this.validationToken});

  @override
  _RegisterValidationPageState createState() => _RegisterValidationPageState();
}

class _RegisterValidationPageState extends State<RegisterValidationPage> {
  Steps _currentStep;

  @override
  void initState() {
    super.initState();

    Globals.analytics.trackPage("RegisterValidationPage");

    _currentStep = Steps.READY;
  }

  // STEP 1
  void stepConfirmToken(BuildContext context) async {
    final currentAccount = Globals.appState.currentAccount;
    if (currentAccount == null) throw Exception("Internal error");

    setState(() => _currentStep = Steps.AUTHORIZE_ACTION);

    var patternLockKey = await Navigator.push(
        context,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PinPromptModal(currentAccount)));

    if (!mounted)
      return;
    else if (patternLockKey == null) {
      setState(() => _currentStep = Steps.READY);
      return;
    } else if (patternLockKey is InvalidPatternError) {
      setState(() => _currentStep = Steps.READY);
      showMessage(getText(context, "main.thePinYouEnteredIsNotValid"),
          context: context, purpose: Purpose.DANGER);
    } else {
      stepSendRequest(context, patternLockKey);
    }
  }

  // STEP 2
  void stepSendRequest(BuildContext context, String patternLockKey) async {
    final currentAccount = Globals.appState.currentAccount;
    setState(() => _currentStep = Steps.CONFIRM_TOKEN);

    try {
      // PREPARE THE REQUEST
      final mnemonic = await Symmetric.decryptStringAsync(
          currentAccount.identity.value.keys[0].encryptedMnemonic,
          patternLockKey);

      if (!mounted) return;

      // Derive per-entity key
      final wallet = EthereumWallet.fromMnemonic(mnemonic,
          entityAddressHash: widget.entityId);

      final dvoteGw =
          DVoteGateway(widget.backendUri, publicKey: widget.backendPublicKey);

      // Already registered?
      final privateKey = await wallet.privateKeyAsync;
      final status =
          await registrationStatus(widget.entityId, dvoteGw, privateKey);
      if (status["registered"] == true) {
        showMessage(getText(context, "main.youAreAlreadyRegistered"),
            purpose: Purpose.HIGHLIGHT, context: context);

        setState(() => _currentStep = Steps.DONE);
        await Future.delayed(Duration(seconds: 2));
        Navigator.of(context).pop();
        return;
      }

      // API CALL
      await validateRegistrationToken(
          widget.entityId, widget.validationToken, dvoteGw, privateKey);

      if (!mounted) return;

      setState(() => _currentStep = Steps.DONE);

      showMessage(getText(context, "main.yourRegistrationHasBeenConfirmed"),
          context: context, purpose: Purpose.GOOD);
      // final notify = await showPrompt(
      //     getText(context,
      //             "main.wouldYouLikeToReceivePersonalNotificationsFromThisEntity") +
      //         " (" +
      //         getText(context, "main.recommended").toLowerCase() +
      //         ")",
      //     context: context,
      //     title: getText(context, "action.enableEntityNotifications"),
      //     okButton: getText(context, "main.yes"),
      //     cancelButton: getText(context, "main.no"));
      // if (notify) {
      //   Notifications.getPushToken();
      // }
    } catch (error) {
      if (!mounted) return;
      setState(() => _currentStep = Steps.READY);

      // Already registered?
      if (error.toString().contains("duplicate user") ||
          error.toString().contains("already registered")) {
        showMessage(getText(context, "main.youAreAlreadyRegistered"),
            purpose: Purpose.HIGHLIGHT, context: context);

        setState(() => _currentStep = Steps.DONE);
        await Future.delayed(Duration(seconds: 2));
        Navigator.of(context).pop();
      } else {
        showMessage(
            getText(context, "error.theRegistrationCouldNotBeCompleted"),
            purpose: Purpose.DANGER,
            context: context);
      }
    }
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      appBar: TopNavigation(title: getText(context, "main.registration")),
      body: SafeArea(
        child: Builder(
          builder: (BuildContext context) => Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 350),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Spacer(),
                  Section(
                    text: widget.entityName,
                    withDectoration: true,
                  ),
                  Summary(
                      maxLines: 10,
                      text: getText(context,
                          "main.youAreAboutToValidateYourDigitalIdentityDoYouWantToContinue")),
                  buildStep(
                      getText(context, "main.authorizing"),
                      getText(context, "main.authorized"),
                      Steps.AUTHORIZE_ACTION),
                  buildStep(getText(context, "main.confirming"),
                      getText(context, "main.confirmed"), Steps.CONFIRM_TOKEN),
                  Spacer(),
                  _currentStep != Steps.READY
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.all(paddingPage),
                          child: BaseButton(
                              text: getText(context, "main.confirm"),
                              isSmall: false,
                              style: BaseButtonStyle.FILLED,
                              purpose: Purpose.HIGHLIGHT,
                              onTap: () => stepConfirmToken(context)),
                        ),
                  _currentStep != Steps.DONE
                      ? Container()
                      : Padding(
                          padding: EdgeInsets.all(paddingPage),
                          child: BaseButton(
                              text: getText(context, "main.close"),
                              isSmall: false,
                              style: BaseButtonStyle.FILLED,
                              purpose: Purpose.HIGHLIGHT,
                              onTap: () => Navigator.of(context).pop()),
                        )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildStep(String doingText, String doneText, Steps stepIndex) {
    String text = doingText;

    if (_currentStep == stepIndex)
      text = doingText;
    else if (_currentStep.index > stepIndex.index) text = doneText;

    return ListItem(
      mainText: text,
      rightIcon:
          _currentStep.index > stepIndex.index ? FeatherIcons.check : null,
      isSpinning: _currentStep == stepIndex,
      rightTextPurpose: Purpose.GOOD,
      isBold: _currentStep == stepIndex,
      disabled: _currentStep.index < stepIndex.index,
    );
  }
}
