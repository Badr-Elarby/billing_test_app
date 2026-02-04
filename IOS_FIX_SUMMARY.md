# 🚨 iOS SUBSCRIPTION FIX - QUICK REFERENCE

## ✅ WHAT WAS FIXED

1. ✅ Created `Configuration.storekit` - StoreKit test configuration
2. ✅ Created `ios/Runner/Runner.entitlements` - In-app purchase entitlements  
3. ✅ Installed CocoaPods dependencies
4. ✅ Created comprehensive setup guide

---

## 🎯 CRITICAL STEP: Configure Xcode (REQUIRED!)

The files are created, but you **MUST** add them to Xcode manually:

```bash
# Open Xcode workspace
open ios/Runner.xcworkspace
```

Then follow these steps IN XCODE:

### 1️⃣ Add StoreKit Configuration
- Right-click `Runner` folder → **Add Files to Runner**
- Select `Configuration.storekit` from project root
- ✅ Check **"Add to targets: Runner"**
- Click **Add**

### 2️⃣ Add Entitlements File  
- Right-click `Runner` folder → **Add Files to Runner**
- Select `ios/Runner/Runner.entitlements`
- ✅ Check **"Add to targets: Runner"**
- Click **Add**

### 3️⃣ Add In-App Purchase Capability
- Select **Runner** project → **Runner** target
- Go to **Signing & Capabilities** tab
- Click **+ Capability**
- Add **"In-App Purchase"**
- Verify **Code Signing Entitlements** = `Runner/Runner.entitlements`

### 4️⃣ Enable StoreKit Testing
- Menu: **Product** → **Scheme** → **Edit Scheme**
- Select **Run** → **Options** tab
- **StoreKit Configuration** → Select **Configuration.storekit**
- Click **Close**

---

## 🚀 TESTING

### Local Testing (Recommended)
```bash
# After Xcode setup above, run in Xcode (⌘ + R)
# Or from terminal:
flutter run -d iPhone

# You'll see:
# ✅ Billing ready
# ✅ Product loaded successfully 🎉
# 💵 Billing Test Monthly - $4.99
```

### Run from Xcode (Best for debugging):
```bash
open ios/Runner.xcworkspace
# Then press ⌘ + R in Xcode
```

---

## 🔍 VERIFY SETUP

Run this script to check everything is configured:
```bash
./check_ios_config.sh
```

---

## 📖 DETAILED DOCS

See **`IOS_SETUP_GUIDE.md`** for:
- Detailed explanation of each fix
- Troubleshooting guide
- Sandbox testing instructions
- App Store Connect configuration
- Common errors and solutions

---

## ⚡ TL;DR

1. Open: `open ios/Runner.xcworkspace`
2. Add `Configuration.storekit` to Xcode project
3. Add `Runner.entitlements` to Xcode project  
4. Add In-App Purchase capability
5. Enable StoreKit in scheme settings
6. Run app in Xcode (⌘ + R)
7. Tap Subscribe → Test purchase works! 🎉

---

## ❓ STILL NOT WORKING?

Common issues:
- ❌ Forgot to add files to Xcode → See steps 1️⃣ and 2️⃣ above
- ❌ Didn't enable StoreKit in scheme → See step 4️⃣ above
- ❌ Running from terminal instead of Xcode → Use Xcode for StoreKit
- ❌ Product ID mismatch → Should be `billing_test_monthly_ios`

Check the detailed guide: **IOS_SETUP_GUIDE.md**
