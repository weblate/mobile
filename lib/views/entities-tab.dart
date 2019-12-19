import 'package:dvote/models/dart/entity.pbserver.dart';
import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:states_rebuilder/states_rebuilder.dart';
import 'package:vocdoni/models/entModel.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/widgets/baseCard.dart';
import 'package:vocdoni/widgets/listItem.dart';

class EntitiesTab extends StatefulWidget {
  EntitiesTab();

  @override
  _EntitiesTabState createState() => _EntitiesTabState();
}

class _EntitiesTabState extends State<EntitiesTab> {
  @override
  void initState() {
    super.initState();
    analytics.trackPage(pageId: "EntitiesTab");
  }

  @override
  Widget build(ctx) {
    if (account.ents.length == 0) return buildNoEntities(ctx);

    return ListView.builder(
        itemCount: account.ents.length,
        itemBuilder: (BuildContext ctxt, int index) {
          final ent = account.ents[index];

          return StateBuilder(
              viewModels: [ent],
              tag: EntTags.ENTITY_METADATA,
              builder: (ctx, tagId) {
                return ent.entityMetadata.isValid
                    ? buildCard(ctx, ent)
                    : buildEmptyMetadataCard(ctx, ent.entityReference);
              });
        });
  }

  Widget buildEmptyMetadataCard(
      BuildContext ctx, EntityReference entityReference) {
    return BaseCard(children: [
      ListItem(
          mainText: entityReference.entityId,
          avatarHexSource: entityReference.entityId,
          isBold: true,
          onTap: () => onTapEntity(ctx, entityReference))
    ]);
  }

  Widget buildCard(BuildContext ctx, EntModel ent) {
    return BaseCard(children: [
      buildName(ctx, ent),
      buildFeedItem(ctx, ent),
      buildParticipationItem(ctx, ent),
    ]);
  }

  int getFeedPostAmount(EntModel ent) {
    if (ent.feed.isValid)
      return ent.feed.value.items.length;
    else
      return 0;
  }

  Widget buildName(BuildContext ctx, EntModel ent) {
    String title =
        ent.entityMetadata.value.name[ent.entityMetadata.value.languages[0]];
    return ListItem(
        heroTag: ent.entityReference.entityId + title,
        mainText: title,
        avatarUrl: ent.entityMetadata.value.media.avatar,
        avatarText: title,
        avatarHexSource: ent.entityReference.entityId,
        isBold: true,
        onTap: () => onTapEntity(ctx, ent.entityReference));
  }

  buildParticipationItem(BuildContext ctx, EntModel ent) {
    if (ent.processes.isNotValid) return Container();

    return ListItem(
        mainText: "Participation",
        icon: FeatherIcons.mail,
        rightText: ent.processes.value.length.toString(),
        rightTextIsBadge: true,
        onTap: () => onTapParticipation(ctx, ent.entityReference),
        disabled: ent.processes.value.length == 0);
  }

  Widget buildFeedItem(BuildContext ctx, EntModel ent) {
    return StateBuilder(
        viewModels: [ent],
        tag: EntTags.FEED,
        builder: (ctx, tagId) {
          final feedPostAmount = getFeedPostAmount(ent);
          return ListItem(
              mainText: "Feed",
              icon: FeatherIcons.rss,
              rightText: feedPostAmount.toString(),
              rightTextIsBadge: true,
              onTap: () {
                Navigator.pushNamed(ctx, "/entity/feed", arguments: ent);
              },
              disabled: feedPostAmount == 0);
        });
  }

  Widget buildNoEntities(BuildContext ctx) {
    // TODO: UI
    return Center(
      child: Text("No entities"),
    );
  }

  onTapEntity(BuildContext ctx, EntityReference entityReference) {
    Navigator.pushNamed(ctx, "/entity", arguments: entityReference);
  }

  onTapParticipation(BuildContext ctx, EntityReference entityReference) {
    Navigator.pushNamed(ctx, "/entity/participation",
        arguments: entityReference);
  }
}
