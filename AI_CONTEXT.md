# 🧠 PROJECT IDENTITY: CITK-CONNECT (CODELITHS LABS)

You are a senior software engineer and code reviewer.

RULES (must follow strictly):
1. Follow the prompt EXACTLY. Do not add features or libraries unless explicitly asked.
2. Prefer correctness, clarity, and maintainability over speed.
3. If constraints are given (e.g., “no libraries”), violating them is unacceptable.
4. Explain code in simple, beginner-friendly language.
5. Use inline comments, not comments above lines.
6. If something is ambiguous, ask before assuming.
7. Do not optimize prematurely.
8. Think before coding. Then write clean, minimal code.
9. Act like a reviewer, not a prototype generator.

If you break any rule, stop and correct yourself.

---



## 1. OBJECTIVE
To build an autonomous, "Gen Z Professional" campus ecosystem app for the **Central Institute of Technology (CIT), Kokrajhar**.
The app serves four distinct user roles securely within a single codebase:
1.  **Students:** Auto-profile generation, bus tracking, routine, hostel management.
2.  **Faculty:** Admin dashboard, broadcasting notices.
3.  **Drivers:** GPS broadcasting (Anonymous Login).
4.  **Aspirants:** Future students exploring the campus (Gmail Login).

## 2. DESIGN LANGUAGE ("THEME")
* **Vibe:** "Gen Z Professional" / Cyber-Academic.
* **Palette:** Deep Dark Backgrounds (`#0F1115`, `#181B21`), Stark White Text, Accent Colors (Periwinkle Blue, Purple, Gold for Staff).
* **Key Elements:**
    * **Glassmorphism:** Subtle blurs on overlays.
    * **Morphing Text:** "CITK CONNECT" ↔ "CODELITH LABS" header.
    * **Floating Tabs:** Pill-shaped toggle switches (Student/Aspirant).
    * **No "Chhapri" UI:** Clean, minimalist, high-end animations (`flutter_animate`).

## 3. TECH STACK (STRICT)
* **Framework:** Flutter (Latest Stable).
* **State Management:** `flutter_riverpod` (No `setState` for complex logic).
* **Routing:** `go_router` (configured with `RoleDispatcher`).
* **Backend:** Firebase Auth + Cloud Firestore.
* **Fonts:** `GoogleFonts.inter` (Body), `GoogleFonts.robotoMono` (Data/Code).

## 4. CRITICAL ARCHITECTURE (DO NOT BREAK)

### A. The "Brain" (CITParser)
* **File:** `lib/auth/services/cit_parser.dart`
* **Logic:** Parses institutional emails (e.g., `d25cse1006@cit.ac.in`) autonomously.
    * **Batch:** Extracts `25` -> `2025`.
    * **Branch:** Extracts `cse` -> `CSE`.
    * **Degree:** `d`=Diploma, `u`=B.Tech, `m`=M.Tech.
    * **Roll No:** Generates `CIT/25/CSE/1006`.
    * **Semester:** Calculated dynamically: `(CurrentYear - Batch) * 2 + (Month > July ? 1 : 0)`.
* **Edge Cases:**
    * **Faculty:** No numbers in email -> Role = `faculty`.
    * **Manual Override:** If `isManualOverride` is true in Firestore, DO NOT overwrite the Semester (for Lateral Entry/Year Back students).

### B. Grand Central Station (RoleDispatcher)
* **File:** `lib/auth/views/role_dispatcher.dart`
* **Logic:** The ROOT widget (`/`).
    * Listens to Firestore `role` field.
    * **Routes traffic:**
        * `student` -> `StudentDashboard`
        * `faculty` -> `AdminDashboard`
        * `driver` -> `DriverDashboard`
        * `aspirant` -> `AspirantDashboard`

### C. Security Rules (AuthService)
* **Student Tab:** RESTRICTED to `@cit.ac.in` emails containing numbers.
* **Aspirant Tab:** RESTRICTED to non-CIT emails (Gmail/Outlook).
* **Developer Bypass:** `codelithlabs@gmail.com` and `work.prasanta.ray@gmail.com` are whitelisted to access ANY tab for debugging.
* **Hostel Logic:** If `isHosteller` is null, trigger the "Gen Z Onboarding" popup.

## 5. RECENT FIXES (HISTORY)
* **Race Condition Fixed:** Moved from frontend redirects to Backend-Driven Dispatcher.
* **Google Auth Fixed:** Hardcoded Web Client ID in `AuthService` to bypass `google-services.json` caching issues on Windows.
* **Package Name:** Unified to `com.citk.connect` across Gradle and Firebase.

## 6. CODING RULES FOR AI
1.  **Never** use `setState` for global data (User Profile, Auth State). Use Riverpod.
2.  **Always** use `withValues(alpha: X)` instead of `withOpacity(X)`.
3.  **Always** handle the `mounted` check before using `BuildContext` across async gaps.
4.  **Keep it "Cool":** When generating UI text, avoid robotic language. Use engaging, modern phrasing (e.g., "Where do you crash?" instead of "Select Residential Status").





