# 🎧 Auracity

[![Flutter Version](https://img.shields.io/badge/Flutter-%E2%9C%93-02569B?style=flat&logo=flutter)](https://flutter.dev)
[![Firebase Integrated](https://img.shields.io/badge/Firebase-%E2%9C%93-FFCA28?style=flat&logo=firebase)](https://firebase.google.com)
[![Platform Support](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS%20%7C%20Web-blue)]()

> **One Line Catchy Description:** A brief, compelling hook explaining exactly what Auracity solves or achieves (e.g., *An AI-powered location-based audio experience seamlessly connecting users to their surroundings.*)

---

## 🚀 Features

*   **📍 Location-Aware Experiences:** Integrated with Google Maps SDK to provide real-time, interactive geography features.
*   **🔐 Seamless Authentication:** Secure user boarding via Firebase Authentication (Email/Password, Anonymous, etc.).
*   **🔥 Real-time Cloud Sync:** Robust backend support using Firebase for instant data retrieval and offline caching.
*   **🤖 AI Insights:** Built-in integration with advanced AI models for smart, tailored content delivery.

---

## 📸 Screenshots

| Splash & Onboarding | Core Maps Interface | Feature View |
| :---: | :---: | :---: |
| <img src="flutter_01.png" width="250"> | *Add Screenshot* | *Add Screenshot* |

---

## 🛠️ Setup Instructions

### 1. Primary Service Setup (Firebase)

1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Click **Add Project** and name it `Auracity`.
3. **Database Configuration**:
   * Navigate to the database tab and click **Create database**.
   * Start in **Test Mode** for initial development. *(Note: Update security rules before production).*
4. **Authentication**:
   * Navigate to *Authentication* -> *Sign-in method*.
   * Enable the options you need (e.g., Email/Password, Anonymous).
5. **Connect your App**:
   * Install the required CLI tools via your terminal:
```bash
     npm install -g firebase-tools
     ```
* Log in and configure:
```bash
     firebase login
     flutterfire configure
     ```

### 2. API Configurations (Google Maps Setup)

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Create a new project or select your existing one.
3. Enable the following APIs:
   * **Maps SDK for Android**
   * **Maps SDK for iOS**
4. Go to **Credentials**, click **Create Credentials** -> **API Key**.
5. Add the generated keys to your native configurations:
   * **Android**: Open `android/app/src/main/AndroidManifest.xml` and add:
```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="YOUR_ANDROID_API_KEY_HERE" />
     ```
   * **iOS**: Open `ios/Runner/AppDelegate.swift` and initialize the Maps SDK with your key.

### 3. AI / Third-Party Key Setup

1. Get an API Key from your provider (e.g., Google AI Studio).
2. Replace the placeholder `'YOUR_API_KEY_HERE'` inside your service file (e.g., `lib/services/ai_service.dart`) to enable your AI modules.

---

## 🏃‍♂️ Running the App

Once you have configured your environment and keys, simply run the following commands in your root terminal:

```bash
# Fetch dependencies
flutter pub get

# Run the application
flutter run
