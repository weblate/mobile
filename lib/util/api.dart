import 'package:dvote/util/parsers.dart';
import 'package:vocdoni/util/singletons.dart';
import 'package:dvote/dvote.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

// ////////////////////////////////////////////////////////////////////////////
// METHODS
// ////////////////////////////////////////////////////////////////////////////

Future<String> makeMnemonic() {
  return generateMnemonic(size: 192);
}

Future<String> privateKeyFromMnemonic(String mnemonic) {
  return mnemonicToPrivateKey(mnemonic);
}

Future<String> publicKeyFromMnemonic(String mnemonic) {
  return mnemonicToPublicKey(mnemonic);
}

Future<String> addressFromMnemonic(String mnemonic) {
  return mnemonicToAddress(mnemonic);
}

Future<EntityMetadata> fetchEntityData(EntityReference entityReference) async {
  if (!(entityReference is EntityReference)) return null;

  try {
    final gwInfo = selectRandomGatewayInfo();

    final DVoteGateway dvoteGw =
        DVoteGateway(gwInfo.dvote, publicKey: gwInfo.publicKey);
    final Web3Gateway web3Gw = Web3Gateway(gwInfo.web3);

    EntityMetadata entityMetadata =
        await fetchEntity(entityReference, dvoteGw, web3Gw);
    entityMetadata.meta[META_ENTITY_ID] = entityReference.entityId;

    return entityMetadata;
  } catch (err) {
    if (!kReleaseMode) print(err);
    throw FetchError("The entity's data cannot be fetched");
  }
}

Future<Feed> fetchEntityNewsFeed(EntityReference entityReference,
    EntityMetadata entityMetadata, String lang) async {
  // Attempt for every node available
  if (!(entityMetadata is EntityMetadata))
    return null;
  else if (!(entityMetadata.newsFeed is Map<String, String>))
    return null;
  else if (!(entityMetadata.newsFeed[lang] is String)) return null;

  final gw = selectRandomGatewayInfo();

  final String contentUri = entityMetadata.newsFeed[lang];

  // Attempt for every node available
  try {
    ContentURI cUri = ContentURI(contentUri);
    DVoteGateway gateway = DVoteGateway(gw.dvote);
    final result = await fetchFileString(cUri, gateway);
    Feed feed = parseFeed(result);
    feed.meta[META_ENTITY_ID] = entityReference.entityId;
    feed.meta[META_LANGUAGE] = lang;
    return feed;
  } catch (err) {
    print(err);
    throw FetchError("The news feed cannot be fetched");
  }
}

// ////////////////////////////////////////////////////////////////////////////
// UTILITIES
// ////////////////////////////////////////////////////////////////////////////

class FetchError implements Exception {
  final String msg;
  const FetchError(this.msg);
  String toString() => 'FetchError: $msg';
}

GatewayInfo selectRandomGatewayInfo() {
  if (appStateBloc.value == null || appStateBloc.value.bootnodes == null)
    return null;

  final gw = GatewayInfo();

  if (kReleaseMode) {
    // PROD
    int dvoteIdx =
        random.nextInt(appStateBloc.value.bootnodes.homestead.dvote.length);
    int web3Idx =
        random.nextInt(appStateBloc.value.bootnodes.homestead.web3.length);

    gw.dvote = appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].uri;
    gw.publicKey =
        appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(appStateBloc.value.bootnodes.homestead.dvote[dvoteIdx].apis);
    gw.web3 = appStateBloc.value.bootnodes.homestead.web3[web3Idx].uri;
  } else {
    int dvoteIdx =
        random.nextInt(appStateBloc.value.bootnodes.goerli.dvote.length);
    int web3Idx =
        random.nextInt(appStateBloc.value.bootnodes.goerli.web3.length);

    gw.dvote = appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].uri;
    gw.publicKey = appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].pubKey;
    gw.supportedApis
        .addAll(appStateBloc.value.bootnodes.goerli.dvote[dvoteIdx].apis);
    gw.web3 = appStateBloc.value.bootnodes.goerli.web3[web3Idx].uri;
  }
  return gw;
}

GatewayInfo getDvote1() {
  GatewayInfo node = new GatewayInfo();
  node.dvote = 'ws://gwdev1.vocdoni.net/dvote';
  node.publicKey = '02325f284f50fa52d53579c7873a480b351cc20f7780fa556929f5017283ad2449';
  return node;
}

GatewayInfo getDvote2() {
  GatewayInfo node = new GatewayInfo();
  node.dvote = 'ws://gwdev2.vocdoni.net/dvote';
  node.publicKey = '0381290a9b7fabe99c24d8edcf4746859f17ee8e6099288fcf9170c356545fcac0';
  return node;
}
