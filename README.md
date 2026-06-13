<div align="center">

# 🧠 MindMate — Mobile App

### AI-Powered Alzheimer's Care, in your pocket

*The Flutter mobile client for the [MindMate](https://github.com/MindMate-Project) platform — connecting patients and caregivers through smart reminders, memory preservation, and on-device face recognition.*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=flat-square&logo=dart)](https://dart.dev)
[![State](https://img.shields.io/badge/State-Bloc%2FCubit-13B9FD?style=flat-square&logo=flutter)](https://bloclibrary.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-3DDC84?style=flat-square&logo=android)](#)
[![API Docs](https://img.shields.io/badge/API%20Docs-Swagger-85EA2D?style=flat-square&logo=swagger)](https://alzaheimer-backend.onrender.com/api-docs/)

</div>

---

## 📋 Quick Links

[Overview](#-overview) · [Screenshots](#-screenshots) · [Features](#-features) · [Tech Stack](#-tech-stack) · [Architecture](#-architecture) · [Getting Started](#-getting-started) · [Configuration](#-configuration) · [Project Structure](#-project-structure) · [Related Repos](#-related-repositories) · [Notes & Roadmap](#-notes--roadmap)

---

## 🎯 Overview

**MindMate** is a full-stack platform that supports Alzheimer's patients and their care networks. This repository is the **cross-platform mobile app** (Flutter / Dart), built for two roles that share one coordinated experience:

- **👴 Patient** — a calm, simple interface for daily life: see today's appointments and medication, browse cherished memories, get gentle brain-training prompts, and **recognise people with the camera** when a face is forgotten.
- **🧑‍⚕️ Caregiver** — a management console for the people they care for: create and edit reminders, curate the patient's Memory Bank, schedule brain-training notifications, and register the faces the patient should recognise.

The app talks to the deployed [MindMate Backend](https://github.com/MindMate-Project/Backend) (`https://alzaheimer-backend.onrender.com`), which in turn calls the [AI face-recognition service](https://github.com/MindMate-Project/AI).

---

## 📸 Screenshots

> Captured on an Android emulator (Android 16) against the live backend. Demo data shown belongs to test accounts.

### Onboarding & Authentication

<table>
  <tr>
    <td align="center"><img src="screenshots/00_splash.png" width="200"/><br/><sub>Splash</sub></td>
    <td align="center"><img src="screenshots/01_role_selection.png" width="200"/><br/><sub>Choose your role</sub></td>
    <td align="center"><img src="screenshots/02_onboarding1.png" width="200"/><br/><sub>Onboarding</sub></td>
    <td align="center"><img src="screenshots/04_onboarding3.png" width="200"/><br/><sub>Remember faces</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/05_signup.png" width="200"/><br/><sub>Sign up</sub></td>
    <td align="center"><img src="screenshots/06_login.png" width="200"/><br/><sub>Login</sub></td>
    <td align="center"><img src="screenshots/03_onboarding2.png" width="200"/><br/><sub>Easy reminders</sub></td>
    <td align="center"></td>
  </tr>
</table>

### 👴 Patient experience

<table>
  <tr>
    <td align="center"><img src="screenshots/07_patient_home.png" width="200"/><br/><sub>Home — today at a glance</sub></td>
    <td align="center"><img src="screenshots/09_patient_medication.png" width="200"/><br/><sub>Medication schedule</sub></td>
    <td align="center"><img src="screenshots/10_patient_memory.png" width="200"/><br/><sub>Memory Bank</sub></td>
    <td align="center"><img src="screenshots/12_patient_profile.png" width="200"/><br/><sub>Profile</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/11_face_start.png" width="200"/><br/><sub>Face recognition</sub></td>
    <td align="center"><img src="screenshots/11b_face_camera.png" width="200"/><br/><sub>Scanning a face</sub></td>
    <td align="center"><img src="screenshots/11d_face_outcome.png" width="200"/><br/><sub>Not recognised → call caregiver</sub></td>
    <td align="center"><img src="screenshots/13_patient_caregiver_requests.png" width="200"/><br/><sub>Caregiver requests (consent)</sub></td>
  </tr>
</table>

### 🧑‍⚕️ Caregiver experience

<table>
  <tr>
    <td align="center"><img src="screenshots/15_caregiver_home.png" width="200"/><br/><sub>Home — connected patients</sub></td>
    <td align="center"><img src="screenshots/17_caregiver_add_appointment.png" width="200"/><br/><sub>Add appointment</sub></td>
    <td align="center"><img src="screenshots/25_caregiver_add_medication.png" width="200"/><br/><sub>Add medication</sub></td>
    <td align="center"><img src="screenshots/19_caregiver_add_memory.png" width="200"/><br/><sub>Add memory</sub></td>
  </tr>
  <tr>
    <td align="center"><img src="screenshots/21_caregiver_brain_training.png" width="200"/><br/><sub>Brain-training scheduler</sub></td>
    <td align="center"><img src="screenshots/23_caregiver_register_face.png" width="200"/><br/><sub>Register a known person</sub></td>
    <td align="center"><img src="screenshots/24_caregiver_notifications.png" width="200"/><br/><sub>Connected patients</sub></td>
    <td align="center"><img src="screenshots/26_caregiver_profile.png" width="200"/><br/><sub>Profile</sub></td>
  </tr>
</table>

---

## ✨ Features

### Shared
| Capability | Description |
|---|---|
| 🔐 **Role-based auth** | Sign up with full profile, email login with *Remember me*, password reset via email code. Session token stored in encrypted secure storage; routing adapts to the user's role. |
| 🧭 **Onboarding** | Role selection (Patient / Caregiver) followed by a tailored, illustrated walkthrough. |
| 👤 **Profile** | View and edit name, email, phone, gender, and date of birth, with avatar upload. |
| 🔔 **Notifications** | On-device local notifications and full-screen alarms for medication & appointments; consent-based caregiver↔patient connection. |

### 👴 Patient
| Capability | Description |
|---|---|
| 🏠 **Home dashboard** | Personal greeting, the next upcoming appointment, and *Today's Medicine*. |
| ⏰ **Reminders** | Appointments and Medication on a weekly calendar (read-only — set by the caregiver). |
| 💾 **Memory Bank** | Browse photo, video, and text memories with search. |
| 🧩 **Face recognition** | Point the camera at a person → the photo is sent through the backend to the AI service → shows **who they are and the relationship**, or *"Person not found"* with a one-tap **Call caregiver** fallback. |
| 🧠 **Brain training** | Receives scheduled memory prompts curated by the caregiver. |

### 🧑‍⚕️ Caregiver
| Capability | Description |
|---|---|
| 🏠 **Patient management** | See connected patients, switch the active patient, and view their reminders. |
| ⏰ **Reminders CRUD** | Create / edit / delete **appointments** (doctor, specialty, location, purpose, date/time, reminders) and **medications** (drug, dosage, type, frequency, schedule). |
| 💾 **Memory Bank CRUD** | Add photo / video / text memories (with relation & tags), edit, and delete. |
| 🧠 **Brain-training scheduler** | Toggle daily memory notifications sent to the patient and pick up to 6 daily times. |
| 🧩 **Register known people** | Add a person the patient should recognise (name, relationship, ≥3 face photos) to power patient-side face recognition. |

---

## 🚀 Tech Stack

| Area | Technologies |
|---|---|
| **Framework** | Flutter · Dart |
| **State management** | `flutter_bloc` (Cubit) |
| **Networking** | `dio` (single configured client, Bearer auth, cold-start warm-up) |
| **Secure storage / prefs** | `flutter_secure_storage` (JWT) · `shared_preferences` (active-patient context, schedules) |
| **Notifications & time** | `flutter_local_notifications` · `timezone` · `flutter_timezone` |
| **Media** | `camera` · `image_picker` · `video_player` · `cached_network_image` · `image` |
| **UI** | `google_fonts` (Cairo) · `smooth_page_indicator` · `easy_date_timeline` · `pinput` · `url_launcher` · `audioplayers` |
| **Backend** | MindMate REST API (Express/TypeScript + MongoDB), AI face service (FastAPI/InsightFace) |

---

## 🏗️ Architecture

A **feature-first, layered (clean) architecture**. Each feature owns its own `data`, `domain`, and `presentation` layers, and UI state is driven by Cubits.

```
presentation (screens, widgets, cubit)  ──>  domain (models)  ──>  data (services, models, mappers)  ──>  Backend API
```

- **Cubit** holds screen state and calls services; widgets rebuild via `BlocBuilder` / `BlocConsumer`.
- **Services** wrap the shared `Dio` client (`core/network/api_http_client.dart`) and attach the bearer token from secure storage.
- **`PatientContextStore`** tracks the currently active patient so caregiver screens act on the right person.
- Navigation uses named routes registered in `main.dart` (with a graceful *"Coming soon"* fallback for unregistered routes).

---

## 🧑‍💻 Getting Started

### Prerequisites
- **Flutter SDK** 3.x (Dart 3.x) — run `flutter doctor` and resolve any issues
- **Android Studio** / Xcode with an emulator or a physical device
- A running emulator or connected device (`flutter devices`)

### Run
```bash
# 1. Clone
git clone https://github.com/MindMate-Project/MindMate-app.git
cd MindMate-app

# 2. Install dependencies
flutter pub get

# 3. Launch a device (Android example)
flutter emulators --launch <emulator_id>

# 4. Run the app
flutter run
```

The app points at the **deployed backend** out of the box, so no local server is required. The backend runs on a free Render dyno that sleeps when idle — the first request after inactivity can take ~30–60s while it wakes (the splash screen warms it up automatically).

---

## ⚙️ Configuration

| Setting | Where | Notes |
|---|---|---|
| **Backend base URL** | `lib/core/config/api_config.dart` (`ApiConfig.baseUrl`) | Defaults to `https://alzaheimer-backend.onrender.com`. |
| **Optional API key** | `--dart-define=MINDMATE_API_KEY=...` | Read by `Secrets.apiKey` at build time. **Never hard-code secrets** in `secrets.dart` — it is committed. |

```bash
# Example: run with an API key supplied at build time
flutter run --dart-define=MINDMATE_API_KEY=your_key_here
```

---

## 📂 Project Structure

```
lib/
├── main.dart                      # App entry: providers, theme, named routes, notification bootstrap
├── core/
│   ├── config/                    # api_config.dart, secrets.dart
│   ├── network/                   # api_http_client.dart (Dio), patient_context_store.dart
│   ├── navigation/                # app_bottom_nav.dart, app_navigation.dart
│   ├── themes/                    # app_theme.dart
│   ├── utils/                     # responsive, validation
│   └── widgets/                   # shared widgets (cards, avatars, form fields, nav bars)
└── features/
    ├── onboarding/                # role selection + walkthrough
    ├── auth/                      # signup, login, forgot/reset password, splash
    ├── assignments/               # caregiver↔patient assignment & consent
    ├── memory/                    # Memory Bank (photo/video/text) + brain training
    ├── caregiver/
    │   ├── home/                  # caregiver dashboard
    │   └── known_people/          # register faces the patient should recognise
    └── patient/
        ├── home/                  # patient dashboard
        ├── reminders/             # appointments & medication (+ add/edit/detail/alarm)
        ├── face_recognition/      # camera → identify → result screens
        └── profile/               # profile, edit, notifications, assignment inbox, privacy
```

Each feature typically follows:
```
features/<feature>/
├── data/        # models, services (API), mappers
├── domain/      # domain models
└── presentation/
    ├── cubit/   # state management
    ├── screens/ # full pages
    └── widgets/ # feature-local widgets
```

---

## 🔗 Related Repositories

| Repo | Stack | Role |
|---|---|---|
| 🔷 [Backend](https://github.com/MindMate-Project/Backend) | TypeScript · Express · MongoDB · Socket.io | REST API, auth, reminders, memories, alerts, location, IoT |
| 🔷 [AI](https://github.com/MindMate-Project/AI) | Python · FastAPI · InsightFace · ONNX | Face-recognition microservice |
| 🔷 [Web](https://github.com/MindMate-Project/Web) | React · Redux Toolkit | Web dashboard for caregivers & families |
| 🔷 [Mobile App](https://github.com/MindMate-Project/MindMate-app) | Flutter · Dart | **This repository** |

📚 **Live API docs:** [alzaheimer-backend.onrender.com/api-docs](https://alzaheimer-backend.onrender.com/api-docs/)

---

## 📝 Notes & Roadmap

- **Reminders are caregiver-managed.** Patients view their reminders read-only; only caregivers can add/edit/delete them.
- **Real-time location tracking** is implemented on the backend (Socket.io + MQTT) and surfaced on the Web dashboard. The caregiver bottom-nav **Location** tab is a placeholder in the app and not yet wired to a screen.
- Unregistered routes degrade gracefully to a *"Coming soon"* page rather than crashing.

---

<div align="center">

*Built with ❤️ to improve the quality of life for Alzheimer's patients and their families.*

**Part of the [MindMate Project](https://github.com/MindMate-Project)**

</div>
