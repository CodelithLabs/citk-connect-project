# 🎓 CITK Connect - Smart Campus Super-App

**CITK Connect** is a centralized mobile platform designed to bridge the gap between students, academic resources, and campus utilities at the **Central Institute of Technology, Kokrajhar**.

Built with **Flutter** & **Google Gemini AI**.

## 🚀 Features

### 🤖 1. AI Academic Assistant (Powered by Gemini)
- A context-aware chatbot that knows CITK specific data (Hostels, Library rules, Exam schedules).
- Uses **RAG (Retrieval Augmented Generation)** principles via System Instructions.
- **Tech:** Google Generative AI SDK (`gemini-1.5-flash`).

### 🗺️ 2. Smart Campus Map
- Satellite view of the CITK campus with markers for Hostels, Academic Blocks, and Canteens.
- **Tech:** Google Maps SDK for Android.

### 🚌 3. Live Bus Tracker
- Real-time tracking of the university bus from Santinagar to Campus.
- Visual route visualization and ETA updates.
- **Tech:** Google Maps Polyline & Custom Markers.

### 📅 4. Digital Class Routine
- Interactive Monday-Friday timetable tabs.
- Auto-highlights the "Next Class" based on current time.

### 📢 5. Digital Notice Board
- Instant updates on Exams, Holidays, and Tech Fests.
- "Pinned" section for urgent Admin alerts.

### 🆘 6. Emergency SOS
- One-tap access to Ambulance, Warden, and Security.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Authentication:** Firebase Auth (Email/Google)
* **AI:** Google Gemini API
* **Maps:** Google Maps SDK
* **State Management:** Riverpod
* **Local Storage:** Shared Preferences (Profile Data)
* **UI:** Material 3 Design + Google Fonts

## 📸 Screenshots

| Dashboard | AI Chat | Campus Map |
|-----------|---------|------------|
| ![Home](assets/screenshots/home.png) | ![AI](assets/screenshots/ai.png) | ![Map](assets/screenshots/map.png) |

*(Note: Add screenshots to an assets/screenshots folder to make this visible)*

## 🔧 Installation

1.  **Clone the repo**
    ```bash
    git clone [https://github.com/codelithlabs/citk-connect.git](https://github.com/codelithlabs/citk-connect.git)
    ```
2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```
3.  **Setup Keys**
    * Add `google-services.json` to `android/app/`.
    * Add your Google Maps & Gemini API Keys in `AndroidManifest.xml` and `gemini_service.dart`.
4.  **Run**
    ```bash
    flutter run
    ```

---

## 🤝 Contributing
Built with ❤️ by **Team CodelithLabs** for the Google Solutions Challenge.

---
