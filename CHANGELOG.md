# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-11-09

### Added
- Initial release of auto_refresh_on_reconnect package
- `AutoRefreshOnReconnect` widget for automatic refresh on reconnection
- `AutoRefreshOnReconnectBuilder` for builder-based data fetching
- `ConnectivityService` for real internet verification
- Debouncing support to prevent rapid re-triggers
- Custom offline UI support via `offlineBuilder`
- Comprehensive test suite
- Example app demonstrating all features
- Full documentation and API reference

### Features
- Real internet access verification using HTTP HEAD requests
- State-management agnostic design
- Customizable debounce duration
- Extensible connectivity service for custom implementations
- Null-safe implementation
- Works with Provider, Bloc, Riverpod, and other state management solutions
