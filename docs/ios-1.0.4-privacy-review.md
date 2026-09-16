# iOS 1.0.4 privacy correction — owner review handoff

Status: **OWNER APPROVED September 16, 2026.** This stage did not merge,
deploy, publish, or change App Store Connect.

Prepared September 16, 2026 from Kanna product commit
`a15e643850a74399b16bf30dca438cbc7492945b` (`apps/mobile/VERSION`
`1.0.4`, production runtime `2.2.7`). The product repository was read only.
The exact signed iOS `1.0.4 (5)` IPA was separately inspected: SHA-256
`886da790ed1fd416e189b777c9c60e84ccf96f4c6033bcc0e03d1f17cae84a9a`,
bundle `build.kanna.app`, source commit `a15e643850a74399b16bf30dca438cbc7492945b`.

## Deliverables and boundaries

- Owner-approved website policy: [`privacy/index.html`](../privacy/index.html),
  with an effective date of September 16, 2026.
- Owner-approved App Store Connect answers: the matrix below. It is a handoff,
  not an App Store Connect change.
- No Terms or EULA text was added. No deployment, App Store Connect edit, app
  build, release QA, merge, or publication was performed.

The exact review diff is the repository diff for this document and
`privacy/index.html`. The owner approved the wording, matrix, and September 16,
2026 effective date in the task conversation. Merging this site branch deploys
the site, so normal review and merge controls still apply. If deployment slips
past September 16, update the effective date to the actual deployment date
before merge rather than backdating the policy.

## Current public claims vs proposed claims

| Topic | Current public claim (checked September 16, 2026) | Approved correction |
| --- | --- | --- |
| App Store privacy label | “Data Not Collected.” | Answer **Yes** and declare the source-supported types below. |
| Purchases | Website policy does not mention subscriptions, StoreKit, Stripe, or purchase records. | Describes both purchase paths, provider processing, UID-linked Apple and Stripe subscription records, purposes, and service providers. |
| Account deletion | Says there is no in-app account deletion and promises email-request deletion within 30 days. | Describes the shipped `Delete account` flow and what a successful callable deletes; removes the unsupported 30-day guarantee. |
| Subscription cancellation on deletion | Omitted. | Stripe subscriptions are canceled by successful account deletion; Apple subscriptions are not and must be canceled in Apple settings. |
| Retained exceptions | Claims logs are kept for a “short” period and backups rotate, without a source-supported duration. | Makes no duration claim; identifies the retained UID deletion fence and calls out provider records, logs, backups, and support correspondence that the callable does not delete. |
| Photos and camera | Says camera is used only for QR scanning and no photo is uploaded. | Describes optional message attachments, on-device resize/re-encode, LAN or transient relay path, Mac storage until task closure, and optional camera/library access. |
| Microphone declaration | The older answer sheet says no microphone usage string exists. | The signed IPA does contain an unused microphone purpose string, but no microphone access/audio data path. Audio Data remains No; cleanup is deferred to the next native change. |

Public checks:

- `https://kanna.build/privacy/` was byte-for-byte identical to the pre-change
  `privacy/index.html` when this review began.
- `https://apps.apple.com/us/app/kanna-mobile/id6802176590` rendered “Data Not
  Collected” and “The developer does not collect any data from this app.”

## Proposed App Store Connect answer matrix

At **App Privacy → Get Started**, proposed answer:

**Yes, this app or its third-party partners collect data.**

These are the owner-approved final entries from Apple's definitions and the
verified data paths. They have not yet been entered in App Store Connect.
“Linked” is Yes when at least some data within that type is tied to the Firebase
UID, account, device, or purchase token.

