# Location Permissions Configuration

## Required Info.plist Entries

To enable location-aware habits, the following entries must be added to the app's Info.plist via Xcode:

### 1. Location When In Use Usage Description

**Key**: `NSLocationWhenInUseUsageDescription`
**Type**: String
**Value**:
```
Ritualist needs your location to send reminders when you arrive at specific places.
```

### 2. Location Always and When In Use Usage Description

**Key**: `NSLocationAlwaysAndWhenInUseUsageDescription`
**Type**: String
**Value**:
```
Ritualist monitors your location in the background to send habit reminders when you enter or leave specific areas.
```

### 3. Background Modes

**Key**: `UIBackgroundModes`
**Type**: Array
**Item 0**: `location`

---

## How to Add These in Xcode

### Method 1: Using Project Settings (Recommended)

1. Open `Ritualist.xcodeproj` in Xcode
2. Select the **Ritualist** target
3. Go to the **Info** tab
4. Click the **+** button to add a new key
5. Add each of the keys above with their respective values

### Method 2: Using Capabilities

For Background Modes:
1. Select the **Ritualist** target
2. Go to the **Signing & Capabilities** tab
3. Click **+ Capability**
4. Add **Background Modes**
5. Check **Location updates**

---

## Testing Location Permissions

### In Simulator:
1. Build and run the app
2. When location permission is requested, grant "While Using the App"
3. Then grant "Always" permission when prompted
4. In Simulator menu: Features → Location → Custom Location to test geofences

### On Physical Device (Required for Geofences):
1. Install app on physical device
2. Grant location permissions
3. Create a location-aware habit
4. Walk into/out of the geofenced area to test notifications

**Note**: Geofences do NOT work reliably in the simulator. Physical device testing is required for geofence functionality.

---

## Privacy Considerations

The app uses the minimum necessary location accuracy (`kCLLocationAccuracyHundredMeters`) to preserve battery life while maintaining geofence reliability.

Users can disable location monitoring for individual habits at any time through the habit settings.
