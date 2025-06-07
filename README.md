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