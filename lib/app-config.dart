import 'package:vocdoni/lib/globals.dart';

/// Contains the compile-time defined config variables:
/// - `APP_MODE`: dev, beta, production
/// - `GATEWAY_BOOTNODES_URL`
/// - `NETWORK_ID` xdai, sokol
/// - `LINKING_DOMAIN`

const String _appMode = String.fromEnvironment("APP_MODE", defaultValue: "dev");
String _bootnodesUrlOverride;

class AppConfig {
  static const APP_MODE = _appMode;

  static bool isDevelopment() => _appMode == "dev";
  static bool isBeta() => _appMode == "beta";
  static bool isProduction() => _appMode == "production";

  static bool useTestingContracts() => AppConfig.isBeta();

  static setBootnodesUrlOverride(String url) async {
    try {
      _bootnodesUrlOverride = url;
      await Globals.appState.refresh(force: true);
    } catch (err) {
      throw err;
    }
  }

  static String get bootnodesUrl =>
      _bootnodesUrlOverride ?? _GATEWAY_BOOTNODES_URL;

  // CONFIG VARS
  static const _GATEWAY_BOOTNODES_URL = String.fromEnvironment(
    "GATEWAY_BOOTNODES_URL",
    defaultValue: _appMode == "dev"
        ? "https://bootnodes.vocdoni.net/gateways.dev.json"
        : "https://bootnodes.vocdoni.net/gateways.json",
  );

  static const NETWORK_ID = String.fromEnvironment(
    "NETWORK_ID",
    defaultValue: _appMode == "dev" ? "sokol" : "xdai",
  );

  static const LINKING_DOMAIN = String.fromEnvironment(
    "LINKING_DOMAIN",
    defaultValue: _appMode == "dev" ? "dev.vocdoni.link" : "vocdoni.link",
  );

  static const termsOfServiceURL = "https://vocdoni.io/terms-of-service/";
  static const privacyPolicyURL = "https://vocdoni.io/privacy-policy/";
  static const pinLength = 4;
  static const identityVersion = "38";
}