| App Store Connect data type | Collect | Linked | Tracking | Purpose | Concrete evidence at pinned commit |
| --- | --- | --- | --- | --- | --- |
| Contact Info → Email Address | Yes | Yes | No | App Functionality | `apps/mobile/src/lib/firebase/auth.ts`, `apps/mobile/src/lib/firebase/sdk.ts`; Firebase Auth email/password; account email also supplied to Stripe by `services/firebase-functions/src/billing/checkout.ts`. |
| User Content → Other User Content | Yes | Yes | No | App Functionality | `crates/kanna-server/src/cloud_task_publisher.rs` persists UID-scoped prompt/output snippets and task/repository metadata; `services/relay/src/cloudTaskPublication.ts`; `apps/mobile/src/lib/firebase/taskIndex.ts`. |
| Identifiers → User ID | Yes | Yes | No | App Functionality | Firebase UID scopes Auth, Firestore, relay routing, billing, and deletion: `services/relay/src/auth.ts`, `services/firebase-functions/src/billing/types.ts`. |
| Identifiers → Device ID | Yes | Yes | No | App Functionality | Kanna mobile device ID and FCM/APNs/installation identifiers: `apps/mobile/src/lib/pairing/machinePairing.ts`, `apps/mobile/src/lib/notifications/mobilePush.ts`, `services/relay/src/auth.ts`. |
| Purchases → Purchase History | **Yes** | **Yes** | No | App Functionality | `apps/mobile/src/lib/billing/appleController.ts` and `client.ts` submit the StoreKit transaction; `services/firebase-functions/src/billing/appStorePurchase.ts`, `appStoreVerification.ts`, and `appStoreEvents.ts` verify the product and store UID-linked original/current transaction IDs, purchase/status/expiry/renewal evidence; `entitlement.ts` grants access. |
| Diagnostics → Other Diagnostic Data | Yes | Yes | No | **App Functionality; Analytics** | Relay connection/error logs associate IP, UID, role, and desktop ID in `services/relay/src/index.ts`, `auth.ts`, and `router.ts`, making this type linked and used for App Functionality. The signed archive's Firebase Messaging manifest adds unlinked/App Functionality diagnostic data, while Firebase Installations and Google Data Transport each add unlinked/Analytics diagnostic data. Select both purposes and Linked = Yes because the Kanna-log subset is linked. |
| Other Data → Other Data Types | Yes | **No** | No | **Analytics** | The signed archive's Firebase Messaging manifest declares Other Data Types as unlinked/Analytics. Firebase documents its user-agent platform/version metadata as adoption measurement, which fits Apple's Analytics definition. No verified path links this data type to the Kanna UID or device; the FCM/APNs/installation token is declared separately as Device ID. |

Recommend **Tracking: No** for every selected type. The verified source has no
advertising SDK, ad measurement, cross-company targeted-advertising linkage, or
data-broker sharing. All 21 manifests in the signed archive set tracking to
false and declare zero tracking domains; the archive also contains no
AdSupport/AppTrackingTransparency linkage, tracking usage description, ads, or
attribution SDK. The owner confirmed that no off-repository practice changes
that conclusion.

### Proposed No answers supported by source

- **Contact Info → Name, Phone Number, Physical Address, and Other User Contact
  Info: No.** The shipped account flow asks for email/password only. It can read
  an optional Firebase display name but does not ask for or write one.
- **Health & Fitness → Health and Fitness: No.** No related framework,
  permission, data model, or feature is present.
- **Financial Info → Payment Info: No.** Payment details are entered into
  Apple's or Stripe's purchase system, and the reviewed Kanna source does not
  receive full card or bank-account details. Apple's definition expressly says
  developer-inaccessible payment information entered outside the app is not
  collected by the developer. **Credit Info and Other Financial Info: No.**
- **Location → Precise Location: No.** No location permission, SDK, or
  coordinates are requested. Coarse Location is also recommended No below.
- **Contacts: No.** No address-book permission or contacts feature is present.
- **User Content → Emails or Text Messages, Audio Data, Gameplay Content, and
  Customer Support: No.** Agent/task text is generic Other User Content, not an
  interpersonal messaging feature; support is not submitted in-app. Photos or
  Videos is also recommended No below.
- **Browsing History and Search History: No.** The terminal WebView is local,
  and task search filters loaded content or is serviced without retained search
  terms.
- **Usage Data → Advertising Data: No.** No advertising SDK or ad feature is in
  the pinned source, and production Firebase configuration has
  `IS_ADS_ENABLED=false`. Product Interaction and Other Usage Data remain
  recommended No for the reasons below.
