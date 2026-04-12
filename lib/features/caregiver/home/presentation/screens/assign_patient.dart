import 'package:flutter/material.dart';
import 'package:mindmate/core/utils/responsive.dart';
import 'package:mindmate/core/widgets/caregiver_bottom_nav.dart';
import 'package:mindmate/core/widgets/custom_elevated_button.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/utils/validation.utils.dart';
import 'package:mindmate/core/themes/app_theme.dart';

class AddPatient extends StatelessWidget {
  AddPatient({super.key});

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _relationshipController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: ProfileAppBar(title: 'Add New Patient'),
      body: SafeArea(
        minimum: EdgeInsets.symmetric(vertical: 40, horizontal: 25),
        child: Form(
          // key: _formKey,
          child: Column(
            children: [
              Column(
                spacing: AppTheme.spacingS,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Patient Email", style: AppTheme.label),
                  CustomTextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'example@gmail.com',
                    validator: (value) => ValidationUtils.validateEmail(value),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Relationship", style: AppTheme.label),
                  CustomTextFormField(
                    controller: _relationshipController,
                    keyboardType: TextInputType.name,
                    hintText: 'Enter your relationship to the patient',
                    validator: (value) => ValidationUtils.validateName(value),
                  ),
                ],
              ),

              // SizedBox(height: 200),
              // Wrap(
              //   children: [
              //     Icon(
              //       Icons.info_outline_rounded,
              //       color: AppTheme.successColor,
              //     ),
              //     Text(
              //       'A request will be sent to the patient. Access will be granted only after the patient approves your request.',
              //       // softWrap: true,
              //       style: TextStyle(overflow: TextOverflow.clip),
              //     ),
              //   ],
              // ),
              Spacer(),
              Wrap(
                spacing: 16,
                // mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomElevatedButton(
                    text: 'Add',
                    onPressed: () {},
                    size: Size(150.w, 45.h),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                  CustomElevatedButton(
                    text: 'Cancel',
                    onPressed: () {},
                    size: Size(150.w, 45.h),
                    backgroundColor: Color(0xffEB4335),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CaregiverBottomNav(),
    );
  }
}
