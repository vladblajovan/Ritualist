# Legal Setup Guide for Ritualist

**Last Updated:** November 25, 2025

This guide provides implementation details for the legal documents and recommended contact information setup.

---

## 1. Support Email Configuration

### 1.1 Recommended Email Addresses

We recommend setting up the following email addresses for Ritualist:

```
support@ritualist.app      - General support and customer service
privacy@ritualist.app      - Privacy requests, GDPR/CCPA inquiries
security@ritualist.app     - Security vulnerabilities and bug reports
legal@ritualist.app        - Legal inquiries and disputes (optional)
```

### 1.2 Email Setup Instructions

**Using Gmail or similar provider:**
1. Create a dedicated inbox or label for Ritualist legal emails
2. Set up email forwarding rules:
   - support@ → forward to your main email
   - privacy@ → forward to your main email
   - security@ → forward to your main email
3. Set up auto-responders for each address:

**Sample Auto-Responder Message:**

```
Thank you for contacting Ritualist support.

We have received your message and will respond within 30 days.

For urgent issues, please clearly mark your email as "URGENT."

Expected Response Times:
- Privacy/GDPR requests: 30 days
- Security vulnerabilities: 48 hours (if critical)
- General support: 3-7 business days

Best regards,
Ritualist Support Team
Developed by Vlad Blajovan
```

### 1.3 Email Response Template

When responding to user requests, use this template:

```
Subject: Re: [Your Original Subject]

Dear [User Name],

Thank you for contacting Ritualist support.

[Your response here - customize based on the inquiry type]

If you have any follow-up questions, please reply to this email.

Best regards,
Ritualist Support
ritualist.app

---
Ritualist is developed by Vlad Blajovan.
For privacy concerns: privacy@ritualist.app
For security issues: security@ritualist.app
```

---

## 2. Legal Compliance Checklist

### 2.1 Pre-Launch Checklist

Before publishing Ritualist to the App Store, ensure:

- [ ] Privacy Policy is published on ritualist.app website
- [ ] Terms of Service is published on ritualist.app website
- [ ] Links to both documents are in the App Store listing
- [ ] Email addresses are configured (support, privacy, security)
- [ ] Privacy Policy is linked in App > Settings > Privacy
- [ ] Terms of Service are linked in App > Settings > Legal
- [ ] Apple's App Store page links to Privacy Policy
- [ ] iOS permissions are properly documented:
  - [ ] Location permissions explanation
  - [ ] Push notification permissions explanation
  - [ ] Calendar permissions (if applicable)

### 2.2 GDPR Compliance Checklist

For EU Users:

- [ ] Privacy Policy includes GDPR-specific language (included)
- [ ] Data processing basis is clearly stated (included)
- [ ] User rights are documented (Section 10.2)
- [ ] Data portability mechanism is available (JSON export)
- [ ] Data deletion process is documented (Section 4.2)
- [ ] Privacy email is monitored and requests are fulfilled within 30 days
- [ ] No marketing emails sent to EU users without explicit consent
- [ ] Location data collection has explicit consent mechanism
- [ ] CloudKit data processors (Apple) are documented
- [ ] GDPR compliance can be demonstrated to authorities if needed

### 2.3 CCPA Compliance Checklist

For California Users:

- [ ] Privacy Policy includes CCPA-specific language (included)
- [ ] Right to Know is documented (Section 10.3)
- [ ] Right to Delete is documented (Section 10.3)
- [ ] Right to Correct is documented (Section 10.3)
- [ ] Right to Opt-Out is documented (Section 10.3)
- [ ] Right to Non-Discrimination is documented (Section 10.3)
- [ ] "Shine the Light" law is addressed (Section 10.3)
- [ ] User rights summary table is provided (Section 16)
- [ ] Data sale disclosure: clearly states that data is NOT sold
- [ ] Third-party sharing disclosure is comprehensive
- [ ] Requests can be fulfilled within 45 days
- [ ] Consumer can designate an authorized representative

### 2.4 Apple App Store Compliance

Before submission, ensure:

- [ ] App Privacy statement in App Store Connect is filled out:
  - [ ] Health & Fitness data (if location/health data is collected)
  - [ ] Location data (required for geofencing)
  - [ ] User ID (if any tracking is implemented)
  - [ ] Other identifiers (device identifiers, IP address, etc.)
