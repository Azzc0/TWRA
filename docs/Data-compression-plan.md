# TWRA Data Compression Plan

## Overview
This document outlines the implementation plan for adding data compression to the TWRA addon's sync functionality to reduce lag when receiving data. We'll be using Huffman compression from the LibCompress library to reduce the size of synced data.

## Current Issues
- When receiving synced data, especially for larger raid compositions, users experience lag
- Large data chunks require multiple addon messages, increasing processing overhead
- Duplicated data (like source strings) consumes unnecessary memory

## Solution: Huffman Compression
We will implement Huffman compression using the LibCompress library. This will significantly reduce the data size being transmitted across the addon channel.

### Why Huffman Compression?
1. Well-suited for text data with repeating patterns (player names, class names, etc.)
2. Provided by LibCompress which is compatible with WoW Vanilla/Classic
3. Testing showed better compression ratio than other methods for our specific data

## Implementation Plan

### 1. Library Integration
- LibCompress library is already embedded in the addon
- Using TableToString + Huffman compression which showed the best results in testing

### 2. Data Workflow

#### Manual Import Flow (Base64 String)
1. User copies a Base64 string from Google Sheets into the addon
2. `ImportString()` function processes this Base64 string:
   - Base64 decoding (unchanged)
   - Parse into table format (unchanged)
   - Clean up data (unchanged)
   - Store uncompressed data in `TWRA_Assignments` (updated)
   - **Don't store original source string**
   - **Immediately compress the clean data using `CompressAssignmentsData()`**
   - **Base64Encode the compressed data**
   - Create client-specific data
   - **Store compressed version in `TWRA_Assignments.compressed`** (updated)
3. UI displays the imported data (unchanged)

#### Sync Import Flow
1. User receives a sync message from another raid member
2. `HandleDataResponseCommand()` processes this message:
   - Process received data as compressed data
   - Pass directly to `ProcessCompressedData()`
   - Decode the Base64 string (unchanged)
   - Decompress using `DecompressAssignmentsData()`
   - Save decompressed data with `SaveAssignments()`
   - **Store compressed version in `TWRA_Assignments.compressed`** (updated)
   - Create client-specific data

#### Sending Data in Sync
1. When sending assignments:
   - Always use compressed data from `GetStoredCompressedData()`
   - *All sync data is compressed by default*

### 3. Technical Changes Required

#### Data Storage Changes
- Remove source string storage completely to save memory
- Store compressed data for sync operations and reuse
- Use the new `TWRA_Assignments` table for storing assignment data (updated)

#### New Functions (Implemented)
1. `CompressAssignmentsData()` - Takes the processed assignment data and compresses it
2. `DecompressAssignmentsData()` - Takes compressed data and restores it to usable format
3. `PrepareDataForSync()` - Strips out client-specific data and prepares for compression
4. `StoreCompressedData()` - Stores compressed data for reuse
5. `GetStoredCompressedData()` - Retrieves or generates compressed data

#### Modified Functions
1. Update `ProcessReceivedData()` to handle compressed data
2. Update `SendDataResponse()` to send compressed data
3. Update data import to stop storing source strings
4. Update `SaveAssignments()` to compress data after saving
5. Update all functions to use `TWRA_Assignments` instead of `TWRA_SavedVariables.assignments` (new)

### 4. Key Implementation Benefits

1. **Memory Usage**: Don't store uncompressed source strings at all
2. **Single Compression**: Compress data once after import and store for future use
3. **Efficient Sync**: Always send compressed data for sync operations
4. **Detach Player-specific Info**: Create client-specific player info after decompression, ensuring a universal source of truth for assignments
5. **Simplified Processing**: Streamline the decompression process for sync
6. **Consistent Variable Structure**: Use the new `TWRA_Assignments` global table for all assignment data (new)

## Performance Results
- Testing showed a compression ratio of approximately 50-60% for typical raid data
- Memory usage expected to decrease by removing unneeded source strings
- Reduced lag during sync operations due to smaller data transfers
- Simplified data structure with `TWRA_Assignments` as the main container (new)

## Implementation Phases

1. **Phase 1**: ✅ Basic compression/decompression functions using TableToString + Huffman
2. **Phase 2**: ✅ Modified sync process to use compressed data
3. **Phase 3**: ✅ Updated saved variables structure to use `TWRA_Assignments` (new)
4. **Phase 4**: Testing with various raid compositions and sizes
5. **Phase 5**: Final integration and documentation (updated)

## Future Considerations
- Monitor performance and consider additional optimizations if needed
- Consider experimenting with different compression settings for special cases
- Evaluate memory impact of the new saved variables structure (new)