- **Diagnostics → Crash Data and Performance Data: No.** Up to five crash
  records are local-only and explicitly copied by the user. The signed archive
  contains no Crashlytics, Firebase Performance, or Sentry pod, framework, or
  dSYM, and source imports no corresponding upload API.
- **Surroundings → Environment Scanning and Body → Hands and Head: No.** QR
  recognition is not environment scanning, and no body-tracking feature is
  present.

### Recommended resolution of the previously conditional types

| Data type | Recommended answer | Narrow basis under Apple's definitions |
| --- | --- | --- |
| Location → Coarse Location | **No** | The relay and Firebase Functions can log an IP address, but the verified implementation neither derives nor uses geographic location. Apple says to classify stored IP according to its use; here it supports security/diagnostics, so it is covered by Other Diagnostic Data rather than Coarse Location. |
| User Content → Photos or Videos | **No** | On WAN, a selected photo is transmitted through the relay only long enough to service the live request, and the relay source does not persist it. The retained copy is on the user's own Mac, not a Kanna-controlled store. This meets Apple's real-time-request exception; the policy still explains the complete path. |
| Sensitive Info | **No** | Kanna requests generic free-form developer content, not an Apple-defined sensitive attribute. Apple specifically directs generic free-form fields to Other User Content and says developers need not declare every type a user might incidentally enter. |
| Usage Data → Product Interaction | **No** | No product-interaction event stream or Analytics SDK is present. Firebase platform/version metadata is not an interaction event and is classified as Other Data Types with Analytics purpose. |
| Usage Data → Other Usage Data | **No** | No other retained app-activity telemetry path was found. Connection/security diagnostics remain Other Diagnostic Data. |

These recommendations are resolved from definitions, implementation, and the
exact signed archive, not left as owner classification homework.

## Signed archive privacy verification

The exact iOS `1.0.4 (5)` IPA has been inspected; the owner does not need to
inspect it:

- All 21 `PrivacyInfo.xcprivacy` manifests declare tracking `false` and no
  tracking domains. The main app manifest declares no collected data and only
  required-reason APIs. Bundled SDK manifests declare Firebase Messaging Device
  ID unlinked/App Functionality, Other Data Types unlinked/Analytics, and Other
  Diagnostic Data unlinked/App Functionality; Firebase Installations and Google
  Data Transport each declare Other Diagnostic Data unlinked/Analytics.
- Kanna's own server paths override SDK-level unlinking only where source proves
  it: the FCM token is stored below UID, so Device ID is linked; relay diagnostic
  logs carry UID/device context, so Other Diagnostic Data is linked. No source
  path links Firebase's Other Data Types platform metadata, so that type remains
  unlinked.
- No Firebase Analytics, Crashlytics, Performance, ads, attribution, or Sentry
  pod/framework/dSYM is present; there is no AdSupport/AppTrackingTransparency
  linkage or symbol and no `NSUserTrackingUsageDescription`. Web Firebase's
  aggregate dependency leaves `firebase/analytics` and `firebase/performance`
  module-name strings in the Hermes bundle, but source imports neither module
  and strings alone are not execution or collection. The absence of a native
  Firebase Analytics SDK does **not** erase the Analytics-purpose Other Data
  Types and Other Diagnostic Data declared by the bundled Messaging,
  Installations, and Google Data Transport manifests; the matrix includes those
  actual purposes.
- The exported `Info.plist` does contain
  `NSMicrophoneUsageDescription="Allow Kanna to access your microphone"`.
  Source has no microphone API call and the archive has no evidence of audio
  access or collection, so Audio Data remains No. Apple's privacy answer follows
  the actual data flow, not the presence of a configured permission description.
  This corrects the older answer sheet's false assertion that no microphone
  usage string exists.
- Camera, photo-library, and local-network usage strings are present as expected.
  Exported entitlements contain only app/team identity and production push
  notification entitlement; no background modes are declared.

**Release disposition:** treat the unused microphone description as a
nonblocking cleanup for this submission. Preserve the exact signed `1.0.4 (5)`
IPA unchanged; do not trigger a native rebuild or runtime-version bump solely
for this string. This is not a promise that Apple will accept the submission.
On the next native change, set Expo Camera's supported
`microphonePermission: false` and make every runtime-version bump required by
that native change. If a real microphone prompt or access is observed, reassess
Audio Data and the policy before publication/submission.

