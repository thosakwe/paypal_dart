// Todo: Funding Instruments, Payer, basically all objects...
/// Contains code to process payments via PayPal.
library paypal_rest_api.apis.payments;

import "dart:async";
import "dart:convert";
import "package:http/src/base_client.dart" as http;

/// Includes an intent, payer, and transactions.
class Payment {
  String id, intent, state, experienceProfileId, noteToPayer, failureReason;
  DateTime createTime, updateTime;
  List transactions = [],
      links = [];
  Map redirectUrls = {};
  var payer;

  Payment({this.id,
  this.intent,
  this.state,
  this.experienceProfileId,
  this.noteToPayer,
  this.failureReason,
  this.createTime,
  this.updateTime,
  this.redirectUrls,
  this.transactions,
  payer}) {
    this.createTime = createTime ?? new DateTime.now();
    this.links = links ?? [];
    this.transactions = transactions ?? [];
    this.redirectUrls = redirectUrls ?? {};
    this.payer = payer ?? {};
  }

  Payment.fromJson(String json) {
    _initializeFromMap(JSON.decode(json));
  }

  Payment.fromMap(Map data) {
    _initializeFromMap(data);
  }

  _initializeFromMap(Map data) {
    id = data["id"];
    intent = data["intent"];
    state = data["state"];
    experienceProfileId = data["experience_profile_id"];
    noteToPayer = data["note_to_payer"];
    failureReason = data["failure_reason"];
    createTime = data["create_time"] != null
        ? DateTime.parse(data["create_time"])
        : new DateTime.now();
    if (updateTime != null) {
      updateTime = DateTime.parse(data["update_time"]);
    }

    if (data["transactions"] != null) {
      for (Map transaction in data["transactions"]) {
        transactions.add(transaction);
      }
    }

    if (data["links"] != null) {
      for (Map link in data["links"]) {
        links.add(link);
      }
    }

    redirectUrls = data["redirect_urls"] ?? {};
  }

  Map toJson() {
    Map result = {
      "id": id,
      "create_time": createTime?.toIso8601String(),
      "update_time": updateTime?.toIso8601String(),
      "state": state,
      "intent": intent,
      "experience_profile_id": experienceProfileId,
      "note_to_payer": noteToPayer,
      "failure_reason": failureReason,
      "payer": payer is Payer ? payer.toJson() : payer
    };

    if (transactions != null) {
      result["transactions"] =
          transactions.map((x) => x is Transaction ? x.toJson() : x).toList();
    }

    if (links != null) {
      result["links"] =
          links.map((x) => x is Link ? x.toJson() : x).toList();
    }

    return result;
  }
}

class Link {
  Map toJson() {
    return {};
  }
}

class Payer {
  String paymentMethod;
  List fundingInstruments = [];

  Payer({this.paymentMethod, List fundingInstruments}) {
    this.fundingInstruments = fundingInstruments ?? [];
  }

  Map toJson() {
    return {
      "payment_method": paymentMethod,
      "funding_instruments": fundingInstruments
    };
  }
}

class Transaction {
  Map toJson() {
    return {};
  }
}

/// Wraps the PayPal Payments API.
class PaymentsApi {
  final String _endPoint = "/payments";
  http.BaseClient _client;

  PaymentsApi(this._client);

  /// Creates a [Payment].
  Future<Payment> createPayment(payment) async {
    var response = await _client.post("$_endPoint/payment",
        body: JSON.encode(payment is Payment ? payment.toJson() : payment),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        });
    return new Payment.fromJson(response.body);
  }
}

/* {
  "id": "PAY-5YK922393D847794YKER7MUI",
  "create_time": "2013-02-19T22:01:53Z",
  "update_time": "2013-02-19T22:01:55Z",
  "state": "approved",
  "intent": "sale",
  "payer": {
    "payment_method": "credit_card",
    "funding_instruments": [
      {
        "credit_card": {
          "type": "mastercard",
          "number": "xxxxxxxxxxxx5559",
          "expire_month": 2,
          "expire_year": 2018,
          "first_name": "Betsy",
          "last_name": "Buyer"
        }
      }
    ]
  },
  "transactions": [
    {
      "amount": {
        "total": "7.47",
        "currency": "USD",
        "details": {
          "subtotal": "7.47"
        }
      },
      "description": "This is the payment transaction description.",
      "note_to_payer": "Contact us for any questions on your order.",
      "related_resources": [
        {
          "sale": {
            "id": "36C38912MN9658832",
            "create_time": "2013-02-19T22:01:53Z",
            "update_time": "2013-02-19T22:01:55Z",
            "state": "completed",
            "amount": {
              "total": "7.47",
              "currency": "USD"
            },
            "protection_eligibility": "ELIGIBLE",
            "protection_eligibility_type": "ITEM_NOT_RECEIVED_ELIGIBLE",
            "transaction_fee": {
              "value": "1.75",
              "currency": "USD"
            },
            "parent_payment": "PAY-5YK922393D847794YKER7MUI",
            "links": [
              {
                "href": "https://api.paypal.com/v1/payments/sale/36C38912MN9658832",
                "rel": "self",
                "method": "GET"
              },
              {
                "href": "https://api.paypal.com/v1/payments/sale/36C38912MN9658832/refund",
                "rel": "refund",
                "method": "POST"
              },
              {
                "href": "https://api.paypal.com/v1/payments/payment/PAY-5YK922393D847794YKER7MUI",
                "rel": "parent_payment",
                "method": "GET"
              }
            ]
          }
        }
      ]
    }
  ],
  "links": [
    {
      "href": "https://api.paypal.com/v1/payments/payment/PAY-5YK922393D847794YKER7MUI",
      "rel": "self",
      "method": "GET"
    }
  ]
}
*/
