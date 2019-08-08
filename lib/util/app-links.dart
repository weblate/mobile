import 'package:flutter/material.dart';
import 'package:vocdoni/lang/index.dart';
import 'package:vocdoni/modals/sign-modal.dart';
// import 'package:vocdoni/util/singletons.dart';
import 'package:vocdoni/util/api.dart';
import 'package:vocdoni/widgets/toast.dart';
import 'package:flutter/foundation.dart'; // for kReleaseMode

// /////////////////////////////////////////////////////////////////////////////
// MAIN
// /////////////////////////////////////////////////////////////////////////////

Future handleIncomingLink(Uri newLink, BuildContext context) async {
  if (!(newLink is Uri)) return null;

  switch (newLink.path) {
    case "/organization":
      return fetchAndShowOrganization(
          resolverAddress: newLink.queryParameters["resolverAddress"],
          entityId: newLink.queryParameters["entityId"],
          networkId: newLink.queryParameters["networkId"],
          entryPoints: newLink.queryParametersAll["entryPoints[]"],
          context: context);
      break;
    case "/signature":
      return showSignatureScreen(
          payload: newLink.queryParameters["payload"],
          returnUri: newLink.queryParameters["returnUri"],
          context: context);
    default:
      if (!kReleaseMode)
        throw LinkingError("Invalid path"); // Throw on debug, ignore on release
  }
}

// /////////////////////////////////////////////////////////////////////////////
// HANDLERS
// /////////////////////////////////////////////////////////////////////////////

Future fetchAndShowOrganization(
    {String resolverAddress,
    String entityId,
    String networkId,
    List<String> entryPoints,
    BuildContext context}) async {
  if (!(resolverAddress is String) ||
      !RegExp(r"^0x[a-zA-Z0-9]{40}$").hasMatch(resolverAddress)) {
    throw LinkingError("Invalid resolverAddress");
  } else if (!(entityId is String) ||
      !RegExp(r"^0x[a-zA-Z0-9]{64}$").hasMatch(entityId)) {
    throw LinkingError("Invalid entityId");
  } else if (!(networkId is String) ||
      !RegExp(r"^[0-9a-zA-Z]+$").hasMatch(networkId)) {
    throw LinkingError("Invalid networkId");
  } else if (!(entryPoints is List) || entryPoints.length == 0) {
    throw LinkingError("Invalid entryPoints");
  }

  List<String> decodedEntryPoints = entryPoints
      .map((String uri) {
        try {
          return Uri.decodeFull(uri);
        } catch (err) {
          throw LinkingError("Invalid entry point URI");
        }
      })
      .where((uri) => uri != null)
      .toList();

  showLoading(Lang.of(context).get("Connecting..."), global: true);

  try {
    // Fetch organization data
    final org = await fetchEntityData(
        resolverAddress, entityId, networkId, decodedEntryPoints);
    if (org == null) throw LinkingError("Could not fetch the details");

    hideLoading(global: true);

    // Show screen
    Navigator.pushNamed(context, "/organization", arguments: org);
  } catch (err) {
    hideLoading(global: true);

    throw err;
  }
}

showSignatureScreen(
    {@required BuildContext context,
    @required String payload,
    @required String returnUri}) {
  if (!(payload is String) || payload.length == 0) {
    throw LinkingError("Invalid payload");
  } else if (!(returnUri is String) || returnUri.length == 0) {
    throw LinkingError("Invalid returnUri");
  }

  payload = Uri.decodeFull(payload);
  final rtnUri = Uri.parse(returnUri);
  if (rtnUri == null) throw LinkingError("Invalid return URI");

  final SignModalArguments args =
      SignModalArguments(payload: payload, returnUri: rtnUri);

  Navigator.pushNamed(context, "/signature", arguments: args);
}

// ////////////////////////////////////////////////////////////////////////////
// UTILITIES
// ////////////////////////////////////////////////////////////////////////////

class LinkingError implements Exception {
  final String msg;
  const LinkingError(this.msg);
  String toString() => 'LinkingError: $msg';
}
