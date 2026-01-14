# 📶 WiFi Viewer

A Flutter application for Android that allows you to view the passwords of WiFi networks saved on your device.

> ⚠️ **WARNING: This application requires ROOT access**

## Features

- **Lists all saved WiFi networks** with their passwords
- **Shows security type** (WPA3, WPA2, WPA/WPA2, WEP, Open)
- **Detects hidden networks** (Hidden SSID)
- **Generates QR codes** to easily share networks
- **Copies passwords** to clipboard with one tap
- **Modern and clean interface** with Material Design
- **Real-time network updates**

## Requirements

- ✅ Android device with **ROOT access**
- ✅ Android 5.0 (Lollipop) or higher
- ✅ Superuser permissions (SU)

## Installation

1. Download the APK from [Releases](https://github.com/Cordiaxis/Wifi-Viewer/releases)
2. Install the application on your device
3. Grant ROOT permissions when requested
4. Done! Open the app and view your WiFi networks

## Build from source code

```bash
# Clone the repository
git clone https://github.com/Cordiaxis/Wifi-Viewer.git
cd Wifi-Viewer

# Install dependencies
flutter pub get

# Build APK
flutter build apk --release

# Or install directly on connected device
flutter run --release
```

## Usage

1. **Open the application** - ROOT permissions will be requested on startup
2. **View networks** - The list will show all saved WiFi networks
3. **Copy password** - Tap the 📋 icon to copy to clipboard
4. **Generate QR** - Tap the QR icon to generate a shareable QR code
5. **Refresh** - Use the refresh button to reload the list

## Security

This application reads system files that require ROOT privileges:
- `/data/misc/apexdata/com.android.wifi/WifiConfigStore.xml`
- `/data/misc/wifi/WifiConfigStore.xml`
- `/data/misc/wifi/wpa_supplicant.conf`

**Note:** The application does NOT send data to the internet. All processing is local.

## Technologies

- **Flutter** - Development framework
- **Dart** - Programming language
- **safe_device** - ROOT detection
- **qr_flutter** - QR code generation
- **xml** - Configuration file parsing

## Screenshots

<div align="center">
  <img src="menu.png" alt="WiFi networks list" width="300"/>
  <img src="red.png" alt="WiFi network QR code" width="300"/>
</div>


## Contributing

Contributions are welcome! If you find a bug or have a suggestion:

1. Fork the project
2. Create a branch for your feature (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is open source and available under the MIT license.

## Disclaimer

This application is designed for personal and educational use only. The user is responsible for how they use this tool. We are not responsible for misuse of the application.

---

**Developed using Flutter**  
**App made by Computer Science Student - Second Semester**
