import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:responder/model/report_model.dart';
import 'package:responder/model/responder_detail_model.dart';
import 'package:responder/screens/chat_page.dart';
import 'package:responder/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';

class ReportDetails extends StatefulWidget {
  const ReportDetails({super.key, required this.reportID, required this.from});
  final String reportID;
  final String from;

  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  ResponderDetails? responderDetails;
  ResponderDetails? reporterDetails;
  Reports? reportDetails;

  Set<Marker> markers = {};
  Set<Polyline> poly = {};
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  CameraPosition? kGooglePlex;
  bool isShowContainer = true;
  StreamSubscription<LocationData>? streamLocation;
  Location location = Location();

  TextEditingController remarks = TextEditingController();

  getReportDetails() async {
    // try {
    var repDetails = await FirebaseFirestore.instance
        .collection('Reports')
        .doc(widget.reportID)
        .get();
    if (repDetails.exists) {
      Map<String, dynamic>? mapreportDetails = repDetails.data();
      reportDetails = Reports(
          dateTime:
              DateTime.parse(mapreportDetails!['dateTime'].toDate().toString()),
          address: mapreportDetails['address'],
          contactnumber: mapreportDetails['contactnumber'],
          year: mapreportDetails['year'],
          caption: mapreportDetails['caption'],
          responder: mapreportDetails['responder'],
          type: mapreportDetails['type'],
          userId: mapreportDetails['userId'],
          long: mapreportDetails["long"]?.toDouble(),
          month: mapreportDetails['month'],
          imageUrl: mapreportDetails['imageURL'] ?? "",
          name: mapreportDetails['name'],
          day: mapreportDetails['day'],
          lat: mapreportDetails['lat'],
          remarks: mapreportDetails['remarks'] ?? "",
          status: mapreportDetails['status'],
          responderRemarks: mapreportDetails['responderRemarks'],
          level: mapreportDetails['level'],
          id: widget.reportID);

      await initializedData();
      await getReporterDetails();
      await initStreamLocation();
    }
    // } catch (_) {
    //   log("ERROR: getReportDetails $_");
    // }
  }

  initStreamLocation() async {
    streamLocation =
        location.onLocationChanged.listen((LocationData locationData) async {
      log(reportDetails!.status.toString());
      if (reportDetails!.status == "Accepted") {
        log(locationData.latitude.toString());
        log(locationData.longitude.toString());
        await FirebaseFirestore.instance
            .collection('Reports')
            .doc(widget.reportID)
            .update({
          "responderLat": locationData.latitude,
          "responderLong": locationData.longitude
        });
      }
    });
  }

  getResponderDetails() async {
    try {
      if (reportDetails!.responder != "" ||
          reportDetails!.responder.isNotEmpty) {
        var responder = await FirebaseFirestore.instance
            .collection('Users')
            .doc(reportDetails!.responder)
            .get();
        if (responder.exists) {
          var responderDetail = responder.data();
          log(jsonEncode(responderDetail));
          setState(() {
            responderDetails =
                responderDetailsFromJson(jsonEncode(responderDetail));
          });
        }
      }
    } catch (_) {
      log(_.toString());
    }
  }

  getReporterDetails() async {
    try {
      var reporter = await FirebaseFirestore.instance
          .collection('Users')
          .doc(reportDetails!.userId)
          .get();
      if (reporter.exists) {
        var repDetail = reporter.data();
        log(jsonEncode(reporterDetails));
        setState(() {
          reporterDetails = responderDetailsFromJson(jsonEncode(repDetail));
        });
      }
    } catch (_) {
      log(_.toString());
    }
  }

