import "package:http/http.dart" as http;

class Device {

  late String name;
  late String serverUrl;
  late String token;

  Device(this.serverUrl, this.token);
  Device.name(this.name, this.serverUrl, this.token);

  Future<http.Response> requestName() async {
    return await http.get(Uri.parse("$serverUrl/v1/name/$token"));
  }

  factory Device.fromJson(Map<String, dynamic> json) => Device.name(json["name"], json["serverUrl"], json["token"]);

  Map<String, dynamic> toJson() => {
    "name": name,
    "serverUrl": serverUrl,
    "token": token
  };

}