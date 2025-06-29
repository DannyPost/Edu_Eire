# Edu Eire – Student Deals Marketplace

**Edu Eire** is a full-stack Flutter + Firebase + Stripe SaaS platform for student discounts, business onboarding, and payments with automated commission logic.

---

## Features

- **User Authentication:** Email/password & Google Sign-In
- **Business Onboarding:** Register as a business, Stripe Connect onboarding, approval workflow
- **Admin Dashboard:** Manage student deals, CRUD products, set supply, filter by sector/location/mode
- **Student Deals:** Browse & purchase deals, add to cart, checkout with Stripe
- **Stripe Payments:** Checkout with per-product commission rates, automatic vendor payouts via Connect
- **Email Notifications:** SendGrid transactional emails on business signup & admin notifications
- **Firestore Security:** Enforced access rules (secure, no open reads/writes)
- **Mobile & Web Support:** Responsive, mobile-friendly UI
- **Configurable:** All keys/secrets via environment variables

---

## Project Structure

root/
├── .gitignore
├── README.md
├── pubspec.yaml # Flutter dependencies
├── lib/
│ ├── main.dart # Entry point
│ ├── login_page.dart
│ ├── signup_page.dart
│ ├── admin/
│ │ └── admin_dashboard.dart
│ └── studentdeals/
│ ├── product_model.dart
│ └── student_deals_page.dart
├── assets/
│ ├── logo.png
│ └── g-logo.png
├── functions/ # Cloud Functions (Node.js)
│ ├── index.js
│ └── package.json
├── firebase.json
├── firestore.rules # Database security
├── .env # Environment variables (not committed)
└── ... # Other configs, IDE files (gitignored)


---

## Setup & Installation

### 1. Prerequisites

- **Flutter** (latest stable) — https://flutter.dev/docs/get-started/install
- **Node.js** (LTS) — https://nodejs.org/
- **Firebase CLI** — `npm install -g firebase-tools`
- **Stripe account** — https://dashboard.stripe.com/
- **SendGrid account** — https://sendgrid.com/

### 2. Clone & Install Dependencies

```bash
git clone <your-repo-url>
cd <project-folder>
flutter pub get

# Setup Functions (from project root)
cd functions
npm install




Example functions/.env:
Copy code
STRIPE_SECRET_KEY=sk_test_xxx
SENDGRID_API_KEY=SG.xxx



Firebase Functions config:
firebase functions:config:set stripe.secret="sk_test_xxx" sendgrid.key="SG.xxx"
firebase deploy --only functions


Firestore Rules (Security)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /admins/{userId} {
      allow create: if request.auth != null;
      allow read, update, delete: if request.auth != null && request.auth.uid == userId;
    }
    match /products/{productId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}



Key Features
Business must register & onboard Stripe before selling.

Checkout only allowed for items from ONE business per cart.

Commission logic:

Under €50: 30%

€50–€1000: 20%

Over €1000: 15%

Stripe Connect: Business payouts use their provided Stripe Account ID.

Email notifications: Business & admins notified on signup, pending approval.