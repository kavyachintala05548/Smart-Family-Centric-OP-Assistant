# Smart Family-Centric OP Assistant

### Specialist Recommendation & Appointment Booking

## Overview

The **Smart Family-Centric OP Assistant** is a mobile healthcare
application designed to help patients and families find suitable medical
specialists and manage outpatient (OP) appointments.

Users can enter their symptoms and preferences to receive specialist
recommendations with match scores and simple explanations. The
application also allows one account to manage multiple family members
and book appointments for them.

The project demonstrates the use of operating system concepts in a real
application, including process management, network communication, file
storage, application sandboxing, concurrency and graphics management.

> **Disclaimer:** This application helps users find suitable medical
> specialists and manage appointments. It does not provide medical
> diagnoses or replace professional medical advice.

## Main Features

-   **User registration and login:** Account creation and JWT-based
    authentication.
-   **Family profiles:** Manage multiple family members under one
    account.
-   **Specialist search:** Enter symptoms and preferences to find
    relevant specialists.
-   **Doctor recommendations:** Rank doctors using symptom relevance,
    distance, availability, consultation fees, waiting time and ratings.
-   **Explainable recommendations:** Display match scores and
    explanations for why a doctor is recommended.
-   **Appointment booking:** Select a family member, doctor, available
    date and time slot, and add optional notes.
-   **Appointment management:** View, reschedule and cancel
    appointments.
-   **Notifications:** View appointment-related updates.
-   **Admin access:** Restrict administrative endpoints to authorized
    admin accounts.

## Technology Stack

  Component                 Technology
  ------------------------- ----------------------------------------
  Mobile application        Flutter and Dart
  Backend API               Python and FastAPI
  API server                Uvicorn
  Database                  SQLite
  Authentication            JWT / OAuth2 Password Bearer
  API documentation         FastAPI Swagger UI
  Device connection         Android Debug Bridge (ADB)
  Development environment   Windows, Android Studio and PowerShell

## System Architecture

The application has three main components:

1.  **Flutter mobile application:** Provides the user interface for
    registration, login, family profiles, specialist search,
    recommendations, appointments and notifications.
2.  **FastAPI backend:** Handles authentication, recommendation
    requests, doctor ranking, appointment operations and notifications.
3.  **SQLite database:** Stores application data such as users, family
    members, doctors, specialities, availability, appointments and
    related records.

### Request Flow

1.  The user performs an action in the Flutter application.
2.  Flutter sends an HTTP request to the FastAPI backend, including the
    JWT token when authentication is required.
3.  The backend validates the request and accesses the SQLite database
    when needed.
4.  FastAPI returns the result as JSON.
5.  Flutter processes the response and updates the screen.

## Project Structure

The project contains two main parts:

``` text
SmartFamilyCentric/
│
├── backend/
│   ├── app/
│   │   ├── main.py
│   │   ├── auth.py
│   │   ├── database.py
│   │   ├── models.py
│   │   ├── schemas.py
│   │   ├── seed_data.py
│   │   ├── routers/
│   │   └── services/
│   ├── requirements.txt
│   └── smartfamilycentric.db
│
├── flutter_app/
│   ├── lib/
│   │   ├── api/
│   │   ├── models/
│   │   └── screens/
│   ├── android/
│   └── pubspec.yaml
│
└── README.md
```

The exact files and folders may differ depending on the current project
version. Do not upload generated files, private credentials or personal
database information.

## Requirements

Install the following before running the project:

-   Python 3
-   Flutter SDK
-   Dart SDK (included with Flutter)
-   Android Studio or Android SDK
-   Android phone with USB debugging enabled, or an Android emulator
-   Git

Check the installations:

``` powershell
python --version
flutter --version
flutter doctor
git --version
```

## Running the Backend

Open PowerShell or a terminal and navigate to the backend folder:

``` powershell
cd backend
```

Create a Python virtual environment:

``` powershell
python -m venv venv
```

Activate it:

``` powershell
.\venv\Scripts\Activate.ps1
```

Install the backend dependencies:

``` powershell
pip install -r requirements.txt
```

Start the FastAPI server:

