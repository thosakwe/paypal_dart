/// Contains code to hold various access credentials.
library paypal_dart.access_credentials;

import "dart:convert";

/// Represents credentials used to access PayPal.
class PayPalAccessCredentials {
  String accessToken, appId, _scope, tokenType;
  num expiresIn;
  List<String> get scopes => _scope.split(" ").map((str) => str.trim()).toList(growable: false);

  PayPalAccessCredentials({String this.appId, String this.accessToken, String this.tokenType, num this.expiresIn, List<String> scopes: const []}) {
    _scope = scopes.join(" ");
  }

  /// Initializes based on a JSON string.
  PayPalAccessCredentials.fromJson(String json) {
    _initializeFromMap(JSON.decode(json));
  }

  /// Initializes with data in a Map.
  PayPalAccessCredentials.fromMap(Map data) {
    _initializeFromMap(data);
  }

  _initializeFromMap(Map data) {
    accessToken = data["access_token"];
    appId = data["app_id"];
    tokenType = data["tokenType"];
    _scope = data["scope"];
    expiresIn = data["expires_in"];
  }
}

