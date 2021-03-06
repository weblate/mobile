import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/data-models/account.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:dvote_common/widgets/section.dart';
import 'package:vocdoni/lib/errors.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/view-modals/pattern-prompt-modal.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'identity-create-page.dart';
import '../lib/globals.dart';

class IdentitySelectPage extends StatefulWidget {
  @override
  _IdentitySelectPageState createState() => _IdentitySelectPageState();
}

class _IdentitySelectPageState extends State<IdentitySelectPage> {
  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("IdentitySelectPage");
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: handleWillPop,
        child: Scaffold(
          body: Builder(
              builder: (context) => Column(
                    // use this context within Scaffold for Toast's to work
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Section(text: getText(context, "main.selectAnIdentity")),
                      buildExistingIdentities(
                          context, Globals.accountPool.value),
                      SizedBox(height: 50),
                      Section(text: getText(context, "action.addAnIdentity")),
                      ListItem(
                          mainText: getText(context, "action.createANewIdentity"),
                          icon: FeatherIcons.plusCircle,
                          onTap: () => createNew(context)),
                      ListItem(
                          mainText: getText(
                              context, "main.restoreAnExistingIdentity"),
                          icon: FeatherIcons.rotateCw,
                          onTap: () => restorePreviousIdentity(context)),
                    ],
                  )),
        ));
  }

  buildExistingIdentities(BuildContext ctx, List<AccountModel> accounts) {
    List<Widget> list = new List<Widget>();
    if (accounts == null) return Column(children: list);

    for (var i = 0; i < accounts.length; i++) {
      if (!accounts[i].identity.hasValue) continue;

      list.add(ListItem(
        mainText: accounts[i].identity.value.alias,
        icon: FeatherIcons.user,
        onTap: () => onAccountSelected(ctx, accounts[i], i),
      ));
    }
    return Column(children: list);
  }

  /////////////////////////////////////////////////////////////////////////////
  // GLOBAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  Future<bool> handleWillPop() async {
    if (!Navigator.canPop(context)) {
      // dispose any resource in use
    }
    return true;
  }

  /////////////////////////////////////////////////////////////////////////////
  // LOCAL EVENTS
  /////////////////////////////////////////////////////////////////////////////

  onAccountSelected(
      BuildContext ctx, AccountModel account, int accountIdx) async {
    final lockPattern = await Navigator.push(
        ctx,
        MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => PatternPromptModal(account)));

    if (lockPattern == null)
      return;
    else if (lockPattern is InvalidPatternError) {
      showMessage(getText(context, "main.thePatternYouEnteredIsNotValid"),
          context: ctx, purpose: Purpose.DANGER);
      return;
    }
    Globals.appState.selectAccount(accountIdx);
    // Replace all routes with /home on top
    Navigator.pushNamedAndRemoveUntil(ctx, "/home", (Route _) => false);
  }

  createNew(BuildContext ctx) {
    // Navigator.pushNamed(ctx, "/identity/create");

    final route = MaterialPageRoute(
      builder: (context) => IdentityCreatePage(cangoBack: true),
    );
    Navigator.push(context, route);
  }

  restorePreviousIdentity(BuildContext ctx) {
    Navigator.pushNamed(ctx, "/identity/restore");
  }
}
