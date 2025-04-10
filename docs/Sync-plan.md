## Sync Implementation Plan 

### Current State Analysis

After code review, the current state appears to have Base64 encoding/decoding working properly for imports, but synchronization between clients is not yet fully functional. The core functionality for parsing and displaying imported data works, and we need to ensure proper communication between instances.

#### Identified Issues to Resolve Before Implementation
- **Empty Section Handling**: When importing data directly, empty section names are correctly filtered out, but they reappear after UI reload. This inconsistency needs to be fixed in RebuildNavigation to apply the same filtering logic in both scenarios.
- **Message Parsing**: Our current message handlers need to be corrected to properly parse messages with colons in the content.

### Implementation Strategy

We're implementing sync features in small, testable increments to ensure stability throughout the process.

### Main sync features

#### Messages

**Broadcast navigation**: When "Live Section Sync" is enabled in the options we want to broadcast to make others navigate to the same section.
Info that is relevant in this broadcast:
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
9. ✅ **Implement Data Request**
   - Handler code implemented and tested ✅
   - Random delay mechanism implemented and working ✅
   - Request/response flow verified ✅

10. ✅ **Implement Import Broadcast**
    - Broadcast functionality working correctly ✅
    - Announcement messages correctly sent ✅
    - Data requests correctly triggered ✅
    - Data transmission using chunking successfully implemented ✅

11. ✅ **Implement Full Data Handler**
    - Empty response issue fixed ✅
    - Data integrity verified after sync ✅
    - Base64 padding handling improved ✅
    - Sync workflow successfully completes end-to-end ✅

### Current Status
- Navigation synchronization is fully operational ✅
- Section changes are successfully broadcast and received ✅
- Timestamp comparison logic for section changes works correctly ✅
- Login/reload broadcast suppression is working correctly ✅
- Import announcements and data requests working correctly ✅
- Data chunking and reassembly working for large datasets ✅
- Full sync workflow verified end-to-end ✅

### Next Tasks
1. ✅ Fix initialization issues when reloading UI - RESOLVED
2. ✅ Verify basic communication between clients - CONFIRMED
3. ✅ Ensure section broadcast/receive is working - CONFIRMED
4. ✅ Suppress section broadcast on login/reload - IMPLEMENTED
5. ✅ Fix data response issue - RESOLVED
   - ✅ Fixed empty response issue
   - ✅ Implemented chunking for large datasets
   - ✅ Verified data integrity with proper Base64 padding
6. ✅ Test full data synchronization flow - CONFIRMED
   - ✅ Verified clients with newer data properly broadcast to clients with older data
   - ✅ Verified timestamp comparison and data request flow
   - ✅ Confirmed clients properly receive and process updated data
7. 🔄 Create test scenarios for edge cases:
   - Simultaneous imports from different clients
   - Very large data imports (initial tests successful)
   - Group members joining/leaving during sync operations

### Final Implementation Phase
14. ⏩ **Optimize and Polish**
    - Review error handling for robustness
    - Clean up debug messages for production
    - Add user-facing sync status indicators
    - Document sync features for end users

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

### Implementation Progress

#### Phase 1: Core Functionality - COMPLETED ✅
1. ✅ **Add timestamp tracking**
   - Added timestamp field to saved variables
   - Store timestamp on manual import (current time())
   - Set timestamp to 0 for example data
   - Added timestamp parameter to SaveAssignments

2. ✅ **Modify NavigateToSection**
   - Added proper handling of suppressSync parameter
   - Enhanced broadcast to include timestamp information
   - Updated BroadcastSectionChange to handle timestamp
   - Added debug logging for sync operations

3. ✅ **Modify import function**
   - Added isSync parameter to control import behavior
   - Added syncTimestamp parameter for sync operations
   - Updated import UI handling to clear input and switch views
   - Modified DecodeBase64 to handle sync operations

