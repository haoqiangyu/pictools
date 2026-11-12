# Native launch mark

The existing Pictools brand is rendered at 96pt with 1×, 2× and 3× assets. Run `swift scripts/generate_launch_icon.swift` from the repository root to regenerate these PNGs. The storyboard constrains both dimensions, preserving the mark in portrait and landscape.

Background appearance comes from `LaunchBackground.colorset`, shared by `LaunchScreen.storyboard` and the initial Flutter controller in `Main.storyboard`. It follows system appearance before Flutter settings are available. The mark stays burnt orange and white in both modes.

See `design-system/pages/launch.md` for Android resource equivalents and startup handoff behavior. Native launch changes require a full rebuild; hot reload cannot update a system launch snapshot.
