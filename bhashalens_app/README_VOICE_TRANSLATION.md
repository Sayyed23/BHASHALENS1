# Voice Translation Features

## Overview
The BhashaLens app now includes comprehensive voice translation capabilities using Google's Gemini AI, Speech-to-Text (STT), and Text-to-Speech (TTS) technologies.

## Features

### 1. Speech Recognition (STT)
- **Real-time speech recognition** using Google's Speech-to-Text API
- **Multi-language support** for 20+ languages including Indian regional languages
- **Automatic language detection** for unknown languages
- **Continuous listening** with configurable pause and listen durations

### 2. AI-Powered Translation
- **Gemini AI integration** for high-quality translations
- **Context-aware translation** that maintains meaning and tone
- **Automatic language detection** when source language is set to "Auto"
- **Fallback to OpenAI** (if configured) for alternative translation

### 3. Text-to-Speech (TTS)
- **Natural voice output** in target languages
- **Language-specific voice settings** for authentic pronunciation
- **Playback controls** for replaying translations
- **Volume and speed controls** for optimal listening experience

### 4. Conversation Management
- **Real-time conversation flow** between two users
- **Language swapping** for easy role reversal
- **Conversation history** with original and translated text
- **Save, copy, and share** functionality for conversations

## Supported Languages

### Primary Languages
- English (en)
- Spanish (es)
- French (fr)
- German (de)
- Italian (it)
- Portuguese (pt)
- Russian (ru)
- Japanese (ja)
- Korean (ko)
- Chinese (zh)
- Arabic (ar)

### Indian Regional Languages
- Hindi (hi)
- Bengali (bn)
- Tamil (ta)
- Telugu (te)
- Malayalam (ml)
- Kannada (kn)
- Gujarati (gu)
- Marathi (mr)
- Punjabi (pa)

## How to Use

### 1. Setting Up Languages
1. Open the Voice Translation page
2. Select "Your Language" (source language)
3. Select "Their Language" (target language)
4. Use "Auto Detect" for automatic language recognition

### 2. Starting a Conversation
1. Tap the microphone button for the user who wants to speak
2. Speak clearly in the selected language
3. Tap the microphone again to stop recording
4. The app will automatically translate and speak the result

### 3. Playing Translations
- **Live translation**: Tap the play button next to translated text
- **History playback**: Tap the play button in conversation history
- **Auto-play**: Translations are automatically spoken after processing

### 4. Managing Conversations
- **Save**: Store important conversations for later reference
- **Copy**: Copy conversation text to clipboard
- **Share**: Share conversations via other apps
- **Clear**: Remove all conversation history

## Technical Implementation

### Dependencies
```yaml
speech_to_text: ^7.0.0      # Speech recognition
flutter_tts: ^3.8.5         # Text-to-speech
google_generative_ai: ^0.3.0 # Gemini AI integration
```

### Key Services
- `VoiceTranslationService`: Manages speech recognition, translation, and TTS
- `GeminiService`: Handles AI-powered translation and language detection
- Real-time state management using Provider pattern

### API Configuration
- **Gemini API Key**: Required for translation services
- **OpenAI API Key**: Optional fallback for translation
- Environment variables stored in `.env` file

## Troubleshooting

### Common Issues
1. **Translation not showing**: Check Gemini API key configuration
2. **Speech not recognized**: Ensure microphone permissions are granted
3. **TTS not working**: Verify device audio settings
4. **Language detection fails**: Check internet connection and API limits

### Performance Tips
- Use clear, slow speech for better recognition
- Ensure stable internet connection for AI services
- Close other audio apps to prevent conflicts
- Use headphones for better audio quality

## Future Enhancements
- Offline translation capabilities
- Voice cloning for personalized TTS
- Multi-speaker conversation support
- Real-time subtitle generation
- Integration with video calls

## Support
For technical support or feature requests, please contact the development team or create an issue in the project repository.
