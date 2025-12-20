# 🎓 CITK Student Connect
> **Open Innovation Hackathon Project** > *Bridging the gap for new students at Central Institute of Technology, Kokrajhar.*

![Project Status](https://img.shields.io/badge/Status-Prototype-blue)
![Hackathon](https://img.shields.io/badge/Hackathon-Google%20Open%20Innovation-green)
![Tech](https://img.shields.io/badge/Built%20With-Google%20Tech-orange)

## 🚀 Overview
**CITK Student Connect** is a digital companion designed to solve the "Day 1 Chaos" faced by freshers (Diploma & B.Tech 1st Sem) at **Central Institute of Technology (CIT), Kokrajhar**.

From finding the right administrative building to understanding anti-ragging affidavits, this platform acts as a bridge between the confusion of admission and the comfort of campus life.

## 💡 The Problem (Local Challenge)
Every year, hundreds of new students arrive at CITK from diverse backgrounds. They face immediate challenges:
1.  **Navigation Chaos:** "Where is the Academic Block vs the Admin Block?"
2.  **Documentation Anxiety:** Confusion over Anti-Ragging affidavits, Medical Certificates, and Admission forms.
3.  **Communication Gap:** Lack of direct contact with seniors or department heads for guidance.

## 🛠 The Solution
We built an all-in-one web and mobile portal that features:

* **🗺️ AI-Powered 3D Campus Map:** A virtual walkthrough of the CITK campus to help students find classrooms and hostels before they even arrive.
* **📄 Smart Document Assistant:** Step-by-step guides for all admission paperwork (Medical, Affidavits, etc.).
* **🤝 Senior Connect:** A verified directory to connect freshers with student mentors from their specific branch.
* **📅 Event Tracker:** Real-time updates on Admission dates, Orientation schedules, and Hackathons.

## 🏗️ Architecture (Monorepo)
We utilize a **Monorepo** structure to maintain both our Web and App codebases efficiently.

```text
citk-connect-project/
├── docs/               # Project Flowcharts & Hackathon Pitch Deck
├── web-client/         # The Student Portal (HTML5, CSS3, JS)
├── mobile-app/         # (Planned) Flutter-based Mobile Application
└── backend-functions/  # Firebase Functions for Auth & Database
