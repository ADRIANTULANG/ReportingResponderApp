// To parse this JSON data, do
//
//     final responderDetails = responderDetailsFromJson(jsonString);

import 'dart:convert';

ResponderDetails responderDetailsFromJson(String str) =>
    ResponderDetails.fromJson(json.decode(str));

String responderDetailsToJson(ResponderDetails data) =>
    json.encode(data.toJson());

class ResponderDetails {
  String profilePicture;
  String address;
  String contactnumber;
  String name;
  String back;
  String front;
  String type;
  String userId;
  String fcmToken;
  String email;
  String status;

  ResponderDetails({
    required this.profilePicture,
    required this.address,
    required this.contactnumber,
    required this.name,
    required this.back,
    required this.front,
    required this.type,
    required this.userId,
    required this.fcmToken,
    required this.email,
    required this.status,
  });

  factory ResponderDetails.fromJson(Map<String, dynamic> json) =>
      ResponderDetails(
        profilePicture: json["profilePicture"],
        address: json["address"],
        contactnumber: json["contactnumber"],
        name: json["name"],
        back: json["back"],
        front: json["front"],
        type: json["type"],
        userId: json["userId"],
        fcmToken: json["fcmToken"],
        email: json["email"],
        status: json["status"],
      );

  Map<String, dynamic> toJson() => {
        "profilePicture": profilePicture,
        "address": address,
        "contactnumber": contactnumber,
        "name": name,
        "back": back,
        "front": front,
        "type": type,
        "userId": userId,
        "fcmToken": fcmToken,
        "email": email,
        "status": status,
      };
}
