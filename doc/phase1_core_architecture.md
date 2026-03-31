# Phase 1: Core Architecture & Setup

## Overview
This phase sets up the fundamental building blocks of the `doctor_app`. It defines the core network layer, local secure storage, and navigational setup using GoRouter.

## Key Components

### 1. Networking (`dio_client.dart`)
- **Dio Client Setup**: We utilize `Dio` as the core HTTP client. It is configured as a Riverpod provider (`dioClientProvider`) for easy dependency injection across the application.
- **Base URL**: Defaults to `http://localhost:3111`, pulling dynamically using `String.fromEnvironment`.

### 2. Token Management (`secure_storage.dart`)
- **Flutter Secure Storage**: Wraps `flutter_secure_storage` to securely save, retrieve, and wipe `access_token` and `refresh_token` in the device's keychain/keystore.

### 3. Authentication Interception (`auth_interceptor.dart`)
- **Token Injection**: Automatically attaches the `Authorization: Bearer <token>` header to all outgoing application requests.
- **Refresh Mechanism**: Transparently handles `401 Unauthorized` responses. It pauses the failed request, utilizes a secondary `Dio` instance (`refreshDio`) to request a new token pair via `/api/auth/refresh`, securely stores the new tokens, and seamlessly retries the original request.
- **Fallback**: Triggers a logout purge and router redirect upon a `403 Forbidden` or a failed refresh cycle.

### 4. Application Routing (`app_router.dart`)
- **GoRouter**: Implements declarative routing. Current core routes include `/login` and `/dashboard`. This will be expanded with redirect logic heavily reliant on the `AuthState` in Phase 2.