- [ ] All required permissions are justified:
  - [ ] Location (required for geofencing feature)
  - [ ] Calendar (if integration is planned)
  - [ ] Reminders (if integration is planned)
- [ ] In-App Purchase disclosures:
  - [ ] Subscription terms are clearly disclosed
  - [ ] Auto-renewal terms are clear
  - [ ] Cancellation method is documented
  - [ ] Refund policy is linked
- [ ] Privacy Policy is linked in App Store description
- [ ] Terms of Service are accessible in-App or via website

---

## 3. In-App Legal Disclosures

### 3.1 Required Settings Screens

Create the following screens in Ritualist's Settings menu:

**Settings > Privacy**
- Toggle: "Enable Personality Analysis"
- Link: "Privacy Policy" → Opens ritualist.app/privacy
- Link: "Delete My Data" → Shows contact form for privacy@ritualist.app

**Settings > Legal**
- Link: "Terms of Service" → Opens ritualist.app/terms
- Link: "Privacy Policy" → Opens ritualist.app/privacy
- Text: "Version [app version]"
- Text: "Last Updated: [date]"

**Settings > Location**
- Explanation: "Geofencing helps Ritualist remind you of habits when you're in a specific location. Location data is never shared with third parties and only stored on your device."
- Link: "Location Privacy" → Opens ritualist.app/privacy#location

**Settings > Subscription**
- Display current subscription status
- Link: "Manage Subscription" → Opens App Store subscription manager
- Link: "Refund Policy" → Opens ritualist.app/terms#refunds

### 3.2 Permission Request Messages

When requesting iOS permissions, use clear language:

**Location Permission (First Launch)**
```
Ritualist wants to access your location to enable location-based habit reminders.

Your location data is stored only on your device and synced via iCloud if enabled.
It is never shared with third parties.

Allow location access to use geofencing features.
```

**Push Notification Permission**
```
Ritualist would like to send you notifications for habit reminders and achievements.

You can manage notifications anytime in Settings > Notifications.
```

**Calendar Permission (If Planned)**
```
Ritualist can sync your habits with your calendar.

Your calendar data is stored securely and not shared with others.
```

---

## 4. Website Implementation

### 4.1 Website Legal Pages

On ritualist.app, create these pages:

**Page: /privacy**
- Full Privacy Policy (PRIVACY_POLICY.md)
- Easily printable format
- Last updated date prominently displayed
- Contact form for privacy requests

**Page: /terms**
- Full Terms of Service (TERMS_OF_SERVICE.md)
- Easily printable format
- Last updated date prominently displayed
- Table of contents for navigation

**Page: /support**
- Support contact form
- FAQ section
- Known issues
- Troubleshooting guides
- Email: support@ritualist.app

### 4.2 Footer Links

Add to website footer:
```
[Privacy Policy](https://ritualist.app/privacy) |
[Terms of Service](https://ritualist.app/terms) |
[Support](https://ritualist.app/support)
```

### 4.3 App Store Description

In App Store Connect, include in the app description:
```
PRIVACY & LEGAL:
- Privacy Policy: ritualist.app/privacy
- Terms of Service: ritualist.app/terms
- No account required - uses Apple ID for iCloud sync
- No third-party analytics
- Location data never shared
```

---

## 5. Data Subject Access Request (DSAR) Process

### 5.1 Receiving a Request

When you receive an email to privacy@ritualist.app, check:
1. Is this a valid DSAR/CCPA/GDPR request?
2. Does the request include identifying information?
3. Is the requester the account holder or authorized representative?

### 5.2 Verification Steps

For GDPR requests (30-day deadline):
1. Email the requester asking them to confirm:
   - Their name
   - The Apple ID email address associated with their account
   - The date range of data they're requesting
2. For additional verification:
   - Ask them to confirm last access date/time
   - Ask them to confirm a habit name they created
   - Ask them to confirm when they last used the App

For CCPA requests (45-day deadline):
1. Same verification as above
2. Must verify identity with 2 pieces of identifying information

### 5.3 Fulfilling the Request

