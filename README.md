# BhashaLens: Real-time Voice & Camera Translation App

BhashaLens is a Flutter-based mobile application that provides real-time language translation for both voice conversations and text extracted from images. It leverages Google's Gemini API for online translation and offers an experimental offline translation mode using TensorFlow Lite models for on-device processing.

## Features

-   **Real-time Voice Translation:** Engage in natural, bidirectional conversations with instant translation.
-   **Camera Translation (OCR):** Translate text from images captured with your camera, powered by Gemini Vision.
-   **Offline Translation (Experimental):** Translate text without an internet connection using on-device TensorFlow Lite models.
-   **Multi-language Support:** Supports a wide range of languages for seamless communication.
-   **Conversation History:** Save and review past voice translations.
-   **User-friendly Interface:** Clean and intuitive design for a smooth translation experience.

## Technologies Used

-   **Flutter:** Cross-platform UI toolkit for native mobile, web, and desktop apps.
-   **Google Gemini API:** For powerful online text translation and image text extraction (OCR).
-   **TensorFlow Lite:** For on-device machine learning inference, enabling offline translation.
-   **`speech_to_text`:** Flutter plugin for speech recognition.
-   **`flutter_tts`:** Flutter plugin for text-to-speech.
-   **`camera`:** Flutter plugin for camera access.
-   **`image_picker`:** Flutter plugin for picking images from gallery or camera.
-   **`flutter_dotenv`:** For managing environment variables (API keys).
-   **`supabase_flutter`:** For user authentication and data storage.
-   **`provider`:** For state management.

## Setup and Installation

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/BhashaLens.git
cd BhashaLens/bhashalens_app
```

### 2. Install Flutter Dependencies

```bash
flutter pub get
```

### 3. API Key Configuration (Gemini)

BhashaLens relies on the Google Gemini API for its core online translation and OCR functionalities.

1.  **Get a Gemini API Key:**
    *   Go to the [Google AI Studio](https://aistudio.google.com/app/apikey) and generate a new API key.
2.  **Create a `.env` file:** In the root of the `bhashalens_app` directory, create a file named `.env`.
3.  **Add your API Key:** Add the following line to your `.env` file, replacing `YOUR_GEMINI_API_KEY` with your actual key:
    ```
    GEMINI_API_KEY=YOUR_GEMINI_API_KEY
    ```

### 4. Offline Translation Setup (TensorFlow Lite Model)

The offline translation feature requires a `.tflite` model file to be placed in your assets.

1.  **Obtain a `.tflite` Translation Model:**
    *   You will need to find a pre-trained Neural Machine Translation (NMT) model in `.tflite` format for your desired language pair (e.g., English to Spanish). Resources like [Hugging Face Models](https://huggingface.co/models?pipeline_tag=translation&library=tflite) can be a starting point, but direct, ready-to-use TFLite NMT models can be scarce. You might need to broaden your search or consider converting a model.
2.  **Rename the Model:** Rename your downloaded `.tflite` file to `translation_model.tflite`.
3.  **Place in Assets:** Put this file into the `assets` folder:
    `bhashalens_app/assets/translation_model.tflite`
4.  **Implement Tokenization/De-tokenization:** The `lib/services/offline_translation_service.dart` file contains placeholder methods (`_tokenizeInput` and `_detokenizeOutput`). You *must* replace these with the actual logic specific to your chosen TFLite model, including any necessary vocabulary loading and text processing.
5.  **Adjust Output Shape:** Update the `output` tensor shape in `lib/services/offline_translation_service.dart` (`var output = List.filled(...).reshape([...]);`) to match the exact output tensor shape of your `.tflite` model.

### 5. Running the Application

After setting up API keys and (optionally) the offline model, you can run the app:

```bash
flutter run
```

Or, to build an APK for Android:

```bash
flutter build apk --release
```

## 📸 Screenshots

### Home Screen
![Home screen](./image2.jpg)

### voice Screen
![voice transllate Screen](./image1.jpg)

### image Screen
![image transllate Screen](./image3.jpg)


## Contributing

Contributions are welcome! Please feel free to open issues or submit pull requests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
