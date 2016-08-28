/// Contains code for error handling.
library paypal_dart.paypal_exception;

import "dart:convert";

/// Represents an error while using the PayPal API.
class PayPalException implements Exception {
  List details;
  String informationLink, message, name;
  int statusCode;

  PayPalException(
      {List this.details,
      String this.informationLink,
      String this.message,
      String this.name,
      int this.statusCode: 500});

  PayPalException.fromJson(String json, {int statusCode: 500}) {
    _initializeFromMap(JSON.decode(json), statusCode: statusCode);
  }

  PayPalException.fromMap(Map data, {int statusCode: 500}) {
    _initializeFromMap(data, statusCode: statusCode);
  }

  _initializeFromMap(Map data, {int statusCode: 500}) {
    this.statusCode = statusCode;
    details = data["details"];
    informationLink = data["information_link"];
    message = data["message"];
    name = data["name"];
  }

  @override
  String toString() => "PayPal responded with error code $statusCode. $name: $message";
}