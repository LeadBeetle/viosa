# Google Play Store Publication Plan for VIOSA

**Date Created:** 2025-01-16
**Current App Version:** 1.0.0+1
**Estimated Total Time:** 20-35 hours
**Current Readiness:** ~40%

---

## Executive Summary

VIOSA is an audio transcription app using OpenRouter API with Gemini Flash 2.5. The app has a solid technical foundation but requires significant work in three areas before Google Play Store publication:

1. **App Signing & Configuration** (Critical)
2. **Privacy & Compliance Documentation** (Critical)
3. **Store Listing Assets** (Important)

**Target Publication Deadline:** August 31, 2025 (for API 35 compliance)

---

## Part A: Changes in the App (Code & Configuration)

### A1. CRITICAL - App Signing Configuration
**Priority:** P0 (Blocker)
**Time Estimate:** 1-2 hours
**Status:** ❌ Not Started

**What needs to be done:**

1. **Create Upload Keystore File**
   - Generate keystore using keytool command
   - Store securely (NEVER commit to git)
   - Location: `c:\Users\doria\workspace\aeon-project\viosa\android\app\upload-keystore.jks`

2. **Create key.properties File**
   - Location: `c:\Users\doria\workspace\aeon-project\viosa\android\key.properties`
   - Contents:
     ```properties
     storePassword=<your-password>
     keyPassword=<your-password>
     keyAlias=upload
     storeFile=../app/upload-keystore.jks
     ```
   - Must be in .gitignore (already configured ✓)

3. **Update build.gradle.kts**
   - File: `c:\Users\doria\workspace\aeon-project\viosa\android\app\build.gradle.kts`
   - Add code to load key.properties
   - Update signingConfigs section to use release signing (not debug)
   - Update buildTypes.release to use signingConfig

**Impact:** Cannot publish without proper signing
**Risk:** High - App cannot be uploaded to Play Store

---

### A2. CRITICAL - Change Application ID
**Priority:** P0 (Blocker)
**Time Estimate:** 5 minutes
**Status:** ❌ Not Started

**What needs to be done:**

1. **Update Application ID in build.gradle.kts**
   - File: `c:\Users\doria\workspace\aeon-project\viosa\android\app\build.gradle.kts`
   - Current: `com.example.viosa` (lines 9, 24)
   - Change to: `com.[yourdomain].viosa` or `com.[yourcompany].viosa`

   **Examples:**
   - `com.viosaapp.viosa`
   - `com.audioscribe.viosa`
   - `com.yourname.viosa`

**⚠️ CRITICAL WARNING:**
- This CANNOT be changed after first publication
- Choose carefully and permanently
- Must be unique across all Play Store apps

**Impact:** Cannot publish with "com.example" prefix
**Risk:** Critical - Rejected by Play Store

---

### A3. CRITICAL - Verify/Update Target SDK to API 35
**Priority:** P0 (Deadline: August 31, 2025)
**Time Estimate:** 2-4 hours (including testing)
**Status:** ❌ Needs Verification

**What needs to be done:**

1. **Check Current SDK Version**
   - File: `c:\Users\doria\workspace\aeon-project\viosa\android\app\build.gradle.kts`
   - Verify `compileSdk` and `targetSdk` values
   - Currently using Flutter defaults (need explicit values)

2. **Update to API Level 35**
   - Set `compileSdk = 35` (or "android-35")
   - Set `targetSdk = 35`
   - May need to update Flutter SDK version

3. **Update Dependencies**
   - Run `flutter pub upgrade`
   - Check for compatibility warnings
   - Update any incompatible packages

4. **Test on Android 15**
   - Test all app functionality
   - Test permissions (Android 15 has stricter rules)
   - Test file access
   - Test audio recording/playback

**Impact:** Required by August 31, 2025 for new apps
**Risk:** High - Cannot publish after deadline without compliance

---

### A4. RECOMMENDED - Review and Optimize Permissions
**Priority:** P2 (Best Practice)
**Time Estimate:** 2-4 hours
**Status:** ❌ Not Started