``` powershell
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

The backend will run on port `8000`.

Open the API documentation in your PC browser:

``` text
http://127.0.0.1:8000/docs
```

The Swagger UI allows you to view and test the available API endpoints.

## Running the Flutter Application

Open a second terminal and navigate to the Flutter application folder:

``` powershell
cd flutter_app
```

Get the required Flutter packages:

``` powershell
flutter pub get
```

Check connected Android devices:

``` powershell
flutter devices
```

### Option 1: Run on a Physical Android Phone Using USB Debugging

1.  Enable Developer Options and USB debugging on the Android phone.
2.  Connect the phone to the Windows PC using a USB cable.
3.  Accept the USB debugging authorization prompt on the phone.
4.  Find the connected device ID:

``` powershell
$adb = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
& $adb devices
```

5.  Set up ADB reverse port forwarding. 
``` powershell
& $adb -s Your_Phone_ID reverse tcp:8000 tcp:8000
```

6.  Check the forwarding rule:

``` powershell
& $adb reverse --list
```

7.  Run the Flutter application:

``` powershell
flutter run -d Your_Phone_ID
```

With ADB reverse forwarding, the Android device can access the backend
through:

``` text
http://127.0.0.1:8000
```

Make sure the backend is running before using the application.

### Important: Backend Base URL

The Flutter API client must use a base URL that matches the connection
method:

-   **Physical Android phone with ADB reverse:** `http://127.0.0.1:8000`
-   **Android emulator:** `http://10.0.2.2:8000`

Use the URL appropriate to your setup. If you change the connection
method, update the API base URL in the Flutter project accordingly.

## API Documentation

FastAPI provides interactive API documentation at:

``` text
http://127.0.0.1:8000/docs
```

The API includes operations for authentication, family members,
specialist recommendations, doctor availability, appointments,
notifications and administrative functions.

Swagger UI supports OAuth2 Password Bearer authorization. Use the
appropriate demo account configured by the project for patient or
administrator testing. Do not publish real passwords or access tokens.

## Operating System Concepts Demonstrated

  -----------------------------------------------------------------------
  OS Concept                          How it is used in the project
  ----------------------------------- -----------------------------------
  Process management                  Windows runs the Uvicorn backend
                                      process; Android runs the Flutter
                                      application process.

  Networking                          HTTP requests are exchanged over
                                      TCP connections between the mobile
                                      application and backend.

  USB debugging and ADB               Reverse port forwarding connects
                                      the physical Android phone to the
                                      backend running on the PC.

  File system                         SQLite stores application records
                                      in a database file.

  Application sandboxing              Android isolates application data
                                      from other applications.

  Concurrency                         The backend handles incoming
                                      requests, while booking operations
                                      require careful handling of shared
                                      data.

  Memory and CPU scheduling           Android and Windows allocate system
                                      resources to the application,
                                      backend and development tools.

  Graphics and window management      Android manages the application
                                      window and display; Flutter renders
                                      the user interface.
  -----------------------------------------------------------------------

## Testing

The application was tested using a physical Android phone connected to a
Windows PC through USB debugging.

The main functional tests included:

-   User registration and login
-   Duplicate account validation
-   Family member creation and editing
-   Specialist search and recommendations
-   Doctor availability
-   Appointment booking
-   Invalid booking validation
-   Appointment notifications
-   Appointment rescheduling and cancellation
-   Admin access restrictions

Successful requests and expected error responses were checked using the
application and backend logs.

## Security and Repository Notes

Before uploading the project to GitHub:

-   Do not commit real passwords, JWT tokens, API keys or secret keys.
-   Do not commit personal user data or a database containing private
    information.
-   Keep local environment files such as `.env` out of the repository.
-   Use a `.env.example` file containing placeholder values if
    environment variables are required.
-   Check that the repository does not contain private information
    before making it public.
-   Review the database seed data and use only fictional demo accounts.

A suitable `.gitignore` should exclude generated and sensitive files.
For example:

``` gitignore
# Python
__pycache__/
*.py[cod]
venv/
.env
.pytest_cache/

# SQLite database (review before committing)
*.db
*.sqlite
*.sqlite3

# Flutter / Dart
.dart_tool/
.packages
.flutter-plugins
.flutter-plugins-dependencies
build/
.flutter-plugins-dependencies

# IDE
.idea/
.vscode/

# Android generated files
android/.gradle/
```

If your project needs a pre-populated demo database to run, provide a
sanitized database or a documented seed-data setup instead of uploading
a database containing real or private information.

## Future Enhancements

-   Move from SQLite to PostgreSQL for a larger deployment.
-   Add push, SMS or email appointment reminders.
-   Store authentication tokens using encrypted storage.
-   Add map-based distance and travel-time information.
-   Integrate reliable live waiting-time information.
-   Add automated tests for recommendation scoring and appointment
    booking.
-   Perform concurrent booking tests to check for double-booking.

