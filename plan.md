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
- `features/Minimap.lua`: Minimap button and related functionality

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
- [ ] Replace all `DEFAULT_CHAT_FRAME:AddMessage` with `TWRA:Debug` calls
- [ ] Fix syntax errors in existing files
- [ ] Standardize function naming and parameter patterns

### 2. UI Improvements
- [x] Fix the options button functionality
- [ ] Make the main frame properly movable and resizable
- [ ] Improve the section navigation dropdown
- [ ] Enhance the visual appeal of assignments display

### 3. Module Refactoring
- [ ] Move constants to `core/Constants.lua`
- [ ] Implement proper debug system in `core/Debug.lua` 
- [ ] Extract base64 logic to `core/Base64.lua`
- [ ] Create `features/Minimap.lua` for minimap functionality
- [ ] Organize tank handling in `features/AutoTanks.lua`
- [ ] Refactor auto-navigation into `features/AutoNavigate.lua`

### 4. Sync System Enhancement
- [ ] Improve reliability of sync operations
- [ ] Add version checking to sync protocol
- [ ] Implement proper error handling for sync failures
- [ ] Add progress indicators for sync operations

### 5. Documentation
- [ ] Add consistent comments throughout the code
- [ ] Document the public API for each module
- [ ] Create user documentation for key features
- [ ] Update TOC file with proper metadata

## Future Features
- Integration with raid markers
- Auto-targeting based on assignments
- Whisper commands for assignment lookup
- Statistical tracking of performance
- Support for alternate tank management addons
