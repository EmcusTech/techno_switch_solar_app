# Panel System Implementation Guide

## Overview
The panel system creates unique identifiers for solar panels/devices and manages their association with sites. Each panel gets a consistent, unique ID based on device characteristics.

## Key Components

### 1. Panel Model (`lib/models/panel_model.dart`)
- **Panel ID Generation**: Creates unique IDs using device characteristics
- **Device Info Storage**: Stores device details (MAC address, VID/PID, etc.)
- **Site Association**: Links panels to sites with foreign key relationship

#### Panel ID Generation Logic:
- **Bluetooth**: Uses MAC address + device name → `BT_[HASH]`
- **USB**: Uses VID/PID + product name → `USB_[HASH]`
- **Consistent**: Same device always gets same ID

### 2. Database Schema
- **panels table**: Stores panel information
- **Foreign key**: `site_id` references `sites(id)` with SET NULL on delete
- **Unique constraint**: `panel_id` ensures no duplicates
- **Indexes**: On `panel_id` and `site_id` for performance

### 3. Panel Service (`lib/services/panel_service.dart`)
- **Registration**: `registerPanelFromDevice()` - upserts panel on connection
- **Assignment**: Manage panel-to-site relationships
- **Validation**: Ensure panels aren't double-assigned

### 4. Integration Points

#### Connection Flow
1. User connects to device (Bluetooth/USB)
2. System automatically registers/updates panel in database
3. Panel gets unique ID based on device characteristics
4. Connection state includes current panel ID

#### Site Creation Flow
1. **Within Site**: Panel automatically associated with current site
2. **Standalone**: User prompted to create site, panel gets associated

## Database Relationships

```
sites (1) ←→ (0..∞) panels
sites (1) ←→ (0..∞) logs
```

- One site can have multiple panels
- One panel can only belong to one site
- Panel can exist without site (unassigned)
- Deleting site sets panel.site_id to NULL

## Key Methods

### PanelService
- `registerPanelFromDevice()` - Auto-register on connection
- `assignPanelToSite()` - Link panel to site
- `getPanelsBySiteId()` - Get site's panels
- `getUnassignedPanels()` - Get panels without sites

### SiteService (Panel Methods)
- `getSitePanels()` - Get panels for site
- `associateCurrentPanelWithSite()` - Link current connected panel
- `canAssignPanelToSite()` - Check assignment validity

## Usage Examples

### Connecting to Panel
```dart
// Automatic - happens in SerialCommunicationService
final panel = await panelService.registerPanelFromDevice(
  device: bluetoothDevice,
  scanType: 'bluetooth',
);
```

### Site Creation with Panel (Retrieve Log Flow)
```dart
// In EventLogScreen - store panel ID before disconnect
final currentPanelId = AppServices.serialService.currentPanelId;
AppServices.serialService.disconnect();

// Pass panel ID to SimpleSiteCreationScreen
Navigator.pushReplacement(context, MaterialPageRoute(
  builder: (context) => SimpleSiteCreationScreen(
    retrievedLogs: logs,
    panelId: currentPanelId, // Key fix!
  ),
));

// In SimpleSiteCreationScreen - use stored panel ID
final panelIdToAssociate = widget.panelId ?? AppServices.serialService.currentPanelId;
await siteService.associateCurrentPanelWithSite(panelIdToAssociate, site.id!);
```

### Getting Site Panels
```dart
final panels = await siteService.getSitePanels(siteId);
```

## Benefits

1. **Unique Identification**: Each physical device gets consistent ID
2. **Automatic Registration**: No manual panel setup required
3. **Flexible Assignment**: Panels can be moved between sites
4. **Data Integrity**: Foreign key constraints prevent orphaned data
5. **Performance**: Indexed queries for fast lookups

## Migration Notes

- Database version incremented to 2
- Existing installations will auto-upgrade
- No data loss during migration
- Backward compatible with existing site/log data
