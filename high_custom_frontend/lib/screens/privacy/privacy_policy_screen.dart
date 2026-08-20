import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color primaryDark = Color(0xFF0F3B4F);
  static const Color primaryBlue = Color(0xFF2B6A9F);
  static const Color textColor = Color(0xFF2C4258);
  static const Color secondaryText = Color(0xFF5A6E7C);
  static const Color borderColor = Color(0xFFE2EDF2);
  static const Color backgroundColor = Color(0xFFF2F5F8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 680;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 12 : 32,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 1120,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        isMobile ? 20 : 32,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x14000000),
                          blurRadius: 35,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
                        isMobile ? 20 : 40,
                      ),
                      child: const _PrivacyPolicyContent(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PrivacyPolicyContent extends StatelessWidget {
  const _PrivacyPolicyContent();

  static const Color primaryDark = Color(0xFF0F3B4F);
  static const Color primaryBlue = Color(0xFF2B6A9F);
  static const Color textColor = Color(0xFF2C4258);
  static const Color secondaryText = Color(0xFF5A6E7C);
  static const Color borderColor = Color(0xFFE2EDF2);

  TextStyle get bodyStyle => const TextStyle(
        fontSize: 15,
        height: 1.6,
        color: textColor,
      );

  TextStyle get listStyle => const TextStyle(
        fontSize: 15,
        height: 1.55,
        color: Color(0xFF2C4E6E),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ============================================================
        // BRAND HEADER
        // ============================================================

        Row(
          children: [
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  colors: [
                    Color(0xFF1E3C5C),
                    Color(0xFF2B5B8B),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'HighCustomAI',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        Container(
          height: 2,
          color: const Color(0xFFEEF2F6),
        ),

        const SizedBox(height: 24),

        // ============================================================
        // TITLE
        // ============================================================

        ShaderMask(
          shaderCallback: (bounds) {
            return const LinearGradient(
              colors: [
                Color(0xFF0F2B3D),
                Color(0xFF1F5E8E),
              ],
            ).createShader(bounds);
          },
          child: Text(
            'HighCustomAI Privacy Policy',
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width < 540
                  ? 29
                  : 36,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ============================================================
        // INTRO
        // ============================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFBFEFE),
            borderRadius: BorderRadius.circular(18),
            border: const Border(
              left: BorderSide(
                color: primaryBlue,
                width: 5,
              ),
            ),
          ),
          child: const Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Last Updated: August 19, 2026\n\n',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1C3F5C),
                  ),
                ),
                TextSpan(
                  text:
                      'HighCustomAI ("HighCustomAI," "we," "us," or "our") respects your privacy and is committed to protecting your personal information and the information processed through our CRM and email communication services.\n\n',
                ),
                TextSpan(
                  text:
                      'This Privacy Policy explains how HighCustomAI collects, uses, stores, protects, and processes information when you use our website, CRM platform, applications, and integrations, including our integration with Google Gmail through Google OAuth and Google APIs.\n\n',
                ),
                TextSpan(
                  text:
                      'By accessing or using HighCustomAI, you acknowledge that you have read, understood, and agreed to this Privacy Policy.',
                ),
              ],
            ),
            style: TextStyle(
              fontSize: 15.5,
              height: 1.6,
              color: Color(0xFF1C3F5C),
            ),
          ),
        ),

        const SizedBox(height: 30),

        // ============================================================
        // SECTIONS
        // ============================================================

        _section(
          '1. Scope of This Privacy Policy',
          [
            _p(
              'This Privacy Policy applies to information processed through:',
            ),
            _list([
              'The HighCustomAI website.',
              'The HighCustomAI CRM platform.',
              'HighCustomAI user accounts.',
              'Google OAuth authentication.',
              'Gmail integration.',
              'Email-sending functionality.',
              'CRM contact and communication functionality.',
              'Other features and services made available through HighCustomAI.',
            ]),
            _p(
              'This Privacy Policy applies to information relating to HighCustomAI users and, where applicable, information relating to recipients of emails sent through the HighCustomAI platform.',
            ),
          ],
        ),

        _section(
          '2. Information We Collect',
          [
            _p(
              'HighCustomAI collects and processes only the information reasonably necessary to provide the services and functionality requested by users.',
            ),
            _p(
              'Depending on the features you use, we may collect or process the following categories of information.',
            ),
            _subheading('Account Information'),
            _p('This may include:'),
            _list([
              'Name.',
              'Email address.',
              'Company or organization information.',
              'Account information.',
              'Authentication information.',
              'Account preferences.',
              'Subscription or billing information, where applicable.',
            ]),
            _subheading('CRM Information'),
            _p(
              "When users use HighCustomAI's CRM functionality, the platform may process information entered by the user, including:",
            ),
            _list([
              'Customer names.',
              'Prospect names.',
              'Business contact information.',
              'Email addresses.',
              'Company information.',
              'Communication records.',
              'CRM notes.',
              'Sales-related information.',
              'Other information voluntarily entered by the user.',
            ]),
            _p(
              'Users are responsible for ensuring that information entered into the CRM is collected, used, and processed lawfully.',
            ),
          ],
        ),

        _section(
          '3. How We Use Google Data',
          [
            _p(
              'HighCustomAI uses information obtained through Google APIs only to provide the Google-related functionality that you explicitly authorize.',
            ),
            _p(
              'For the Gmail integration, Google-authorized access is used to:',
            ),
            _list([
              'Send emails through your connected Gmail account.',
              'Support email communication and automation workflows initiated or configured by you.',
              'Perform the specific Gmail functionality for which you have granted permission.',
            ]),
            _p(
              'HighCustomAI does not use Google user data for purposes unrelated to the functionality you have authorized.',
            ),
            _p(
              "HighCustomAI's access to and use of information received from Google APIs is subject to the Google API Services User Data Policy, including its Limited Use requirements.",
            ),
            _p(
              'HighCustomAI requests only the minimum permissions necessary to provide the relevant functionality and does not intentionally access or collect Google data beyond the scope of the permissions required for that functionality.',
            ),
          ],
        ),

        _section(
          '4. Why Gmail Access Is Required',
          [
            _p(
              "The Gmail permission requested by HighCustomAI is necessary because the platform provides functionality that allows an authenticated user to send business emails through the user's own connected Gmail account.",
            ),
            _p(
              'The requested Gmail permission enables HighCustomAI to perform the authorized email-sending operation on behalf of the user.',
            ),
            _p(
              "Without the required Gmail permission, HighCustomAI cannot send an email through the user's connected Gmail account.",
            ),
            _p(
              'HighCustomAI does not request broader Gmail mailbox permissions when those permissions are not required for the application\'s email-sending functionality.',
            ),
            _note(
              '🔐 HighCustomAI follows the principle of least privilege and requests only the permissions necessary to provide the functionality offered by the application.',
            ),
          ],
        ),

        _section(
          '5. Gmail Data We Access',
          [
            _p(
              'For Gmail email-sending functionality, HighCustomAI may process information necessary to perform the authorized email transmission.',
            ),
            _p('This may include:'),
            _list([
              "The user's authorized Gmail account identifier.",
              'Recipient email addresses.',
              'Email subjects.',
              'Email body content.',
              'Email attachments or files explicitly selected by the user for sending, where applicable.',
              'Sending information necessary to complete the email transmission.',
            ]),
            _p(
              "HighCustomAI does not request Gmail permissions for functionality unrelated to the services provided by the application.",
            ),
            _p(
              "HighCustomAI does not use the Gmail integration to obtain unrelated access to the user's mailbox.",
            ),
          ],
        ),

        _section(
          '6. Gmail Data We Do Not Access',
          [
            _p(
              'Unless separately authorized through a specific feature and corresponding Google permission, HighCustomAI does not request permission to:',
            ),
            _list([
              "Read the user's Gmail inbox.",
              "Search the user's Gmail mailbox.",
              'Modify existing Gmail messages.',
              'Delete Gmail messages.',
              'Manage Gmail labels.',
              'Read unrelated Gmail messages.',
              'Access unrelated mailbox information.',
            ]),
            _p(
              'HighCustomAI requests only the permissions required for the features actually provided by the application.',
            ),
          ],
        ),

        _section(
          '7. How We Use Google User Data',
          [
            _p(
              'Information received through Google APIs is used only to provide functionality requested and authorized by the user.',
            ),
            _p(
              'For the Gmail integration, Google user data may be used to:',
            ),
            _list([
              "Connect the user's authorized Gmail account to HighCustomAI.",
              "Send emails through the user's connected Gmail account.",
              'Support authorized CRM business communication workflows.',
              'Complete the email-sending functionality requested by the user.',
            ]),
            _boldP('HighCustomAI does not use Google user data for advertising.'),
            _boldP('HighCustomAI does not sell Google user data.'),
            _p(
              'HighCustomAI does not use Google user data for purposes unrelated to the functionality authorized by the user.',
            ),
          ],
        ),

        _section(
          '8. Google API Services User Data Policy',
          [
            _p(
              "HighCustomAI's access to and use of information received through Google APIs complies with the Google API Services User Data Policy, including applicable Limited Use requirements.",
            ),
            _p(
              'HighCustomAI follows the principle of least privilege when requesting Google API permissions.',
            ),
            _p(
              'HighCustomAI requests only the permissions necessary to provide the functionality described in this Privacy Policy.',
            ),
            _p(
              'HighCustomAI does not request access to Google user data that is unrelated to the functionality provided by the application.',
            ),
            _p(
              'Google user data is used only to provide the functionality requested and authorized by the user.',
            ),
          ],
        ),

        _section(
          '9. No Advertising or Sale of Google Data',
          [
            _p('HighCustomAI does not:'),
            _list([
              'Sell Google user data.',
              'Rent Google user data.',
              'Use Google user data for advertising.',
              'Use Google user data for targeted advertising.',
              'Use Google user data for unrelated commercial purposes.',
            ]),
            _p(
              "HighCustomAI's revenue model does not depend on selling Google user data.",
            ),
          ],
        ),

        _section(
          '10. AI and Machine Learning',
          [
            _p(
              'HighCustomAI does not use Google Workspace or Gmail user data to:',
            ),
            _list([
              'Train generalized artificial intelligence models.',
              'Train generalized machine-learning models.',
              'Develop generalized AI models.',
              'Improve generalized AI models.',
              'Improve generalized machine-learning models.',
            ]),
            _p(
              'HighCustomAI does not transfer Google Workspace or Gmail user data to third-party AI or machine-learning providers for the purpose of training or improving generalized AI or machine-learning models.',
            ),
            _p(
              'HighCustomAI does not use Gmail data to create generalized AI or machine-learning products.',
            ),
          ],
        ),

        _section(
          '11. Third-Party AI Services',
          [
            _p(
              'HighCustomAI does not use OpenAI, Google Gemini, Anthropic Claude, or other third-party AI or machine-learning providers to process Google Workspace or Gmail user data for generalized model training.',
            ),
            _p(
              'Google user data obtained through Google APIs is not transferred to third-party AI or machine-learning services for generalized model training or improvement.',
            ),
          ],
        ),

        _section(
          '12. Email Communication',
          [
            _p(
              'When a user sends an email through HighCustomAI, the platform may process information necessary to complete the requested communication.',
            ),
            _p('This may include:'),
            _list([
              'Sender email address.',
              'Recipient email address.',
              'Email subject.',
              'Email body.',
              'Attachments explicitly selected by the user for sending.',
              'Date and time of transmission.',
              'Email delivery or transmission status.',
            ]),
            _p(
              'This information is processed only for providing the email communication functionality requested by the user and for associated operational purposes.',
            ),
          ],
        ),

        _section(
          '13. Email Content',
          [
            _p(
              'HighCustomAI may temporarily process email content when technically necessary to prepare, transmit, or otherwise complete an authorized email.',
            ),
            _p(
              'Email content is not used for advertising or unrelated purposes.',
            ),
            _p(
              'HighCustomAI does not use email content received through the Gmail integration to train generalized AI or machine-learning models.',
            ),
            _p(
              'Where email information is stored as part of an explicitly provided CRM feature, that information may be retained for the period reasonably necessary to provide the applicable feature.',
            ),
          ],
        ),

        _section(
          '14. CRM Communication Records',
          [
            _p(
              'Where the CRM provides communication history or activity records, HighCustomAI may store information necessary to display, maintain, or manage those records.',
            ),
            _p('Such information may include:'),
            _list([
              'Recipient email address.',
              'Sender email address.',
              'Email subject.',
              'Date and time.',
              'Communication status.',
              'CRM contact information.',
              "Other information generated through the user's use of the CRM.",
            ]),
            _p(
              'HighCustomAI stores such information only for legitimate operational purposes associated with providing the CRM service.',
            ),
          ],
        ),

        _section(
          '15. Data Controller and Data Processor Roles',
          [
            _p(
              'Depending on the nature of the service and the relationship with the customer, HighCustomAI may act as either a Data Controller or Data Processor.',
            ),
            _subheading('HighCustomAI as Data Controller'),
            _p(
              'HighCustomAI may act as a Data Controller for information relating to:',
            ),
            _list([
              'User accounts.',
              'Account administration.',
              'Authentication.',
              'Billing.',
              'Customer support.',
              'Website operation.',
              'Security and fraud prevention.',
            ]),
            _subheading('HighCustomAI as Data Processor'),
            _p(
              'When a business uses HighCustomAI to manage its customers, leads, contacts, or business communications, HighCustomAI may process such information on behalf of that business.',
            ),
            _p(
              'In those circumstances, the business customer may determine:',
            ),
            _list([
              'What information is entered into the CRM.',
              'Why the information is processed.',
              'Which customers or prospects are contacted.',
              'What communications are sent.',
              'How the information is used.',
            ]),
            _p(
              "HighCustomAI processes such information according to the customer's instructions and applicable data protection requirements.",
            ),
          ],
        ),

        _section(
          '16. Business Customer Responsibilities',
          [
            _p(
              'Businesses using HighCustomAI are responsible for ensuring that their use of the platform complies with applicable privacy and data protection laws.',
            ),
            _p('This includes, where applicable:'),
            _list([
              'Having a lawful basis for processing personal information.',
              'Providing appropriate privacy notices.',
              'Obtaining consent where required.',
              'Respecting marketing and communication preferences.',
              'Responding to applicable data-subject requests.',
              'Ensuring that contact information is collected and processed lawfully.',
            ]),
            _p(
              'HighCustomAI provides technical functionality but does not determine the legal basis for a customer\'s individual business communications.',
            ),
          ],
        ),

        _section(
          '17. Recipient Privacy',
          [
            _p(
              'If you receive an email sent through HighCustomAI, the business or individual who sent the email may be responsible for determining the purpose and legal basis for the communication.',
            ),
            _p('The sender may determine:'),
            _list([
              'Why your email address was collected.',
              'Why the email was sent.',
              'What information is included in the communication.',
              'How the communication is used.',
              'How long the sender retains your information.',
            ]),
            _p(
              'Where HighCustomAI acts only as a processor for the sender, the sender or business customer remains responsible for applicable data-controller obligations.',
            ),
            _p(
              'Recipients may contact the sender or organization responsible for the communication regarding their applicable privacy rights.',
            ),
            _p(
              'HighCustomAI may assist its business customers with applicable privacy requests where required by law or contractual arrangements.',
            ),
          ],
        ),

        _section(
          '18. Data Security',
          [
            _p(
              'HighCustomAI implements reasonable technical and organizational measures designed to protect personal information and Google user data.',
            ),
            _p('These measures may include:'),
            _list([
              'Encryption of data in transit using TLS.',
              'Secure authentication.',
              'Access controls.',
              'Restricted access to application data.',
              'Secure handling of OAuth credentials and tokens.',
              'Protection of application infrastructure.',
              'Security monitoring.',
              'Regular maintenance and security reviews.',
            ]),
            _p(
              'Access to personal information is limited to authorized personnel or service providers who require access for legitimate business or technical purposes.',
            ),
            _p(
              'Although no online system can guarantee absolute security, HighCustomAI continuously works to maintain and improve its security practices.',
            ),
          ],
        ),

        _section(
          '19. OAuth Token Security',
          [
            _p(
              'Where OAuth tokens are required to maintain an authorized Google connection, HighCustomAI stores and handles those tokens using appropriate security controls.',
            ),
            _p(
              'OAuth tokens are used only to maintain the authorized integration and provide functionality approved by the user.',
            ),
            _p(
              'HighCustomAI does not sell or disclose OAuth tokens for advertising or unrelated purposes.',
            ),
          ],
        ),

        _section(
          '20. Third-Party Service Providers',
          [
            _p(
              'HighCustomAI may use third-party infrastructure and service providers that are necessary to operate and maintain the application.',
            ),
            _p(
              'Depending on the actual infrastructure used, these providers may include services for:',
            ),
            _list([
              'Cloud hosting.',
              'Database infrastructure.',
              'Authentication.',
              'Security.',
              'Application infrastructure.',
              'Email delivery.',
              'Customer support.',
              'Payment processing.',
            ]),
            _p(
              'Third-party providers may process information only as necessary to provide their services to HighCustomAI or as otherwise permitted by applicable law.',
            ),
            _p(
              'HighCustomAI does not authorize third-party service providers to use Google user data for advertising or generalized AI/ML model training.',
            ),
          ],
        ),

        _section(
          '21. International Data Transfers',
          [
            _p(
              'HighCustomAI may use service providers located in countries outside the country where a user is located.',
            ),
            _p(
              'Where personal information is transferred internationally, HighCustomAI will use appropriate safeguards required by applicable data protection laws.',
            ),
            _p(
              'Depending on the circumstances, these safeguards may include:',
            ),
            _list([
              'Adequacy decisions.',
              'Standard Contractual Clauses.',
              'Appropriate contractual protections.',
              'Other legally recognized transfer mechanisms.',
            ]),
          ],
        ),

        _section(
          '22. Data Retention',
          [
            _p(
              'HighCustomAI retains information only for as long as reasonably necessary to:',
            ),
            _list([
              'Provide the requested services.',
              'Maintain the CRM.',
              'Complete authorized email communications.',
              'Maintain account functionality.',
              'Provide customer support.',
              'Maintain security.',
              'Prevent fraud and abuse.',
              'Comply with legal obligations.',
              'Resolve disputes.',
              'Enforce applicable agreements.',
            ]),
            _p(
              'Retention periods may vary depending on the type of information and the functionality being used.',
            ),
            _p(
              'When information is no longer required, HighCustomAI will delete or anonymize it where reasonably appropriate, subject to legal or legitimate operational requirements.',
            ),
          ],
        ),

        _section(
          '23. Google Data Retention',
          [
            _p(
              'HighCustomAI does not retain Gmail data longer than reasonably necessary to provide the authorized functionality.',
            ),
            _p(
              'Where information is required to complete an email transmission, it may be processed for the period necessary to perform that operation.',
            ),
            _p(
              'Where a user explicitly uses a CRM feature that stores communication history, information required for that feature may be retained for the applicable operational period.',
            ),
            _p(
              'HighCustomAI does not retain Google user data for advertising or unrelated purposes.',
            ),
          ],
        ),

        _section(
          '24. User Control and Google Access Revocation',
          [
            _p(
              'Users remain in control of their Google account permissions.',
            ),
            _p(
              "Users may revoke HighCustomAI's access to their Google account at any time through their Google Account security settings.",
            ),
            _p(
              'After Google access is revoked, HighCustomAI will no longer be able to access Google data through the revoked authorization.',
            ),
            _p(
              'Revoking Google access does not automatically delete information previously stored in the HighCustomAI account.',
            ),
            _p(
              'Users may separately request deletion of applicable HighCustomAI account information.',
            ),
          ],
        ),

        _section(
          '25. Data Deletion',
          [
            _p(
              'Users may request deletion of their HighCustomAI account and applicable personal information.',
            ),
            _p(
              'A deletion request may be submitted using the contact details provided in this Privacy Policy.',
            ),
            _p(
              'Upon receiving a valid deletion request, HighCustomAI will delete applicable information within a reasonable period, subject to:',
            ),
            _list([
              'Applicable legal obligations.',
              'Security requirements.',
              'Fraud prevention.',
              'Dispute resolution.',
              'Contractual requirements.',
              'Information that must legally be retained.',
            ]),
            _p(
              'Users who no longer want HighCustomAI to access their Gmail account should also revoke the Google authorization through their Google Account settings.',
            ),
          ],
        ),

        _section(
          '26. GDPR Rights',
          [
            _p(
              'Where GDPR applies, individuals may have the following rights:',
            ),
            _subheading('Right of Access'),
            _p(
              'You may request a copy of personal information held about you.',
            ),
            _subheading('Right to Rectification'),
            _p(
              'You may request correction of inaccurate or incomplete information.',
            ),
            _subheading('Right to Erasure'),
            _p(
              'You may request deletion of your personal information where applicable.',
            ),
            _subheading('Right to Restriction'),
            _p(
              'You may request restriction of processing in certain circumstances.',
            ),
            _subheading('Right to Data Portability'),
            _p(
              'Where applicable, you may request your information in a structured, commonly used, and machine-readable format.',
            ),
            _subheading('Right to Object'),
            _p(
              'You may object to certain processing activities where permitted by applicable law.',
            ),
            _subheading('Right to Withdraw Consent'),
            _p(
              'Where processing is based on consent, you may withdraw your consent at any time. Withdrawal of consent does not affect processing that occurred lawfully before withdrawal.',
            ),
          ],
        ),

        _section(
          '27. Exercising Your Privacy Rights',
          [
            _p(
              'To exercise applicable privacy rights, request deletion, request access to information, or raise a privacy concern, please contact HighCustomAI using the contact details provided below.',
            ),
            _p(
              'We may request information necessary to verify your identity before fulfilling certain requests.',
            ),
            _p(
              'HighCustomAI will process valid requests in accordance with applicable data protection laws.',
            ),
            _p(
              'Where HighCustomAI acts as a Data Processor on behalf of a business customer, the relevant business customer may be the appropriate Data Controller responsible for responding to the request.',
            ),
            _p(
              'In such circumstances, HighCustomAI may assist the business customer as required by applicable law and contractual arrangements.',
            ),
          ],
        ),

        _section(
          '28. Cookies',
          [
            _p(
              'HighCustomAI may use cookies and similar technologies for purposes such as:',
            ),
            _list([
              'Authentication.',
              'Security.',
              'Website functionality.',
              'User preferences.',
              'Performance.',
              'Service improvement.',
            ]),
            _p(
              'Where required by applicable law, non-essential cookies will be used only after obtaining appropriate consent.',
            ),
          ],
        ),

        _section(
          "29. Children's Privacy",
          [
            _p(
              'HighCustomAI is intended primarily for business and professional use.',
            ),
            _p(
              'HighCustomAI does not knowingly collect personal information from children in violation of applicable law.',
            ),
            _p(
              'If you believe that a child has provided personal information to HighCustomAI in circumstances where such collection was not permitted, please contact us.',
            ),
          ],
        ),

        _section(
          '30. Security Incidents',
          [
            _p(
              'HighCustomAI maintains procedures designed to identify, investigate, and respond to security incidents.',
            ),
            _p(
              'Where required by applicable law, HighCustomAI will notify relevant customers, authorities, or affected individuals regarding a personal data breach within the legally required timeframe.',
            ),
            _p(
              'Where HighCustomAI acts as a Data Processor, it will notify the relevant business customer in accordance with applicable legal and contractual requirements.',
            ),
          ],
        ),

        _section(
          '31. Legal Basis for Processing',
          [
            _p(
              'Where GDPR or another applicable data protection law applies, HighCustomAI may process personal information based on:',
            ),
            _list([
              'Performance of a contract.',
              'Steps taken at the request of the user before entering into a contract.',
              'Compliance with a legal obligation.',
              'Legitimate interests, where permitted by law.',
              'Consent, where required.',
            ]),
            _p(
              'The applicable legal basis depends on the nature and purpose of the processing.',
            ),
          ],
        ),

        _section(
          '32. Changes to This Privacy Policy',
          [
            _p(
              'HighCustomAI may update this Privacy Policy from time to time to reflect:',
            ),
            _list([
              'Changes to the service.',
              'New features.',
              'Changes in technology.',
              'Changes in data-processing practices.',
              'Changes in applicable laws.',
              'Security improvements.',
            ]),
            _p(
              'When material changes are made, the updated Privacy Policy will be published on this page and the "Last Updated" date will be revised.',
            ),
          ],
        ),

        // ============================================================
        // 33 CONTACT
        // ============================================================

        _section(
          '33. Contact Information',
          [
            _p(
              'For questions regarding this Privacy Policy, Google account access, Gmail data, data deletion, GDPR rights, or other privacy concerns, please contact HighCustomAI.',
            ),
            _contactRow(
              'Website',
              'https://highcustomai.com/',
            ),
            _contactRow(
              'Privacy Email',
              'INSERT YOUR PRIVACY EMAIL',
            ),
            _contactRow(
              'Security Email',
              'INSERT YOUR SECURITY EMAIL',
            ),
            _contactRow(
              'Data Protection Officer',
              'INSERT DPO DETAILS IF APPLICABLE',
            ),
            _p(
              'HighCustomAI will respond to applicable privacy requests within the timeframe required by applicable law.',
            ),
          ],
        ),

        // ============================================================
        // 34 GOOGLE LIMITED USE
        // ============================================================

        _section(
          '34. Google API Limited Use Disclosure',
          [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FA),
                borderRadius: BorderRadius.circular(18),
                border: const Border(
                  left: BorderSide(
                    color: Color(0xFF3685B5),
                    width: 4,
                  ),
                ),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryBlue,
                    size: 22,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "HighCustomAI's use and transfer of information received from Google APIs adheres to the Google API Services User Data Policy, including applicable Limited Use requirements.",
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.55,
                        color: Color(0xFF155A7E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _p(
              'HighCustomAI requests only the minimum Google API permissions necessary to provide the application\'s authorized functionality.',
            ),
            _p(
              'For Gmail functionality, the requested permission is used to allow the authenticated user to send emails through their connected Gmail account.',
            ),
            _p('HighCustomAI does not:'),
            _list([
              'Use Google user data for advertising.',
              'Sell Google user data.',
              'Use Google Workspace or Gmail user data to train generalized AI or machine-learning models.',
              'Use Google Workspace or Gmail user data to develop generalized AI or machine-learning models.',
              'Use Google Workspace or Gmail user data to improve generalized AI or machine-learning models.',
              'Transfer Google Workspace or Gmail user data to third-party AI or machine-learning providers for generalized model training or improvement.',
            ]),
            _p(
              "Users can revoke HighCustomAI's access to their Google account at any time through their Google Account settings.",
            ),
          ],
        ),

        // ============================================================
        // 35 PRIVACY PRINCIPLES
        // ============================================================

        _section(
          '35. Our Privacy Principles',
          [
            _p(
              'HighCustomAI follows these principles when processing personal information:',
            ),
            _principle(
              'Data Minimization',
              'We request and process only the information necessary for the functionality provided.',
            ),
            _principle(
              'Purpose Limitation',
              'Information is used only for legitimate and disclosed purposes.',
            ),
            _principle(
              'Least Privilege',
              'Google API permissions are limited to the functionality that requires them.',
            ),
            _principle(
              'Security',
              'We use reasonable technical and organizational safeguards to protect information.',
            ),
            _principle(
              'Transparency',
              'We explain how information is collected and processed.',
            ),
            _principle(
              'User Control',
              'Users can revoke Google authorization and request applicable data deletion.',
            ),
            _principle(
              'Responsible Processing',
              'We process personal information in accordance with applicable privacy and data protection requirements.',
            ),
          ],
        ),

        // ============================================================
        // FOOTER
        // ============================================================

        const Divider(
          color: borderColor,
          height: 40,
        ),

        Center(
          child: Column(
            children: [
              const Text(
                'HighCustomAI',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4A627A),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Website:',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  // Add url_launcher here if you want the website clickable.
                },
                child: const Text(
                  'https://highcustomai.com/',
                  style: TextStyle(
                    color: primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Last Updated: August 19, 2026',
                style: TextStyle(
                  color: secondaryText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION
  // ============================================================

  Widget _section(
    String title,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: primaryDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 2,
            width: 70,
            color: const Color(0xFFE4EEF5),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  // ============================================================
  // PARAGRAPH
  // ============================================================

  Widget _p(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: bodyStyle,
      ),
    );
  }

  // ============================================================
  // BOLD PARAGRAPH
  // ============================================================

  Widget _boldP(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          height: 1.6,
          color: textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ============================================================
  // SUBHEADING
  // ============================================================

  Widget _subheading(String text) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 8,
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: primaryDark,
        ),
      ),
    );
  }

  // ============================================================
  // LIST
  // ============================================================

  Widget _list(List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        bottom: 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items.map(
          (item) {
            return Padding(
              padding: const EdgeInsets.only(
                bottom: 9,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 2,
                      right: 10,
                    ),
                    child: Text(
                      '▹',
                      style: TextStyle(
                        color: primaryBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: listStyle,
                    ),
                  ),
                ],
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  // ============================================================
  // NOTE
  // ============================================================

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        top: 4,
        bottom: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          height: 1.55,
          color: textColor,
        ),
      ),
    );
  }

  // ============================================================
  // CONTACT ROW
  // ============================================================

  Widget _contactRow(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 14,
      ),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '$title: ',
            style: const TextStyle(
              fontSize: 15,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FA),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F6392),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PRINCIPLE
  // ============================================================

  Widget _principle(
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(
              top: 3,
              right: 10,
            ),
            child: Text(
              '▹',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 16,
              ),
            ),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: textColor,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                  TextSpan(
                    text: description,
                    style: const TextStyle(
                      color: Color(0xFF2C4E6E),
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}