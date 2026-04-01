# BlueSpan Doctor App

A Flutter-based mobile application for medical professionals to manage profiles, patients, and clinical records.

## 🛠 Prerequisites

Before starting, ensure you have the following installed:

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install) (Target version: `^3.11.0`)
- **Dart SDK**: Automatically included with Flutter.
- **Backend Service**: The [Health Platform API](../health-platform/README.md) must be running on `http://localhost:3111`.

## 🚀 Getting Started

1.  **Clone the repository** (if you haven't already).
2.  **Configure environment** — copy the example file and adjust values (never commit `.env`):
    ```bash
    cp .env.example .env
    ```
    See **Environment variables** below for each key. The app loads `.env` at startup.
3.  **Install dependencies**:
    ```bash
    flutter pub get
    ```

## 🔐 Environment variables

All keys are documented in `.env.example`. Summary:

| Variable                 | Description |
|--------------------------|-------------|
| `API_BASE_URL`           | Health platform API base URL (default `http://localhost:3111`). |
| `FEATURE_KYC_ENABLED`    | `false` (default): skip KYC gating, go to `/dashboard`. `true`: enable `/kyc` flow by verification status. Accepts `true`/`false`, `1`/`0`, `yes`/`no`. |

## ⚙️ Feature Toggles

KYC is controlled by `FEATURE_KYC_ENABLED` in `.env` (see table above). Defaults match `.env.example`.

## Signup and OTP

Registration calls `POST /api/auth/signup/otp/generate` and `POST /api/auth/signup/otp/verify` before `POST /api/auth/register`. The backend enforces a verified signup OTP for the same email (see `health-platform/modules/identity/README.md`). Local seed scripts may set `SKIP_SIGNUP_OTP_VERIFICATION=true` on the API server to bypass this.

## 📱 Running the App

### 1. Ensure the Backend is Running
The app depends on the Rust backend for authentication and data. Follow the instructions in the `health-platform` folder to start it.
```bash
cd ../health-platform
cargo run --package api-server
```

### 3. Running on a Physical iOS Device (USB)

If you see a message saying "Wireless debugging... consider using a wired (USB) connection," follow these steps to force a **Wired (USB)** mode for better performance:

1.  **Connect via USB**: Use a MFi-certified USB-to-Lightning/USB-C cable.
2.  **Xcode Settings**:
    - Open `ios/Runner.xcworkspace` in Xcode.
    - Go to **Window > Devices and Simulators** (or press `Shift + Cmd + 2`).
    - Select your iPhone on the left.
    - **Uncheck** "Connect via network".
3.  **Trust Hardware**: Ensure you've clicked **"Trust"** on your iPhone while connected.
4.  **Launch from CLI**:
    ```bash
    # Get your Device ID
    flutter devices
    
    # Run targeting that ID
    flutter run -d <DEVICE_ID>
    ```

> [!TIP]
> If it still shows `(wireless)`, try turning off Wi-Fi on your iPhone temporarily to force the connection over the USB cable.

## 🧪 Testing

Run unit and widget tests using:
```bash
flutter test
```
