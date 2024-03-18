import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responder/model/chat_model.dart';
import 'package:sizer/sizer.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.reportID,
  });
  final String reportID;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController message = TextEditingController();
  StreamSubscription<dynamic>? chatListener;
  Stream? chatStream;
  String userID = FirebaseAuth.instance.currentUser!.uid;

  List<Chat> chatList = <Chat>[];

  ScrollController scrollController = ScrollController();

  getChats({required String reportID}) async {
    try {
      chatStream = FirebaseFirestore.instance
          .collection('chat')
          .where('reportID', isEqualTo: reportID)
          .orderBy('datecreated', descending: true)
          .limit(100)
          .snapshots();

      chatListener = chatStream!.listen((event) async {
        List data = [];
        for (var report in event.docs) {
          Map mapdata = report.data();
          mapdata['id'] = report.id;
          data.add(mapdata);
        }
        setState(() {
          chatList = chatFromJson(jsonEncode(data));
        });
        chatList.sort((a, b) => a.datecreated.compareTo(b.datecreated));
        Future.delayed(const Duration(seconds: 1), () {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        });
      });
    } catch (_) {}
  }

  navigateBack() async {
    Navigator.pop(context);
  }

  sendMessage({required String messagetosend}) async {
    message.clear();
    await FirebaseFirestore.instance.collection('chat').add({
      "reportID": widget.reportID,
      "chats": messagetosend,
      "url": "",
      "datecreated": DateTime.now().toString(),
      "sender": userID,
      "type": "text",
    });
  }

  sendImage() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: [
      'jpg',
      'png',
      'jpeg',
    ]);
    if (result != null) {
      var filepath = result.files.single.path!;
      var fileName = result.files.single.name;

      Uint8List uint8list =
          Uint8List.fromList(File(filepath).readAsBytesSync());
      final ref = FirebaseStorage.instance.ref().child("chatimages/$fileName");
      var uploadTask = ref.putData(uint8list);
      final snapshot = await uploadTask.whenComplete(() {});
      var fileLink = await snapshot.ref.getDownloadURL();
      await FirebaseFirestore.instance.collection('chat').add({
        "reportID": widget.reportID,
        "chats": "",
        "url": fileLink,
        "sender": userID,
        "datecreated": DateTime.now().toString(),
        "type": "image"
      });
    }
  }

  @override
  void initState() {
    getChats(reportID: widget.reportID);
    super.initState();
  }

  @override
  void dispose() {
    chatListener!.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: WillPopScope(
          onWillPop: () => navigateBack(),
          child: SizedBox(
            height: 100.h,
            width: 100.w,
            child: Column(
              children: [
                Expanded(
                  child: SizedBox(
                    child: ListView.builder(
                      itemCount: chatList.length,
                      shrinkWrap: true,
                      controller: scrollController,
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      itemBuilder: (context, index) {
                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 14,
                                top: 10,
                              ),
                              child: chatList[index].type == "text"
                                  ? Align(
                                      alignment:
                                          (chatList[index].sender != userID
                                              ? Alignment.topLeft
                                              : Alignment.topRight),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          color:
                                              (chatList[index].sender != userID
                                                  ? Colors.blue
                                                  : const Color.fromARGB(
                                                      255, 178, 220, 240)),
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          chatList[index].chats,
                                          style: const TextStyle(fontSize: 15),
                                        ),
                                      ),
                                    )
                                  : Align(
                                      alignment:
                                          (chatList[index].sender != userID
                                              ? Alignment.topLeft
                                              : Alignment.topRight),
                                      child: Container(
                                        height: 30.h,
                                        width: 50.w,
                                        decoration: BoxDecoration(
                                            color: Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            image: DecorationImage(
                                                image: NetworkImage(
                                                    chatList[index].url))),
                                        padding: const EdgeInsets.all(16),
                                      ),
                                    ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(
                                left: 7.w,
                                right: 7.w,
                              ),
                              child: Align(
                                  alignment: (chatList[index].sender != userID
                                      ? Alignment.topLeft
                                      : Alignment.topRight),
                                  child: Text(
                                    "${DateFormat('yMMMd').format(chatList[index].datecreated)} ${DateFormat('jm').format(chatList[index].datecreated)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey,
                                        fontSize: 9.sp),
                                  )),
                            )
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  height: 10.h,
                  decoration:
                      const BoxDecoration(color: Colors.white, boxShadow: [
                    BoxShadow(
                        color: Colors.grey,
                        blurRadius: 5,
                        spreadRadius: 3,
                        offset: Offset(1, 2))
                  ]),
                  padding: EdgeInsets.only(bottom: 2.h, left: 3.w, right: 3.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        height: 6.h,
                        width: 70.w,
                        child: TextField(
                          controller: message,
                          decoration: InputDecoration(
                              fillColor: Colors.white,
                              filled: true,
                              contentPadding: EdgeInsets.only(left: 3.w),
                              alignLabelWithHint: false,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              hintText: 'Type something..'),
                        ),
                      ),
                      InkWell(
                          onTap: () {
                            sendImage();
                          },
                          child: const Icon(Icons.attachment)),
                      InkWell(
                          onTap: () {
                            sendMessage(messagetosend: message.text);
                          },
                          child: const Icon(Icons.send))
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