  callReporter() async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: reporterDetails!.contactnumber,
    );
    await launchUrl(launchUri);
  }

  sendNotifToUser({required String status}) async {
    try {
      var body = jsonEncode({
        "to": reporterDetails!.fcmToken,
        "notification": {
          "body": status == "Accepted"
              ? "We have accepted your report"
              : status == "Rejected"
                  ? "Your report has been rejected"
                  : status == "Cancelled"
                      ? "Your report has been cancelled"
                      : "We have already acted on your report and it is done",
          "title": "Report Notification",
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

      senfEmailNotif(
          email: reporterDetails!.email,
          message: jsonDecode(body)['notification']['body']);
    } catch (_) {}
  }

  initializedData() async {
    Future.delayed(const Duration(milliseconds: 500), () async {
      await getResponderDetails();
      var loc = await Geolocator.getCurrentPosition();
      setState(() {
        markers.add(Marker(
          markerId: MarkerId(reportDetails!.name),
          icon: BitmapDescriptor.defaultMarker,
          position: LatLng(reportDetails!.lat, reportDetails!.long),
          infoWindow: InfoWindow(
            title: reportDetails!.caption,
            snippet: 'Status: ${reportDetails!.status}',
          ),
        ));

        poly.add(
          Polyline(
              color: Colors.transparent,
              width: 2,
              points: [
                LatLng(loc.latitude, loc.longitude),
                LatLng(reportDetails!.lat, reportDetails!.long),
              ],
              polylineId: PolylineId(reportDetails!.name)),
        );
        kGooglePlex = CameraPosition(
          target: LatLng(reportDetails!.lat, reportDetails!.long),
          zoom: 14.4746,
        );
      });
      // if (context.mounted) {
      // Navigator.pop(context);
      // }
    });
  }

  updateReport({required String status}) async {
    try {
      await FirebaseFirestore.instance
          .collection('Reports')
          .doc(reportDetails!.id)
          .update({
        "status": status,
        "responder":
            status == "Rejected" ? "" : FirebaseAuth.instance.currentUser!.uid
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        reportDetails!.status = status;
        reportDetails!.responder = FirebaseAuth.instance.currentUser!.uid;
        if (status == "Accepted") {
          getResponderDetails();
          prefs.setString("reportID", widget.reportID);
        }
      });
      sendNotifToUser(status: status);
      if (status == "Rejected") {
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
      if (status == "Done") {
        streamLocation!.cancel();
        await prefs.remove('reportID');
      }
    } catch (_) {}
  }

  cancelReport() async {
    try {
      await FirebaseFirestore.instance
          .collection('Reports')
          .doc(reportDetails!.id)
          .update({
        "status": "Pending",
        "responder": "",
        "responderLat": 0.0,
        "responderLong": 0.0,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('reportID');
      setState(() {
        reportDetails!.status = "Pending";
        reportDetails!.responder = "";
      });
      // sendNotifToUser(status: "Cancelled");
      if (context.mounted) {
        if (widget.from == "Root") {
          Navigator.pop(context);
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const HomeScreen()));
        } else {
          Navigator.pop(context);
        }

        // Navigator.pushAndRemoveUntil(
        //     context,
        //     MaterialPageRoute(
        //         builder: (BuildContext context) => const HomeScreen()),
        //     ModalRoute.withName('/'));
      }
    } catch (_) {}
  }

  updateResponderRemarks(
      {required String remarks, required String level}) async {
    try {
      await FirebaseFirestore.instance
          .collection('Reports')
          .doc(reportDetails!.id)
          .update({
        "responderRemarks": remarks,
        "level": level,
      });
      setState(() {
        reportDetails!.responderRemarks = remarks;
        reportDetails!.level = level;
      });
    } catch (_) {}
  }

  showDialogAddRemarks() {
    remarks.clear();
    bool major = true;
    bool minor = false;
    String level = "Major";

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: Text(
                "Remarks",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15.sp),
              ),
              content: SizedBox(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 15.h,
                        width: 100.w,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all()),
                        child: TextField(
                          maxLines: 5,
                          controller: remarks,
                          decoration: InputDecoration(
                              contentPadding:
                                  EdgeInsets.only(top: .5.h, left: 2.w),
                              border: InputBorder.none),
                        ),
                      ),
                      SizedBox(
                        height: 2.h,
                      ),
                      Row(
                        children: [
                          Checkbox(
                              value: major,
                              onChanged: (value) {
                                setState(() {
                                  minor = false;
                                  major = true;
                                  level = "Major";
                                });
                              }),
                          const Text("Major")
                        ],
                      ),
                      Row(
                        children: [
                          Checkbox(
                              value: minor,
                              onChanged: (value) {
                                setState(() {
                                  minor = true;
                                  major = false;
                                  level = "Minor";
                                });
                              }),
                          const Text("Minor")
                        ],
                      ),
                      SizedBox(
                        height: 6.h,
                        width: 100.w,
                        child: ElevatedButton(
                            onPressed: () {
                              if (remarks.text.isNotEmpty) {
                                Navigator.pop(context);
                                updateResponderRemarks(
                                    remarks: remarks.text, level: level);
                              }
                            },
                            child: const Text("ADD")),
                      )
                    ],
                  ),
                ),
              ),
            );
          });
        });
  }

  senfEmailNotif({
    required String email,
    required String message,
  }) async {
    var response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {
          'origin': 'http://localhost',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'service_id': 'service_lrb1u5l',
          'template_id': 'template_13mp4el',
          'user_id': 'QHapO9GkU6VTFkw8t',
          'template_params': {
            'user_subject': 'Report Notif',
            'email': email,
            'message': message
          }
        }));
    print(response.statusCode);
  }

  @override
  void initState() {
    super.initState();
    getReportDetails();
  }

  @override
  void dispose() {
    if (streamLocation != null) {
      streamLocation!.cancel();
    }
    super.dispose();
  }

  getBack() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? reportid = prefs.getString('reportID');
    if (reportid != null) {
    } else {
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: WillPopScope(
      onWillPop: () => getBack(),
      child: kGooglePlex == null
          ? const SizedBox(
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : SizedBox(
              child: Stack(
                alignment: AlignmentDirectional.bottomCenter,
                children: [
                  SizedBox(
                    height: 100.h,
                    width: 100.w,
                    child: GoogleMap(
                      padding: EdgeInsets.only(bottom: 9.h),
                      markers: markers,
                      polylines: poly,
                      mapType: MapType.normal,
                      initialCameraPosition: kGooglePlex!,
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                      },
                    ),
                  ),
                  isShowContainer
                      ? Container(
                          width: 100.w,
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 4,
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 0), // changes x,y position of shadow
                                ),
                              ],
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20))),
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 5.w, right: 5.w, top: 2.h, bottom: 2.h),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            reportDetails!.type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15.sp,
                                            ),
                                          ),
                                          Text(
                                            " (${reportDetails!.status})",
                                            style: TextStyle(
                                              color: reportDetails!.status ==
                                                      "Pending"
                                                  ? Colors.orange
                                                  : Colors.green,
                                              fontWeight: FontWeight.normal,
                                              fontSize: 13.5.sp,
                                            ),
                                          ),
                                        ],
                                      ),
                                      GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              isShowContainer = isShowContainer
                                                  ? false
                                                  : true;
                                            });
                                          },
                                          child: const Icon(Icons.clear)),
                                    ],
                                  ),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  Text(
                                    reportDetails!.name,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                  Text(
                                    reportDetails!.contactnumber,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Text(
                                    reportDetails!.address,
                                    style: TextStyle(
                                      fontWeight: FontWeight.normal,
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                  Text(
                                    "${DateFormat.yMMMMd().format(reportDetails!.dateTime)} ${DateFormat.jm().format(reportDetails!.dateTime)}",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12.sp),
                                  ),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  Text(
                                    reportDetails!.caption,
                                    maxLines: 3,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12.sp,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  reportDetails!.imageUrl == ""
                                      ? const SizedBox.shrink()
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height: 2.h,
                                            ),
                                            Container(
                                              height: 15.h,
                                              width: 100.w,
                                              decoration: BoxDecoration(
                                                  image: DecorationImage(
                                                      fit: BoxFit.cover,
                                                      image: NetworkImage(
                                                          reportDetails!
                                                              .imageUrl))),
                                            ),
                                            SizedBox(
                                              height: 2.h,
                                            ),
                                          ],
                                        ),
                                  reportDetails!.remarks == ""
                                      ? const SizedBox.shrink()
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Remarks",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.sp,
                                              ),
                                            ),
                                            SizedBox(
                                              height: 2.h,
                                            ),
                                            Text(
                                              reportDetails!.remarks,
                                              style: TextStyle(
                                                fontWeight: FontWeight.normal,
                                                fontSize: 12.sp,
                                              ),
                                            ),
                                          ],
                                        ),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  reportDetails!.status == "Pending"
                                      ? SizedBox(
                                          height: 6.h,
                                          width: 100.w,
                                          child: ElevatedButton(
                                              onPressed: () {
                                                updateReport(
                                                    status: "Accepted");
                                              },
                                              child: const Text("ACCEPT")),
                                        )
                                      : reportDetails!.status == "Accepted"
                                          ? Column(
                                              children: [
                                                SizedBox(
                                                  height: 6.h,
                                                  width: 100.w,
                                                  child: ElevatedButton(
                                                      onPressed: () {
                                                        updateReport(
                                                            status: "Done");
                                                      },
                                                      child:
                                                          const Text("DONE")),
                                                ),
                                                SizedBox(
                                                  height: 2.h,
                                                ),
                                                SizedBox(
                                                  height: 6.h,
                                                  width: 100.w,
                                                  child: ElevatedButton(
                                                      style: const ButtonStyle(
                                                          backgroundColor:
                                                              MaterialStatePropertyAll(
                                                                  Colors
                                                                      .redAccent)),
                                                      onPressed: () {
                                                        cancelReport();
                                                      },
                                                      child:
                                                          const Text("CANCEL")),
                                                ),
                                              ],
                                            )
                                          : const SizedBox(),
                                  reportDetails!.status == "Pending"
                                      ? Padding(
                                          padding: EdgeInsets.only(top: 2.h),
                                          child: SizedBox(
                                            height: 6.h,
                                            width: 100.w,
                                            child: ElevatedButton(
                                                style: const ButtonStyle(
                                                    backgroundColor:
                                                        MaterialStatePropertyAll(
                                                            Colors.redAccent)),
                                                onPressed: () {
                                                  updateReport(
                                                      status: "Rejected");
                                                },
                                                child: const Text("REJECT")),
                                          ),
                                        )
                                      : const SizedBox.shrink(),
                                  reportDetails!.status == "Done" &&
                                          reportDetails!.responderRemarks ==
                                              null
                                      ? Padding(
                                          padding: EdgeInsets.only(top: 2.h),
                                          child: SizedBox(
                                            height: 6.h,
                                            width: 100.w,
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  showDialogAddRemarks();
                                                },
                                                child:
                                                    const Text("ADD REMARKS")),
                                          ),
                                        )
                                      : reportDetails!.status == "Done" &&
                                              reportDetails!.responderRemarks !=
                                                  null
                                          ? Padding(
                                              padding:
                                                  EdgeInsets.only(top: 2.h),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        "Responder Remarks",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 13.sp,
                                                        ),
                                                      ),
                                                      GestureDetector(
                                                          onTap: () {
                                                            showDialogAddRemarks();
                                                          },
                                                          child: const Icon(
                                                              Icons.edit))
                                                    ],
                                                  ),
                                                  Text(
                                                    reportDetails!
                                                        .responderRemarks!,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                  Text(
                                                    "Level",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 13.sp,
                                                    ),
                                                  ),
                                                  Text(
                                                    reportDetails!.level!,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontSize: 12.sp,
                                                    ),
                                                  ),
                                                ],
                                              ))
                                          : const SizedBox.shrink(),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 9.h,
                          width: 100.w,
                          decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  spreadRadius: 4,
                                  blurRadius: 5,
                                  offset: const Offset(
                                      0, 0), // changes x,y position of shadow
                                ),
                              ],
                              color: Colors.white,
                              borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20))),
                          child: Center(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  isShowContainer =
                                      isShowContainer ? false : true;
                                });
                              },
                              child: CircleAvatar(
                                radius: 5.w,
                                backgroundColor: Colors.black,
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                  Positioned(
                      top: 5.h,
                      left: 5.w,
                      child: SizedBox(
                        width: 90.w,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                getBack();
                              },
                              child: Container(
                                height: 7.h,
                                width: 12.w,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 4,
                                      blurRadius: 5,
                                      offset: const Offset(0,
                                          0), // changes x,y position of shadow
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 14.sp,
                                  ),
                                ),
                              ),
                            ),
                            responderDetails != null
                                ? Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {
                                          callReporter();
                                        },
                                        child: Container(
                                          height: 7.h,
                                          width: 12.w,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                spreadRadius: 4,
                                                blurRadius: 5,
                                                offset: const Offset(0,
                                                    0), // changes x,y position of shadow
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.call,
                                              size: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 3.w,
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      ChatPage(
                                                        reportID:
                                                            reportDetails!.id,
                                                      )));
                                        },
                                        child: Container(
                                          height: 7.h,
                                          width: 12.w,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.2),
                                                spreadRadius: 4,
                                                blurRadius: 5,
                                                offset: const Offset(0,
                                                    0), // changes x,y position of shadow
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.message,
                                              size: 14.sp,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox()
                          ],
                        ),
                      ))
                ],
              ),
            ),
    ));
  }
}
