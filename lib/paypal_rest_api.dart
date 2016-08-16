/// Contains classes useful for interacting with the PayPal REST API.
library paypal_rest_api;

import "package:http/src/base_client.dart" as http;
import "src/apis/payments.dart";

/// A wrapper class over the entire PayPal REST API.
class PayPalRestApi {
  http.BaseClient _client;

  /// PayPal provides various payment-related operations through the /payment resource and related sub-resources.
  ///
  /// Use payment for direct credit card payments and PayPal account payments. You can also use sub-resources to get payment-related details.
  PaymentsApi payments;

  PayPalRestApi(this._client) {
    payments = new PaymentsApi(_client);
  }
}