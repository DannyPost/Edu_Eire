<<<<<<< HEAD
# flutter_application_1

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# Edu Eire App

This is the **Edu Eire** app – a Flutter-based project for Irish secondary school and university students. It features:

✅ A **news feed** for Irish education news, powered by the NewsAPI and OpenAI for summarization  
✅ A **chatbot** powered by GPT-4 for answering questions about Irish education (CAO, SUSI, etc.)  
✅ **Dark mode and dyslexic-friendly font** toggles  
✅ Persistence of **chat logs** on local file storage (desktop)  
✅ Works seamlessly on **Windows desktop** and **Web**

---

## ⚙️ Project Structure

.
├── assets/
│ ├── chatbot/
│ │ ├── edu_eire_logo.png
│ │ └── menu.png
│ └── fonts/
│ ├── OpenDyslexic-Regular.otf
│ ├── OpenDyslexic-Bold.otf
│ └── OpenDyslexic-Italic.otf
├── lib/
│ ├── homepage/
│ │ ├── widgets/
│ │ │ └── education_news_feed.dart
│ │ └── services/
│ │ └── education_news_service.dart
│ ├── chatbot/
│ │ ├── chatbot_screen.dart
│ │ ├── services/
│ │ │ └── openai_service.dart
│ │ ├── models/
│ │ │ └── message_model.dart
│ │ └── utils/
│ │ ├── logger.dart # Platform-agnostic conditional import
│ │ ├── logger_io.dart # File-based storage for desktop
│ │ └── logger_web.dart # LocalStorage for web
│ ├── settings/
│ │ └── settings_page.dart
│ ├── main.dart
│ └── ...
├── .env
├── pubspec.yaml
└── README.md

---

## ⚡ .env File

Create a `.env` file in the root of the project to store **API keys**:

```env
NEWSAPI_API_KEY=YOUR_NEWSAPI_KEY
OPENAI_API_KEY=YOUR_OPENAI_API_KEY
>>>>>>> e0b4353cf7ba5b3fecaec3524f9d21f0f5e54769
