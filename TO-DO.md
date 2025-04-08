## Inför release
- [x] Autonavigaring kolla så det fortarande fungerar
- [x] Autotanks, kolla så oRA2 koppling fungerar (dubbelkika hur man fastställer om den är aktiv)
- [ ] Sync

## Sync Implementation Plan

### Section Navigation Broadcast
When navigating to a new section:
- Include timestamp for version control (most recent data wins)
- Section name we're navigating to
- Sender is implied in addon messages
- Include target section for post-import navigation

### Data Import Broadcast
When importing new data manually:
- Broadcast the full import string
- Include timestamp of when we imported the data
- Sender is implied in addon messages

### Handling Incoming Navigation Broadcasts
When receiving a navigation broadcast:
- Compare timestamps
  - If their timestamp > our timestamp:
    - Request full data string from sender
    - After receiving, update our data if different
    - Navigate to the specified section (without re-broadcasting)
  - If our timestamp > their timestamp:
    - Broadcast our string and timestamp
    - Implement throttling to prevent all players broadcasting simultaneously

### File Structure
- Using existing files:
  - ChunkManager.lua - For handling large data strings
  - Sync.lua - Core sync functionality
  - SyncHandlers.lua - Processing specific sync events

## Current Status Analysis

### Already Implemented
1. Basic addon messaging framework with TWRA prefix
2. Communication channel selection (RAID if in raid, otherwise PARTY)
3. Section change broadcasting (but without timestamps or version control)
4. Handling incoming section change messages and navigating accordingly
5. Live Sync toggle functionality and initialization
6. Data import/save functions that can:
   - Update `TWRA_SavedVariables.assignments` with new data
   - Store current section info before data update
   - Rebuild navigation with new section information
   - Update to selected section after import

### Missing Components
1. Timestamp tracking for data versioning
   - Need to add a dataTimestamp property to TWRA.SYNC
   - Update timestamp when importing data or receiving newer data

2. Enhanced message protocol
   - Current "SECTION:" format needs to be updated to include timestamps
   - Need to implement proper command handling for VERSION, DATA_REQUEST, DATA_RESPONSE

3. Data request/response handling
   - Request full data when receiving a message with newer timestamp
   - Send data when receiving a request
   - Process incoming data and update if newer

4. Chunk management for large data strings
   - Implement ChunkManager usage for breaking up and reassembling large strings
   - Handle timeout/retry logic for failed transmissions

5. Import broadcasting
   - Add function to broadcast when new data is imported manually
   - Include timestamp in broadcast
   - Add parameter to `SaveAssignments` to trigger broadcast on manual import

6. Throttling mechanism
   - Prevent flooding when multiple users have newer data
   - Random delay before responding to broadcast requests

## Sync Implementation Plan Refinement

After reviewing current code, we should enhance the existing functions:

1. Enhance `SaveAssignments` to:
   - Add broadcast parameter that triggers sharing with group
   - Include timestamp in broadcast messages
   - Add origin information for conflict resolution

2. Enhance `NavigateToSection` to:
   - Include data timestamp in section change announcements
   - Avoid re-broadcasting when receiving sync message
   
3. Update `BroadcastSectionChange` to:
   - Format message as "SECTION:timestamp:sectionName:sectionIndex"
   - Add a throttling mechanism for responses

## Additional Considerations

1. Error handling & recovery:
   - Implement timeout handling for requested data that never arrives
   - Add recovery mechanism for incomplete chunk transfers
   - Add version compatibility check for different addon versions

2. User feedback:
   - Add visual indicators for sync status (in progress/complete)
   - Show which player's data is being used
   - Notify when local data is overwritten by newer data

3. Conflict resolution:
   - Handle edge cases where timestamps are identical
   - Implement leadership priority (raid leader/assistant data takes precedence)
   - Allow manual override of automatic sync decisions

4. Performance optimizations:
   - Implement data diffing to only send changed sections
   - Add compression for large datasets
   - Use throttling for large groups to prevent message flooding

5. Disruption prevention:
   - Add option to delay sync during combat
   - Implement sync queuing during high-activity periods
   - Add safeguards against sync loops or message storms