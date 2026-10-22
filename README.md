# CommunityAssist

**CommunityAssist** is a modern, community-driven mobile application built with Flutter and Firebase. It bridges the gap between citizens, administrators, and maintenance workers to efficiently report, assign, and resolve community infrastructure issues (such as potholes, broken streetlights, and water leaks).

## Features

- **Multi-Role System:** Dedicated interfaces and permissions for Community Members, Administrators, and Maintenance Workers.
- **Geofencing Location Validation:** Utilizes native GPS to enforce community boundaries (KuGompo Metro). Users cannot submit reports outside the 30km radius.
- **Smart Duplicate Detection:** Automatically warns users if a similar report was made within 100 meters to prevent spam.
- **Base64 Image Storage:** Optimized image compression and Base64 encoding to store photographic evidence directly within Firestore (eliminating the need for paid Firebase Storage).
- **Real-time Community Feed:** An interactive OpenStreetMap view allowing citizens to see active issues in their area while protecting reporter privacy.
- **End-to-End Workflow:** Admins assign jobs to workers -> Workers submit proof of repair -> Citizens verify the repair.

## Tech Stack

- **Frontend:** Flutter & Dart
- **Backend & Database:** Firebase (Authentication, Cloud Firestore)
- **Mapping:** OpenStreetMap (`flutter_map`)
- **Location Services:** `geolocator`
- **Image Handling:** `image` & `image_picker`

## How to Run Locally

Since Firebase API keys are excluded from this repository for security, you must configure your own Firebase project to run the app.

### 1. Prerequisites
- Flutter SDK installed on your machine.
- An active Firebase account.
- Android Emulator or a physical Android device.

### 2. Installation
Clone the repository:
```bash
git clone https://github.com/Olwabo/community-assist.git
cd community_assist