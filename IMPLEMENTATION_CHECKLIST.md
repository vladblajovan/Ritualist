# Ritualist Legal Implementation Checklist

**Last Updated:** November 25, 2025

Use this checklist to ensure all legal documents and requirements are properly implemented before launching Ritualist.

---

## Phase 1: Document Review & Customization (Week 1)

### 1.1 Review All Documents
- [ ] Read PRIVACY_POLICY.md completely
- [ ] Read TERMS_OF_SERVICE.md completely
- [ ] Read LEGAL_SETUP_GUIDE.md completely
- [ ] Read LEGAL_SUMMARY.md completely
- [ ] Note any sections needing customization

### 1.2 Customize Documents
- [ ] Replace "Vlad Blajovan" with your name
- [ ] Replace "ritualist.app" with your domain
- [ ] Update all email addresses (support, privacy, security)
- [ ] Update "Last Updated" dates if making changes
- [ ] Review all placeholder sections for accuracy

### 1.3 Legal Review
- [ ] Send documents to qualified attorney for review (RECOMMENDED)
- [ ] Document any feedback from attorney
- [ ] Make requested changes to documents
- [ ] Attorney signs off on final versions

### 1.4 Documentation
- [ ] Create a version control log (see LEGAL_SETUP_GUIDE.md Section 12)
- [ ] Store documents in version control
- [ ] Create backup copies
- [ ] Document customizations made

---

## Phase 2: Email Configuration (Week 1)

### 2.1 Email Setup

**Using Gmail or similar provider:**

- [ ] Create email account for: support@ritualist.app
  - [ ] Set up email forwarding to your main email
  - [ ] Set up auto-responder (see LEGAL_SETUP_GUIDE.md Section 1)
  - [ ] Create label/folder for organization

- [ ] Create email account for: privacy@ritualist.app
  - [ ] Set up email forwarding to your main email
  - [ ] Set up auto-responder
  - [ ] Note 30-day response deadline for GDPR requests

- [ ] Create email account for: security@ritualist.app
  - [ ] Set up email forwarding to your main email
  - [ ] Set up auto-responder
  - [ ] Note 24-48 hour target for security reports

- [ ] Optional: Create email account for: legal@ritualist.app
  - [ ] Forward to privacy@ or support@

### 2.2 Email Monitoring
- [ ] Set calendar reminders to check emails weekly
- [ ] Create email templates for common responses
- [ ] Document response times for compliance tracking
- [ ] Set up filtering rules for spam

### 2.3 Email Documentation
- [ ] Create a log to track GDPR/CCPA requests
- [ ] Document response dates and times
- [ ] Keep copies of requests and responses (3+ years)
- [ ] Note any issues or complications

---

## Phase 3: Website Setup (Week 1-2)

### 3.1 Create Legal Pages

- [ ] Create page: ritualist.app/privacy
  - [ ] Copy PRIVACY_POLICY.md content
  - [ ] Add table of contents (optional)
  - [ ] Make printable (CSS for printing)
  - [ ] Test all internal links
  - [ ] Display "Last Updated" date

- [ ] Create page: ritualist.app/terms
  - [ ] Copy TERMS_OF_SERVICE.md content
  - [ ] Add table of contents
  - [ ] Make printable
  - [ ] Test all internal links
  - [ ] Display "Last Updated" date

- [ ] Create page: ritualist.app/support
  - [ ] Add support contact form
  - [ ] List email addresses (support@, privacy@, security@)
  - [ ] Add FAQ section
  - [ ] Link to privacy and terms

### 3.2 Website Navigation
- [ ] Add footer links to all pages:
  - [ ] Link to Privacy Policy
  - [ ] Link to Terms of Service
  - [ ] Link to Support
  - [ ] Test links work correctly

- [ ] Add header/navigation menu:
  - [ ] Link to Legal Documents
  - [ ] Link to Support/Contact
  - [ ] Link to FAQ

