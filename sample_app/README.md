# Taskly: Fewchurs sample app

A small to-do app that shows the main ways to add Fewchurs.

| Where | What it shows | File |
|---|---|---|
| **Ideas** tab | `FewchursBoard` embedded as a tab | `lib/pages/home_shell.dart` |
| 💡 button on Tasks | `Fewchurs.showBoardSheet` | `lib/pages/tasks_page.dart` |
| "Coming soon" card | Headless `BoardController` with your own widgets | `lib/widgets/roadmap_card.dart` |
| Settings → Feature requests | `Fewchurs.showBoard` | `lib/pages/settings_page.dart` |
| Settings → Suggest a feature | `showFewchursSubmitSheet` | `lib/pages/settings_page.dart` |
| Settings → Quick idea | `Fewchurs.submitFeature` from a custom form | `lib/pages/settings_page.dart` |
| Settings → Branded board | `FewchursTheme`, `BoardOptions`, builders | `lib/pages/settings_page.dart` |
| Settings → Pro / email / theme | `isSubscriber`, `userEmail`, light and dark mode | `lib/main.dart` |

## Run

```bash
flutter create . --project-name taskly --platforms=android,ios,web,macos
flutter run --dart-define=FEWCHURS_API_KEY=fr_live_xxx
```

On Android release builds, add the `INTERNET` permission. On macOS, add the `network.client` entitlement. The web build needs CORS enabled on the server.
