# Edu_Eire
# Read the Read  in the Directory for Intructions

# EduEire Academic Support

A cross-platform Flutter app giving Irish students one-stop access to:
- **Grants** (DARE, HEAR, SUSI, etc.)
- **Motivational Quotes & Videos**
- **Academic Resources** (wellness, writing centers, study skills)
- **Student Deals** (Amazon, Spotify, Dominos)
- **Scholarship Directories**

---

## Key Features

1. **Branded, Responsive UI**  
   - Custom AppBar with logo + title  
   - Hero “Welcome” card  
   - Material 3 theming & two-tone color scheme  
   - Light & Dark modes (toggle in header)  
   - Responsive (single-column on phones, two-column on wider screens)

2. **Navigation & Content**  
   - 5-tab structure (Grants, Motivation, Resources, Deals, Scholarships)  
   - Each tab fetches real Firestore data (with offline caching)  
   - Tappable links open via `url_launcher`

3. **Search & Filtering**  
   - Global search bar filters across titles/subtitles  
   - Category chips (Disability, Financial, Wellness, etc.)

4. **Animations & Polish**  
   - Fade-in cards with `TweenAnimationBuilder`  
   - Ripple/press feedback on taps  

5. **Firebase Integration**  
   - Firestore for dynamic content  
   - Firebase Analytics (user & tab/link click tracking)  
   - Firebase Crashlytics (real-time crash reporting)  
   - (Optional) Firebase Auth for Google sign-in & user bookmarks

6. **CI/CD & Quality**  
   - GitHub Actions workflow: `flutter analyze`, tests, and web build on each PR  
   - `flutter_lints` enabled, auto-format on save  
   - Comprehensive README & badges  

7. **Accessibility & i18n**  
   - Semantic labels on images & tappables  
   - Prep for multi-locale support (English / Irish-Gaelic ARB files)

---

## Getting Started

1. **Clone**  
   ```bash
   git clone git@github.com:YOUR_USERNAME/edu_eire_academic_support.git
   cd edu_eire_academic_support
