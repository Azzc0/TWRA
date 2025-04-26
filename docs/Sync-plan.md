# TWRA Synchronization Implementation Plan

## Current Implementation Analysis

### Overview of Sync Architecture

The TWRA addon currently uses a segmented synchronization system that consists of:

1. **Core Components**:
   - `Sync.lua`: Contains general sync functionality and initialization
   - `SyncHandlers.lua`: Handles specific message types and commands
   - `ChunkManager.lua`: Manages splitting and reassembly of large messages

2. **Message Types**:
   - `SEC`: Section change notifications
   - `REQ`: Data requests
   - `RESP`: Data responses
   - `ANC`: Announcements of new imports
   - `VER`: Version checking (not fully implemented)
   - `SREQ`: Structure requests (segmented sync)
   - `SRES`: Structure responses (segmented sync)
   - `SECREQ`: Section data requests
   - `SECRESP`: Section data responses

3. **Data Structures**:
   - `TWRA_Assignments`: Main data structure for raid assignments
   - `TWRA_CompressedAssignments`: Compressed data for sync operations

### Sync Flow Analysis

#### Current Flow for Section Navigation Sync

1. User changes section in UI
2. `NavigateToSection()` is called in `TWRA.lua`
3. Navigation is updated locally
4. If not suppressed, `BroadcastSectionChange()` sends a message with section index and timestamp
5. Recipients receive message through `HandleSectionCommand()` in `SyncHandlers.lua`
6. Timestamp comparison occurs:
   - If timestamps match: navigate to the section
   - If our timestamp is newer: ignore the message
   - If their timestamp is newer: request their structure with `RequestStructureSync()`

#### Current Flow for Data Import/Sync

1. User imports data
2. Data is saved via `SaveAssignments()`
3. If in a group, `AnnounceDataImport()` is called
4. An announcement is sent with timestamp
5. Recipients can request data via `RequestStructureSync()`

#### Current Chunking System

The ChunkManager splits large messages:
1. Unique transfer ID is generated
2. Header message is sent with total size, ID, and chunk count
3. Individual chunks are sent with staggered delays
4. Recipient assembles data when all chunks are received

## Implementation Issues and Divergences

### Identified Issues

1. **Inconsistent Command Handling**:
   - Some commands use hardcoded strings ("SRES") while others use constants
   - Mix of direct string handling and constants in different files

2. **Fragmented Sync Logic**:
   - Core sync logic is spread across multiple files
   - Some functions are duplicated or have similar implementations

3. **Timestamp Inconsistencies**:
   - Different timestamp handling in different parts of the code
   - Some areas use GetTime() while others use time()

4. **Error Handling Gaps**:
   - Some error conditions are not properly handled
   - Missing validation in some message handlers

5. **Divergences from Original Plan**:
   - The `SRES` command uses a different name than originally planned
   - Some sync features like version checking are not fully implemented

### Data Flow Inefficiencies

1. **Redundant Data Transfer**:
   - When full sync happens, all data is transferred even if not needed
   - Compressed structure is regenerated more often than necessary

2. **Request Flooding**:
   - No coordination mechanism for multiple clients making requests
   - Potential for request storms when many users join a group

## Improvement Plan

### 1. Standardize Command Handling

- Consolidate all command constants in a single location
- Use consistent naming patterns for all commands
- Replace hardcoded strings with constants throughout the codebase

### 2. Optimize Data Flow

- Implement proper caching of compressed data
- Add validation to avoid redundant transfers
- Implement differential sync where possible

### 3. Improve Error Handling and Recovery

- Add comprehensive validation for all incoming messages
- Implement automatic recovery for interrupted transfers
- Add timeout handling for pending responses

### 4. Enhanced Permissions System

- Expand permission model beyond raid leader/assistant
- Add configurable permission options
- Implement conflict resolution for simultaneous edits

### 5. Throttling and Load Distribution

- Implement better throttling of requests based on raid size
- Add exponential backoff for retries
- Distribute response load across multiple clients

### 6. UI Feedback Enhancements

- Add progress indicators for sync operations
- Improve status messages for sync activities
- Add detailed sync statistics in debug mode

## Implementation Tasks

1. **Code Cleanup**
   - [ ] Standardize all command constants
   - [ ] Remove duplicate code across files
   - [ ] Improve code organization in sync modules

2. **Core Improvements**
   - [ ] Refactor message handler routing
   - [ ] Standardize timestamp handling
   - [ ] Implement proper version checking

3. **Performance Optimizations**
   - [ ] Add proper caching of compressed data
   - [ ] Improve chunking system efficiency
   - [ ] Add differential sync for section updates

4. **UI Enhancements**
   - [ ] Add sync progress indicators
   - [ ] Improve error messages
   - [ ] Add detailed sync statistics display

## Testing Strategy

1. **Unit Tests**
   - Test individual message handler functions
   - Validate compression/decompression

2. **Integration Tests**
   - Test full sync flow with different group sizes
   - Test edge cases like disconnections during sync

3. **Performance Tests**
   - Measure sync times with large datasets
   - Benchmark compression efficiency

4. **User Acceptance Tests**
   - Test with real raid groups of varying sizes
   - Collect feedback on sync reliability and speed

## Conclusion

The current TWRA sync implementation has evolved from a simple system to a more complex segmented approach. While fundamentally sound, the implementation has diverged from the original plan in several areas. By standardizing the code, improving error handling, and optimizing data flow, we can create a more robust and efficient sync system that will work reliably across all raid sizes and network conditions.