#### Phase 2: Communication Setup - COMPLETED ✅
4. ✅ **Implement Message Formats**
   - Defined message prefix constants for each message type
   - Created message serialization/deserialization functions
   - Implemented proper error handling for malformed messages

5. ✅ **Create Sync Module Foundation**
   - Initialized event frame for message handling ✅
   - Created message routing based on prefixes ✅
   - Added throttling mechanism to prevent flood ✅
   - Proper event registration occurring ✅
   - Fixed issues with initialization on reload ✅

6. ✅ **Implement Basic Message Handlers**
   - Created handler stubs for all message types ✅
   - Added debug logging for all message events ✅
   - Basic routing and parsing working ✅
   - Verified communications between clients ✅
   - Message relay mechanism verified ✅
   - Added message monitoring feature for debugging ✅

#### Phase 3: Navigation Synchronization - COMPLETED ✅
7. ✅ **Implement Navigation Broadcast**
   - Implementation fully working and tested with multiple clients
   - Timestamp and section information correctly included
   - Broadcasts are properly sent and received
   - Fixed issues with initialization and activation ✅
   - Added initial broadcast suppression on login/reload ✅

8. ✅ **Implement Navigation Handler**
   - Navigation handler implemented ✅
   - Section changes properly broadcast and received ✅
   - Timestamp comparison logic verified ✅
   - Section changes with matching timestamps work correctly ✅

#### Phase 4: Data Synchronization - MOSTLY COMPLETE ✅
9. ✅ **Implement Data Request**
   - Handler code implemented and tested ✅
   - Random delay mechanism implemented and working ✅
   - Request/response flow verified ✅

10. ✅ **Implement Import Broadcast**
    - Broadcast functionality working correctly ✅
    - Announcement messages correctly sent ✅
    - Data requests correctly triggered ✅
    - Data transmission using chunking successfully implemented ✅

11. ✅ **Implement Full Data Handler**
    - Empty response issue fixed ✅
    - Data integrity verified after sync ✅
    - Base64 padding handling improved ✅
    - Sync workflow successfully completes end-to-end ✅

### Current Status
- Navigation synchronization is fully operational ✅
- Section changes are successfully broadcast and received ✅
- Timestamp comparison logic for section changes works correctly ✅
- Login/reload broadcast suppression is working correctly ✅
- Import announcements and data requests working correctly ✅
- Data chunking and reassembly working for large datasets ✅
- Full sync workflow verified end-to-end ✅

### Next Tasks
1. ✅ Fix initialization issues when reloading UI - RESOLVED
2. ✅ Verify basic communication between clients - CONFIRMED
3. ✅ Ensure section broadcast/receive is working - CONFIRMED
4. ✅ Suppress section broadcast on login/reload - IMPLEMENTED
5. ✅ Fix data response issue - RESOLVED
   - ✅ Fixed empty response issue
   - ✅ Implemented chunking for large datasets
   - ✅ Verified data integrity with proper Base64 padding
6. ✅ Test full data synchronization flow - CONFIRMED
   - ✅ Verified clients with newer data properly broadcast to clients with older data
   - ✅ Verified timestamp comparison and data request flow
   - ✅ Confirmed clients properly receive and process updated data
7. 🔄 Create test scenarios for edge cases:
   - Simultaneous imports from different clients
   - Very large data imports (initial tests successful)
   - Group members joining/leaving during sync operations

### Final Implementation Phase
14. ⏩ **Optimize and Polish**
    - Review error handling for robustness
    - Clean up debug messages for production
    - Add user-facing sync status indicators
    - Document sync features for end users

### Debugging Tools
- The `/syncmon` command provides real-time monitoring of all addon messages
- This is extremely valuable for debugging and has helped confirm proper communication
- Messages are color-coded for better visibility and include sender information
- Can monitor other addon communications as well for integration testing

### Future Work
- Add UI indicators for sync status and progress
- Implement conflict resolution for simultaneous updates
- Add version checking for compatibility between different addon versions
- Consider refining chunking algorithm for very large datasets