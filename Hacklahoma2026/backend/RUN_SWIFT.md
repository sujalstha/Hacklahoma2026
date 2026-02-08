# Run the whatsForDinner Swift App in Xcode

The Xcode project is ready. Do this on your Mac:

## 1. Open the project

In Finder, go to the `backend` folder and **double‑click**:

**`whatsForDinner.xcodeproj`**

Or from Terminal:

```bash
cd /Users/sujalshrestha/Hacklahoma2026/backend
open whatsForDinner.xcodeproj
```

## 2. Resolve Swift packages (first time only)

When Xcode opens, it will fetch the **Supabase** package. Wait until the spinner in the status bar finishes (“Fetching package dependencies” / “Resolving Package Graph”). If it fails, use **File → Packages → Resolve Package Versions**.

## 3. Confirm target and Info.plist

- The app target **whatsForDinner** already includes:
  - **Models/RecipeModels.swift**
  - **Networking/RecipeService.swift**
  - **Views/RecipeDetailView.swift**
  - **AppConfig.swift**
  - All other existing Swift files and **Assets.xcassets**
- **Info.plist** is set to `whatsForDinner/Info.plist` and already has ATS exceptions for **127.0.0.1** and **localhost** (so the app can call your backend over HTTP).

No need to add these by hand unless you created the project yourself and something is missing.

## 4. Run on the Simulator

1. At the top of Xcode, pick the **whatsForDinner** scheme and a simulator (e.g. **iPhone 16**).
2. Press **⌘R** or click the **Run** (play) button.

The app will build and launch in the Simulator. The Recipes tab will call `http://127.0.0.1:8000` for suggestions. Start your Python backend first so the app can load recipes.

## 5. Run on a physical device (optional)

1. Connect your iPhone and select it as the run destination.
2. In the project, open **AppConfig.swift** and set `apiBaseURL` to your Mac’s IP, e.g. `"http://192.168.1.100:8000"`.
3. Ensure the phone and Mac are on the same Wi‑Fi and the backend is running with `--host 0.0.0.0`.
4. Run with **⌘R**.

---

**Summary:** Open `backend/whatsForDinner.xcodeproj` in Xcode, wait for packages to resolve, then press **⌘R** to run on the Simulator.
