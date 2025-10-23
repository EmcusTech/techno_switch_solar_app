# Responsive Layout Implementation

This application implements a responsive design that automatically switches between mobile and desktop layouts based on screen size.

## Breakpoint

- **Desktop Layout**: Screens wider than 900px
- **Mobile Layout**: Screens 900px or narrower

## Layouts

### Desktop Layout (`DesktopHomeScreen`)
**Location**: `lib/screens/desktop_home_screen.dart`

**Features**:
- Menu bar with File, Panel, Settings, Help options
- Two connection cards side-by-side:
  - **Connect Via USB** (blue) - Placeholder for future USB functionality
  - **Tap to Connect** (red) - Bluetooth connection
- 2x2 grid of action cards:
  - New Site
  - Live Event
  - Retrieve Log
  - Open Site
- Recent Sites data table with columns:
  - Project (clickable)
  - Location (building name)
  - Date Created
  - Status (with colored badge)
  - Actions (menu button)

### Mobile Layout (`_HomeContent`)
**Location**: `lib/screens/home_screen.dart`

**Features**:
- Gradient background with logo
- "Tap to connect" button
- Quick links in a horizontal row
- Recent sites as vertical cards
- Bottom navigation bar with Home, Settings, Help tabs

## Implementation Details

### Responsive Switch Logic
Located in `lib/screens/home_screen.dart`:

```dart
@override
Widget build(BuildContext context) {
  final isDesktop = MediaQuery.of(context).size.width > 900;
  
  if (isDesktop) {
    return const DesktopHomeScreen();
  }
  
  // Mobile layout continues...
}
```

### Connection Methods

Both layouts support:
1. **Bluetooth Connection**: Navigates to `ScanningScreen()` for Bluetooth device pairing
2. **USB Connection**: Placeholder UI in desktop layout (not yet implemented)

### Shared Functionality

Both layouts share:
- Site loading from `SiteService`
- Bluetooth cleanup on screen init via `AppServices`
- App state reset via `AppState`
- Navigation to site details, creation screens, etc.

## Testing

To test responsive behavior:

### Desktop (Windows/macOS/Linux)
```bash
flutter run -d windows  # or macos, linux
```
Resize the window to see layout switch at 900px width.

### Mobile (Android/iOS)
```bash
flutter run -d android  # or ios
```
Mobile layout will be shown automatically.

### Web
```bash
flutter run -d chrome
```
Resize browser window to see responsive changes.

## Future Enhancements

1. **USB Connection Implementation**: Add functionality to the "Connect Via USB" card
2. **Tablet Layout**: Consider an intermediate layout for tablets (600-900px)
3. **Menu Bar Actions**: Implement File, Panel, Settings, Help menu functionality
4. **Context Menus**: Add actions to the table's menu button (edit, delete, share, etc.)

