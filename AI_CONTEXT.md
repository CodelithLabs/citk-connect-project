# 🧠 PROJECT IDENTITY: CITK-CONNECT (CODE LITH LABS)

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