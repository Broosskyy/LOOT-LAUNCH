# Web and Android Export

## Browser

Install the matching Godot Web export template. Select the `Web Test` preset and export. Serve `build/web` over HTTP/HTTPS; opening `index.html` directly from the filesystem is not supported.

For a local test:

```bash
python -m http.server 8060 --directory build/web
```

Open `http://localhost:8060` and add that origin to the Supabase development CORS/Auth configuration.

## Android APK

Install Godot Android build templates, Android SDK and Java. Select `Android APK`, configure a debug keystore if requested, then export to `build/android/loot-launch.apk`. Copy the APK to the phone or install with `adb install -r build/android/loot-launch.apk`.

## Android AAB

Use `Android AAB` only after configuring the private Play signing keystore outside the repository. Increment version code/name before every store upload.

