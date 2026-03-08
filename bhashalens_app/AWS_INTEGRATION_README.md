# AWS Integration for BhashaLens

This document describes the AWS cloud integration for BhashaLens, which is now primarily focused on cross-device synchronization and data management.

## Overview

BhashaLens uses a hybrid architecture. While all core AI features (Translation, Extraction, Explanation, Simplification) are powered by **Google Gemini API** (online) and **ML Kit** (on-device), AWS services are used for:
1. **History Synchronization**: Syncing translation history across devices.
2. **Preferences Synchronization**: Maintaining user settings across platforms.
3. **Data Management**: Exporting and importing user data.

## Architecture

### Components

1. **AWS API Gateway Client** (`aws_api_gateway_client.dart`)
   - HTTP client for AWS Amplify Gen 2 API endpoints.
   - Handles authentication and retry logic.
   - Focuses on non-AI data operations.

2. **Gemini Service** (`gemini_service.dart`)
   - **The primary online AI engine.**
   - Handles text translation, OCR, text refinement, and chat.
   - Used for "Explain" and "Simplify" modes.

3. **Hybrid Translation Service** (`hybrid_translation_service.dart`)
   - Manages routing between Gemini (online) and ML Kit (on-device).
   - Provides a unified interface for the UI.

4. **Retry Policy** (`retry_policy.dart`)
   - Exponential backoff retry logic for AWS API calls.

## AWS Endpoints

The AWS backend (via Amplify) exposes the following data-centric endpoints:

### 1. History Endpoints
- `getHistory`: Retrieve synced translation history.
- `addHistoryItem`: Sync a new history item to the cloud.
- `deleteHistoryItem`: Remove a specific item from synced history.

### 2. Saved Translations Endpoints
- `getSavedTranslations`: Retrieve explicitly saved items.
- `saveTranslation`: Save a translation to the cloud.
- `deleteSavedTranslation`: Delete a saved item.

### 3. Preferences Endpoints
- `getPreferences`: Retrieve cloud-synced user settings.
- `updatePreferences`: Update settings in the cloud.

### 4. Export Endpoint
- `exportData`: Generate an export of user history/data.

## AI Service Routing (Strict Gemini)

As of version 2.1.0, BhashaLens follows a **Gemini Strict Mode**:

1. **Online**: All requests are routed directly to the Gemini API.
2. **Offline**: All requests fall back to on-device ML Kit models.
3. **AWS Integration**: No longer handles AI inference; it strictly manages user data persistence.

## Troubleshooting

### Sync not working
1. Verify "Cloud sync" is enabled in **Settings**.
2. Check network connectivity.
3. Ensure you are signed in via **Firebase Authentication**.

### AI Features not working
1. Ensure `GEMINI_API_KEY` is correctly set in your environment.
2. Check if the device has internet access (required for Gemini).
3. Check **Offline Language Packs** if working in a low-connectivity environment.

## Security

- All AWS communication is encrypted via HTTPS.
- Authentication is handled via Firebase ID tokens passed to Amplify.
- User AI data is processed according to the Gemini API privacy policy.
