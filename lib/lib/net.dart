import 'dart:convert';
import 'package:dvote/dvote.dart';
import 'package:vocdoni/lib/singletons.dart';
import 'package:vocdoni/constants/settings.dart';
import 'package:vocdoni/lib/util.dart';

DVoteGateway _dvoteGw;
Web3Gateway _web3Gw;
bool connecting = false;

Future<void> ensureConnectedGateways() async {
  if (connecting) return;

  final gwInfo = await _getFastestGatewayInfo();
  if (gwInfo == null) throw Exception("There is no gateway available");

  connecting = true;
  if (_dvoteGw is DVoteGateway) {
    if (!_dvoteGw.isConnected) {
      devPrint("Connecting to ${gwInfo.dvote}");
      if (_dvoteGw.publicKey == gwInfo.publicKey)
        _dvoteGw.connect(gwInfo.dvote);
      else {
        _dvoteGw = DVoteGateway(gwInfo.dvote,
            publicKey: gwInfo.publicKey,
            onTimeout: _onGatewayTimeout); // calls `connect()` internally
      }
    }
  } else {
    devPrint("Connecting to ${gwInfo.dvote}");
    _dvoteGw = DVoteGateway(gwInfo.dvote,
        publicKey: gwInfo.publicKey,
        onTimeout: _onGatewayTimeout); // calls `connect()` internally
  }

  if (!(_web3Gw is Web3Gateway)) {
    _web3Gw = Web3Gateway(gwInfo.web3);
  }
  connecting = false;
}

void _onGatewayTimeout() {
  devPrint("GW timeout: ${_dvoteGw.uri}\nConnecting again...");
  ensureConnectedGateways().then((_) {
    devPrint("Connected to ${_dvoteGw.uri}");
  }).catchError((err) {
    devPrint("Reconnect failed: ${err.toString()}");
  });
}

bool areGatewaysConnected() =>
    _dvoteGw is DVoteGateway && _dvoteGw.isConnected && _web3Gw is Web3Gateway;

Future<DVoteGateway> getDVoteGateway() {
  if (!areGatewaysConnected()) {
    return ensureConnectedGateways().then((_) => _dvoteGw);
  } else {
    return Future.value(_dvoteGw);
  }
}

Future<Web3Gateway> getWeb3Gateway() {
  if (!areGatewaysConnected()) {
    return ensureConnectedGateways().then((_) => _web3Gw);
  } else {
    return Future.value(_web3Gw);
  }
}

Future<GatewayInfo> _getFastestGatewayInfo() async {
  if (!globalAppState.bootnodes.hasValue) return null;

  List<BootNodeGateways_NetworkNodes_DVote> dvoteNodes;
  List<BootNodeGateways_NetworkNodes_Web3> web3Nodes;

  // Detect the network
  if (NETWORK_ID == "homestead") {
    if (globalAppState.bootnodes.value.homestead.dvote.length < 1) {
      print("The DVote gateway list is empty for Homestead");
      return null;
    }

    // PROD
    dvoteNodes = globalAppState.bootnodes.value.homestead.dvote;
    web3Nodes = globalAppState.bootnodes.value.homestead.web3;
  } else {
    if (globalAppState.bootnodes.value.goerli.dvote.length < 1) {
      print("The DVote gateway list is empty for Goerli");
      return null;
    }

    // DEV
    dvoteNodes = globalAppState.bootnodes.value.goerli.dvote;
    web3Nodes = globalAppState.bootnodes.value.goerli.web3;
  }

  // Find the fastest to respond
  int fastestDVoteIdx = -1;

  await Future.wait(dvoteNodes
      .map((node) => DVoteGateway.isUp(node.uri).then((isUp) {
            if (fastestDVoteIdx < 0) fastestDVoteIdx = dvoteNodes.indexOf(node);
          }).catchError((_) {}))
      .cast<Future>()
      .toList());

  if (fastestDVoteIdx < 0) {
    devPrint("None of the gateways is available");
    return null;
  }
  final web3Idx = random.nextInt(web3Nodes.length);

  final gw = GatewayInfo();
  gw.dvote = dvoteNodes[fastestDVoteIdx].uri;
  gw.publicKey = dvoteNodes[fastestDVoteIdx].pubKey;
  gw.supportedApis.addAll(dvoteNodes[fastestDVoteIdx].apis);
  gw.web3 = web3Nodes[web3Idx].uri;
  return gw;
}

/*
 * Get a URI providing the given string content
 */
String uriFromContent(String content) {
  return new Uri.dataFromString(content,
          mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
      .toString();
}
