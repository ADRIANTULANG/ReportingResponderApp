import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responder/screens/report_details_page.dart';
import 'package:responder/widgets/message_dialog.dart';
import 'package:responder/widgets/text_widget.dart';
import 'package:sizer/sizer.dart';

import '../../model/report_model.dart';

class ReportTab extends StatefulWidget {
  const ReportTab({super.key});

  @override
  State<ReportTab> createState() => _ReportTabState();
}

class _ReportTabState extends State<ReportTab> {
  StreamSubscription<dynamic>? reportListener;
  Stream? reportStream;

  List<Reports> reportList = <Reports>[];
  @override
  void initState() {
    log("called");
    getChats();
    super.initState();
  }

  @override
  void dispose() {
    reportListener!.cancel();
    super.dispose();
  }

  getChats() async {
    try {
      reportStream = FirebaseFirestore.instance
          .collection('Reports')
          .where(Filter.or(
            Filter("status", isEqualTo: 'Pending'),
            Filter("status", isEqualTo: 'Accepted'),
            Filter("status", isEqualTo: 'Done'),
          ))
          .orderBy('dateTime', descending: true)
          .snapshots();

      reportListener = reportStream!.listen((event) async {
        List data = [];
        for (var report in event.docs) {
          Map mapdata = report.data();
          mapdata['id'] = report.id;
          mapdata['dateTime'] = mapdata['dateTime'].toDate().toString();

          data.add(mapdata);
        }
        Future.delayed(const Duration(seconds: 2), () {
          setState(() {
            reportList = reportsFromJson(jsonEncode(data));
          });
        });
        // setState(() {
        //   chatList = chatFromJson(jsonEncode(data));
        // });
        // chatList.sort((a, b) => a.datecreated.compareTo(b.datecreated));
        // Future.delayed(const Duration(seconds: 1), () {
        //   scrollController.jumpTo(scrollController.position.maxScrollExtent);
        // });
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100.h,
      width: 100.w,
      child: Padding(
        padding: EdgeInsets.only(left: 5.w, right: 5.w, top: 1.h),
        child: reportList.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: reportList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: EdgeInsets.only(top: 2.h),
                    child: SizedBox(
                        width: 100.w,
                        child: GestureDetector(
                          onTap: () {
                            if (reportList[index].responder != "Rejected") {
                              if (reportList[index].responder == "" ||
                                  reportList[index].responder ==
                                      FirebaseAuth.instance.currentUser!.uid) {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => ReportDetails(
                                          reportDetails: reportList[index],
                                        )));
                              } else {
                                MessageDialog.showMessageDialog(
                                    context: context,
                                    message:
                                        "Your report has been retrieved and is being acted upon by another responder");
                              }
                            } else {
                              MessageDialog.showMessageDialog(
                                  context: context,
                                  message: "This report has been rejected");
                            }
                          },
                          child: Card(
                            child: Padding(
                              padding: EdgeInsets.only(
                                  left: 2.w, top: 2.w, right: 2.w, bottom: 1.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        reportList[index].type,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15.sp),
                                      ),
                                      Text(
                                        "${DateFormat.yMMMMd().format(reportList[index].dateTime)} ${DateFormat.jm().format(reportList[index].dateTime)}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.normal,
                                            fontSize: 12.sp),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    reportList[index].status,
                                    style: TextStyle(
                                        color: reportList[index].status ==
                                                "Pending"
                                            ? Colors.orange
                                            : reportList[index].status ==
                                                    "Accepted"
                                                ? Colors.blue
                                                : reportList[index].status ==
                                                        "Done"
                                                    ? Colors.green
                                                    : Colors.red,
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12.sp),
                                  ),
                                  SizedBox(
                                    height: 2.h,
                                  ),
                                  Text(
                                    reportList[index].caption,
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal,
                                        fontSize: 12.sp),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  );
                },
              ),
      ),
    );
  }
}
