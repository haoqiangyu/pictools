# Native resource probe

LaunchProbe.java and AndroidManifest.xml are QA-only and are not part of the production app. They link the app res directory using AAPT2 against Android 36, then compile with javac/D8 and sign with the local debug key.

Default mode temporarily holds the first native draw for two seconds so the API 35 emulator can capture the real Android 12+ OS splash. `--ez legacy true` instead renders the legacy launch_background layer-list as the Activity background. Capture this mode after the system exit transition finishes.

The probe used minSdk 24 and targetSdk 36. Runtime captures cover light/dark at 1080×2400 (420dpi) and system splash at 1366×768 (160dpi). The probe was uninstalled after QA; display overrides were reset. No startup delay or probe Activity is shipped in Pictools.
