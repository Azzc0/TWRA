# TWRA Development Plan

## Current Status
TWRA (Turtle WoW Raid Assignments) has basic functionality in place, but needs code cleanup and refactoring for better organization and maintainability.

## Main Goals
1. Clean up existing code
2. Refactor into a more organized structure
3. Replace debug messages with proper debug system
4. Fix UI issues, particularly with options panel
5. Complete implementation of core features

## Code Structure Refactoring

### Core Modules
- `core/Constants.lua`: Store all default data, configuration constants
- `core/Base64.lua`: Handle all encoding/decoding between spreadsheet format and addon
- `core/Debug.lua`: Custom debug system with categories, levels, and filtering
- `core/Core.lua`: Main addon initialization and lifecycle management

### Feature Modules
- `features/AutoTanks.lua`: Tank handling (oRA2 integration and future alternatives)
- `features/AutoNavigate.lua`: Auto-navigation using SuperWoW's GUID
- `features/Minimap.lua`: REMOVED - Integrated directly into Core.lua

### UI Modules
- `ui/Frame.lua`: Main frame creation and management
- `ui/OSD.lua`: On-screen display functionality
- `ui/Options.lua`: Options panel implementation
- `ui/UIUtils.lua`: Shared UI utilities and components

### Sync Modules
- `sync/Sync.lua`: Main synchronization controller
- `sync/Protocol.lua`: Message protocol implementation
- `sync/Handlers.lua`: Message handlers for different sync operations

## Priority Tasks

### 1. Code Cleanup
- [x] Remove unused files and code
- [x] Replace all `DEFAULT_CHAT_FRAME:AddMessage` with `TWRA:Debug` calls
- [x] Fix syntax errors in existing files
- [ ] Standardize function naming and parameter patterns

### 2. UI Improvements
- [x] Fix the options button functionality
- [x] Make the main frame properly movable
- [x] Improve the section navigation dropdown
- [x] Enhance the visual appeal of assignments display
- [ ] Make the footer backgrounds a bit brigther both in main frame and OSD

### 3. Module Refactoring
- [x] Move constants to `core/Constants.lua`
- [x] Implement proper debug system in `core/Debug.lua` 
- [x] Extract base64 logic to `core/Base64.lua`
- [x] Handle minimap functionality in Core.lua instead of a separate file
- [x] Organize tank handling in `features/AutoTanks.lua`
- [x] Refactor auto-navigation into `features/AutoNavigate.lua`

### 4. Debug System Enhancements
- [x] Create debug framework with categories and levels
- [x] Fix early message handling to use proper categories
- [x] Ensure we only capture our addon's errors, not other addons
- [x] Update all code to use the Debug system instead of direct chat messages

### 5. Item Linking System
- [x] Create item database with names and IDs
- [x] Implement color coding system for different item rarities
- [x] Add support for item linking in Notes/Warnings
- [ ] Enhance display of items with appropriate icons
- [ ] Implement tooltip support for linked items

### 6. Sync System Enhancement
- [ ] Begin sync testing for reliability
- [ ] Add version checking to sync protocol
- [ ] Implement proper error handling for sync failures
- [ ] Add progress indicators for sync operations

### 7. Documentation
- [ ] Add consistent comments throughout the code
- [ ] Document the public API for each module
- [ ] Create user documentation for key features
- [ ] Update TOC file with proper metadata

## Immediate Tasks (Tomorrow)
- [x] Fix OSD Warning padding
- [ ] Implement the datarows in OSD
  - [ ] Healer format:  
  - [ ] Add a fallback to heal Target if no non-healer is in the row
- [ ] Move the buttons in the main frame a few pixels up
- [ ] Fix OSD behavior (show when appropriate)
- [ ] Change OSD Test button to behave properly with some dummy data
- [ ] Verify oRA2 check
- [ ] Properly test out AutoNavigate
  - [ ] Allow both just the GUID and the full UNITEXISTS return in the appropriate cells
- [ ] Fix column update to show appropriate amount of columns in the main frame
- [ ] Force Warnings to be above Notes in main frame to make OSD and main frame more uniform

## Future Features
- Integration with raid markers
- ~~Auto-targeting based on assignments~~
- Whisper commands for assignment lookup
- Statistical tracking of performance
- Support for alternate tank management addons
