## Sync Implementation Plan 

### Current State Analysis

After code review, the current state appears to have Base64 encoding/decoding working properly for imports, but lacks synchronized data sharing between clients. The core functionality for parsing and displaying imported data works, but needs to be extended for real-time syncing.

#### Identified Issues to Resolve Before Implementation
- **Empty Section Handling**: When importing data directly, empty section names are correctly filtered out, but they reappear after UI reload. This inconsistency needs to be fixed in RebuildNavigation to apply the same filtering logic in both scenarios.

### Implementation Strategy

We'll implement sync features in small, testable increments to ensure stability throughout the process.

### Main sync features

#### Messages

**Broadcast navigation**: When "Live Section Sync" is enabled in the options we want to broadcast to make others navigate to the same section.
Info that I think is relevant in this broadcast:
- Timestamp, the time our data was imported
- Section, the name of the section we're navigating to
- Section index, to ensure consistent navigation

**Broadcast import**: When we import data in our options menu we **always** want to broadcast that we're importing new data.
- Import string, seems the most feasible to broadcast rather than the decoded string. Decoding does not seem to be a taxing operation
- Timestamp, the time that the import happened

**Request data:** When we see someone broadcasting navigation with more recent data we want to request it.
- Ask for more recent data, requesting data with specific timestamp

**Broadcast full data**: Answer to request data.
- Send our string and timestamp.

#### Handlers
**Navigation**: When we see a navigation message
- If broadcast timestamp > local timestamp request data with the new timestamp.
- Navigate to broadcast section, if we need new data do not navigate until we have processed it. We should add a suppressSync argument to NavigateToSection to make sure we're never broadcasting a navigation that happens as an answer to a navigation broadcast.

**Import**: Handle mostly like when we import data manually from the options menu.
- A new import is always of a greater timestamp than our current so we shouldn't have to compare our timestamp in this scenario.
- Process the string and import the data.
    - Do not broadcast this import, this is a reaction to a import broadcast
    - Use the broadcast timestamp instead of generating a new one - we're on the same data.
    - NavigateToSection just like we'd do when we import manually but suppressSync.

**Request data**: Send our data if it's requested
- Compare our timestamp with the requested timestamp and only try to send our info if they match.
- Throttle, we do not want 39 players to send their data at the same time when the 40th client asks for it.

**Broadcast full data**: When we see someone sending data that we've requested
- Handle much like Import.

### Step-by-Step Implementation Plan

#### Phase 0: Pre-Implementation Fixes (1 day)
1. **Fix Empty Section Handling**
   - Update RebuildNavigation to filter out empty section names
   - Ensure consistent behavior between import and UI reload
   - Test thoroughly with imported data containing empty sections

#### Phase 1: Core Functionality (1-2 days)
1. **Add timestamp tracking**
   - Add timestamp field to saved variables
   - Store timestamp on manual import
   - Update timestamp display in UI if appropriate

2. **Modify NavigateToSection**
   - Add suppressSync parameter (default: false)
   - Update all NavigateToSection calls to maintain current behavior

3. **Modify import function**
   - Add isSync parameter (default: false)
   - Add timestamp parameter for sync operations
   - Test manual imports still work correctly

#### Phase 2: Communication Setup (1-2 days)
4. **Implement Message Formats**
   - Define message prefix constants for each message type
   - Create message serialization/deserialization functions
   - Implement proper error handling for malformed messages

5. **Create Sync Module Foundation**
   - Initialize event frame for message handling
   - Create message routing based on prefixes
   - Add throttling mechanism to prevent flood

6. **Implement Basic Message Handlers**
   - Create handler stubs for all message types
   - Add debug logging for all message events
   - Test basic message routing

#### Phase 3: Navigation Synchronization (2 days)
7. **Implement Navigation Broadcast**
   - Send navigation info when user changes sections
   - Include timestamp and section information
   - Test with debug output only

8. **Implement Navigation Handler**
   - Process incoming navigation broadcasts
   - Add logic to check timestamps
   - Make navigation handler request newer data if needed
   - Test navigation sync between clients

#### Phase 4: Data Synchronization (3 days)
9. **Implement Data Request**
   - Send request when detecting newer timestamp
   - Add random delay to prevent simultaneous responses
   - Test request functionality

10. **Implement Import Broadcast**
    - Send import data when user imports manually
    - Include proper timestamp
    - Test with small imports

11. **Implement Full Data Handler**
    - Process incoming data
    - Update local data with newer data
    - Verify timestamp handling
    - Test with various data sizes

#### Phase 5: Reliability Improvements (2 days)
12. **Add Error Recovery**
    - Handle failed syncs gracefully
    - Implement version checking
    - Add data verification

13. **UI Indicators**
    - Add sync status indicators
    - Show sync progress for large imports

### Testing Plan
- **Unit Testing**: Test each component individually
  - Test NavigateToSection with suppressSync
  - Test import function with isSync
  - Test message handling without actual network

- **Integration Testing**: Test combinations of components
  - Test navigation broadcast triggering data request
  - Test data response handling and UI updates

- **Full System Testing**: End-to-end scenarios
  - Different group sizes (2, 5, 10+ players)
  - Different data sizes (small to large imports)
  - Edge cases (simultaneous imports, disconnects)

### Files to Modify
- `TWRA.lua` - Update RebuildNavigation for empty section handling
- `core/Base64.lua` - No changes needed, functionality verified
- `core/DataProcessing.lua` - Add timestamp handling for imports
- `Core.lua` - Update NavigateToSection function
- `sync/Sync.lua` - Create message handlers
- `sync/SyncHandlers.lua` - Implement specific handlers for each message type
- `core/Debug.lua` - Add sync-related debug messages

### Future Enhancements
- Chunk manager for very large data. Not needed initially as current string transmission works, but could be needed for very large raids.
- Sync progress inside OSD. We'll be fine just using a TWRA:Debug("sync", "importProgress", true) if we need this feature but having it show update inside our OSD would be a nice addition down the road.
- Conflict resolution for simultaneous imports from different clients

### Immediate Next Steps
1. Fix empty section handling in RebuildNavigation
2. Add timestamp tracking to import process
3. Update NavigateToSection to handle suppressSync parameter
4. Create basic message handlers