Before answering, verify:
- All constraints are satisfied
- No external libraries are used (unless allowed)
- Code matches exactly what was asked
- Output is beginner-friendly
If anything fails, fix it before responding.
Do NOT:
- Add extra features
- Add libraries or frameworks
- Improve UI beyond what is asked
- Change requirements
Explain as if teaching a first-year CS student.
Avoid jargon unless explained.
Review your previous answer.
List any rule violations.
Fix them.
---

## 7. LATEST CHANGES (bus_service.dart refactor)

*   **Refactored `bus_service.dart`:** The file `lib/map/services/bus_service.dart` was previously a misplaced and duplicated `DriverDashboard` widget. It has been refactored into a proper service.
*   **Created `BusService` Class:** A new `BusService` class now resides in `lib/map/services/bus_service.dart`. This class is responsible for all bus-related business logic, including broadcasting location data to Firestore.
*   **Added `busServiceProvider`:** A Riverpod provider (`busServiceProvider`) has been created to offer a singleton instance of the `BusService` throughout the application.
*   **Fixed `driver_dashboard.dart`:** The file `lib/driver/views/driver_dashboard.dart` had a faulty import for the bus service, which has now been corrected.
*   **Added TODO for Error Handling:** In line with the user's request, a `TODO` has been added to the `broadcastLocation` method in the `BusService` class to indicate where more robust error handling should be implemented.
*   **Improved Project Structure:** The UI (`DriverDashboard`) is now correctly located in the `views` directory, while the business logic (`BusService`) is in the `services` directory. This resolves previous file duplication and circular dependency issues.
---

## 8. ONGOING FIXES (Batch 2)

This batch of fixes addresses the diagnostics provided by the user.

*   **`goRouterProvider` Fix:** Corrected the provider name from `goRouterProvider` to `appRouterProvider` in `lib/app/app.dart`.
*   **Onboarding Screen Fix:**
    *   Corrected the import in `lib/app/routing/app_router.dart` to point to `onboarding_page.dart` instead of the non-existent `onboarding_screen.dart`.
    *   Replaced the `OnboardingPlaceholder` widget with the actual `OnboardingPage` widget in the router.
    *   Removed the redundant `OnboardingPlaceholder` class definition.
*   **Riverpod Deprecation Fix:** Updated the deprecated `.stream` property on the `authStateChangesProvider` to use `.notifier.stream` in `lib/app/routing/app_router.dart`.
*   **RoleDispatcher Null Safety:** Applied the recommended fix from the initial `AI_CONTEXT.md` to handle potential null data from Firestore in `lib/app/routing/role_dispatcher.dart`, preventing a crash.
*   **Missing Files Created:**
    *   Created `lib/providers/theme_provider.dart` to manage the app's theme.
    *   Created `lib/app/config/env_config.dart` to handle environment-specific configurations.
*   **Deprecation Fixes:**
    *   Replaced the deprecated `CardTheme` with `CardThemeData` in `lib/main.dart`.
    *   Replaced deprecated `value` with `initialValue` in `DropdownButtonFormField` in `lib/auth/views/register_screen.dart`.
    *   Replaced deprecated `activeColor` with `activeThumbColor` in `Switch` in `lib/home/views/home_screen.dart`.
*   **Bus Tracker Screen Fixes:**
    *   Created a new `BusData` model in `lib/map/models/bus_data.dart` to represent bus location data.
    *   Imported `BusData` into `lib/map/views/bus_tracker_screen.dart`.
    *   Implemented the missing `getRoute` and `streamBus` methods in the `BusService` class (`lib/map/services/bus_service.dart`). `getRoute` currently returns a hardcoded route for demonstration purposes.

*   **Outstanding Issues:**
    *   Errors in `lib/ai/views/chat_screen.dart` related to `share_plus` and `flutter_tts` could not be resolved as `flutter pub get` is not available. This is likely an IDE synchronization issue.
---

## 9. ONGOING FIXES (Batch 3)

This batch of fixes addresses the diagnostics provided by the user.

*   **Onboarding Logic Update:**
    *   Converted `OnboardingScreen` (`lib/onboarding/views/onboarding_screen.dart`) to a `ConsumerStatefulWidget` to integrate with Riverpod state management.
    *   The `_finishOnboarding` function now correctly persists the `seenOnboarding` flag to `SharedPreferences`.
    *   The `onboardingStateProvider` is now updated upon completion, signaling the `AppRouter` to allow navigation to the main application.
    *   Navigation on completion now correctly points to `/login`.
    *   Corrected a typo in a `flutter_animate` import.
    *   Cleaned up styling to be more consistent with the app's theme, replacing hardcoded colors with `Theme.of(context).colorScheme` values.
## 10. ONGOING FIXES (Batch 4)

This batch of fixes addresses the diagnostics provided by the user.

*   **`settings_provider.dart` Fix:**
    *   Resolved an `Undefined class 'Ref'` error in `lib/app/routing/settings_provider.dart` by adding the missing `import 'package:flutter_riverpod/flutter_riverpod.dart';`. The `Ref` type is part of the core Riverpod package and was not being imported.
