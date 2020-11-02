import 'dart:async';
import 'package:dvote_common/widgets/flavor-banner.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/app-config.dart';
import "dart:developer";
import "package:flutter/material.dart";
import 'package:uni_links/uni_links.dart';
import 'package:dvote_common/constants/colors.dart';
import 'package:vocdoni/lib/net.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/notifications.dart';
import 'package:vocdoni/view-modals/qr-scan-modal.dart';
import 'package:vocdoni/views/home-content-tab.dart';
import 'package:vocdoni/views/home-entities-tab.dart';
import 'package:vocdoni/views/home-identity-tab.dart';
import 'package:dvote_common/widgets/alerts.dart';
import 'package:dvote_common/widgets/bottomNavigation.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:dvote_common/widgets/topNavigation.dart';
// import 'package:vocdoni/lib/extensions.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int selectedTab = 0;
  bool scanning = false;

  /// Store it on build, so that external events like deep link handling can display
  /// snackbars on it
  BuildContext scaffoldBodyContext;

  /////////////////////////////////////////////////////////////////////////////
  // DEEP LINKS / UNIVERSAL LINKS
  /////////////////////////////////////////////////////////////////////////////

  StreamSubscription<Uri> linkChangeStream;

  @override
  void initState() {
    try {
      // HANDLE APP LAUNCH LINK
      getInitialUri()
          .then((initialUri) => handleLink(initialUri))
          .catchError((err) => handleIncomingLinkError(err));

      // HANDLE RUNTIME LINKS
      linkChangeStream = getUriLinksStream()
          .listen((uri) => handleLink(uri), onError: handleIncomingLinkError);

      // Display the screen for a notification (if one is pending)
      Future.delayed(Duration(seconds: 1))
          .then((_) => Notifications.handlePendingNotification());
    } catch (err) {
      showAlert(getText(context, "main.theLinkYouFollowedAppearsToBeInvalid"),
          title: getText(context, "main.error"), context: context);
    }

    // APP EVENT LISTENER
    WidgetsBinding.instance.addObserver(this);

    // DETERMINE INITIAL TAB
    final currentAccount =
        Globals.appState.currentAccount; // It is expected to be non-null

    selectedTab = 1;
    currentAccount.refresh(); // detached from async
    // }

    super.initState();
  }

  handleLink(Uri givenUri) {
    if (givenUri == null) return;

    handleIncomingLink(givenUri, scaffoldBodyContext ?? context)
        .catchError(handleIncomingLinkError);
  }

  handleIncomingLinkError(err) {
    log(err?.toString() ?? "handleIncomingLinkError");
    final ctx = scaffoldBodyContext ?? context;
    showAlert(getText(ctx, "error.thereWasAProblemHandlingTheLink"),
        title: getText(scaffoldBodyContext ?? context, "main.error"),
        context: scaffoldBodyContext ?? context);
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.inactive:
        log("Inactive");
        break;
      case AppLifecycleState.paused:
        log("Paused");
        break;
      case AppLifecycleState.resumed:
        log("Resumed");
        if (!AppNetworking.isReady) AppNetworking.init(forceReload: true);
        break;
      case AppLifecycleState.detached:
        log("Detached");
        break;
    }
  }

  /////////////////////////////////////////////////////////////////////////////
  // CLEANUP
  /////////////////////////////////////////////////////////////////////////////

  @override
  void dispose() {
    // RUNTIME LINK HANDLING
    if (linkChangeStream != null) linkChangeStream.cancel();

    // APP EVENT LISTENER
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  /////////////////////////////////////////////////////////////////////////////
  // MAIN
  /////////////////////////////////////////////////////////////////////////////

  @override
  Widget build(context) {
    return WillPopScope(
      onWillPop: handleWillPop,
      child: FlavorBanner(
        mode: AppConfig.APP_MODE,
        child: Scaffold(
          appBar: TopNavigation(
            title: getTabName(selectedTab),
            showBackButton: false,
          ),
          // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          // floatingActionButtonAnimator: FloatingActionButtonAnimator.scaling,
          floatingActionButton: selectedTab == 1 ? buildFab(context) : null,
          body: Builder(builder: (ctx) {
            // Store the build context from the scaffold, so that deep links can show
            // snackbars on top of this scaffold
            scaffoldBodyContext = ctx;

            return buildBody(context);
          }),
          bottomNavigationBar: BottomNavigation(
            onTabSelect: (index) => onTabSelect(index),
            selectedTab: selectedTab,
          ),
        ),
      ),
    );
  }

  buildFab(BuildContext context) {
    // Force the toast context to descend from Scaffold and not from the widget
    return EventualBuilder(
        notifier: Globals.appState.currentAccount?.entities,
        builder: (BuildContext ctx, _, __) {
          final entitiesCount =
              Globals.appState.currentAccount?.entities?.value?.length ?? 0;

          if (entitiesCount == 0) {
            return SizedBox.shrink();
          }

          return FloatingActionButton(
            onPressed: () => onScanQrCode(ctx),
            backgroundColor: colorDescription,
            child: Icon(Icons.camera_alt),
            elevation: 5.0,
            tooltip: getText(ctx, "tooltip.scanaQrCode"),
          );
        });
  }

  buildBody(BuildContext ctx) {
    Widget body;

    // RENDER THE CURRENT TAB BODY
    switch (selectedTab) {
      // VOTES+FEED
      case 0:
        body = HomeContentTab();
        break;
      // SUBSCRIBED ENTITIES
      case 1:
        body = HomeEntitiesTab();
        break;
      // IDENTITY INFO
      case 2:
        body = HomeIdentityTab();
        break;
      default:
        body = Container(
          child: Center(
            child: Text("Vocdoni"),
          ),
        );
    }
    return body;
  }

  onTabSelect(int idx) {
    setState(() {
      selectedTab = idx;
    });
  }

  onScanQrCode(BuildContext floatingBtnContext) async {
    if (scanning) return;
    scanning = true;

    try {
      final result = await Navigator.push(
          context,
          MaterialPageRoute(
              fullscreenDialog: true, builder: (context) => QrScanModal()));

      if (!(result is String)) {
        scanning = false;
        return;
      }
      // await Future.delayed(Duration(milliseconds: 50));

      final link = Uri.tryParse(result);
      if (!(link is Uri) || !link.hasScheme || link.hasEmptyPath)
        throw Exception("Invalid URI");

      await handleIncomingLink(link, scaffoldBodyContext ?? context);
      scanning = false;
    } catch (err) {
      scanning = false;

      await Future.delayed(Duration(milliseconds: 10));

      showMessage(
          getText(context,
              "error.theQrCodeDoesNotContainAValidLinkOrTheDetailsCannotBeRetrieved"),
          context: scaffoldBodyContext,
          purpose: Purpose.DANGER);
    }
  }

  String getTabName(int idx) {
    if (idx == 0)
      return getText(context, "main.home");
    else if (idx == 1)
      return getText(context, "main.yourEntities");
    else if (idx == 2)
      return getText(context, "main.yourIdentity");
    else
      return "";
  }
}
