import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:responder/screens/notif_screen.dart';
import 'package:responder/screens/tabs/main_map_tab.dart';
import 'package:responder/screens/tabs/newhazard_tab.dart';
import 'package:responder/screens/tabs/report_tab.dart';
import 'package:responder/services/add_message.dart';
import 'package:responder/services/add_notif.dart';
import 'package:responder/widgets/drawer_widget.dart';
import 'package:responder/widgets/text_widget.dart';
import 'package:responder/widgets/textfield_widget.dart';
import 'package:responder/widgets/toast_widget.dart';

import '../model/users_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> children = [
    NewHazardTab(),
    const ReportTab(),
    const MainMapTab(),
  ];

  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  updateFcmToken() async {
    var token = await FirebaseMessaging.instance.getToken();
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .update({"fcmToken": token});
      log("token updated");
    } catch (_) {}
  }

  final reportController = TextEditingController();

  final msgController = TextEditingController();
  String msg = '';
  List<Users> usersList = <Users>[];

  @override
  void initState() {
    getUsers();
    Future.delayed(const Duration(seconds: 3), () {
      updateFcmToken();
    });
    super.initState();
  }

  getUsers() async {
    try {
      var res = await FirebaseFirestore.instance
          .collection('Users')
          .where('type', isEqualTo: 'User')
          .get();
      var users = res.docs;
      List data = [];
      for (var i = 0; i < users.length; i++) {
        Map mapdata = users[i].data();
        mapdata['documentID'] = users[i].id;
        data.add(mapdata);
      }
      usersList = usersFromJson(jsonEncode(data));
    } catch (_) {}
  }

  sendNotifToUser({required String message}) async {
    for (var i = 0; i < usersList.length; i++) {
      if (usersList[i].fcmToken != "" ||
          usersList[i].fcmToken.trim().toString().isNotEmpty) {
        try {
          var body = jsonEncode({
            "to": usersList[i].fcmToken,
            "notification": {
              "body": message,
              "title": "Emergency Notification",
              "subtitle": "",
            }
          });
          await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
              headers: {
                "Authorization":
                    "key=AAAAomtn0Yk:APA91bH2B8WQvFaTv0K7pcqcdTM8PX_V28b5JgfMRasrWaM4Cw8j6JgXmc1xEk1457mnKN3nJ_RBJBiV_T46_pvTD4c7EiEQNDGl4KiPUlbtyU_TbzpiHh0s0YH6GXBD-z4Yz7S7HDTb",
                "Content-Type": "application/json"
              },
              body: body);
        } catch (_) {}
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Stream<DocumentSnapshot> userData = FirebaseFirestore.instance
        .collection('Users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .snapshots();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(
          Icons.health_and_safety_outlined,
        ),
        onPressed: () {
          showDialog(
              context: context,
              builder: (context) => AlertDialog(
                    title: const Text(
                      'Emergency Confirmation',
                      style: TextStyle(
                          fontFamily: 'QBold', fontWeight: FontWeight.bold),
                    ),
                    content: SizedBox(
                      height: 100,
                      child: TextFieldWidget(
                        controller: reportController,
                        label: 'Name of Emergency Report',
                      ),
                    ),
                    actions: <Widget>[
                      MaterialButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                              fontFamily: 'QRegular',
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      StreamBuilder<DocumentSnapshot>(
                          stream: userData,
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot> snapshot) {
                            if (!snapshot.hasData) {
                              return const SizedBox();
                            } else if (snapshot.hasError) {
                              return const Center(
                                  child: Text('Something went wrong'));
                            } else if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox();
                            }
                            dynamic data = snapshot.data;
                            return MaterialButton(
                              onPressed: () async {
                                addNotif(
                                    data['name'],
                                    data['contactnumber'],
                                    data['address'],
                                    'EMERGENCY REPORT ALERT: ${reportController.text}',
                                    'imageURL',
                                    0,
                                    0);
                                sendNotifToUser(
                                    message:
                                        'EMERGENCY REPORT ALERT: ${reportController.text}');
                                showToast('Emergency Alert Added!');
                                Navigator.of(context).pop();
                              },
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                    fontFamily: 'QRegular',
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }),
                    ],
                  ));
        },
      ),
      drawer: const DrawerWidget(),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 128, 194, 231),
        title: TextWidget(
          text: 'RESPONDER',
          fontSize: 20,
          color: const Color.fromARGB(255, 8, 8, 8),
          fontFamily: 'Bold',
        ),
        centerTitle: true,
        actions: [
          StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('Notifs').snapshots(),
              // stream: FirebaseFirestore.instance
              //     .collection('Reports')
              //     .where('status', isEqualTo: 'Pending')
              //     .snapshots(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  print(snapshot.error);
                  return const Center(child: Text('Error'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  print('waiting');
                  return const Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: Center(
                        child: CircularProgressIndicator(
                      color: Colors.black,
                    )),
                  );
                }

                final data = snapshot.requireData;
                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const NotifPage()));
                    },
                    child: Badge(
                      backgroundColor: Colors.red,
                      label: TextWidget(
                        text: data.docs.length.toString(),
                        fontSize: 12,
                        color: Colors.white,
                      ),
                      child: const Icon(
                        Icons.notifications_rounded,
                      ),
                    ),
                  ),
                );
              }),
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    contentPadding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    content: SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextWidget(
                            text: 'Chats',
                            fontSize: 18,
                            fontFamily: 'Bold',
                          ),
                          Expanded(
                            child: StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('Message')
                                  .snapshots(),
                              builder: (BuildContext context,
                                  AsyncSnapshot<QuerySnapshot> snapshot) {
                                if (snapshot.hasError) {
                                  print(snapshot.error);
                                  return const Center(child: Text('Error'));
                                }
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                    ),
                                  );
                                }

                                final data1 = snapshot.requireData;
                                return ListView.builder(
                                  itemCount: data1.docs.length,
                                  itemBuilder: (context, index1) {
                                    return ListTile(
                                      leading: const CircleAvatar(
                                        child: Icon(
                                          Icons.account_circle_outlined,
                                        ),
                                      ),
                                      title: TextWidget(
                                        text: data1.docs[index1]['msg'],
                                        fontSize: 14,
                                      ),
                                      subtitle: TextWidget(
                                        text: data1.docs[index1]['name'],
                                        fontSize: 12,
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          TextFormField(
                            controller: msgController,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintText: 'Type a message...',
                              suffixIcon: StreamBuilder<DocumentSnapshot>(
                                stream: userData,
                                builder: (context,
                                    AsyncSnapshot<DocumentSnapshot> snapshot) {
                                  if (!snapshot.hasData) {
                                    return const SizedBox();
                                  } else if (snapshot.hasError) {
                                    return const Center(
                                        child: Text('Something went wrong'));
                                  } else if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const SizedBox();
                                  }
                                  dynamic data = snapshot.data;
                                  return IconButton(
                                    onPressed: () {
                                      if (msgController.text != '') {
                                        addMessage(
                                            data['name'], msgController.text);
                                        showToast('Message sent!');
                                        msgController.clear();
                                      } else {
                                        showToast('Please input a message');
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.send,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: TextWidget(
                          text: 'Close',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            icon: const Icon(
              Icons.chat,
            ),
          ),
        ],
      ),
      body: children[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        selectedLabelStyle: const TextStyle(fontFamily: 'Bold'),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Bold'),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        onTap: onTabTapped,
        currentIndex: _currentIndex,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.warning),
            label: 'HAZARD',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.visibility),
            label: 'REPORTS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pin_drop_sharp),
            label: 'MAP',
          ),
        ],
      ),
    );
  }
}
