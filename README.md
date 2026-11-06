# CommunityAssist

**CommunityAssist** is a modern, community-driven mobile application built with Flutter and Firebase. It bridges the gap between citizens, administrators, and maintenance workers to efficiently report, assign, and resolve community infrastructure issues (such as potholes, broken streetlights, and water leaks).

🔗 **[View the Live Web App Here](https://community-assist-c6ac6.web.app)**

## Features

- **Multi-Role System:** Dedicated interfaces and permissions for Community Members, Administrators, and Maintenance Workers.
- **Geofencing Location Validation:** Utilizes native GPS to enforce community boundaries (KuGompo Metro). Users cannot submit reports outside the 30km radius.
- **Smart Duplicate Detection:** Automatically warns users if a similar report was made within 100 meters to prevent spam.
- **Base64 Image Storage:** Optimized image compression and Base64 encoding to store photographic evidence directly within Firestore (eliminating the need for paid Firebase Storage).
- **Real-time Community Feed:** An interactive OpenStreetMap view allowing citizens to see active issues in their area while protecting reporter privacy.
- **Visual Status Tracker:** A modern, 5-step visual stepper (Submitted → Assigned → In Progress → Repaired → Verified) so citizens always know exactly where their report is in the pipeline.
- **Admin Analytics Dashboard:** A visually rich dashboard featuring a real-time 7-day Activity Bar Chart (grouped by Total, Resolved, and In Progress) and summary stat cards.
- **Deep Linking & Native Features:** Workers can tap "Navigate" to launch Google Maps directly to the job site. Admins can tap to dial workers directly from the app.
- **CSV Data Export:** Admins can export all community reports into a formatted CSV file for Excel/budgeting.
- **Dark Mode:** Full, seamless Dark Mode support across all screens, saved locally on the device.
- **End-to-End Workflow:** Admins assign jobs to workers -> Workers submit proof of repair -> Citizens verify the repair.

## Tech Stack

- **Frontend:** Flutter & Dart
- **Backend & Database:** Firebase (Authentication, Cloud Firestore)
- **Mapping:** OpenStreetMap (`flutter_map`)
- **Location Services:** `geolocator`
- **Image Handling:** `image` & `image_picker`
- **Native Integration:** `url_launcher` (Maps & Dialer)
- **Data Export:** `csv` & `share_plus`

## How to Run Locally

Since Firebase API keys are excluded from this repository for security, you must configure your own Firebase project to run the app.

### 1. Prerequisites
- Flutter SDK installed on your machine.
- An active Firebase account.
- Android Emulator, a physical Android device, or Google Chrome for Web.

### 2. Installation
Clone the repository:
```bash
git clone https://github.com/Olwabo/community-assist.git
cd community-assist