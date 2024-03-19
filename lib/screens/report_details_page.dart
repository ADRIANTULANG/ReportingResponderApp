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
import 'package:sizer/sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;

class ReportDetails extends StatefulWidget {
  const ReportDetails({super.key, required this.reportDetails});
  final Reports reportDetails;
  @override
  State<ReportDetails> createState() => _ReportDetailsState();
}

class _ReportDetailsState extends State<ReportDetails> {
  ResponderDetails? responderDetails;
  ResponderDetails? reporterDetails;

  Set<Marker> markers = {};
  Set<Polyline> poly = {};
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  CameraPosition? kGooglePlex;
  bool isShowContainer = true;
  TextEditingController remarks = TextEditingController();
  getResponderDetails() async {
    try {
      if (widget.reportDetails.responder != "" ||
          widget.reportDetails.responder.isNotEmpty) {
        var responder = await FirebaseFirestore.instance
            .collection('Users')
            .doc(widget.reportDetails.responder)
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
          .doc(widget.reportDetails.userId)
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
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    initializedData();
    getReporterDetails();
  }

  initializedData() async {
    Future.delayed(const Duration(milliseconds: 500), () async {
      await getResponderDetails();
      var loc = await Geolocator.getCurrentPosition();
      setState(() {
        markers.add(Marker(
          markerId: MarkerId(widget.reportDetails.name),
          icon: BitmapDescriptor.defaultMarker,
          position: LatLng(widget.reportDetails.lat, widget.reportDetails.long),
          infoWindow: InfoWindow(
            title: widget.reportDetails.caption,
            snippet: 'Status: ${widget.reportDetails.status}',
          ),
        ));

        poly.add(
          Polyline(
              color: Colors.transparent,
              width: 2,
              points: [
                LatLng(loc.latitude, loc.longitude),
                LatLng(widget.reportDetails.lat, widget.reportDetails.long),
              ],
              polylineId: PolylineId(widget.reportDetails.name)),
        );
        kGooglePlex = CameraPosition(
          target: LatLng(widget.reportDetails.lat, widget.reportDetails.long),
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
          .doc(widget.reportDetails.id)
          .update({
        "status": status,
        "responder":
            status == "Rejected" ? "" : FirebaseAuth.instance.currentUser!.uid
      });
      setState(() {
        widget.reportDetails.status = status;
      });
      sendNotifToUser(status: status);
      if (status == "Rejected") {
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: kGooglePlex == null
            ? const SizedBox()
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
                                              widget.reportDetails.type,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15.sp,
                                              ),
                                            ),
                                            Text(
                                              " (${widget.reportDetails.status})",
                                              style: TextStyle(
                                                color: widget.reportDetails
                                                            .status ==
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
                                                isShowContainer =
                                                    isShowContainer
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
                                      widget.reportDetails.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.sp,
                                      ),
                                    ),
                                    Text(
                                      widget.reportDetails.contactnumber,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      widget.reportDetails.address,
                                      style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    Text(
                                      "${DateFormat.yMMMMd().format(widget.reportDetails.dateTime)} ${DateFormat.jm().format(widget.reportDetails.dateTime)}",
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12.sp),
                                    ),
                                    SizedBox(
                                      height: 2.h,
                                    ),
                                    Text(
                                      widget.reportDetails.caption,
                                      maxLines: 3,
                                      style: TextStyle(
                                          fontWeight: FontWeight.normal,
                                          fontSize: 12.sp,
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                    SizedBox(
                                      height: 2.h,
                                    ),
                                    Container(
                                      height: 15.h,
                                      width: 100.w,
                                      decoration: BoxDecoration(
                                          image: DecorationImage(
                                              fit: BoxFit.cover,
                                              image: NetworkImage(widget
                                                  .reportDetails.imageUrl))),
                                    ),
                                    SizedBox(
                                      height: 2.h,
                                    ),
                                    widget.reportDetails.remarks == ""
                                        ? const SizedBox()
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
                                                widget.reportDetails.remarks,
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
                                    widget.reportDetails.status == "Pending"
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
                                        : widget.reportDetails.status ==
                                                "Accepted"
                                            ? SizedBox(
                                                height: 6.h,
                                                width: 100.w,
                                                child: ElevatedButton(
                                                    onPressed: () {
                                                      updateReport(
                                                          status: "Done");
                                                    },
                                                    child: const Text("DONE")),
                                              )
                                            : const SizedBox(),
                                    widget.reportDetails.status == "Pending"
                                        ? Padding(
                                            padding: EdgeInsets.only(top: 2.h),
                                            child: SizedBox(
                                              height: 6.h,
                                              width: 100.w,
                                              child: ElevatedButton(
                                                  style: const ButtonStyle(
                                                      backgroundColor:
                                                          MaterialStatePropertyAll(
                                                              Colors
                                                                  .redAccent)),
                                                  onPressed: () {
                                                    updateReport(
                                                        status: "Rejected");
                                                  },
                                                  child: const Text("REJECT")),
                                            ),
                                          )
                                        : const SizedBox.shrink()
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
                                  Navigator.pop(context);
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
                                                          reportID: widget
                                                              .reportDetails.id,
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
              ));
  }
}
