import 'package:dvote_common/constants/colors.dart';
import 'package:dvote_common/widgets/toast.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/data-models/entity.dart';
import 'package:vocdoni/data-models/process.dart';
import 'package:vocdoni/lib/app-links.dart';
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:vocdoni/view-modals/qr-scan-modal.dart';
import 'package:vocdoni/views/entity-page.dart';
import 'package:dvote_common/widgets/baseCard.dart';
import 'package:dvote_common/widgets/card-loading.dart';
import 'package:dvote_common/widgets/listItem.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import "package:vocdoni/lib/extensions.dart";

class HomeEntitiesTab extends StatefulWidget {
  HomeEntitiesTab();

  @override
  _HomeEntitiesTabState createState() => _HomeEntitiesTabState();
}

class _HomeEntitiesTabState extends State<HomeEntitiesTab> {
  bool scanning = false;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("HomeEntitiesTab");
  }

  void _onRefresh() {
    final currentAccount = Globals.appState.currentAccount;

    currentAccount.refresh().then((_) {
      _refreshController.refreshCompleted();
    }).catchError((err) {
      _refreshController.refreshFailed();
    });
  }

  @override
  Widget build(ctx) {
    final currentAccount = Globals.appState.currentAccount;

    if (currentAccount == null) return buildNoEntities(ctx);

    return EventualBuilder(
      notifiers: [currentAccount.entities, currentAccount.identity],
      builder: (context, _, __) {
        if (!currentAccount.entities.hasValue ||
            currentAccount.entities.value.length == 0) {
          return buildNoEntities(ctx);
        }

        return SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          header: WaterDropHeader(
            complete: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.done, color: Colors.grey),
                  Container(width: 10.0),
                  Text(getText(context, "main.refreshCompleted"),
                      style: TextStyle(color: Colors.grey))
                ]),
            failed: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.close, color: Colors.grey),
                  Container(width: 10.0),
                  Text(getText(context, "main.couldNotRefresh"),
                      style: TextStyle(color: Colors.grey))
                ]),
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: ListView.builder(
              itemCount: currentAccount.entities.value.length,
              itemBuilder: (BuildContext context, int index) {
                final entity = currentAccount.entities.value[index];

                if (entity.metadata.hasValue)
                  return buildCard(ctx, entity);
                else if (entity.metadata.isLoading)
                  return CardLoading(getText(context, "main.loadingEntity"));
                return buildEmptyMetadataCard(ctx, entity);
              }),
        );
      },
    );
  }

  Widget buildEmptyMetadataCard(BuildContext ctx, EntityModel entityModel) {
    return BaseCard(children: [
      ListItem(
          mainText: entityModel.reference.entityId,
          avatarHexSource: entityModel.reference.entityId,
          isBold: true,
          onTap: () => onTapEntity(ctx, entityModel))
    ]);
  }

  Widget buildCard(BuildContext ctx, EntityModel ent) {
    return BaseCard(children: [
      buildName(ctx, ent),
      buildFeedRow(ctx, ent),
      buildParticipationRow(ctx, ent),
    ]);
  }

  int getFeedPostCount(EntityModel entity) {
    if (!entity.feed.hasValue)
      return 0;
    else if (entity.feed.value.items is List)
      return entity.feed.value.items.length;
    return 0;
  }

  Widget buildName(BuildContext ctx, EntityModel entity) {
    String title =
        entity.metadata.value.name[entity.metadata.value.languages[0]];
    return ListItem(
        heroTag: entity.reference.entityId + title,
        mainText: title,
        avatarUrl: entity.metadata.value.media.avatar,
        avatarText: title,
        avatarHexSource: entity.reference.entityId,
        isBold: true,
        onTap: () => onTapEntity(ctx, entity));
  }

  Widget buildParticipationRow(BuildContext ctx, EntityModel entity) {
    // Consume intermediate values, not present from the root context and rebuild if
    // the entity's process list changes
    return EventualBuilder(
      notifier: entity.processes,
      builder: (context, _, __) {
        int itemCount = 0;
        if (entity.processes.hasValue) {
          final availableProcesses = List<ProcessModel>();
          if (entity.processes.hasValue) {
            availableProcesses.addAll(
                entity.processes.value.where((item) => item.metadata.hasValue));
          }
          itemCount = availableProcesses.length;
        }

        return ListItem(
            mainText: getText(context, "main.participation"),
            icon: FeatherIcons.mail,
            rightText: itemCount.toString(),
            rightTextIsBadge: true,
            onTap: () => onTapParticipation(ctx, entity),
            disabled: itemCount == 0);
      },
    );
  }

  Widget buildFeedRow(BuildContext ctx, EntityModel entity) {
    // Consume intermediate values, not present from the root context and rebuild if
    // the entity's news feed changes
    return EventualBuilder(
      notifier: entity.feed,
      builder: (context, _, __) {
        final feedPostAmount = getFeedPostCount(entity);
        return ListItem(
            mainText: getText(context, "main.feed"),
            icon: FeatherIcons.rss,
            rightText: feedPostAmount.toString(),
            rightTextIsBadge: true,
            onTap: () => onTapFeed(ctx, entity),
            disabled: feedPostAmount == 0);
      },
    );
  }

  Widget buildNoEntities(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Icon(
              FeatherIcons.home,
              size: 50.0,
              color: Colors.black38,
            ),
            ListItem(
              mainText:
                  getText(ctx, "main.youHaveNotSubscribedToAnyEntitiesYet"),
              isTitle: true,
              isBold: true,
              rightIcon: null,
            ),
            ListItem(
              mainText:
                  getText(ctx, "main.getStartedByScanningAnEntitysQrCode"),
              onTap: () => onScanQrCode(ctx),
              rightIcon: FeatherIcons.camera,
            ),
            ListItem(
              mainText: getText(ctx, "main.orSubscribeToVocdoniCommunity"),
              onTap: () => onSubscribeToVocdoniCommunity(context),
              rightIcon: FeatherIcons.users,
            ),
          ],
        ));
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

      await handleIncomingLink(link, floatingBtnContext);
      scanning = false;
    } catch (err) {
      scanning = false;

      await Future.delayed(Duration(milliseconds: 10));

      showMessage(
          getText(floatingBtnContext,
              "error.theQrCodeDoesNotContainAValidLinkOrTheDetailsCannotBeRetrieved"),
          context: floatingBtnContext,
          purpose: Purpose.DANGER);
    }
  }

  onSubscribeToVocdoniCommunity(BuildContext context) async {
    try {
      final entity =
          "https://vocdoni.link/entities/0x01897ea1c6cf606c5cadcb67b32087bd8343fe578e71d53b9b511f7df1f58a17";
      final link = Uri.tryParse(entity);
      await handleIncomingLink(link, context);
    } catch (err) {
      showMessage(getText(context, "error.thereWasAProblemHandlingTheLink"),
          context: context, purpose: Purpose.DANGER);
    }
  }

  onTapEntity(BuildContext ctx, EntityModel entity) {
    final route =
        MaterialPageRoute(builder: (context) => EntityInfoPage(entity));
    Navigator.push(ctx, route);
  }

  onTapParticipation(BuildContext ctx, EntityModel entity) {
    Navigator.pushNamed(ctx, "/entity/participation", arguments: entity);
  }

  onTapFeed(BuildContext ctx, EntityModel entity) {
    Navigator.pushNamed(ctx, "/entity/feed", arguments: entity);
  }
}
