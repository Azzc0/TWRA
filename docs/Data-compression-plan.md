# TWRA Data Compression Plan

## Overview
This document outlines the implementation plan for adding data compression to the TWRA addon's sync functionality to reduce lag when receiving data. We'll be using Huffman compression from the LibCompressVanilla library to reduce the size of synced data.

## Current Issues
- When receiving synced data, especially for larger raid compositions, users experience lag
- Large data chunks require multiple addon messages, increasing processing overhead
- Duplicated data (like source strings) consumes unnecessary memory

## Solution: Huffman Compression
We will implement Huffman compression using the LibCompressVanilla library (https://github.com/tdymel/LibCompressVanilla). This will significantly reduce the data size being transmitted across the addon channel.

### Why Huffman Compression?
1. Well-suited for text data with repeating patterns (player names, class names, etc.)
2. Provided by LibCompressVanilla which is compatible with WoW Vanilla/Classic
3. Simpler implementation than combining multiple compression algorithms

## Implementation Plan

### 1. Library Integration
- Embed the LibCompressVanilla library in the addon
- No dependency management required for users

### 2. Data Workflow
We'll maintain most of the current workflow with these key changes:

#### Import Process (unchanged)
- Continue using Base64 encoding for the initial import from Google Sheets
- Process the data normally (expand abbreviations, handle special rows, etc.)

#### Compression Step (new)
After processing imported data, add a compression step:

1. Create a table with the following fields to be compressed:
   - TWRA_SavedVariables.assignments.currentSectionName
   - TWRA_SavedVariables.assignments.isExample
   - TWRA_SavedVariables.assignments.version
   - TWRA_SavedVariables.assignments.timestamp
   - TWRA_SavedVariables.assignments.currentSection
   - TWRA_SavedVariables.assignments.data

2. Remove fields that shouldn't be synced:
   - TWRA_SavedVariables.assignments.source (don't store the source string at all)
   - TWRA_SavedVariables.assignments.data[section index].Section Player Info (client-specific)

3. Compress the table using LibCompressVanilla's Huffman encoder

#### Sync Process
- Instead of sending the raw data, send the compressed data
- When receiving, decompress before processing
- Rebuild Section Player Info on the recipient's side

### 3. Technical Changes Required

#### Data Storage
- Remove source string storage to save memory
- Store compressed data for sync operations

#### New Functions
1. `CompressAssignmentsData()` - Takes the processed assignment data and compresses it
2. `DecompressAssignmentsData()` - Takes compressed data and restores it to usable format
3. `PrepareDataForSync()` - Strips out client-specific data and prepares for compression

#### Modified Functions
1. Update `ProcessReceivedData()` to handle compressed data
2. Update `SendDataResponse()` to send compressed data
3. Update data import to stop storing source strings

### 4. Compatibility Considerations
- The change will be backward incompatible - older versions won't be able to receive data from newer versions
- Consider adding a version check in the sync protocol

## Performance Expectations
- Estimated 40-60% reduction in data size
- Significantly reduced lag when receiving synced data
- Slight increase in CPU usage during compression/decompression (but overall net improvement)

## Risks and Mitigations
- **Risk**: Compression/decompression errors
  - **Mitigation**: Robust error handling and fallback mechanisms
  
- **Risk**: Compatibility issues
  - **Mitigation**: Clear version communication and graceful degradation

## Implementation Phases
1. **Phase 1**: Embed LibCompressVanilla and create compression/decompression functions
2. **Phase 2**: Modify sync process to use compressed data
3. **Phase 3**: Testing and optimization
4. **Phase 4**: Release and monitoring

## Future Considerations
- Monitor performance and consider additional optimizations if needed
- Explore custom Huffman dictionaries optimized for raid assignment data