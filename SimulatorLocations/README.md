# Location Simulation GPX Files

GPX files for testing location-based habit reminders in the iOS Simulator.

## Files

### `ArriveAtHome.gpx`
Simulates **arriving** at a location (triggering ENTRY geofence event).
- **Use case**: Test "when arriving home" reminders
- **Starting position**: Inside at center (37.3349, -122.0090)
- **Behavior**: Immediately triggers ENTRY event when loaded (via `requestState()`)
- **Note**: With the `requestState()` fix, positioning inside a geofence triggers immediate entry detection

### `DepartFromHome.gpx`
Simulates **departing** from a location (triggering EXIT geofence event).
- **Use case**: Test "when leaving home" reminders
- **Starting position**: Outside, 500m away (37.3394, -122.0140)
- **Path**: Positioned outside → moves toward center if route is played
- **Trigger point**: ~100m from center (enters 100m geofence radius if route plays)

## How to Use in iOS Simulator

### 1. Load GPX File in Xcode
1. Run the app in iOS Simulator
2. In Xcode, go to: **Debug** → **Simulate Location** → **Add GPX File to Project...**
3. Select either `DepartFromHome.gpx` or `ArriveAtHome.gpx`
4. The simulator will follow the route automatically

### 2. Or Use From Features Menu (Easier)
1. With simulator running, in Xcode menu: **Features** → **Location** → **Custom Location...**
2. Drag and drop the GPX file into Xcode's location panel
3. Or use **Debug** → **Simulate Location** → browse to the GPX file

### 3. Watch Console Logs
Monitor the Xcode console for geofence events:
```
✅ [LocationMonitoring] Started monitoring region: <habit-id>
📍 [LocationMonitoring] Determined state for region <habit-id>: inside
🏠 [LocationMonitoring] Device is inside region - triggering entry event
📍 [LocationMonitoring] Geofence event: entry for habit <habit-id>
🔔 [LocationMonitoring] Triggering notification for habit <habit-id>
✅ [HandleGeofenceEvent] Notification sent for habit: <habit-name>
```

## Testing Workflow

### Test Entry Reminder (Arriving) - RECOMMENDED FOR QUICK TESTING
1. Create a habit with location reminder: "When arriving home"
2. Set the location to: **37.3349, -122.0090** with **100m** radius
3. Load `ArriveAtHome.gpx` in simulator
4. **Notification fires immediately** when `requestState()` detects you're inside the region

### Test Exit Reminder (Departing)
1. Create a habit with location reminder: "When leaving home"
2. Set the location to: **37.3349, -122.0090** with **100m** radius
3. First load `ArriveAtHome.gpx` to position yourself inside
4. Then load `DepartFromHome.gpx` to move outside
5. Watch for notification when crossing out of the geofence

## Customizing Coordinates

The GPX files use **Apple Park** coordinates (Cupertino, CA) as a default:
- **Latitude**: 37.3349
- **Longitude**: -122.0090

### To Use Your Actual Location:
1. Get your coordinates (use Maps app or GPS tool)
2. Replace all `lat="37.3349" lon="-122.0090"` occurrences
3. Adjust the path points accordingly (add/subtract ~0.0005 for ~50m movements)

### Distance Calculations:
- ~0.001 degrees ≈ 100 meters
- ~0.0005 degrees ≈ 50 meters
- ~0.0045 degrees ≈ 500 meters

## Geofence Behavior Notes

- iOS geofences have **100m minimum radius**
- **Entry event**: Fires when device crosses from outside → inside
- **Exit event**: Fires when device crosses from inside → outside
- **Frequency limiting**: Notifications respect configured frequency (e.g., "once per day")
- **Background monitoring**: Works even when app is killed (after fix applied)

## Troubleshooting

### Geofence not triggering?
1. Check location permissions: **Settings** → **Privacy** → **Location Services** → **Ritualist** → **Always**
2. Verify habit has `isActive = true` and `locationConfiguration.isEnabled = true`
3. Check console for logs: `🌍 [LocationMonitoring]` or `❌ [RestoreGeofences]`
4. Ensure geofence radius is ≥ 100m

### Multiple triggers?
- Check `lastTriggerDate` in habit's location configuration
- Frequency rules should prevent excessive notifications
- Console shows: `⏭️ [HandleGeofenceEvent] Skipping notification due to frequency rules`

## Real Device Testing

For testing on a physical iPhone:
1. Export GPX files to your Mac
2. Use a tool like [GPX Tracker](https://apps.apple.com/app/gpx-tracker/id1321964178)
3. Or just walk around physically entering/exiting your configured location
