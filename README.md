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

### ⚠️ Required Steps for Database Setup:
To enable room creation, real-time multiplayer synchronization, dynamic words, and images:
1. Open your [Supabase Dashboard](https://supabase.com/dashboard/project/hrkdyopytppbcntgwayo).
2. Go to **SQL Editor** (icon with `>_` on the left sidebar) $\rightarrow$ **New Query**.
3. Run [`supabase/migrations/20261026000000_get_the_gaddar_schema.sql`](supabase/migrations/20261026000000_get_the_gaddar_schema.sql) (Core Game Schema & Multi-Phone Barrier RPCs).
4. Run [`supabase/migrations/20261028000000_global_words_and_images.sql`](supabase/migrations/20261028000000_global_words_and_images.sql) (`global_words` table with multiple hints per word, image URLs, and pre-seeded content).

---

## 🛠️ Local Word Vault Manager (`admin.html`)

You can add, edit, or delete words, multiple hints, and image URLs **locally without rebuilding the APK**:
1. Simply double-click [`admin.html`](admin.html) to open it in your browser (Chrome, Edge, Firefox, Brave, etc.).
2. Features:
   - Add words under standard or custom categories.
   - Attach **multiple hints** (in each game, the Gaddar gets one randomly chosen hint!).
   - Add an optional **Image URL** with live image preview.
   - Search, filter, and delete words with 1-click Supabase live synchronization.
   - Works 100% locally from your computer — no hosting required!

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
