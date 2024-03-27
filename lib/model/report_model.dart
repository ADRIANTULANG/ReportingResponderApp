// To parse this JSON data, do
//
//     final reports = reportsFromJson(jsonString);

import 'dart:convert';

List<Reports> reportsFromJson(String str) =>
    List<Reports>.from(json.decode(str).map((x) => Reports.fromJson(x)));

String reportsToJson(List<Reports> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Reports {
  DateTime dateTime;
  String address;
  String contactnumber;
  int year;
  String caption;
  String responder;
  String type;
  String userId;
  double long;
  int month;
  String imageUrl;
  String name;
  int day;
  double lat;
  String remarks;
  String status;
  String id;
  String? responderRemarks;
  String? level;

  Reports(
      {required this.dateTime,
      required this.address,
      required this.contactnumber,
      required this.year,
      required this.caption,
      required this.responder,
      required this.type,
      required this.userId,
      required this.long,
      required this.month,
      required this.imageUrl,
      required this.name,
      required this.day,
      required this.lat,
      required this.remarks,
      required this.status,
      required this.id,
      this.responderRemarks,
      this.level});

  factory Reports.fromJson(Map<String, dynamic> json) => Reports(
        dateTime: DateTime.parse(json["dateTime"]),
        address: json["address"],
        responderRemarks: json["responderRemarks"],
        level: json["level"],
        contactnumber: json["contactnumber"],
        year: json["year"],
        caption: json["caption"],
        responder: json["responder"],
        type: json["type"],
        userId: json["userId"],
        long: json["long"]?.toDouble(),
        month: json["month"],
        imageUrl: json["imageURL"],
        name: json["name"],
        day: json["day"],
        lat: json["lat"]?.toDouble(),
        remarks: json["remarks"],
        status: json["status"],
        id: json["id"],
      );

  Map<String, dynamic> toJson() => {
        "dateTime": dateTime.toIso8601String(),
        "address": address,
        "contactnumber": contactnumber,
        "year": year,
        "caption": caption,
        "level": level,
        "responderRemarks": responderRemarks,
        "responder": responder,
        "type": type,
        "userId": userId,
        "long": long,
        "month": month,
        "imageURL": imageUrl,
        "name": name,
        "day": day,
        "lat": lat,
        "remarks": remarks,
        "status": status,
        "id": id,
      };
}
