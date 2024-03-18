import 'package:flutter/material.dart';
import 'package:responder/screens/auth/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';

class TermsAndConditionsPage extends StatefulWidget {
  const TermsAndConditionsPage({super.key});

  @override
  State<TermsAndConditionsPage> createState() => _TermsAndConditionsPageState();
}

class _TermsAndConditionsPageState extends State<TermsAndConditionsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SizedBox(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 3.h,
                ),
                SizedBox(
                  width: 100.w,
                  child: Center(
                    child: Text(
                      "Terms & Conditions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 3.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "Welcome! We're excited to have you as a user. Before using our app, please read the following Terms and Conditions carefully.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "1. Acceptance of Terms \n\n  By using our app, you agree to comply with these Terms and Conditions. If you do not agree with any part of these terms, please refrain from using the app.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "2. Proper Use of the App \n\n A. You agree to use our apps responsibly and for its intended purpose. \n\n  B. Users must not engage in any activity that disrupts or interferes with the proper functioning of the app. \n\n C. Users must not submit prank reports or provide false information with malicious intent.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "3. Prank Reports \n\n A. Our app takes prank reports seriously and expects users to submit genuine and legitimate reports. \n\n B. Users are prohibited from submitting prank reports or false information intentionally.\n\n C. Any user found submitting prank reports or false information may face legal consequences, including but not limited to legal action and termination of their account.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "4. User Liability \n\n A. Users are solely responsible for the content they submit through the app. \n\n B. Users must ensure that the information they provide is accurate, lawful, and does not infringe upon the rights of others.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "5. App Changes and Termination \n\n A. Our app reserves the right to modify, suspend, or terminate the app's services at any time without prior notice. \n\n B. We may also update these Terms and Conditions periodically. It is your responsibility to review them regularly.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "6. Disclaimer of Liability \n\n A. Our app shall not be held liable for any damages, losses, or liabilities arising from the use or inability to use the app. \n\n B. We do not guarantee the accuracy, reliability, or availability of the app's content or services.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "7. Governing Law \n\n These Terms and Conditions shall be governed by and construed in accordance with the laws of Philippines, without regard to its conflict of laws principles.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 2.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: Text(
                    "By using our app, you acknowledge that you have read and understood these Terms and Conditions. If you have any questions or concerns, please contact us at jnwl838@gmail.com.",
                    style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 12.sp),
                  ),
                ),
                SizedBox(
                  height: 3.h,
                ),
                Padding(
                  padding: EdgeInsets.only(left: 5.w, right: 5.w),
                  child: SizedBox(
                    width: 100.w,
                    child: Text(
                      "Last updated: March 18, 2024",
                      style: TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 8.sp),
                    ),
                  ),
                ),
                SizedBox(
                  height: 4.h,
                ),
                Padding(
                    padding: EdgeInsets.only(left: 5.w, right: 5.w),
                    child: SizedBox(
                      width: 100.w,
                      height: 7.h,
                      child: ElevatedButton(
                          onPressed: () async {
                            final SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.setBool('TermsAndConditionStatus', true);
                            if (!mounted) return;
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => LoginScreen()));
                          },
                          child: Text(
                            "Accept Terms & Conditions",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12.sp),
                          )),
                    )),
                SizedBox(
                  height: 2.h,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
