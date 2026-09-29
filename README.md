# Daybook

**Clear your head. Close your day.**

A calm, clean journal, notes, and reminders app for iPhone, built for working professionals and everyday parents. Get things out of your head during the day, then close out the day in two minutes at night. Your journal writes itself from what you got done.

> "Daybook" and the `com.zeroday.daybook` bundle ID are placeholders. Rename them in `project.yml` whenever you settle on a name.

## What's in v1

| Tab | What it does |
| --- | --- |
| **Today** | Today's score, a daily journaling prompt, one tap quick add (journal, note, reminder), what's due today, and your last entry. |
| **Journal** | Entries grouped by month, mood tracking with emoji, search, share, edit, delete. |
| **Notes** | Fast plain notes with pinning, search, and swipe actions. |
| **Reminders** | Work / Family / Personal lists, due times, repeat (daily, weekdays, weekly), effort points, local notifications. |
| **Evening Close-Out** | A three step nightly wrap-up: see what you got done and your score, roll unfinished items to tomorrow or drop them, then tap a mood and write one line. Saved to the journal with the day's points and finished tasks. |

### Points

Every reminder has an effort size: **Quick +1**, **Medium +3** (the default), or **Big +5**. Checking it off adds to today's score.

- No streaks, so a missed day never takes anything away. Instead the close-out celebrates personal bests ("Your best Tuesday this month", "Your best day this week").
- Weekly and all-time totals, with milestones at 50, 100, 250, 500, 1,000 and up.
- Earned points are logged separately (`TaskCompletion`), so deleting a reminder later never lowers a past score.
- Repeating reminders reset each day and can be earned again every time they come around.

Design choices:
- Warm "paper" background, soft white cards, sage green accent. Full dark mode.
- Serif type for anything you write, so it feels like a journal, not a spreadsheet.
- Everything is stored on device with SwiftData. No accounts, no servers, no tracking. That makes App Review and the privacy label simple.
- Notification permission is only requested the first time you set a reminder time, not at launch.

## Tech

- SwiftUI + SwiftData, iOS 17 and up, iPhone
- Zero third party dependencies
- Project generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml` so the repo stays clean

```
Daybook/
  App/            App entry point, notification delegate, preview data
  Models/         JournalEntry, Note, Reminder (SwiftData)
  Services/       NotificationManager (local reminders)
  Design/         Theme (colors, fonts, card style), daily prompts
  Views/          Today, Journal, Notes, Reminders, shared components
  Resources/      Asset catalog (colors, app icon), privacy manifest
```

## Run it on your Mac

You need a Mac for iOS development. There is no way around this one.

1. Install **Xcode** from the Mac App Store (free).
2. Install XcodeGen: `brew install xcodegen`
3. Clone this repo, then from the repo root:
   ```bash
   xcodegen generate
   open Daybook.xcodeproj
   ```
4. In Xcode, pick an iPhone simulator and press **Cmd + R**.
5. To run on your own iPhone: select the Daybook target, go to **Signing & Capabilities**, and choose your Apple ID team.

## Road to the App Store

1. **Apple Developer Program**: enroll at developer.apple.com ($99/year).
2. **App icon**: drop a 1024x1024 PNG into `Resources/Assets.xcassets/AppIcon.appiconset` (no transparency).
3. **Bundle ID and team**: set `PRODUCT_BUNDLE_IDENTIFIER` and `DEVELOPMENT_TEAM` in `project.yml`, then rerun `xcodegen generate`.
4. **App Store Connect**: create the app record, fill in description, keywords, category (Productivity or Lifestyle), and support URL.
5. **Privacy policy URL**: required even though no data leaves the device. A one page site is fine.
6. **Privacy label**: "Data Not Collected" is accurate for this build.
7. **Screenshots**: 6.9" and 6.5" iPhone sizes. The simulator's Cmd + S works well.
8. **Archive and upload**: Xcode, Product, Archive, then Distribute App. Test with TestFlight first.

## Roadmap

Next up:
- One capture box that sorts anything you type into a note, reminder, or journal line (on-device AI, iOS 26)
- Family members and a chore scoreboard with rewards ("50 points = pizza night")
- Work mode and home mode tied to iPhone Focus
- Nightly "time to close out" notification

Later:

- iCloud sync across devices (SwiftData + CloudKit)
- Face ID lock for the journal
- Home Screen and Lock Screen widgets (today's prompt, next reminder)
- Photos in journal entries
- Shared family reminder lists
- Mood trends over time with Swift Charts
- Daily "time to journal" nudge
- Premium tier via StoreKit subscriptions
