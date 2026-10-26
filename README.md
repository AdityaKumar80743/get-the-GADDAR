# 🕵️ Get the GADDAR — Real-Time Multi-Phone Social Deduction Party Game

[![Build Android APK](https://github.com/AdityaKumar80743/get-the-GADDAR/actions/workflows/build_apk.yml/badge.svg)](https://github.com/AdityaKumar80743/get-the-GADDAR/actions/workflows/build_apk.yml)

**Get the GADDAR** is an exhilarating real-time social deduction party game built with **Flutter** and **Supabase Realtime**. Every player plays simultaneously on their own Android smartphone with **zero accounts required** (instant guest join via 6-digit room code).

---

## 🎮 Game Concept & Rules

1. **Host Creates Room**: Select round timer, max rounds, categories (Bollywood, Cricket, Memes, Food, Anime, or Custom Words), and number of Gaddars.
2. **Friends Join via 6-Digit Code**: Each friend enters a nickname, picks an avatar, and joins from their own smartphone.
3. **Role Reveal (Shield Your Screen!)**:
   - **Friends (Loyal)**: Peek to see the **Secret Word** (e.g. *"MS Dhoni"*).
   - **Gaddar (Traitor)**: Peeks and sees **"YOU ARE THE GADDAR"** with only a subtle category hint (e.g. *"Helicopter Finisher"*). Gaddar does not know the exact word!
4. **Discussion & Clue Round**:
   - Players take turns speaking a 1-word or phrase clue out loud in real life.
   - The Gaddar must bluff and blend in without giving away that they don't know the word.
5. **Secret Ballot Voting**:
   - Every player casts their vote privately on their own phone.
   - Voter names are 100% anonymous in the ballot box.
6. **Last Chance Clue / Victory**:
   - If caught, the Gaddar gets one final chance to guess the secret word to steal victory!
   - Full post-game leaderboard ranks players by secret score and survival rounds.

---

## 🚀 Supabase Backend Setup

The project is pre-configured with your Supabase credentials in `lib/main.dart`:
- **Project URL**: `https://hrkdyopytppbcntgwayo.supabase.co`
- **Anon Public Key**: Configured as default in `lib/main.dart`

### ⚠️ Required Step for Database Setup:
To enable room creation and real-time multiplayer synchronization, execute the SQL schema once in your Supabase project:
1. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/hrkdyopytppbcntgwayo).
2. Go to **SQL Editor** (icon with `>_` on the left sidebar).
3. Click **New Query**.
4. Copy and paste the entire contents of [`supabase/migrations/20261026000000_get_the_gaddar_schema.sql`](supabase/migrations/20261026000000_get_the_gaddar_schema.sql).
5. Click **Run**.
   - This creates the `rooms`, `players`, `custom_words`, and `votes` tables with Row Level Security (RLS), adds them to `supabase_realtime`, and installs the 8 atomic barrier RPC functions.

---

## 📦 Building & Installing the APK

### Automatic Cloud Build (Recommended via GitHub Actions)
Every push to `main` triggers `.github/workflows/build_apk.yml`:
1. Go to the [GitHub Actions tab](https://github.com/AdityaKumar80743/get-the-GADDAR/actions).
2. Click on the latest workflow run: **Build Release APK**.
3. Under **Artifacts**, download **`get-the-gaddar-android-apk`**.
4. Extract the `.zip` file on your phone or PC to get `app-release.apk`.
5. Tap `app-release.apk` to install on your Android device.

### Local Build (Requires Android SDK & Flutter)
```bash
flutter pub get
flutter build apk --release
```
The output APK will be generated at:
`build/app/outputs/flutter-apk/app-release.apk`
