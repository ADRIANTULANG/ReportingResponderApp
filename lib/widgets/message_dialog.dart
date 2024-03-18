import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class MessageDialog {
  static showMessageDialog(
      {required BuildContext context, required String message}) async {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Okay"))
            ],
            content: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(
                  color: Colors.white,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        message,
                        style: TextStyle(fontSize: 12.sp),
                      )
                    ],
                  )),
            ),
          );
        },
        barrierDismissible: false);
  }
}
