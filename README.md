# CITK Connect: The All-in-One Student Portal

Welcome to the CITK Connect project! This is a monorepo containing the web and mobile applications for a hackathon project sponsored by Google. Our goal is to solve common challenges faced by new students at CITK with a modern, AI-powered platform.

## 💡 The Problem

Every year, new students at CITK face:
*   **Navigation Chaos:** Finding their way around a large campus.
*   **Documentation Anxiety:** Dealing with complex admission paperwork.
*   **Communication Gaps:** Lacking a direct line to seniors or faculty for guidance.

## 🛠 The Solution

We're building a unified platform featuring:
*   **🗺️ AI-Powered 3D Campus Map:** A virtual guide to the CITK campus.
*   **📄 Smart Document Assistant:** Step-by-step help for all admission-related paperwork.
*   **🤝 Senior Connect:** A directory to connect freshers with student mentors.
*   **📅 Event Tracker:** Real-time updates on important dates and events.

## 🏗️ Project Architecture

This project is a **monorepo** containing two main clients:

```text
citk-connect-project/
├── web-client/         # The Next.js (React) Student Portal
└── mobile-app/         # The Flutter-based Mobile Application
```

*   **`web-client`**: A modern web application built with [Next.js](https://nextjs.org/) and [Tailwind CSS](https://tailwindcss.com/). It connects directly to Firebase for backend services.
*   **`mobile-app`**: A cross-platform mobile app built with [Flutter](https://flutter.dev/).

## Getting Started

### Web Client

To run the web application:
1.  Navigate to the `web-client` directory: `cd web-client`
2.  Install dependencies: `npm install`
3.  Run the development server: `npm run dev`
4.  Open [http://localhost:3000](http://localhost:3000) in your browser.

### Mobile App

To run the mobile application:
1.  Navigate to the `mobile-app` directory: `cd mobile-app`
2.  Install dependencies: `flutter pub get`
3.  Run the app on a connected device or emulator.

---
*This project was bootstrapped for a Google-sponsored hackathon.*