**For Data Access Requests:**
1. Access the user's habit data (if stored in your backend - note: Ritualist is serverless)
2. Since Ritualist is serverless:
   - You maintain no user data on your servers
   - Direct user to export their data via: Settings > Data & Privacy > Export Data
   - Explain that their data is stored in their iCloud account (Apple's responsibility)
   - Provide link to Apple's data request process
3. Send the data in a commonly used format (JSON from the App)
4. Include a summary of what data exists

**For Data Deletion Requests:**
1. Acknowledge the request
2. Explain that since the app is serverless, their data is stored on:
   - Their local iOS device (they can delete by uninstalling the app)
   - Their iCloud account (they can manage through Apple ID settings)
3. Document that you have no server-side data to delete
4. Provide instructions for deleting iCloud data
5. Confirm deletion within 30-45 days

**For Data Correction Requests:**
1. Explain that users can edit their data directly in the App
2. Users should make corrections themselves for accuracy
3. Assist with any technical issues preventing corrections

### 5.4 Documentation

Keep records of:
- Date request was received
- Type of request (access, deletion, correction, etc.)
- Verification steps taken
- Date response was sent
- How the request was fulfilled
- Keep records for minimum 3 years

### 5.5 Response Email Template

```
Subject: Your Data Request - [Request Type]

Dear [User Name],

Thank you for submitting a Data Subject Access Request / Privacy Request
regarding your Ritualist account.

[CUSTOM RESPONSE BASED ON REQUEST TYPE]

If you have any questions about this response or need further assistance,
please reply to this email.

Best regards,
Ritualist Privacy Team
privacy@ritualist.app

---
Ritualist is developed by Vlad Blajovan.
```

---

## 6. Data Deletion and Retention Policy

### 6.1 User-Initiated Deletion

When a user deletes their account or data:
1. Local app data is deleted when they uninstall the App
2. iCloud data persists in their iCloud account (managed by Apple)
3. User can delete iCloud data through:
   - Settings > [Their Name] > iCloud > Manage Storage > Ritualist
4. Or through: Delete Data in App > Settings > Data & Privacy

### 6.2 Automatic Deletion

Since Ritualist is serverless, there is no automatic server-side deletion schedule.

However, if you ever implement a server component, implement:
- 90-day inactivity deletion (optional, with notice to user)
- 1-year grace period after account deletion (for recovery)
- Compliance with regional retention requirements

### 6.3 Breach Scenario - Data Retention

If a security breach is discovered:
1. Document the breach immediately
2. Assess the impact and affected data types
3. Notify affected users within 30 days (GDPR) or 60 days (CCPA)
4. Include in notification:
   - What data was affected
   - When the breach occurred
   - What security measures you implemented
   - What steps users should take
5. Retain records of the breach for regulatory review

---

## 7. Marketing and Email Compliance

### 7.1 Push Notifications Compliance

Push notifications sent through the App must:
- Be relevant to app functionality
- Include a clear way to disable in Settings
- Never be unsolicited or excessive
- Comply with Apple's guidelines on push notification use

**Sample compliant notifications:**
- "Your morning routine habit is due today"
- "Congratulations! 7-day streak on fitness"
- "Version 2.0 now available with new features"

**Non-compliant notifications:**
- "Buy our premium subscription now!"
- "Check out these cool apps..."
- "Rate us 5 stars!"

### 7.2 Promotional Email Compliance (If Added)

If you ever add email opt-in for newsletters:

**CAN-SPAM Compliance (USA):**
- Include unsubscribe link in every email
- Honor unsubscribe requests within 10 days
- Include your physical address
- Accurate subject lines
- Identify as promotional content

**GDPR Compliance (EU):**
- Explicit opt-in required (not pre-checked)
- Allow easy opt-out
- Keep records of consent
- Honor opt-out immediately

**CASL Compliance (Canada):**
- Express written consent required
- Identify company name
- Include unsubscribe mechanism
- Unsubscribe within 10 days

**Note:** Currently, Ritualist does not send marketing emails beyond app-based notifications. If this changes, update this policy.

---

## 8. Third-Party Integrations Compliance

### 8.1 Current Status: No Third-Party Analytics

Ritualist currently uses:
- Apple's built-in App Analytics (required by App Store)
- iCloud CloudKit for data sync
- Apple's crash reporting

This is compliant because:
- Apple's analytics don't track individual users
- CloudKit is Apple's service, covered by their privacy policy
- No third-party data brokers

### 8.2 If You Add Third-Party Services

If you integrate any third-party service (Analytics, CRM, etc.), you MUST:

1. **Update Privacy Policy:**
   - Disclose the third-party service
   - Explain what data is shared
   - Link to their privacy policy
   - Provide opt-out mechanism

2. **Get User Consent:**
   - Request explicit permission before sharing data
   - Allow easy opt-out
   - Never force users to consent

3. **Sign Data Processor Agreement:**
   - Ensure GDPR DPA is in place
   - Verify CCPA compliance
   - Document the data processing

4. **Update Terms of Service:**
   - Disclose the third-party service
   - Explain potential data sharing

---

## 9. App Store Connect Setup

### 9.1 Privacy Label (App Store Connect)

In App Store Connect, fill out the Privacy Label under "App Privacy":

**Data Categories to Disclose:**

```
Location:
  ✓ Precise Location (for geofencing)
  Purpose: Location-based reminders
  Used for: Habit reminders
  Not linked to identity: TRUE
  Not sold: TRUE

Identifiers:
  ✓ User ID (if any tracking implemented)
  Purpose: Habit tracking and sync
  Linked to identity: FALSE (uses Apple ID)
  Sold: FALSE

Health & Fitness:
  ✓ Fitness (if tracking fitness habits)
  Purpose: Habit tracking
  Linked to identity: FALSE
  Sold: FALSE

Other Data:
  ✓ Habit/pattern data (if applicable)
  Purpose: App functionality and analytics
  Linked to identity: FALSE
  Sold: FALSE
```

### 9.2 Subscription Information

In App Store Connect, provide:

**Subscription Details:**
- Weekly: $2.99/week (auto-renewing)
- Monthly: $9.99/month (auto-renewing)
- Annual: $49.99/year (auto-renewing)
- Lifetime: $99.99 (one-time purchase)

**Renewal Terms:**
- Auto-renew: Yes (for subscriptions)
- Cancellation must be stated: "Cancel anytime through Settings > Subscriptions"

**Legal Documents:**
- Link to Terms of Service: ritualist.app/terms
- Link to Privacy Policy: ritualist.app/privacy

---

## 10. Monitoring and Updates

### 10.1 Quarterly Compliance Review

Every 3 months, review:
- [ ] Are privacy laws changing in key markets?
- [ ] Have we added new data processing activities?
- [ ] Have we received any privacy complaints?
- [ ] Is our Privacy Policy current?
- [ ] Is our Terms of Service current?
- [ ] Are our contact emails being monitored?

### 10.2 Annual Audit

Yearly, conduct:
- [ ] GDPR compliance audit
- [ ] CCPA compliance audit
- [ ] Apple App Store compliance review
- [ ] Data processing review
- [ ] Third-party service review
- [ ] Update documents if needed

### 10.3 Regulatory Changes

Monitor these sources for updates:
- GDPR enforcement actions (edpb.europa.eu)
- CCPA regulations (oag.ca.gov)
- Apple's App Store guidelines (apple.com/app-store/review/guidelines/)
- iOS privacy features (apple.com/privacy)

---

## 11. Incident Response Plan

### 11.1 Security Breach Protocol

If a security breach is discovered:

**Immediate (Within 1 hour):**
1. Assess the scope of the breach
2. Determine what data was affected
3. Document the discovery time and date
4. Begin investigation

**Short-term (Within 24 hours):**
1. Contain the breach (disable affected features if needed)
2. Determine the cause
3. Notify Apple (if Apple systems were affected)
4. Draft notification to affected users

**Medium-term (Within 30-45 days):**
1. Notify affected users of the breach
2. Notify regulatory authorities (if required)
3. Provide information on what users should do
4. Complete investigation and implement fixes

**Long-term (Beyond 45 days):**
1. Monitor for any compromise of affected data
2. Implement additional security measures
3. Update security procedures
4. Document the incident for compliance

### 11.2 Breach Notification Email Template

```
Subject: IMPORTANT: Security Notification - Ritualist Account

Dear [User Name],

We are writing to notify you of a security incident that may have affected
your Ritualist account.

WHAT HAPPENED:
[Describe the breach in plain language]

WHAT DATA WAS AFFECTED:
[List specific data types: habit logs, location data, etc.]

WHAT WE'RE DOING:
- We have secured the affected systems
- We are investigating the root cause
- We are implementing additional security measures

WHAT YOU SHOULD DO:
[Specific actions for users to take]

NEXT STEPS:
We will provide updates on Friday, [date]. You can contact us with
questions at security@ritualist.app.

Best regards,
Ritualist Security Team
```

---

## 12. Document Version Control

### 12.1 Tracking Changes

Create a version log for your legal documents:

```
Privacy Policy - Version History
v1.0 - November 25, 2025 - Initial publication
v1.1 - [Date] - [Change description]

Terms of Service - Version History
v1.0 - November 25, 2025 - Initial publication
v1.1 - [Date] - [Change description]
```

### 12.2 Document Updates

When updating legal documents:
1. Create a new version (v1.1, v2.0, etc.)
2. Update the "Last Updated" date
3. Document what changed
4. Notify users of significant changes
5. Give users time to review (optional: 30 days notice)
6. Keep previous versions for at least 2 years (for audit purposes)

---

## 13. Template Support Email Responses

### 13.1 GDPR Data Access Request Response

```
Subject: Your Data Access Request - Ritualist

Dear [User Name],

Thank you for submitting a Data Subject Access Request under the GDPR.

We have received your request and are processing it according to our
legal obligations.

IMPORTANT NOTE:
Ritualist stores your habit data primarily in your device's local storage
and in your iCloud account via Apple CloudKit. We do not maintain
personal data on our own servers.

WHAT WE'RE PROVIDING:
1. A copy of all data processing activities related to your account
2. Instructions for exporting your habit data from the App
3. Information about Apple's data storage and processing

HOW TO EXPORT YOUR DATA:
1. Open Ritualist
2. Go to Settings > Data & Privacy > Export Data
3. Your habit data will be downloaded as a JSON file

YOUR ICLOUD DATA:
Your iCloud/CloudKit data is managed by Apple. To request access to Apple's
copies, visit: https://privacy.apple.com

If you have questions about this response, please reply to this email.

Best regards,
Ritualist Privacy Team
```

### 13.2 CCPA Right to Delete Response

```
Subject: Your California Privacy Right - Data Deletion Request

Dear [User Name],

Thank you for your request to delete personal information under the
California Consumer Privacy Act (CCPA).

We are processing your deletion request and will complete it within 45 days.

WHAT WILL BE DELETED:
- Local app data: Will be deleted when you uninstall the App
- iCloud data: You can delete through your Apple ID settings
- Server data: Ritualist has no server-based data storage

HOW TO COMPLETE DELETION:
1. Uninstall Ritualist from your device (deletes local data)
2. Go to Settings > [Your Name] > iCloud > Manage Storage
3. Select Ritualist and delete iCloud data

STATUS:
We will confirm completion of your deletion request by [DATE + 45 days].

If you have questions, please reply to this email.

Best regards,
Ritualist Privacy Team
```

### 13.3 General Support Response

```
Subject: Re: [User's Question/Issue]

Dear [User Name],

Thank you for contacting Ritualist support. We appreciate your feedback.

[Your detailed response here - customize based on the issue]

TROUBLESHOOTING:
If the issue persists, please try:
1. Force-close and reopen the App
2. Check that you're running the latest version
3. Restart your device

If you need further assistance:
1. Reply to this email with additional details
2. Include your device model and iOS version
3. Describe the exact steps to reproduce the issue

We typically respond within 3-7 business days.

Best regards,
Ritualist Support Team
support@ritualist.app
```

---

## 14. Privacy Impact Assessment (PIA)

### 14.1 Data Processing Activities

For regulatory compliance, document each data processing activity:

**Activity 1: Habit Creation and Storage**
```
Purpose: Core app functionality
Data Collected: Habit name, description, schedule, completion logs
Storage: Local device + iCloud CloudKit
Duration: Until user deletion
Legal Basis: Contractual necessity
Risk Level: Low (user-generated data)
Safeguards: Device encryption, iCloud encryption
```

**Activity 2: Geofencing**
```
Purpose: Location-based reminders
Data Collected: GPS coordinates, geofence boundaries
Storage: Local device + iCloud CloudKit
Duration: Until user disables geofencing
Legal Basis: Consent (via iOS permission)
Risk Level: Medium (precise location)
Safeguards: On-device processing, no third-party sharing
```

**Activity 3: Push Notifications**
```
Purpose: Habit reminders and notifications
Data Collected: Notification preferences, reminder schedules
Storage: Local device + Apple's notification service
Duration: Until user disables notifications
Legal Basis: Consent (via iOS permission)
Risk Level: Low (preferences only)
Safeguards: Encrypted transmission, user control
```

**Activity 4: App Analytics**
```
Purpose: Understand app usage and improve features
Data Collected: Aggregated usage data, crash reports
Storage: Apple's App Analytics servers
Duration: 12-24 months (Apple's policy)
Legal Basis: Legitimate interest
Risk Level: Low (aggregated, not personal)
Safeguards: Apple's analytics privacy controls
```

### 14.2 Third-Party Data Processor Assessment

For Apple CloudKit (current):
```
Service: Apple CloudKit
Function: Habit data storage and synchronization
Data Shared: User habit data, timestamps, sync metadata
Jurisdiction: US, potentially multi-region
Data Protection: Apple's privacy policy applies
DPA Needed: GDPR applicability - review Apple's SCCs
Risk Mitigation: Use of DPA language in Privacy Policy
```

---

## 15. Regulatory Authority Contact Information

### 15.1 Data Protection Authorities

If users need to file complaints about Ritualist's privacy practices:

**GDPR - EU Member States:**
- European Data Protection Board: https://edpb.europa.eu
- National DPA list: https://edpb.europa.eu/about-edpb/board/members_en

**CCPA - California:**
- California Attorney General: https://oag.ca.gov/privacy

**Other US States (with privacy laws):**
- Virginia VCDPA
- Colorado CPA
- Connecticut CTDPA
- Utah UCPA

**Non-EU Countries:**
- UK ICO: https://ico.org.uk
- Canada PIPEDA: https://www.priv.gc.ca

### 15.2 Apple Regulatory Contact

If issues arise with App Store compliance:
- Apple App Store Review: appstorereview@apple.com
- Developer Support: https://developer.apple.com/support

---

## 16. Final Checklist Before Launch

Before publishing Ritualist to the App Store:

- [ ] Privacy Policy is final and published
- [ ] Terms of Service is final and published
- [ ] Email addresses are configured and monitored
- [ ] Privacy Policy link is in App > Settings > Privacy
- [ ] Terms of Service link is in App > Settings > Legal
- [ ] App Store description links to legal documents
- [ ] App Store Privacy Label is complete
- [ ] In-App Purchase disclosures are clear
- [ ] Location permission message is clear
- [ ] Push notification permission message is clear
- [ ] Support email is monitored (support@ritualist.app)
- [ ] Privacy email is monitored (privacy@ritualist.app)
- [ ] Security email is monitored (security@ritualist.app)
- [ ] Process for handling GDPR/CCPA requests is documented
- [ ] Data retention policy is documented
- [ ] Terms are compliant with Apple's guidelines
- [ ] Privacy Policy is GDPR-compliant
- [ ] Privacy Policy is CCPA-compliant
- [ ] You have reviewed competitors' legal documents for gaps

---

## 17. Document Maintenance Schedule

### Monthly
- Monitor support email for complaints or issues
- Review any support inquiries for privacy implications
- Check for security vulnerability reports

### Quarterly
- Review privacy-related laws for updates
- Check Apple's guidelines for changes
- Review analytics for any unexpected data processing

### Semi-Annually
- Audit compliance with legal documents
- Update documents if needed
- Review user feedback for privacy concerns

### Annually
- Full regulatory compliance audit
- Update Privacy Policy and Terms of Service if needed
- Review and update this guide
- Assess any new data processing activities

---

## Contact Information

For questions about legal compliance for Ritualist:

**Email**: privacy@ritualist.app (privacy-specific questions)
**Email**: support@ritualist.app (general support)
**Website**: ritualist.app
**Developer**: Vlad Blajovan

---

**Last Updated:** November 25, 2025

This guide is provided for informational purposes. While we have aimed for accuracy, consult with a qualified attorney regarding specific legal compliance questions.
