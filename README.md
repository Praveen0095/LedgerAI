# ⚡ LedgerAI — Dynamic Daily Quota & Personal Menu

> **AI-Powered Personal Finance, UPI/PayPal Payments, Dynamic Quotas & Craving Analytics**

LedgerAI is an intelligent, privacy-first personal expense manager that redefines budgeting through dynamic daily quotas, real-time UPI and PayPal payment integration, OCR/AI receipt itemization, and context-aware spending advisories.

---

## 🌟 What's New in LedgerAI (Latest Features)

### 1. 🔍 Real-time City & Area Search Filter
- **Live Search Bar:** Replaces rigid dropdowns with an interactive search bar covering 80+ major Indian cities, metro hubs, and local tech corridors (e.g., Koramangala, Indiranagar, HSR Layout, Whitefield, Hosur).
- **Auto-Persistence & Fallbacks:** Instantly filters expenses, craving statistics, and purchase history based on your active location with automatic local caching.

### 2. 🛡️ Recoverable Loans & Due-Date Reminders ("Expense / Lend")
- **Track Money Lent:** Dedicated module to record money lent to friends, colleagues, or bill recharges.
- **Smart Reminders:** Set an expected repayment date with custom alerts (e.g., alert 1 day before or on the due date: *"₹500 from Ravi is due today"*).
- **One-Tap Reconciliation:** Built-in "Mark as Received" button dismisses active alerts and reconciles your ledger instantly.

### 3. 🐖 Dedicated Savings Mode
- **Three Allocation Modes:** Choose between **Weekend Dhamaka** (saves surplus for the weekend), **Dynamic Rebalance** (spreads leftover budget daily), or the all-new **Savings Mode**.
- **Monthly Spending Caps & Goals:** Set custom target notes (e.g., *"Emergency Fund"*, *"MacBook Fund"*) alongside an optional monthly ceiling that keeps your dynamic quota strictly disciplined.

### 4. ⚠️ Proactive Budget Threshold Alerts
- **Safety Thresholds:** Configure threshold warnings (e.g., alert when less than ₹500 remains in your monthly allocation).
- **Custom Alert Dates:** Schedule specific review dates to get banner warnings on your dashboard before overspending occurs.

### 5. 📊 3-Tab Period Spend Comparison
- **Visual Analytics:** Compare your spending across **Past 7 Days**, **Past Week**, and **Past Month**.
- **Trend Indicators:** Clear metrics showing whether your daily burn rate is decreasing or exceeding target limits.

### 6. 🌐 Enhanced PayPal & Multi-Currency Engine
- **Currency Dropdown:** Seamlessly switch between **INR (₹)**, **USD ($)**, **EUR (€)**, and **GBP (£)** during checkout.
- **Explicit Currency URLs:** Generates explicit links (`paypal.me/user/amountCURRENCY`) to prevent default EUR conversion issues.
- **Intelligent Payee Parser:** Automatically isolates clean payee identifiers from deep links and QR codes.

### 7. 🏷️ Categorized Scan & Manual Entry
- **Category Tags:** Tag expenses under *Food & Dining*, *Utilities*, *Recharge*, *Groceries*, *Transport*, *Entertainment*, and *Others*.
- **Integrated Camera / Bill Scanner:** Upload or capture physical receipts to parse line items with unit prices and total splits.

### 8. 🎨 Polished Adaptive Design (Dark & Light Mode)
- **Psychology-Driven Palette:** Tailored light (`#F9F8FC` / `#5845D3`) and dark (`#040307` / `#3F2CBA`) color systems with clean rounded surfaces.
- **Typography:** Styled with *Space Grotesk* for clean headers and *Plus Jakarta Sans* for readable body text.
- **High-Contrast Readability:** Eliminated hardcoded white panels in dark mode for a consistent visual experience across all dialogs and screens.

---

## 🚀 Core Architecture & Features

- **Dynamic Quota Calculation:** Re-adjusts your daily discretionary spending limit automatically based on your monthly discretionary pool, fixed expenses, and past days' spending habits.
- **Craving Index & Personal Menu:** Tracks historical prices of frequently craved items (e.g., Chai, Biryani, Coffee) across locations and stalls to prevent impulse spending.
- **AI Spending & Craving Advisor:** Context-aware suggestions, value-for-money (VFM) checks, and weather-driven spending predictions powered by Google Gemini.
- **Local-First Privacy:** All transactions, budget configurations, and custom locations are safely stored locally using `SharedPreferences`.

---

## 🛠️ Tech Stack

- **Framework:** Flutter (Web, Android, iOS, Desktop)
- **State Management:** Provider
- **Local Storage:** `shared_preferences`
- **AI Services:** Google Gemini API
- **Payments:** UPI Deep Linking (`upi://pay`) & PayPal Me (`paypal.me`)

---

## 💻 Getting Started

### Prerequisites
- Flutter SDK (v3.0.0 or higher)
- Dart SDK

### Installation
```bash
# Clone the repository
git clone https://github.com/your-username/LedgerAI.git
cd LedgerAI

# Fetch dependencies
flutter pub get

# Run on Chrome / Web
flutter run -d chrome

# Build for Web Release
flutter build web --release
```

---

## 📄 License
MIT License. Built for hackathons, personal budgeting, and intelligent daily expense management.