**Current Permissions (AndroidManifest.xml):**
- ✓ INTERNET (required for API)
- ✓ RECORD_AUDIO (required for recording)
- ✓ READ_MEDIA_AUDIO (required for file access)
- ⚠️ MANAGE_EXTERNAL_STORAGE (broad permission - may be flagged)
- READ_EXTERNAL_STORAGE (maxSdkVersion="32")
- WRITE_EXTERNAL_STORAGE (maxSdkVersion="32")

**What needs to be done:**

1. **Evaluate MANAGE_EXTERNAL_STORAGE**
   - Check if scoped storage (READ_MEDIA_AUDIO) is sufficient
   - Review code in file_picker usage
   - Consider removing if not strictly necessary

2. **Test with Scoped Storage**
   - Test file selection with only READ_MEDIA_AUDIO
   - Ensure all functionality works
   - Update code if needed

3. **Update AndroidManifest.xml**
   - Remove unnecessary permissions
   - Add permission justification comments

**Impact:** Easier Play Store approval, better user trust
**Risk:** Low - Optional optimization

---

### A5. RECOMMENDED - Add Content Descriptions for Accessibility
**Priority:** P3 (Best Practice)
**Time Estimate:** 1-2 hours
**Status:** ❌ Not Started

**What needs to be done:**

1. **Add Semantic Labels**
   - Review all IconButton, Image, and interactive widgets
   - Add `semanticLabel` or `tooltip` properties
   - Examples:
     ```dart
     IconButton(
       icon: Icon(Icons.mic),
       tooltip: 'Start recording',
       onPressed: () {},
     )
     ```

2. **Test with TalkBack**
   - Enable TalkBack on Android device
   - Navigate through entire app
   - Ensure all elements are announced properly

**Impact:** Better accessibility, wider user reach
**Risk:** None - Optional enhancement

---

### A6. OPTIONAL - Add Analytics/Crash Reporting
**Priority:** P4 (Future Enhancement)
**Time Estimate:** 2-3 hours
**Status:** ❌ Not Started

**What could be added:**

1. **Firebase Crashlytics**
   - Track crashes and errors
   - Monitor app stability

2. **Firebase Analytics**
   - Track user behavior
   - Monitor feature usage

**Note:** Must update privacy policy and data safety form if added

**Impact:** Better post-launch monitoring
**Risk:** None - Optional

---

## Part B: Manual Tasks (Outside the App)

### B1. CRITICAL - Privacy Policy Creation
**Priority:** P0 (Blocker)
**Time Estimate:** 3-6 hours
**Status:** ❌ Not Started

**What YOU need to do manually:**

1. **Write Privacy Policy Document**

   **Must Include:**
   - App name: "VIOSA" or "Viosa"
   - Developer/company name
   - Clear "Privacy Policy" heading
   - Date of last update

   **Data Collection Section:**
   - Audio files (temporary, for transcription)
   - API keys (stored locally, encrypted)
   - Transcription history (stored locally in Hive)
   - User preferences and settings

   **Data Usage Section:**
   - Audio sent to OpenRouter API for transcription
   - Local storage for history and convenience
   - No data sold to third parties

   **Third-Party Services:**
   - OpenRouter API (processes audio files)
   - Link to OpenRouter privacy policy
   - Explain data is sent for transcription only

   **Data Security:**
   - Encryption in transit (HTTPS)
   - Secure local storage (flutter_secure_storage)
   - No cloud backup of audio files

   **User Rights:**
   - Access to their data
   - Deletion of transcription history
   - Delete account/data
   - How to exercise these rights

   **Permissions Explanation:**
   - Why RECORD_AUDIO is needed
   - Why READ_MEDIA_AUDIO is needed
   - Why INTERNET is needed

   **Contact Information:**
   - Email address for privacy questions
   - Response time commitment

2. **Host Privacy Policy**

   **Options:**
   - **GitHub Pages** (Free, recommended)
     - Create repository or use existing
     - Create `privacy-policy.html` or `.md`
     - Enable GitHub Pages in settings
     - URL: `https://yourusername.github.io/viosa-privacy-policy`

   - **Simple Website** (Free options)
     - Netlify (free tier)
     - Vercel (free tier)
     - Google Sites (free)

   - **Privacy Policy Generators** (Quick start)
     - Termly: https://termly.io
     - TermsFeed: https://www.termsfeed.com
     - FreePrivacyPolicy: https://www.freeprivacypolicy.com

   **Requirements:**
   - Must be publicly accessible URL
   - No geofencing/blocking allowed
   - Cannot be a PDF file
   - Must be stable/permanent URL

