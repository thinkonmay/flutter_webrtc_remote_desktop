import 'dart:convert';

class UserResponse {
  late int? Id;
  late String? Error;
  late Map<String, String> Data;

  UserResponse(int? id, String? error, Map<String, String> data) {
    Id = id;
    Error = error;
    var Data = <String, String>{};
    for (var key in data.keys) {
      Data[key] = data[key]!;
    }

    this.Data = Data;
  }

  @override
  String toString() {
    Map<String, dynamic> ret = {
      "id": Id,
      "error": Error,
      "data": {},
    };
    Data.forEach((key, value) {
      ret["data"][key] = value;
    });
    return jsonEncode(ret);
  }
}

class UserRequest {
  late int Id;
  late String Target;
  late Map<String, String> Headers;
  late Map<String, String> Data;

  UserRequest(int id, String target, Map<String, String> headers,
      Map<String, String> data) {
    Id = id;
    Target = target;
    Headers = headers;
    Data = data;
  }

  @override
  String toString() {
    Map<String, dynamic> ret = {
      "id": Id,
      "target": Target,
      "headers": {},
      "data": {}
    };
    Headers.forEach((key, value) {
      ret["headers"][key] = value;
    });
    Data.forEach((key, value) {
      ret["data"][key] = value;
    });
    return jsonEncode(ret);
  }
}
