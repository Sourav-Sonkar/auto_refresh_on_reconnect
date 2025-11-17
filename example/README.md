# auto_refresh_on_reconnect Example

This example demonstrates how to use the `auto_refresh_on_reconnect` package with real API calls.

## Features Demonstrated

### Main Screen (ExamplePage)
- ✅ Auto-refresh on reconnection using real API
- ✅ Fetches posts from JSONPlaceholder API
- ✅ Custom offline UI with icon and message
- ✅ Refresh counter to track automatic refreshes
- ✅ Timestamp showing last refresh time
- ✅ Loading states and error handling
- ✅ Beautiful card-based UI

### Builder Example Screen
- ✅ Builder-based API with `AutoRefreshOnReconnectBuilder`
- ✅ Fetches users from JSONPlaceholder API
- ✅ Automatic data fetching on reconnection
- ✅ AsyncSnapshot handling for loading/error/success states
- ✅ Navigation between screens

## Running the Example

**On Web** (recommended for quick testing):
```bash
flutter run -d chrome
```

**On Mobile/Desktop**:
```bash
flutter run
```

## Testing Offline Behavior

### On Web:
1. Run the app in Chrome
2. Open DevTools (F12) → Network tab
3. Check "Offline" checkbox
4. Observe the offline UI
5. Uncheck "Offline"
6. Watch the app automatically fetch fresh data!

### On Mobile/Desktop:
1. Run the app on a device or emulator
2. Turn off WiFi or mobile data
3. Observe the offline UI appearing
4. Turn WiFi/data back on
5. Watch the app automatically refresh and fetch new data

## API Endpoints Used

- **Posts**: `https://jsonplaceholder.typicode.com/posts?_limit=10`
- **Users**: `https://jsonplaceholder.typicode.com/users?_limit=5`

[JSONPlaceholder](https://jsonplaceholder.typicode.com/) is a free fake REST API for testing and prototyping.

## Code Structure

- `main.dart` - Complete example app with:
  - `ExamplePage` - Main screen with widget-based API
  - `BuilderExample` - Secondary screen with builder-based API
  - Real HTTP requests using the `http` package
  - Error handling and loading states
  - Navigation between examples