### 3.3 Website Technical
- [ ] Test website on mobile (iOS Safari)
- [ ] Test website on desktop
- [ ] Verify links are HTTPS (encrypted)
- [ ] Test PDF download (if enabled)
- [ ] Test email contact form (if implemented)
- [ ] Verify accessibility (readable, keyboard navigable)

---

## Phase 4: In-App Setup (Week 2-3)

### 4.1 Settings Menu Structure

Create these screens in Ritualist Settings:

```
Settings (main)
├── Account
│   └── [No separate account - uses Apple ID]
├── Notifications
│   ├── Habit Reminders: Toggle
│   ├── Achievements: Toggle
│   └── App Updates: Toggle
├── Location
│   ├── Enable Geofencing: Toggle
│   └── [Explain location privacy]
├── Data & Privacy
│   ├── Export Data: Button
│   ├── Delete Account: Button
│   └── [Privacy explanation]
├── Privacy & Legal
│   ├── Privacy Policy: Link to ritualist.app/privacy
│   ├── Terms of Service: Link to ritualist.app/terms
│   └── Support: Link to support@ritualist.app
└── About
    ├── App Version: [version]
    ├── Last Updated: [date]
    └── Developer: Vlad Blajovan
```

### 4.2 Implement Settings Screens

- [ ] **Settings > Privacy & Legal**
  - [ ] "Privacy Policy" link (opens ritualist.app/privacy in browser)
  - [ ] "Terms of Service" link (opens ritualist.app/terms in browser)
  - [ ] Privacy statement text explaining data use
  - [ ] Contact for privacy requests: privacy@ritualist.app

