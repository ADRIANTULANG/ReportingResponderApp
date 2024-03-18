// To parse this JSON data, do
//
//     final chat = chatFromJson(jsonString);

import 'dart:convert';

List<Chat> chatFromJson(String str) =>
    List<Chat>.from(json.decode(str).map((x) => Chat.fromJson(x)));

String chatToJson(List<Chat> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Chat {
  String reportId;
  String chats;
  String url;
  DateTime datecreated;
  String sender;
  String type;

  Chat({
    required this.reportId,
    required this.chats,
    required this.url,
    required this.datecreated,
    required this.sender,
    required this.type,
  });

  factory Chat.fromJson(Map<String, dynamic> json) => Chat(
        reportId: json["reportID"],
        chats: json["chats"],
        url: json["url"],
        datecreated: DateTime.parse(json["datecreated"]),
        sender: json["sender"],
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
        "reportID": reportId,
        "chats": chats,
        "url": url,
        "datecreated": datecreated.toIso8601String(),
        "sender": sender,
        "type": type,
      };
}
