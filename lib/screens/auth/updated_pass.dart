import 'package:flutter/material.dart';
import 'package:mindmate/themes/app_theme.dart';

class UpdatedPass extends StatefulWidget {
  const UpdatedPass({super.key});

  @override
  State<UpdatedPass> createState() => _UpdatedPassState();
}

class _UpdatedPassState extends State<UpdatedPass> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF1F6F9),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset('../assets/images/splash.png'),
            SizedBox(height: 21),
            Text(
              'Your password has been updated successfully',

              style: AppTheme.heading2,
            ),
          ],
        ),
      ),
    );
  }
}