- [ ] **Settings > Location**
  - [ ] Display toggle for geofencing: "Enable Geofencing"
  - [ ] Explanation: "Location data helps Ritualist send reminders when you're at specific places. Your location is never shared with third parties."
  - [ ] Link to Privacy Policy location section (ritualist.app/privacy#location)

- [ ] **Settings > Data & Privacy**
  - [ ] "Export Data" button → Downloads JSON file
  - [ ] "Delete Account" button → Shows contact form to privacy@ritualist.app
  - [ ] Explanation of what data will be deleted
  - [ ] Confirmation dialog before deletion request

- [ ] **Settings > Subscription**
  - [ ] Display current subscription status
  - [ ] Button: "Manage Subscription" (opens iOS Subscriptions)
  - [ ] Link: "Refund Policy" (ritualist.app/terms#refunds)
  - [ ] Explain auto-renewal terms
  - [ ] Explain how to cancel

### 4.3 Permission Request Messages

- [ ] **Location Permission (First Time)**
  - [ ] Use message from LEGAL_SETUP_GUIDE.md Section 3.2
  - [ ] Clear explanation of how location is used
  - [ ] Reassurance that it's never shared
  - [ ] Allow user to see before agreeing

- [ ] **Push Notification Permission (First Time)**
  - [ ] Use message from LEGAL_SETUP_GUIDE.md Section 3.2
  - [ ] Explain what notifications will be sent
  - [ ] Mention they can disable anytime

### 4.4 Feature Screens

- [ ] **Geofencing Setup**
  - [ ] Explain how geofencing works
  - [ ] Show accuracy limitations
  - [ ] Privacy assurance: "Location never leaves your device"

- [ ] **Personality Analysis**
  - [ ] Explain analysis happens on-device
  - [ ] Option to disable in Settings
  - [ ] No data is sent to external services

- [ ] **In-App Purchase Screen**
  - [ ] Clear subscription pricing display
  - [ ] Explain auto-renewal terms
  - [ ] Link to Terms of Service
  - [ ] Link to cancellation instructions

---

## Phase 5: App Store Setup (Week 2-3)

### 5.1 App Store Connect Information

- [ ] **App Description**
  - [ ] Include: "Privacy Policy: ritualist.app/privacy"
  - [ ] Include: "Terms of Service: ritualist.app/terms"
  - [ ] Include: "No account required - uses Apple ID"
  - [ ] Include: "No third-party analytics or data sharing"

- [ ] **Keywords & Search**
  - [ ] Add relevant keywords
  - [ ] Include privacy-focused keywords (optional): "privacy," "no tracking"

### 5.2 App Privacy Label (Most Important)

- [ ] Go to App Store Connect > Privacy
- [ ] Complete Privacy Label for each data type:

**Locations:**
- [ ] Precise Location
  - [ ] Used for: Geofencing reminders
  - [ ] Linked to user identity: NO
  - [ ] Sold: NO

**Identifiers:**
- [ ] User ID (if tracking implemented)
  - [ ] Used for: Account/device sync
  - [ ] Linked to user identity: NO (uses Apple ID)
  - [ ] Sold: NO

**Fitness:**
- [ ] If tracking fitness habits:
  - [ ] Used for: Habit tracking
  - [ ] Linked to user identity: NO
  - [ ] Sold: NO

**Other Data:**
- [ ] Habit patterns/data
  - [ ] Used for: Core app functionality
  - [ ] Linked to user identity: NO
  - [ ] Sold: NO

### 5.3 Subscription Information

- [ ] **Subscription Details**
  - [ ] Weekly: $2.99/week (or your price)
  - [ ] Monthly: $9.99/month
  - [ ] Annual: $49.99/year
  - [ ] Lifetime: $99.99 (non-renewing)

- [ ] **Renewal Terms**
  - [ ] Auto-renew: YES (for subscriptions)
  - [ ] Renewal description: "Subscription renews at end of billing period unless canceled"
  - [ ] Cancellation: "Cancel through Settings > Subscriptions > Ritualist"

- [ ] **Legal Links**
  - [ ] Link to Terms of Service: ritualist.app/terms
  - [ ] Link to Privacy Policy: ritualist.app/privacy
  - [ ] Link to Refund Policy: ritualist.app/terms#refunds

### 5.4 Permissions Declaration

In App Store Connect, declare all permissions:
- [ ] Location Services (precise location for geofencing)
- [ ] Push Notifications (reminders and notifications)
- [ ] Calendar (if adding calendar sync)
- [ ] Reminders (if adding reminder sync)

For each permission:
- [ ] Explain why it's needed
- [ ] Reassure it's optional (if applicable)
- [ ] Link to Privacy Policy

### 5.5 Review & Guidelines Compliance

- [ ] Review Apple's App Store Guidelines (apple.com/app-store/review/guidelines/)
- [ ] Ensure compliance with:
  - [ ] Health & Fitness Guidelines (if applicable)
  - [ ] Financial Information Guidelines
  - [ ] User Privacy Guidelines
  - [ ] Performance Guidelines
  - [ ] Business Model Guidelines
- [ ] Documentation for Apple reviewers (if needed)

---

## Phase 6: Compliance Documentation (Week 3)

### 6.1 Create Compliance Records

- [ ] Document which regulations apply:
  - [ ] GDPR (EU users) ✓
  - [ ] CCPA (California users) ✓
  - [ ] COPPA (children's privacy) ✓
  - [ ] CASL (Canada - if marketing emails planned)
  - [ ] Other (list any others)

- [ ] Create Privacy Impact Assessment:
  - [ ] Document each data processing activity
  - [ ] Assess risks for each activity
  - [ ] Document safeguards for each activity
  - [ ] See LEGAL_SETUP_GUIDE.md Section 14

- [ ] Create Subprocessor Documentation:
  - [ ] Apple CloudKit (iCloud sync provider)
  - [ ] Apple App Analytics
  - [ ] Apple Crash Reporting
  - [ ] Document data processing for each

### 6.2 Create Incident Response Plan

- [ ] Document your breach response procedures
- [ ] Create breach notification email template
- [ ] Document who to notify (Apple, authorities, users)
- [ ] Document response timelines (30-45 days)
- [ ] See LEGAL_SETUP_GUIDE.md Section 11

### 6.3 Create DSAR/CCPA Request Procedures

- [ ] Document verification procedures
- [ ] Create response email templates
- [ ] Document response timelines (30 GDPR / 45 CCPA days)
- [ ] Create tracking log for requests
- [ ] See LEGAL_SETUP_GUIDE.md Section 5

### 6.4 Data Retention Documentation

- [ ] Document retention periods for each data type
- [ ] Document deletion procedures for each type
- [ ] Document how users can delete their data
- [ ] Create deletion verification process

---

## Phase 7: Testing & Validation (Week 3)

### 7.1 App Testing

- [ ] **Permissions Flow**
  - [ ] Test location permission request message
  - [ ] Test notification permission request message
  - [ ] Verify user can revoke permissions in Settings
  - [ ] Verify app functions without permissions (where applicable)

- [ ] **Settings Navigation**
  - [ ] Test all links in Settings > Privacy & Legal
  - [ ] Verify links open to correct web pages
  - [ ] Test on both WiFi and cellular
  - [ ] Verify no SSL/HTTPS warnings

- [ ] **Data Export**
  - [ ] Test Settings > Data & Privacy > Export Data
  - [ ] Verify JSON file is downloadable
  - [ ] Verify JSON contains expected data
  - [ ] Verify format is machine-readable
  - [ ] Test on multiple devices

- [ ] **Account Deletion**
  - [ ] Test Settings > Data & Privacy > Delete Account
  - [ ] Verify contact form works
  - [ ] Verify email arrives at privacy@ritualist.app
  - [ ] Verify deletion process functions

### 7.2 Website Testing

- [ ] **Navigation & Links**
  - [ ] Test all header/footer links
  - [ ] Verify no broken links
  - [ ] Test on mobile (iOS Safari)
  - [ ] Test on desktop browsers
  - [ ] Verify responsive design

- [ ] **Content Display**
  - [ ] Verify Privacy Policy displays correctly
  - [ ] Verify Terms of Service displays correctly
  - [ ] Check formatting is readable
  - [ ] Verify "Last Updated" date shows
  - [ ] Test PDF printing (if applicable)

- [ ] **Contact Forms**
  - [ ] Test support contact form
  - [ ] Verify form submission works
  - [ ] Verify email arrives at correct inbox
  - [ ] Test error handling

### 7.3 Email Testing

- [ ] **Email Delivery**
  - [ ] Send test email to support@ritualist.app
  - [ ] Verify it arrives at your inbox
  - [ ] Verify auto-responder sends reply
  - [ ] Test privacy@ and security@ emails

- [ ] **Email Response**
  - [ ] Verify email templates are accurate
  - [ ] Test sending response from template
  - [ ] Verify formatting looks professional
  - [ ] Check for typos and clarity

### 7.4 Accessibility Testing

- [ ] **Text Size**
  - [ ] Test with large text (iOS Dynamic Type)
  - [ ] Verify settings text is readable
  - [ ] Test with smallest text size

- [ ] **Color Contrast**
  - [ ] Verify text meets WCAG AA contrast standards
  - [ ] Test with color blindness simulator
  - [ ] Verify website has good contrast

- [ ] **VoiceOver**
  - [ ] Test app with VoiceOver enabled
  - [ ] Verify buttons are accessible
  - [ ] Verify links are properly labeled

---

## Phase 8: Preparation for Launch (Week 4)

### 8.1 Final Documentation Review

- [ ] All legal documents are finalized
- [ ] All customizations are complete
- [ ] Attorney has reviewed (if applicable)
- [ ] No placeholder text remains
- [ ] All dates are current

### 8.2 Stakeholder Communication

- [ ] If you have advisors/co-founders, notify them:
  - [ ] Share final Privacy Policy
  - [ ] Share final Terms of Service
  - [ ] Confirm compliance procedures
  - [ ] Document their sign-off

### 8.3 Customer Support Preparation

- [ ] Create FAQ section on website
- [ ] Create support response templates
- [ ] Train anyone handling support (if applicable)
- [ ] Set up email monitoring system
- [ ] Create response timeline: 3-7 days for support, 30/45 days for DSAR

### 8.4 Monitoring Setup

- [ ] Create calendar reminders:
  - [ ] Weekly: Check support emails
  - [ ] Monthly: Check for compliance issues
  - [ ] Quarterly: Review legal documents
  - [ ] Annually: Full compliance audit

- [ ] Set up tracking systems:
  - [ ] DSAR/privacy request log
  - [ ] Security incident log
  - [ ] Complaint/issue log
  - [ ] Regulatory change log

### 8.5 Backup & Archive

- [ ] Create backup of all legal documents
- [ ] Store in version control (Git)
- [ ] Store in cloud backup
- [ ] Keep printed copies (optional)
- [ ] Document storage locations

---

## Phase 9: Pre-Submission Verification (Before App Store)

### 9.1 Final Checklist

**Legal Documents**
- [ ] Privacy Policy is final and published
- [ ] Terms of Service is final and published
- [ ] Both documents are accessible in-App
- [ ] Both documents are on website
- [ ] Email addresses are configured and monitored

**App Configuration**
- [ ] All permission messages are clear
- [ ] Settings menu is complete
- [ ] Legal links are working
- [ ] Data export functionality works
- [ ] Subscription terms are clear

**App Store Submission**
- [ ] Privacy Label is complete and accurate
- [ ] App description includes legal links
- [ ] Keywords are appropriate
- [ ] Screenshots don't show data (privacy)
- [ ] Version notes are clear

**Compliance**
- [ ] GDPR requirements covered
- [ ] CCPA requirements covered
- [ ] Apple guidelines compliance verified
- [ ] Children's privacy (COPPA) addressed if applicable
- [ ] Email support is ready

### 9.2 Legal Review Before Submission

- [ ] Attorney confirms compliance (if reviewed)
- [ ] No outstanding legal issues
- [ ] No required changes from Apple (that you're aware of)
- [ ] All disclosures are clear
- [ ] Liability limitations are properly stated

### 9.3 Documentation Sign-Off

- [ ] Privacy Policy: FINAL ✓
- [ ] Terms of Service: FINAL ✓
- [ ] Support procedures: DOCUMENTED ✓
- [ ] Email monitoring: READY ✓
- [ ] Response templates: PREPARED ✓

---

## Phase 10: After Launch Monitoring (Ongoing)

### 10.1 Weekly Tasks

- [ ] Check support@ritualist.app inbox
- [ ] Check privacy@ritualist.app inbox
- [ ] Check security@ritualist.app inbox
- [ ] Respond to support requests (within 3-7 days)
- [ ] Monitor App Store reviews for issues

### 10.2 Monthly Tasks

- [ ] Review all received support emails
- [ ] Check for privacy-related complaints
- [ ] Verify no unresponded requests
- [ ] Check for security reports
- [ ] Monitor for regulatory news

### 10.3 Quarterly Tasks

- [ ] Review compliance with legal documents
- [ ] Check for new privacy laws/regulations
- [ ] Update Privacy Policy if needed
- [ ] Review GDPR/CCPA procedures
- [ ] Check Apple guidelines for changes

### 10.4 Annual Tasks

- [ ] Full compliance audit
- [ ] Update Privacy Policy (if needed)
- [ ] Update Terms of Service (if needed)
- [ ] Review all documented procedures
- [ ] Consult attorney (if needed)

---

## Important Notes

### Before You Start
- Read all four legal documents completely
- Understand your app architecture (serverless with iCloud)
- Know your target jurisdictions (EU, California, etc.)
- Have attorney contact info ready

### Key Success Factors
1. **Accuracy:** Keep legal documents accurate and up-to-date
2. **Transparency:** Be clear about data practices
3. **Responsiveness:** Respond promptly to privacy requests
4. **Documentation:** Keep records of all requests and responses
5. **Compliance:** Follow GDPR/CCPA procedures closely

### Common Mistakes to Avoid
- ❌ Not updating documents when adding features
- ❌ Ignoring DSAR/CCPA requests
- ❌ Not responding within required timelines
- ❌ Vague privacy disclosures
- ❌ Overstating app capabilities in marketing
- ❌ Collecting data you don't disclose
- ❌ Sharing data with third parties not mentioned
- ❌ Not keeping response records

---

## Troubleshooting

### Email Setup Issues
- **Problem:** Emails not forwarding
  - **Solution:** Check forwarding rules in email provider settings
- **Problem:** Auto-responder not working
  - **Solution:** Verify auto-responder is enabled and not blocked

### Website Issues
- **Problem:** Links open to 404 errors
  - **Solution:** Verify page URLs are correct (use absolute URLs)
- **Problem:** Website looks bad on mobile
  - **Solution:** Check responsive design CSS; test in Safari

### App Issues
- **Problem:** Settings menu not displaying legal links
  - **Solution:** Verify URLs are correct; test link functionality
- **Problem:** Data export not working
  - **Solution:** Check file permissions; verify JSON format

### DSAR Issues
- **Problem:** Can't verify user identity
  - **Solution:** Ask for multiple identifying details; contact Apple if needed
- **Problem:** User says 30-day deadline passed
  - **Solution:** Respond immediately; document delay reasons

---

## Success Criteria

By the end of implementation, you should have:

✓ Complete, published Privacy Policy on ritualist.app/privacy
✓ Complete, published Terms of Service on ritualist.app/terms
✓ Functional email addresses (support@, privacy@, security@)
✓ In-App links to legal documents
✓ Clear permission request messages
✓ Data export functionality working
✓ App Store Privacy Label complete
✓ Subscription terms clearly disclosed
✓ Support procedures documented
✓ DSAR/CCPA response procedures ready
✓ Email monitoring system in place
✓ All compliance requirements addressed

---

## Final Checklist Before Launch

```
LEGAL DOCUMENTS
☐ Privacy Policy final and published
☐ Terms of Service final and published
☐ Both documents legally reviewed
☐ All customizations complete
☐ Version control in place

EMAIL & SUPPORT
☐ support@ email configured
☐ privacy@ email configured
☐ security@ email configured
☐ All auto-responders set up
☐ Email monitoring system ready

APP & WEBSITE
☐ Links to legal documents in-App
☐ Links to legal documents on website
☐ All website links functional
☐ Settings menu complete
☐ Permission messages clear

APP STORE
☐ Privacy Label complete
☐ Subscription information disclosed
☐ Legal links in description
☐ Keywords appropriate
☐ Version notes are clear

COMPLIANCE
☐ GDPR requirements covered
☐ CCPA requirements covered
☐ COPPA requirements addressed
☐ Apple guidelines compliance verified
☐ International jurisdictions addressed

PROCEDURES
☐ DSAR request process documented
☐ CCPA request process documented
☐ Incident response plan ready
☐ Data retention policy documented
☐ Support templates prepared

MONITORING
☐ Calendar reminders set
☐ Email monitoring ready
☐ Tracking logs prepared
☐ Backup system ready
☐ Procedures documented

SIGN-OFF
☐ Developer review complete
☐ Attorney review complete (if applicable)
☐ All stakeholders notified
☐ Ready for App Store submission
☐ Launch approved
```

---

**Last Updated:** November 25, 2025

**Status:** Ready for implementation

**Questions?** Contact privacy@ritualist.app

---

**IMPORTANT REMINDER:** This is a template. Have a qualified attorney review these documents and this checklist before launching your app. Privacy and legal compliance is critical for your app's success and your protection.
