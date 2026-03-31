# Phase 2: Authentication & Context Switching

## Overview
Phase 2 focuses on establishing robust state management for user authentication, implementing the login UI, handling session persistence, and supporting dynamic context switching (useful for doctors shifting between multiple clinics/roles).

## Key Components

### 1. Authentication State (`auth_provider.dart`)
- **State Definition**: Tracks the user's status: `unauthenticated`, `authenticating`, `contextSelection`, and `authenticated`.
- **Login Action**: Hits the `POST /api/auth/login` endpoint, captures the tokens into `SecureStorage`, and advances the application state.
- **Logout Action**: Calls the `POST /api/auth/logout` endpoint, clears the local storage, and resets the state.

### 2. Route Redirection (`app_router.dart` updates)
- **State-Aware Routing**: `GoRouter` listens to `authProvider`. If a user attempts to access `/dashboard` while `unauthenticated`, they are redirected to `/login`. Conversely, authenticated users on `/login` are immediately pushed to `/dashboard`.

### 3. Context Switching (`POST /api/auth/switch-context`)
- Supports workflows where a user possesses multiple profiles or contexts (e.g., Hospital A vs. Clinic B). If applicable, an intermediate "Select Context" screen is shown before granting full access to the dashboard.

### 4. Login UI (`login_screen.dart`)
- A robust, visually appealing login page capturing credentials (e.g., email/password or phone/OTP based on exactly what the backend `/api/auth/login` dictates) that integrates cleanly with the `authProvider`.
