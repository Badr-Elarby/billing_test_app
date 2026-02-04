# iOS Subscription Testing Setup Guide

## 🔴 CRITICAL ISSUES FIXED

Your iOS subscription configuration was incomplete. Here's what was missing and has been fixed:

### ✅ Files Added:
1. **`Configuration.storekit`** - StoreKit configuration file for local testing
2. **`ios/Runner/Runner.entitlements`** - iOS entitlements for in-app purchases

---

## 📋 STEP-BY-STEP FIX

### **STEP 1: Add StoreKit Configuration to Xcode Project**

⚠️ **CRITICAL**: The `.storekit` file must be added to your Xcode project manually.

1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode, **right-click** on the `Runner` folder in the Project Navigator
3. Select **"Add Files to Runner..."**
4. Navigate to your project root and select `Configuration.storekit`
5. ✅ Make sure **"Copy items if needed"** is **UNCHECKED**
6. ✅ Make sure **"Add to targets: Runner"** is **CHECKED**
7. Click **"Add"**

### **STEP 2: Add Entitlements File to Xcode Project**

1. In Xcode Project Navigator, **right-click** on `Runner` folder
2. Select **"Add Files to Runner..."**
3. Navigate to `ios/Runner/` and select `Runner.entitlements`
4. Click **"Add"**

### **STEP 3: Configure Build Settings**

1. In Xcode, select the `Runner` project (top of navigator)
2. Select the `Runner` target
3. Go to **"Signing & Capabilities"** tab
4. Click **"+ Capability"** button
5. Select **"In-App Purchase"**
6. Ensure **"Code Signing Entitlements"** is set to `Runner/Runner.entitlements`

### **STEP 4: Enable StoreKit Testing**

#### For Simulator/Debug Testing:
1. In Xcode, go to **Product → Scheme → Edit Scheme...**
2. Select **"Run"** on the left
3. Go to **"Options"** tab
4. Under **"StoreKit Configuration"**, select **"Configuration.storekit"**
5. Click **"Close"**

Now you can test subscriptions in the iOS Simulator without App Store Connect!

#### For Device Testing with App Store Sandbox:
1. On your iPhone, go to **Settings → App Store → Sandbox Account**
2. Sign in with your Apple ID test account (create one in App Store Connect if needed)

---

## 🎯 PRODUCT ID CONFIGURATION

Your current iOS product ID is: **`billing_test_monthly_ios`**

### For Local Testing (Simulator):
✅ The StoreKit file already has this product configured. No changes needed!

### For Real Device Testing (App Store Connect):
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to **"Monetization" → "Subscriptions"**
4. Create a new subscription group (if not exists)
5. Add a subscription with **EXACT** product ID: `billing_test_monthly_ios`
6. Configure pricing and subscription period

⚠️ **IMPORTANT**: The product ID in App Store Connect must **EXACTLY** match `billing_test_monthly_ios`

---

## 🚀 TESTING WORKFLOWS

### **Local Testing (Simulator - Recommended for Quick Testing)**

1. Open in Xcode: `open ios/Runner.xcworkspace`
2. Select **iPhone simulator** as target
3. Ensure StoreKit Configuration is enabled (Step 4 above)
4. Run the app (⌘ + R)
5. Tap "Subscribe" button
6. A fake StoreKit purchase dialog will appear
7. Complete the purchase (it's free in testing)
8. Check console logs for the receipt data

**Advantages:**
- ✅ No App Store Connect setup needed
- ✅ Instant testing
- ✅ No waiting for app review
- ✅ Free test purchases

### **Sandbox Testing (Real Device)**

1. Create a Sandbox Tester account in App Store Connect
2. Configure product in App Store Connect
3. Build and install app on device via Xcode
4. Sign in with sandbox account on device (Settings → App Store)
5. Test subscription purchase

**Advantages:**
- ✅ Tests real App Store flow
- ✅ Tests receipt validation
- ✅ Tests subscription renewals

---

## 🔍 DEBUGGING TIPS

### If Product Not Found:

#### In Simulator:
- Ensure `Configuration.storekit` is added to Xcode project
- Ensure StoreKit Configuration is enabled in scheme settings
- Check product ID matches exactly: `billing_test_monthly_ios`

#### On Real Device:
- Product must exist in App Store Connect
- App must be uploaded to TestFlight or Internal Testing
- Bundle ID must match exactly
- Wait 2-3 hours after creating product in App Store Connect

### Check Logs:
```bash
# Run app from Xcode and check console
# Or use this command if running from command line:
flutter run --verbose
```

### Enable Debug Mode in Code:
The app already has detailed logging. Check these messages:
- ✅ "Billing ready" - In-app purchase is available
- ❌ "Billing not available" - Device/simulator doesn't support IAP
- ⚠️ "Product not found" - Check configuration

---

## 📱 QUICK START (Simulator Testing)

```bash
# 1. Clean build
cd /Users/mrbebo/Documents/Github/billing_test_app
flutter clean
flutter pub get

# 2. Open in Xcode to configure StoreKit
open ios/Runner.xcworkspace
```

Then in Xcode:
1. Add `Configuration.storekit` to project (see STEP 1 above)
2. Add `Runner.entitlements` to project (see STEP 2 above)
3. Add In-App Purchase capability (see STEP 3 above)
4. Enable StoreKit Configuration in scheme (see STEP 4 above)
5. Run the app (⌘ + R)

---

## 🎉 WHAT YOU SHOULD SEE

When working correctly:
1. App launches → "Billing ready ✅"
2. Product loads → "Product loaded successfully 🎉"
3. Card shows: "Billing Test Monthly" ($4.99/month)
4. Tap "Subscribe" → StoreKit dialog appears
5. Confirm purchase → "Purchase successful 🎉"
6. Receipt appears in the status card

---

## 🆘 STILL NOT WORKING?

### Checklist:
- [ ] `Configuration.storekit` is added to Xcode project
- [ ] `Runner.entitlements` is added to Xcode project
- [ ] In-App Purchase capability is added in Xcode
- [ ] StoreKit Configuration is enabled in scheme
- [ ] Product ID in code matches StoreKit file: `billing_test_monthly_ios`
- [ ] Running on iOS Simulator (not just command line)

### Common Mistakes:
1. ❌ Forgetting to add `.storekit` file to Xcode project
2. ❌ Not enabling StoreKit Configuration in scheme settings
3. ❌ Running with `flutter run` instead of Xcode (StoreKit needs Xcode scheme)
4. ❌ Product ID mismatch

### Need Help?
Run these diagnostic commands:

```bash
# Check if entitlements file exists
ls -la ios/Runner/Runner.entitlements

# Check if StoreKit file exists
ls -la Configuration.storekit

# Verify product ID in code
grep -n "billing_test_monthly_ios" lib/main.dart
```

---

## 📖 Additional Resources

- [Flutter in_app_purchase plugin](https://pub.dev/packages/in_app_purchase)
- [Apple StoreKit Testing Guide](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
- [App Store Sandbox Testing](https://developer.apple.com/apple-pay/sandbox-testing/)

---

**Created**: 2026-02-04
**Last Updated**: 2026-02-04
