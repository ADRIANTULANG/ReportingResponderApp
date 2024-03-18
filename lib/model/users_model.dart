// To parse this JSON data, do
//
//     final users = usersFromJson(jsonString);

import 'dart:convert';

List<Users> usersFromJson(String str) =>
    List<Users>.from(json.decode(str).map((x) => Users.fromJson(x)));

String usersToJson(List<Users> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Users {
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
  String documentId;

  Users({
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
    required this.documentId,
  });

  factory Users.fromJson(Map<String, dynamic> json) => Users(
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
        documentId: json["documentID"],
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
        "documentID": documentId,
      };
}
