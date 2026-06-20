import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const _headingStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppTheme.neutralBlack,
  );
  static const _bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.neutralDark,
    height: 1.5,
  );
  static const _subheadingStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppTheme.neutralDark,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Privacy Policy', centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingXL,
          vertical: AppTheme.spacingXXL,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 20,
          children: [
            ..._sections.map((s) => _buildSection(s)),
            _buildContactSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(_SectionData s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${s.number}. ${s.title}', style: _headingStyle),
        if (s.content != null) ...[
          const SizedBox(height: AppTheme.spacingS),
          Text(s.content!, style: _bodyStyle),
        ],
        for (final sub in s.subsections) ...[
          Text(sub.title, style: _subheadingStyle),
          if (sub.intro != null) ...[
            Text(sub.intro!, style: _bodyStyle),
          ],
          ...sub.bullets.map((b) => _bullet(b)),
        ],
        if (s.bullets != null) ...[
          ...s.bullets!.map(_bullet),
        ],
        if (s.footer != null) ...[
          Text(s.footer!, style: _bodyStyle),
        ],
      ],
    );
  }

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.only(left: 16),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('• ', style: _bodyStyle),
        Expanded(child: Text(text, style: _bodyStyle)),
      ],
    ),
  );

  Widget _buildContactSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('9. Contact Us', style: _headingStyle),
        Text(
          'If you have questions regarding this Privacy Policy, please contact us at',
          style: _bodyStyle,
        ),
        InkWell(
          onTap: () => _launchEmail('support@alzheimerassistant.com'),
          child: Row(
            children: [
              Icon(
                Icons.email_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'support@alzheimerassistant.com',
                style: _bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.primaryColor,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Icon(Icons.location_on, size: 18, color: AppTheme.errorColor),
            const SizedBox(width: 8),
            Text('Cairo, Egypt', style: _bodyStyle),
          ],
        ),
      ],
    );
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

class _SectionData {
  final int number;
  final String title;
  final String? content;
  final List<String>? bullets;
  final String? footer;
  final List<_Subsection> subsections;

  const _SectionData(
    this.number,
    this.title, {
    this.content,
    this.bullets,
    this.footer,
    this.subsections = const [],
  });
}

class _Subsection {
  final String title;
  final String? intro;
  final List<String> bullets;

  const _Subsection({required this.title, this.intro, required this.bullets});
}

final _sections = [
  const _SectionData(
    1,
    'Introduction',
    content:
        'Welcome to Alzheimer Assistant. Your privacy and data security are very important to us. This Privacy Policy explains how we collect, use, and protect personal and medical information when using our mobile application. By using the application, you agree to the practices described in this policy.',
  ),
  _SectionData(
    2,
    'Information We Collect',
    subsections: [
      _Subsection(
        title: 'Personal Information',
        bullets: [
          'Patient full name',
          'Date of birth',
          'Gender',
          'Contact Information',
          'Emergency contact details',
        ],
      ),
      _Subsection(
        title: 'Medical Information',
        bullets: [
          'Medical condition details',
          'Medication schedules',
          'Appointment records',
          'Health notes added by caregivers',
        ],
      ),
      _Subsection(
        title: 'Location Data',
        intro: 'We collect real-time location data of patients to:',
        bullets: [
          'Monitor their safety',
          'Detect if they leave safe zones',
          'Allow caregivers to track their live location',
        ],
      ),
      _Subsection(
        title: 'Camera Usage',
        intro: 'The application may access the device camera to:',
        bullets: [
          'Capture patient photos',
          'Store memory photos and videos',
          'Support face recognition features (if enabled)',
        ],
      ),
    ],
  ),
  const _SectionData(
    3,
    'How We use the Information',
    content: 'We use collected data to:',
    bullets: [
      'Provide patient monitoring services',
      'Send medication and appointment reminders',
      'Enable GPS tracking for safety',
      'Store memory photos and videos',
      'Improve care coordination',
    ],
    footer: 'We do not sell or share personal data with third parties.',
  ),
  const _SectionData(
    4,
    'Data Security',
    content:
        'We apply appropriate security measures to protect all stored data, including:',
    bullets: [
      'Encrypted storage',
      'Secure authentication',
      'Restricted access based on user roles',
    ],
    footer:
        'Only authorized caregivers and approved users can access patient information.',
  ),
  const _SectionData(
    5,
    'Data Sharing',
    content: 'Patient information is shared only with:',
    bullets: [
      'Authorized caregivers',
      'Approved family members (if added)',
      'Healthcare professionals (when necessary)',
    ],
    footer:
        'We never share information for advertising or commercial purposes.',
  ),
  const _SectionData(
    6,
    'User Permissions',
    content: 'The application requests permission to access:',
    bullets: ['Location services', 'Camera', 'Notifications', 'Media storage'],
    footer:
        'Users may disable these permissions at any time from device settings.',
  ),
  const _SectionData(
    8,
    'Updates to This Policy',
    content:
        'We may update this Privacy Policy to reflect improvements or legal changes. Users will be notified of any major updates.',
  ),
];
