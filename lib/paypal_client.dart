/// Contains [PayPalClient], which is used to access the PayPal API.
library paypal_rest_api.paypal_client;

import "dart:async";
import "dart:convert";
import "package:http/src/base_client.dart";
import "package:http/src/base_request.dart";
import "package:http/src/streamed_response.dart";
import "package:http/src/request.dart";
import "package:http/src/response.dart";
import "src/access_credentials.dart";
import "src/paypal_exception.dart";

/// Authorizes requests to the PayPal API, and automatically refreshes its token when necessary.
class PayPalClient extends BaseClient {
  String apiVersion, clientId, clientSecret, paypalEndpoint;
  PayPalAccessCredentials credentials;
  BaseClient _inner;
  DateTime _lastTokenTime;
  final RegExp _leadingSlashes = new RegExp(r"^/+");
  bool debug;

  PayPalClient(this._inner, this.clientId, this.clientSecret,
      {String this.apiVersion: "v1",
      String this.paypalEndpoint: "https://api.paypal.com",
      bool this.debug: false}) {
    this.paypalEndpoint = paypalEndpoint.replaceAll(new RegExp(r"/+$"), "");
  }

  Future _fetchToken() async {
    credentials = await obtainAccessCredentials();
    _lastTokenTime = new DateTime.now();
  }

  String _makeUrl(String url) =>
      "$paypalEndpoint/$apiVersion/${url.replaceAll(_leadingSlashes, "")}";

  /*
   * The Authorization field is constructed as follows:[7][8][9]

      The username and password are combined with a single colon.
      The resulting string is encoded using the RFC2045-MIME variant of Base64, except not limited to 76 char/line.
      The authorization method and a space i.e. "Basic " is then put before the encoded string.
      For example, if the user agent uses Aladdin as the username and OpenSesame as the password then the field is formed as follows:

      echo -n "Aladdin:OpenSesame" | base64

      .. yields a string 'QWxhZGRpbjpPcGVuU2VzYW1l' that is used like so:

      (The -n makes sure there's not an extra newline being encoded)

      Authorization: Basic QWxhZGRpbjpPcGVuU2VzYW1l
   */

  /// Asynchronously obtains an access token from the PayPal API.
  Future<PayPalAccessCredentials> obtainAccessCredentials() async {
    var authString = BASE64.encode("$clientId:$clientSecret".codeUnits);
    var response = await _inner.post("$paypalEndpoint/$apiVersion/oauth2/token",
        body: "grant_type=client_credentials",
        headers: {
          "Accept": "application/json",
          "Accept-Language": "en_US",
          "Authorization": "Basic $authString",
          "Content-Type": "application/x-www-form-urlencoded"
        });
    return new PayPalAccessCredentials.fromJson(response.body);
  }

  @override
  Future<StreamedResponse> send(BaseRequest request) async {
    if (_lastTokenTime != null && credentials != null) {
      var now = new DateTime.now();
      var difference = now.difference(_lastTokenTime);
      if (difference.inSeconds >= credentials.expiresIn) await _fetchToken();
    } else
      await _fetchToken();

    if (credentials != null) {
      request.headers["authorization"] = "Bearer ${credentials.accessToken}";
    } else if (credentials == null) {
      var provisional = await obtainAccessCredentials();
      request.headers["authorization"] = "Bearer ${provisional.accessToken}";
      request.headers["dart_paypal_client"] = "provisional";
      credentials = provisional;
      await _fetchToken();
    }

    if (debug) {
      print("Sending ${request.method} to ${request.url}");
      print("Headers: ${request.headers}");

      if (request is Request) {
        print("Body: ${request.body}");
      }
    }

    var response = await _inner.send(request);

    if (response.statusCode != 200 && response.statusCode != 201) {
      var out = await Response.fromStream(response);

      if (debug) {
        print("Error response text: ${out.body}");
      }

      throw new PayPalException.fromJson(out.body,
          statusCode: response.statusCode);
    } else
      return response;
  }

  @override
  Future<Response> head(url, {Map<String, String> headers}) {
    return super.head(_makeUrl(url), headers: headers);
  }

  @override
  Future<Response> get(url, {Map<String, String> headers}) {
    return super.get(_makeUrl(url), headers: headers);
  }

  @override
  Future<Response> post(url,
      {Map<String, String> headers, body, Encoding encoding}) {
    return super
        .post(_makeUrl(url), headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<Response> put(url,
      {Map<String, String> headers, body, Encoding encoding}) {
    return super
        .put(_makeUrl(url), headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<Response> patch(url,
      {Map<String, String> headers, body, Encoding encoding}) {
    return super
        .patch(_makeUrl(url), headers: headers, body: body, encoding: encoding);
  }

  @override
  Future<Response> delete(url, {Map<String, String> headers}) {
    return super.delete(_makeUrl(url), headers: headers);
  }

  @override
  void close() {
    _inner.close();
    return super.close();
  }
}