3. **Save Privacy Policy URL**
   - You'll need this URL for Play Console
   - Test URL is accessible from different networks
   - Keep URL document for reference

**Impact:** Cannot submit without privacy policy URL
**Risk:** Critical - Blocker for submission

---

### B2. CRITICAL - Google Play Developer Account Setup
**Priority:** P0 (Blocker)
**Time Estimate:** 1-2 hours
**Status:** ❓ Unknown (check if you have existing account)

**What YOU need to do manually:**

1. **Check Existing Account**
   - Do you have a Google Play Developer account?
   - If yes, skip to account verification
   - If no, proceed to create account

2. **Create Developer Account** (if needed)
   - Visit: https://play.google.com/console/signup
   - Pay $25 one-time registration fee
   - Accept developer distribution agreement
   - Choose account type:
     - Personal (individual developer)
     - Organization (company/business)

3. **Identity Verification**
   - Google requires government-issued ID
   - Photo ID verification (passport, driver's license, etc.)
   - May take 1-2 days for approval
   - Check email for verification status

4. **Payment Profile Setup** (if monetizing)
   - Not needed if app is completely free
   - Set up if planning future paid features

**Impact:** Cannot access Play Console without account
**Risk:** Critical - Blocker for submission
**Cost:** $25 USD (one-time)

---

### B3. CRITICAL - Store Listing Assets Creation
**Priority:** P0 (Blocker)
**Time Estimate:** 3-5 hours
**Status:** ❌ Not Started

**What YOU need to do manually:**

#### 3.1 Feature Graphic (MANDATORY)

**Specifications:**
- Dimensions: 1024 x 500 pixels (exactly)
- Format: JPEG or 24-bit PNG
- NO transparency allowed
- Maximum size: 15 MB
- Quality: High resolution

**Design Guidelines:**
- Keep important content centered (safe zone)
- Avoid pure white, black, or dark gray backgrounds
- No duplicate branding from app icon
- No promotional text ("Best," "Free," "#1," "New")
- No cutoff zones on edges
- Professional appearance

**Content Suggestions:**
- App name "VIOSA" prominently displayed
- Visual representation of audio transcription
- Waveform graphics
- Microphone icon
- Clean, modern design
- Brand colors consistent with app icon

**Tools You Can Use:**
- Canva (free templates available)
- Adobe Photoshop
- Figma
- GIMP (free)
- Google Slides (simple option)

#### 3.2 High-Resolution Icon (MANDATORY)

**Specifications:**
- Dimensions: 512 x 512 pixels (exactly)
- Format: 32-bit PNG with alpha channel
- Maximum size: 1 MB

**Action Required:**
- Verify existing icon: `c:\Users\doria\workspace\aeon-project\viosa\assets\viosa_icon.png`
- Check dimensions are 512x512
- Check format is 32-bit PNG
- Check file size under 1 MB
- If not compliant, create/resize icon

#### 3.3 Screenshots (MANDATORY - Minimum 2)

**Specifications:**
- Minimum: 2 screenshots
- Maximum: 8 screenshots
- Format: JPEG or 24-bit PNG (no transparency)
- Dimensions: Min 320px, Max 3840px per side
- Aspect Ratio: 16:9 recommended
- File size: Reasonable (under 8 MB each)

**Required Screenshots (Suggested):**
1. **Home/Main Screen** - Audio file selection interface
2. **Recording Screen** - Active recording with waveform
3. **Transcription Result** - Showing successful transcription
4. **History Screen** - List of past transcriptions
5. **Settings Screen** - Configuration options
6. **Prompts Screen** - LLM prompt management (optional)

**Guidelines:**
- Show actual app UI (no mockups)
- Can add minimal text overlay (features, benefits)
- No promotional language ("Best app," "Download now")
- No store performance indicators (ratings, downloads)
- Clean, professional appearance
- Consider localization for different languages

**How to Capture:**
- Use Android Studio screenshot tool
- Use device screenshot (Power + Volume Down)
- Use scrcpy for computer-based capture
- Edit/crop to remove status bar if desired

#### 3.4 App Descriptions

**App Title (50 character limit):**

**Option 1 (Short):**
`Viosa - AI Audio Transcription`

**Option 2 (Descriptive):**
`Viosa: Fast Audio to Text Transcription`

**Decision needed:** Choose one or create alternative

---

**Short Description (80 character limit):**

**Suggested:**
`Fast, accurate audio transcription powered by AI. Record or import files.`

**Alternative:**
`Convert audio to text instantly with AI-powered transcription technology.`

**Decision needed:** Choose one or create alternative

---

**Full Description (4000 character limit):**

**Template to customize:**

```
VIOSA - Professional Audio Transcription

Transform your audio recordings into accurate text transcriptions instantly with VIOSA, powered by advanced AI technology.

KEY FEATURES

🎙️ Record Audio Directly
Record audio directly within the app with high-quality capture. Perfect for meetings, interviews, lectures, and notes.

📂 Import Audio Files
Select existing audio files from your device in multiple formats. Transcribe recordings, podcasts, voice memos, and more.

🤖 AI-Powered Transcription
Leverage cutting-edge AI technology through OpenRouter API with Gemini 2.5 Flash for fast, accurate transcription results.

🌍 Multi-Language Support
Automatic language detection or manually select from supported languages including English, German, and more.

📝 Custom Prompts
Create custom prompts to guide the AI transcription for specialized use cases and improved accuracy.

📚 Transcription History
Access all your past transcriptions anytime. Browse, search, and manage your transcription library.

🔒 Secure & Private
Your API key is stored securely on your device. You maintain full control over your data and privacy.

HOW IT WORKS

1. Record new audio or select an existing file
2. Choose your preferred language or use auto-detect
3. Tap transcribe and let AI do the work
4. Get accurate text results in seconds
5. Access your transcription history anytime

PERFECT FOR

• Students recording and transcribing lectures
• Journalists conducting interviews
• Business professionals in meetings
• Content creators working with audio
• Anyone who needs audio-to-text conversion

REQUIREMENTS

VIOSA uses OpenRouter API for transcription. You'll need to:
• Create a free OpenRouter account at openrouter.ai
• Generate an API key
• Enter your API key in app settings

Free tier available. Pay-as-you-go pricing for transcription.

PRIVACY & SECURITY

Your privacy matters. Audio files are sent securely to OpenRouter API for transcription only. No data is stored on external servers. Your API key is encrypted and stored locally on your device.

SUPPORT

Questions or feedback? Contact us at [your-email@domain.com]

---

Download VIOSA today and experience the future of audio transcription.
```

**Customize this template with:**
- Your actual support email
- Any additional features
- Your preferred tone/style
- Specific use cases relevant to your target audience

---

### B4. CRITICAL - Data Safety Form Completion
**Priority:** P0 (Blocker)
**Time Estimate:** 1-2 hours
**Status:** ❌ Not Started

**What YOU need to do manually in Play Console:**

**This form cannot be completed until you have Play Console access, but prepare answers now:**

#### Data Collection Questions:

**Does your app collect or share user data?**
- Answer: **Yes**

**What data is collected?**

1. **Audio Files**
   - Collected: Yes (temporarily, for transcription)
   - Shared: Yes (with OpenRouter API)
   - Purpose: App functionality (transcription)
   - Optional or Required: Required for transcription feature
   - Deleted: Immediately after transcription OR user can delete from history

2. **Files and Docs (Transcription History)**
   - Collected: Yes (transcription text results)
   - Shared: No (stored locally only)
   - Purpose: App functionality (history feature)
   - Optional or Required: Optional (user can clear history)
   - Encrypted: Yes (local device storage)

3. **App Activity (User Preferences)**
   - Collected: Yes (settings, preferences)
   - Shared: No (stored locally only)
   - Purpose: App functionality (user experience)
   - Optional or Required: Required for app functionality

**Is data encrypted in transit?**
- Answer: **Yes** (HTTPS for API communication)

**Can users request data deletion?**
- Answer: **Yes** (users can delete transcription history in app)

#### Data Sharing Questions:

**Do you share data with third parties?**
- Answer: **Yes**

**Third-Party Services:**

1. **OpenRouter API**
   - Data shared: Audio files (temporary, for transcription)
   - Purpose: App functionality (transcription service)
   - Privacy policy: [Link to OpenRouter privacy policy]

**Is data used for advertising or analytics?**
- Answer: **No** (unless you add Firebase/analytics later)

#### Security Practices:

**Data encrypted in transit?**
- Answer: **Yes** (HTTPS)

**Data encrypted at rest?**
- Answer: **Yes** (flutter_secure_storage for API key)

**Users can request data deletion?**
- Answer: **Yes** (delete history in-app)

---

### B5. CRITICAL - Content Rating (IARC Questionnaire)
**Priority:** P0 (Blocker)
**Time Estimate:** 30 minutes
**Status:** ❌ Not Started

**What YOU need to do manually in Play Console:**

**Complete IARC questionnaire honestly:**

**Expected answers for VIOSA:**

- Violence: None
- Blood/Gore: None
- Sexual content: None
- Nudity: None
- Bad language: None (app doesn't filter user transcriptions, but doesn't promote)
- Drugs/Alcohol/Tobacco: None
- Gambling: None
- User interaction: Yes (users can create content - transcriptions)
- Shares user location: No
- Unrestricted internet access: Yes (API calls)
- Digital purchases: No (API costs are external)

**Expected Rating:** Everyone or Everyone 10+

**Cost:** FREE

**Location:** Play Console → Content Rating section

---

### B6. IMPORTANT - App Category Selection
**Priority:** P1 (Required)
**Time Estimate:** 5 minutes
**Status:** ❌ Not Started

**What YOU need to do manually in Play Console:**

**Suggested Categories:**
- **Primary:** Productivity
- **Secondary:** Tools (if allowed)

**Alternative categories to consider:**
- Business
- Education (if marketed to students)

**Decision needed:** Choose appropriate category

---

### B7. RECOMMENDED - Beta Testing
**Priority:** P2 (Best Practice)
**Time Estimate:** 1 hour setup + testing time
**Status:** ❌ Not Started

**What YOU can do manually (optional but recommended):**

1. **Create Internal Testing Track**
   - Play Console → Testing → Internal testing
   - Upload AAB to internal track first
   - Add your email as tester
   - Test real distribution before public launch

2. **Create Closed Testing Track** (optional)
   - Invite friends/colleagues
   - Get feedback before public launch
   - Test on different devices

**Benefits:**
- Catch distribution issues early
- Test real Play Store installation
- Get user feedback pre-launch
- Lower risk for production launch

---

### B8. OPTIONAL - Promotional Assets
**Priority:** P3 (Optional)
**Time Estimate:** 4-8 hours
**Status:** ❌ Not Started

**What YOU could create manually (optional):**

1. **Promo Video**
   - YouTube video (30 sec - 2 min)
   - Demo of app functionality
   - Screen recording with voiceover
   - Professional but can be simple

2. **Promo Graphic** (1024x500)
   - Additional promotional banner
   - Different from feature graphic
   - Optional

**Benefits:**
- Higher conversion rate
- Better user understanding
- More professional appearance

**Not required for publication**

---

## Part C: Final Submission Checklist

### Before Building Release APK/AAB:

**App Changes:**
- [ ] Application ID changed from "com.example.viosa"
- [ ] Upload keystore created
- [ ] key.properties file created
- [ ] build.gradle.kts updated with release signing
- [ ] Target SDK verified/updated to API 35
- [ ] Signed release build tested locally

**Manual Preparation:**
- [ ] Privacy policy written and hosted
- [ ] Privacy policy URL tested and accessible
- [ ] Google Play Developer account created/verified
- [ ] Feature graphic created (1024x500)
- [ ] High-res icon verified (512x512)
- [ ] Screenshots captured (minimum 2, recommended 4-8)
- [ ] App title finalized (50 chars)
- [ ] Short description written (80 chars)
- [ ] Full description written (4000 chars)
- [ ] Data safety form answers prepared
- [ ] Content rating questionnaire answers prepared
- [ ] App category selected

### In Play Console:

- [ ] New app created in Play Console
- [ ] App details entered (name, default language)
- [ ] Store listing completed:
  - [ ] High-res icon uploaded
  - [ ] Feature graphic uploaded
  - [ ] Screenshots uploaded
  - [ ] App title entered
  - [ ] Short description entered
  - [ ] Full description entered
  - [ ] App category selected
- [ ] Privacy policy URL added
- [ ] Data safety form completed
- [ ] Content rating questionnaire completed
- [ ] Target audience selected
- [ ] App access settings configured (all or restricted)
- [ ] Signed AAB uploaded to production track
- [ ] Release notes written
- [ ] App pricing set (free/paid)
- [ ] Countries/regions selected for distribution
- [ ] Pre-launch report reviewed
- [ ] All errors/warnings addressed

### Final Steps:

- [ ] Review all information one final time
- [ ] Submit for review
- [ ] Monitor email for Google review feedback
- [ ] Respond to any review requests promptly

---

## Part D: Post-Publication Tasks

### After App Goes Live:

**Monitoring:**
- [ ] Monitor crash reports in Play Console
- [ ] Monitor user reviews and ratings
- [ ] Monitor download statistics
- [ ] Monitor ANR (Application Not Responding) reports

**User Support:**
- [ ] Respond to user reviews (especially negative ones)
- [ ] Provide support via contact email
- [ ] Collect feature requests

**Updates:**
- [ ] Plan regular updates for bug fixes
- [ ] Plan feature enhancements based on feedback
- [ ] Maintain Play Store compliance (SDK updates, policy changes)

---

## Part E: Important Warnings & Notes

### ⚠️ CRITICAL WARNINGS:

1. **Application ID Cannot Be Changed**
   - Choose carefully before first upload
   - Must be unique across all Play Store apps
   - Cannot use "com.example" prefix
   - Recommendation: Use your domain or company name

2. **Keystore Security**
   - NEVER commit keystore to git (.gitignore already configured ✓)
   - NEVER share keystore publicly
   - BACKUP keystore securely (multiple locations)
   - Losing keystore = cannot update app ever again
   - Consider cloud backup (Google Drive, Dropbox) encrypted

3. **August 31, 2025 Deadline**
   - New apps MUST target Android 15 (API 35)
   - Extension available until November 1, 2025
   - Plan time for dependency updates and testing

4. **Privacy Policy = Data Safety Form**
   - Information must match exactly
   - Inconsistencies cause rejection
   - Update both when app changes

5. **OpenRouter API Disclosure**
   - MUST disclose audio sent to third party
   - MUST explain in privacy policy
   - MUST declare in data safety form
   - Users must understand data leaves device

6. **Permissions Justification**
   - MANAGE_EXTERNAL_STORAGE may be questioned
   - Be ready to justify or remove
   - Scoped storage preferred when possible

---

## Part F: Timeline Estimation

### Week 1: App Configuration (6-9 hours)
- Create keystore and signing config (2 hours)
- Change application ID (30 min)
- Verify/update target SDK (2-4 hours)
- Test signed release build (1-2 hours)
- Review permissions (optional, 2 hours)

### Week 2: Documentation & Assets (8-12 hours)
- Write privacy policy (3-4 hours)
- Host privacy policy (1 hour)
- Create feature graphic (2-3 hours)
- Capture and prepare screenshots (1-2 hours)
- Write store listing text (1-2 hours)
- Prepare data safety answers (1 hour)

### Week 3: Play Console & Submission (3-5 hours)
- Set up/verify developer account (1-2 hours)
- Create app in Play Console (30 min)
- Upload all assets (30 min)
- Complete forms (1-2 hours)
- Build and upload AAB (30 min)
- Final review and submit (30 min)

### Week 4: Review & Launch (Variable)
- Google review process: Hours to 7 days
- Address any review feedback: 1-4 hours
- Launch and monitoring: Ongoing

**Total Active Work Time: 17-26 hours**
**Total Calendar Time: 2-4 weeks** (including Google review)

---

## Part G: Resources & References

### Official Documentation:
- Flutter Android Deployment: https://docs.flutter.dev/deployment/android
- Google Play Console: https://play.google.com/console
- Play App Signing Guide: https://support.google.com/googleplay/android-developer/answer/9842756
- Data Safety Form Help: https://support.google.com/googleplay/android-developer/answer/10787469
- Target SDK Requirements: https://developer.android.com/google/play/requirements/target-sdk
- Developer Policy Center: https://play.google.com/about/developer-content-policy/

### Privacy Policy Tools:
- Termly (Generator): https://termly.io
- TermsFeed (Generator): https://www.termsfeed.com
- FreePrivacyPolicy: https://www.freeprivacypolicy.com
- GitHub Pages (Free hosting): https://pages.github.com

### Design Resources:
- Canva (Feature graphic): https://www.canva.com
- Google Play Asset Templates: Search "Google Play feature graphic template"
- Material Design Guidelines: https://material.io/design

### Testing Tools:
- bundletool (Test AAB locally): https://developer.android.com/studio/command-line/bundletool
- scrcpy (Android screen mirroring): https://github.com/Genymobile/scrcpy

### OpenRouter Resources:
- OpenRouter Website: https://openrouter.ai
- OpenRouter Privacy Policy: https://openrouter.ai/privacy (check for current link)
- OpenRouter Documentation: https://openrouter.ai/docs

---

## Part H: Frequently Asked Questions

### Q: Can I publish with "com.example.viosa"?
**A:** No, absolutely not. Google Play rejects apps with "com.example" prefix. You must change to a unique identifier.

### Q: What happens if I lose my keystore?
**A:** You will NEVER be able to update your app. You'll have to publish a new app with a different package name. Users won't get updates. BACKUP YOUR KEYSTORE!

### Q: Do I need to pay for OpenRouter separately?
**A:** Yes, OpenRouter API costs are separate from Play Store. Users need their own OpenRouter API key. This should be clearly explained in app description.

### Q: Can I change my privacy policy after publishing?
**A:** Yes, you can update it. Update both the hosted document and Play Console data safety form. Users should be notified of material changes.

### Q: How long does Google review take?
**A:** Typically hours to 3 days for first submission. Can take up to 7 days. Updates are usually faster.

### Q: What if my app gets rejected?
**A:** Google will email specific reasons. Address the issues and resubmit. Common issues: privacy policy, permissions, data safety form inconsistencies.

### Q: Can I test the production build before submitting?
**A:** Yes! Use internal testing track in Play Console. Upload AAB, add yourself as tester, install from Play Store test link.

### Q: Do I need a website for my app?
**A:** Not required, but recommended for privacy policy hosting. GitHub Pages is free and works perfectly.

### Q: Can I publish for free?
**A:** Google Play Developer account is $25 one-time fee. After that, free apps have no additional Google fees. OpenRouter API costs apply for usage.

### Q: What about iOS App Store?
**A:** Completely separate process with Apple. Requires Apple Developer account ($99/year), different signing, different requirements. Not covered in this plan.

---

## Part I: Next Steps

### Immediate Actions (Do These First):

1. **Choose Application ID**
   - Decide on final package name
   - Format: com.[yourdomain/company].viosa
   - Write it down: ________________________

2. **Decide on Privacy Policy Hosting**
   - GitHub Pages? Personal website? Other?
   - Plan: ________________________

3. **Verify Google Play Developer Account**
   - Do you have existing account? ___________
   - If no, plan to create and pay $25

4. **Review Timeline**
   - Can you commit 20-35 hours over next 2-4 weeks?
   - Set target submission date: ________________________

### Then Execute Plan:
1. Complete Part A (App Changes)
2. Complete Part B (Manual Tasks)
3. Complete Part C (Submission Checklist)
4. Submit for review
5. Launch!

---

## Document Version History

- **v1.0** - 2025-01-16 - Initial plan created based on gap analysis
- Future updates will be tracked here

---

**End of Document**

*Keep this document updated as you complete tasks. Use it as your master checklist for Play Store publication.*
