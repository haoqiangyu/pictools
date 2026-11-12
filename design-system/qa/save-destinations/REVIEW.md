# Save destinations verification — 2026-11-10

The export dialog now offers **Save to Photos** and **Save to Files** on iOS/Android. Desktop exports use Files. Photos supports PNG/JPEG; the other four formats retain their encoded bytes and use Files. No implicit conversion occurs.

Single-image exports reuse encoded bytes across destinations and retries. Only successful writes mark a destination saved; duplicate saves to that destination are disabled within the export session. Cancellation, permission denial, restrictions, and write failure retain the result. Permission denial includes an Open Settings action.

Batch results track destinations independently. The chooser shows the number eligible for each destination; Photos only writes compatible, not-yet-saved results. Unsupported items and unfinished results remain available. Successful items are not repeated when retrying a partially saved batch.

Native implementation:
- iOS PhotoKit `addOnly`, `PHAssetCreationRequest.addResource`, completion after `performChanges` succeeds. No library enumeration or original modification.
- Android 10+: own MediaStore image, `IS_PENDING` during write, then publish; failed writes delete the pending record. No photo-read/storage permission.
- Android 9 and earlier: runtime WRITE_EXTERNAL_STORAGE, bounded by manifest `maxSdkVersion=28`; unique names in Pictures/Pictools and media scan.
- System Files picker remains responsible for user-selected destinations.

Verified:
- `flutter analyze`: no issues.
- `flutter test`: 53 tests passed, including seven new save-destination tests.
- iOS simulator debug build succeeded.
- iOS native integration passed with real PNG and JPEG writes to PhotoKit (simulator photos-add pre-granted for automation).
- Android Kotlin 2.2.20 compiler passed against cached Flutter embedding and Android 36 SDK. Full Android APK / device gallery validation remains unavailable because the project's Gradle distribution/dependencies could not be downloaded in this environment (same limitation as the preceding UI implementation).
- Reviewed actual Flutter dark phone export and book-layout export captures. Book export remains entirely in the right pane and retains the filename through rotation.

Figma Mobile2.0:
- Updated 29 existing export actions, preserving Files routes.
- Added 17 editable states for phone, dark theme, format compatibility, permissions, batch destination selection, and Duo outer/inner/book exports and results.
- Added 23 main prototype states and context-preserving Photos result routes. Connection audit: 154 connections, 0 missing targets.
- Design board: https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=33-22895

The Figma `plugin.js`, `finalize.js`, and `finish.js` under `design-system/save-destinations` record this one-off migration. Do not rerun the initial migration on a completed board.

Final verification: Figma version history visibly contains **Pictools 2.1 · 保存到相册与文件** with the final 17-state/23-prototype/154-connection summary. The latest normal iOS simulator app was rebuilt, installed, and launched after integration testing.
