# auto_refresh_on_reconnect

A lightweight Flutter package that automatically refreshes widgets when internet connection is restored — without requiring developers to manually manage network listeners or rebuild the UI.

## Demo

![Demo](assets/example.gif)

*Automatic refresh when internet connection is restored*

## Features

✅ Automatic refresh on internet reconnection  
✅ Real internet verification (not just WiFi connection)  
✅ Debounced reconnection events to prevent rapid re-triggers  
✅ Custom offline UI support  
✅ State-management agnostic (works with Provider, Bloc, Riverpod, etc.)  
✅ Builder-based API for data fetching  
✅ Fully null-safe and tested  

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  auto_refresh_on_reconnect: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Usage

### Basic Usage

Wrap your widget with `AutoRefreshOnReconnect` and provide an `onRefresh` callback:

```dart
import 'package:auto_refresh_on_reconnect/auto_refresh_on_reconnect.dart';

AutoRefreshOnReconnect(
  onRefresh: () async {
    // Your refresh logic here
    await fetchProducts();
  },
  child: ProductListView(),
)
```

### With Offline UI

Display a custom widget when the device is offline:

```dart
AutoRefreshOnReconnect(
  onRefresh: () async {
    await fetchProducts();
  },
  offlineBuilder: (context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off, size: 64),
        SizedBox(height: 16),
        Text('No Internet Connection'),
      ],
    ),
  ),
  child: ProductListView(),
)
```


### Custom Debounce Duration

Adjust the debounce duration to control how quickly the refresh triggers after reconnection:

```dart
AutoRefreshOnReconnect(
  debounceDuration: Duration(seconds: 5), // Wait 5 seconds before refreshing
  onRefresh: () async {
    await fetchProducts();
  },
  child: ProductListView(),
)
```

### Builder API

Use the builder-based API for automatic data fetching and display:

```dart
AutoRefreshOnReconnectBuilder<List<Product>>(
  futureBuilder: () => fetchProducts(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (snapshot.hasError) {
      return Center(child: Text('Error: ${snapshot.error}'));
    }
    
    if (snapshot.hasData) {
      return ProductList(products: snapshot.data!);
    }
    
    return Center(child: Text('No data'));
  },
  offlineBuilder: (context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.wifi_off, size: 64),
        SizedBox(height: 16),
        Text('Offline - will refresh when reconnected'),
      ],
    ),
  ),
)
```

## Additional Information

### Platform Support

- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ macOS
- ✅ Windows
- ✅ Linux

### How It Works

1. **Connectivity Monitoring**: Uses `connectivity_plus` to monitor network state changes
2. **Real Internet Verification**: Performs HTTP HEAD requests to verify actual internet access
3. **Debouncing**: Prevents rapid successive refresh calls during unstable connections
4. **Automatic Refresh**: Triggers your callback when connection is restored after being offline

### Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.


## Customization Options

### Custom Connectivity Service

For testing or custom network check implementations, you can provide your own `ConnectivityService`:

```dart
class CustomConnectivityService extends ConnectivityService {
  @override
  Future<bool> hasInternetAccess() async {
    // Your custom internet check logic
    return true;
  }
}

AutoRefreshOnReconnect(
  connectivityService: CustomConnectivityService(),
  onRefresh: () async {
    await fetchData();
  },
  child: MyWidget(),
)
```

### Custom Check URL

Change the URL used for internet verification:

```dart
final service = ConnectivityService(
  checkUrl: 'https://example.com',
  timeout: Duration(seconds: 5),
);

AutoRefreshOnReconnect(
  connectivityService: service,
  onRefresh: () async {
    await fetchData();
  },
  child: MyWidget(),
)
```

## Platform-Specific Behavior

### Web Platform

On web platforms, the package handles CORS (Cross-Origin Resource Sharing) restrictions gracefully:

- The package relies more on the connectivity status from `connectivity_plus`
- HTTP HEAD requests may fail due to CORS, so the package assumes online status when connectivity is detected
- To test offline behavior on web:
  - Use Chrome DevTools → Network tab → Toggle "Offline"
  - Or disable your network connection

### Mobile & Desktop Platforms

On mobile (iOS/Android) and desktop (macOS/Windows/Linux) platforms:

- The package performs actual HTTP HEAD requests to verify internet access
- This provides more accurate connectivity detection
- Default check URL is `https://www.google.com` (customizable)

## API Reference

### AutoRefreshOnReconnect

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | The widget to display when online |
| `onRefresh` | `Future<void> Function()?` | `null` | Callback triggered on reconnection |
| `offlineBuilder` | `WidgetBuilder?` | `null` | Builder for offline UI |
| `debounceDuration` | `Duration` | `Duration(seconds: 2)` | Debounce duration for reconnection |
| `connectivityService` | `ConnectivityService?` | `null` | Custom connectivity service |

### AutoRefreshOnReconnectBuilder<T>

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `futureBuilder` | `Future<T> Function()` | required | Function that returns data |
| `builder` | `AsyncWidgetBuilder<T>` | required | Builder receiving AsyncSnapshot |
| `offlineBuilder` | `WidgetBuilder?` | `null` | Builder for offline UI |
| `debounceDuration` | `Duration` | `Duration(seconds: 2)` | Debounce duration |
| `connectivityService` | `ConnectivityService?` | `null` | Custom connectivity service |


## Example

A complete example app is available in the `example/` directory, demonstrating:

- Real API calls with JSONPlaceholder
- Both widget and builder APIs
- Custom offline UI with loading states
- Navigation between different screens
- Error handling and refresh counters

To run the example:

```bash
cd example
flutter run
```

See the [example README](example/README.md) for detailed instructions.

## Testing

The package includes comprehensive tests. Run them with:

```bash
flutter test
```

### Testing Your Implementation

When testing widgets that use `AutoRefreshOnReconnect`, you can provide a mock connectivity service:

```dart
class MockConnectivityService extends ConnectivityService {
  final StreamController<bool> _controller = StreamController<bool>.broadcast();
  bool _isConnected = true;

  @override
  Stream<bool> get onConnectivityChanged => _controller.stream;

  @override
  Future<bool> hasInternetAccess() async => _isConnected;

  void setConnected(bool connected) {
    _isConnected = connected;
    _controller.add(connected);
  }
}

// In your test
final mockService = MockConnectivityService();

await tester.pumpWidget(
  AutoRefreshOnReconnect(
    connectivityService: mockService,
    onRefresh: () async {
      // Your refresh logic
    },
    child: YourWidget(),
  ),
);

// Simulate going offline
mockService.setConnected(false);
await tester.pumpAndSettle();

// Simulate reconnection
mockService.setConnected(true);
await tester.pumpAndSettle();
```

## Example App

Check out the [example](example/) directory for a complete working example demonstrating:

- Basic auto-refresh functionality with real API calls (JSONPlaceholder)
- Custom offline UI with icons and messages
- Refresh counter and timestamp tracking
- Builder API usage with user data
- Error handling and loading states
- Navigation between examples

To run the example:

```bash
cd example
flutter run -d chrome  # For web
# or
flutter run            # For mobile/desktop
```

The example fetches real data from [JSONPlaceholder API](https://jsonplaceholder.typicode.com/):
- Main screen: Fetches posts
- Builder example: Fetches users

## State Management Integration

This package is state-management agnostic and works seamlessly with any solution:

### With Provider

```dart
AutoRefreshOnReconnect(
  onRefresh: () async {
    await context.read<ProductProvider>().fetchProducts();
  },
  child: Consumer<ProductProvider>(
    builder: (context, provider, child) {
      return ProductList(products: provider.products);
    },
  ),
)
```


### With Bloc

```dart
AutoRefreshOnReconnect(
  onRefresh: () async {
    context.read<ProductBloc>().add(FetchProducts());
  },
  child: BlocBuilder<ProductBloc, ProductState>(
    builder: (context, state) {
      if (state is ProductLoaded) {
        return ProductList(products: state.products);
      }
      return CircularProgressIndicator();
    },
  ),
)
```

### With Riverpod

```dart
class ProductScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AutoRefreshOnReconnect(
      onRefresh: () async {
        ref.invalidate(productsProvider);
      },
      child: Consumer(
        builder: (context, ref, child) {
          final products = ref.watch(productsProvider);
          return products.when(
            data: (data) => ProductList(products: data),
            loading: () => CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          );
        },
      ),
    );
  }
}
```

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.
