# Import sources and save destinations — 2026-11-10

Photos and Files were already separate native import routes. The shared mobile source chooser now makes both explicit: 从相册导入 / 从文件导入, with descriptions. Home, comparison A/B, crop/resize, enhancement, replacement, and batch add all use the shared route. Desktop continues to use the system file picker.

The batch empty screen's primary button now calls the batch importer, enabling multiple selection from the very first import. Android photo import disables FilePicker's additional JPEG recompression; iOS retains the compatible photo representation. Imported content still undergoes existing size, format, and animated-image validation.

Import source never determines export destination. Existing mobile Save to Photos / Save to Files behavior remains in place for single-image exports and batch results. Photos accepts PNG/JPEG; Files accepts PNG/JPEG/WebP/BMP/ICO/TIFF. Unsupported photo formats explicitly direct users to Files. Successful destinations are tracked independently; cancellation and failures do not mark an item saved. Native save validation is documented in ../save-destinations/REVIEW.md.

Verification:

- 71 Flutter tests passed; 16 dedicated import tests cover iOS/Android picker routing, single/multiple selection, cancellation, home plus all four tools, 320px width, 2× German text, and fold exclusion.
- Two additional import visual cases cover actual phone and book-layout dialogs; captures include the modal after its opening animation. No layout exceptions.
- flutter analyze: no issues.
- iOS simulator debug build succeeded; the regular application was installed and launched after this change.
- Native picker routes were inspected in pinned file_picker 8.3.7: iOS Photos uses PHPicker, Files uses UIDocumentPicker; Android Photos uses ACTION_PICK and Files uses ACTION_OPEN_DOCUMENT. Automated routing tests mock the FilePicker boundary, so they do not represent manual Android device picker validation.
- Full Android APK/device verification remains subject to the Gradle download limitation recorded in the earlier save-destination review.

Figma Mobile2.0:

- Updated the two original source panels in place.
- Added five editable examples and five matching prototype states: phone, Duo outer display, Duo book posture, batch, and dark theme.
- Book modal avoids the hinge and the illustrated right system region; phone dialog spacing follows Flutter's shared source component.
- Audited 30 connections; 0 invalid targets. See ledger.json.
- Design board: https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=33-22895
- Phone import: https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=33-27318
- Duo book import: https://www.figma.com/design/3qrw9KAjbnymygVAnmFwlO/Pictools?node-id=33-27764
- Saved named version “Pictools 2.1 · 导入来源与保存去向统一”; version history visibly displayed the new description and “just now”.

The scripts in design-system/import-sources record the one-off Figma migration. Do not rerun patch.js on the completed board. Screens are editable Figma layers; Flutter captures are QA evidence only.
