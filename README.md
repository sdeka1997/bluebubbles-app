# BubbleBeam

BubbleBeam is an Android client for iMessage. It's a fork of [BlueBubbles](https://github.com/BlueBubblesApp/bluebubbles-app): it connects to a Mac you own, which sends and receives iMessages on your behalf.

It began as a few fixes to BlueBubbles and grew into its own app: a new storage layer, Find My that mirrors the Mac, Apple-style thread grouping and read-state sync, and a lot of memory and speed work. It pairs with its own [server fork](https://github.com/sdeka1997/bluebubbles-server).

> **BubbleBeam is an independent project.** It isn't made, endorsed or supported by the BlueBubbles team, so please don't take BubbleBeam issues to them.

> **You need a Mac running the BubbleBeam server and signed in to iMessage.**

---

## What's different from BlueBubbles

### Behaves like your iPhone
- **Threads grouped the way Messages groups them:** the same person over iMessage, SMS and RCS shows up as one thread, as on an iPhone.
- **Read state stays in step with Apple:** reading or marking unread on a Mac or iPhone shows on Android, including changes made while the phone was offline.
- **Spam stays in Spam:** chats Apple files under Spam don't show up in the main list or notify.
- **Reactions:** emoji tapbacks, and people named by first name as on the iPhone.
- **Accurate composer:** Edit and Undo Send only appear while they still work.

### Find My, mirrored from the Mac
- Friends, devices and items, mirrored from the Mac's own Find My (macOS 12 through 15).
- Live location while a Find My screen is open. The Mac only runs Find My while you're looking.
- Accessories that appear twice (such as AirPods) are merged into one.

### Faster, lighter, steadier
- **SQLite storage** replaces ObjectBox: chats open from an index instead of sorting their whole history.
- **Memory:** about 360 MB at launch and about 600 MB after long scrolls through image-heavy chats. The BlueBubbles code this fork started from used 1.1–1.5 GB at launch and could reach 1.7 GB in an image-heavy chat.
- **Launch:** the chat list appears in 2–3 s, with sync done in 3–4 s.
- **Contacts:** the app downloads contact photos only when they change (72 KB per launch instead of 4.2 MB).
- **Notifications:** large messages that used to be dropped now get through, and push registration retries quietly instead of showing an error.

---

## Getting started

1. Install the **server** on your Mac from [the server fork](https://github.com/sdeka1997/bluebubbles-server).
2. Build the **app** from this repository (see below). There are no store listings yet.
3. Connect them the same way as BlueBubbles: the [BlueBubbles installation guide](https://bluebubbles.app/install/) still applies.

### Building

```bash
touch .env            # the app reads an optional .env at build time; an empty one is fine
flutter pub get
flutter test
flutter build apk --flavor alpha --release
```

You'll need your own signing key for a release build.

---

## Branches

- `main`: the app as it runs today. Everything is built from here.
- `master`: an unchanged copy of upstream BlueBubbles, used to track their changes.
- `archive/*` and `backup/*`: old work kept for reference.

---

## Credits and license

BubbleBeam is built on [BlueBubbles](https://github.com/BlueBubblesApp/bluebubbles-app), and keeps their work and its history. Thanks to the BlueBubbles team and contributors.

Licensed under the [Apache License 2.0](LICENSE), like BlueBubbles. Files changed in this fork carry those changes in the project's git history.

Mac, iMessage, iPhone, FaceTime and Find My are trademarks of Apple Inc. BubbleBeam isn't affiliated with Apple.
