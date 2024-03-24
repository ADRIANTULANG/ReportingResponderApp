import 'dart:convert';
import 'dart:math';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:responder/screens/auth/login_screen.dart';
import 'package:responder/screens/home_screen.dart';
import 'package:responder/screens/report_details_page.dart';
import 'package:responder/terms_and_conditions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:http/http.dart' as http;
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initLocation();
  await Firebase.initializeApp(
    name: 'responder-67a90',
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

Future<Position> initLocation() async {
  bool serviceEnabled;
  LocationPermission permission;

  // Test if location services are enabled.
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Location services are not enabled don't continue
    // accessing the position and request users of the
    // App to enable the location services.
    return Future.error('Location services are disabled.');
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      // Permissions are denied, next time you could try
      // requesting permissions again (this is also where
      // Android's shouldShowRequestPermissionRationale
      // returned true. According to Android guidelines
      // your App should show an explanatory UI now.
      return Future.error('Location permissions are denied');
    }
  }

  if (permission == LocationPermission.deniedForever) {
    // Permissions are denied forever, handle appropriately.
    return Future.error(
        'Location permissions are permanently denied, we cannot request permissions.');
  }

  // When we reach here, permissions are granted and we can
  // continue accessing the position of the device.
  return await Geolocator.getCurrentPosition();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  String? token;
  bool? termsAndConditionStatus;
  bool? hasReportToComplete;

  bool isLoading = true;
  String? reportID;

  @override
  void initState() {
    super.initState();
    initNotif();
  }

  Future<bool> checkTermsConditionIfAccepted() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? status = prefs.getBool('TermsAndConditionStatus');

    if (status != null) {
      return status;
    } else {
      return false;
    }
  }

  Future<bool> checkIfHasPendingReport() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? reportid = prefs.getString('reportID');

    if (reportid != null) {
      reportID = reportid;
      return true;
    } else {
      return false;
    }
  }

  Future<void> initNotif() async {
    await checkNotificationPermission();
  }

  sendNotification(
      {required String userToken,
      required String message,
      required String title}) async {
    var body = jsonEncode({
      "to": userToken,
      "notification": {
        "body": message,
        "title": title,
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
  }

  Future<void> notificationSetup() async {
    AwesomeNotifications().initialize(
      null,
      [
        NotificationChannel(
          channelKey: 'basic_channel',
          channelName: 'Basic notifications',
          channelDescription: 'Notification channel for basic tests',
          importance: NotificationImportance.High,
        ),
        NotificationChannel(
          channelKey: 'basic_channel_muted',
          channelName: 'Basic muted notifications ',
          channelDescription: 'Notification channel for muted basic tests',
          importance: NotificationImportance.High,
          playSound: false,
        )
      ],
    );
  }

  Future<void> onForegroundMessage() async {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) {
        if (message.notification != null) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: Random().nextInt(9999),
              channelKey: 'basic_channel_muted',
              title: '${message.notification!.title}',
              body: '${message.notification!.body}',
              notificationLayout: NotificationLayout.BigText,
            ),
          );
          // }

          // call_unseen_messages();
        }
      },
    );
  }

  Future<void> checkNotificationPermission() async {
    termsAndConditionStatus = await checkTermsConditionIfAccepted();
    hasReportToComplete = await checkIfHasPendingReport();
    var res = await messaging.requestPermission();
    if (res.authorizationStatus == AuthorizationStatus.authorized) {
      await notificationSetup();
      await onBackgroundMessage();
      await onForegroundMessage();
    }
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(builder: (context, orientation, deviceType) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: isLoading
            ? Container(
                color: Colors.white,
                height: 100.h,
                width: 100.w,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              )
            : termsAndConditionStatus == null ||
                    termsAndConditionStatus == false
                ? const TermsAndConditionsPage()
                : FirebaseAuth.instance.currentUser == null
                    ? LoginScreen()
                    : hasReportToComplete == true
                        ? ReportDetails(
                            reportID: reportID!,
                            from: "Root",
                          )
                        : const HomeScreen(),
      );
    });
  }
}

Future<void> onBackgroundMessage() async {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.notification != null) {
    // if (Get.find<StorageService>().storage.read("notificationSound") ==
    //     true) {
    //   AwesomeNotifications().createNotification(
    //     content: NotificationContent(
    //       id: Random().nextInt(9999),
    //       channelKey: 'basic_channel',
    //       title: '${message.notification!.title}',
    //       body: '${message.notification!.body}',
    //       notificationLayout: NotificationLayout.BigText,
    //     ),
    //   );
    // } else {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: Random().nextInt(9999),
        channelKey: 'basic_channel_muted',
        title: '${message.notification!.title}',
        body: '${message.notification!.body}',
        notificationLayout: NotificationLayout.BigText,
      ),
    );
    // if (Get.isRegistered<HomeScreenController>() == true &&
    //     message.data['notif_from'] == "Order Status") {
    //   Get.find<HomeScreenController>().getOrders();
    //   if (Get.isRegistered<OrderDetailScreenController>() == true) {
    //     Get.find<OrderDetailScreenController>().getOrderStatus();
    //   }
    // }
    // if (Get.isRegistered<HomeScreenController>() == true &&
    //     message.data['notif_from'] == "Chat") {
    //   Get.find<HomeScreenController>()
    //       .putMessageIdentifier(order_id: message.data['value']);
    //   if (Get.isRegistered<OrderDetailScreenController>()) {
    //     Get.find<OrderDetailScreenController>().hasMessage.value = true;
    //   }
    // }
    // }

    // call_unseen_messages();
  }
}