## Production retention evidence and inaccessible facts

The accessible retained evidence supports deletion scope but not a numeric log
or backup period:

- The production relay writes structured connection and byte-accounting events
  to stdout. Its checked-in `docker-compose.yml` specifies no Docker logging
  driver, `max-size`, `max-file`, or other rotation setting, and the VM
  provisioning scripts do not install a Docker daemon logging policy. The
  actual production VM's Docker daemon configuration is therefore not present
  in retained source.
- Firebase Functions deployment config specifies runtime and source only; it
  does not configure Cloud Logging bucket retention. Firestore config contains
  rules and indexes only; it does not declare backup schedules, point-in-time
  recovery, or retention.
- A read-only query of live project `kanna-build` was attempted, but the local
  gcloud credential requires interactive reauthentication and cannot be used in
  this task. Therefore the precise inaccessible facts are the live Cloud
  Logging bucket retention, live Firestore backup/PITR configuration, and live
  relay Docker daemon rotation settings.
- No support-mail retention system or schedule is represented in the pinned
  product source.

The approved policy consequently keeps the unsupported 30-day deletion, “short”
log period, and backup-rotation guarantees removed. It does not ask the owner
to invent replacement periods. The owner only needs to confirm that the
carefully limited wording—no fixed period asserted, callable scope stated, and
provider/log/backup exceptions disclosed—matches current operations and legal
obligations.

## Source-derived billing and deletion facts

- Apple purchase admission creates and stores an `appAccountToken` mapped to
  UID; verified transaction history stores original/current transaction IDs,
  purchase and signed dates, environment, status, expiry/grace, renewal,
  billing-retry, revocation, and notification evidence:
  `services/firebase-functions/src/billing/appStorePurchase.ts`,
  `appStoreVerification.ts`, and `appStoreEvents.ts`.
- Stripe Checkout creates a Stripe customer using UID metadata and account
  email and persists customer/subscription/session identifiers and entitlement
  state: `services/firebase-functions/src/billing/checkout.ts`,
  `stripeGateway.ts`, `stripeEvents.ts`, and `entitlement.ts`.
- The mobile action calls `deleteAccount` and signs out only after success:
  `apps/mobile/src/lib/firebase/accountDeletion.ts` and
  `apps/mobile/src/App.tsx`.
- Successful server deletion cancels verified Kanna Stripe subscriptions,
  expires verified open checkout sessions, removes the Firestore user tree,
  billing indexes, Apple notification records, push and desktop credentials,
  revokes refresh tokens, and deletes the Auth user:
  `services/firebase-functions/src/accountDeletion.ts`.
- The callable does not cancel Apple billing. The confirmation UI tells the
  user to cancel through Apple and offers **Manage Apple subscription**:
  `apps/mobile/src/components/AccountSheet.tsx`.
- `accountDeletions/{uid}` intentionally survives as a durable fence. It holds
  UID plus `started: true` and blocks recreation/purchase binding:
  `services/firebase-functions/src/accountDeletion.ts`,
  `services/firebase-functions/src/billing/types.ts`, and `firestore.rules`.

## Owner approval record

On September 16, 2026, the owner approved:

1. the exact policy text, recommended ASC matrix, and September 16, 2026
   effective date;
2. the operational assertions that Kanna does not sell data, perform
   advertising measurement or tracking, share with a data broker, or run an
   off-repository product/crash/performance analytics service that changes the
   matrix; and
3. the legal and retention wording, including provider/legal disclosures,
   children, policy-change notice, APPI and cross-border statements, the
   persistent UID deletion fence, and the absence of unsupported
   log/backup/support/provider retention durations.

The owner also confirmed no audio transmission. Audio Data remains No based on
the verified data flow, independently of the unused microphone purpose string.
These approvals make the package ready for the normal review workflow; they do
not themselves merge, deploy, publish, or modify App Store Connect.

## Definition references

- Apple, [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)
- Apple, [Manage app privacy in App Store Connect](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)
- Firebase, [Prepare for Apple's App Store data disclosure requirements](https://firebase.google.com/docs/ios/app-store-data-collection)
