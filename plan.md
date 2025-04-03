# TWRA Development Plan

## Current Status
The basic functionality of TWRA (Turtle WoW Raid Assignments) is in place, but several key systems need improvement and completion.

## Main Goals
1. Improve UI consistency and functionality
2. Fix debugging system
3. Implement reliable data synchronization
4. Complete import/export functionality
5. Document the addon for GitHub publication

## Priority Tasks

### 1. Navigation System Refactoring
- [ ] Set up unified navigation for both options and main view using UIUtils
- [ ] Ensure navigation works properly for both views (main and options)
- [ ] Fix view switching issues

### 2. Options System Improvement
- [ ] Create utility functions for common UI elements
- [ ] Set up navigation for options tabs
- [ ] Fix parent frame issues with options modules
- [ ] Ensure all options are saved correctly

### 3. Debug System Enhancement
- [x] Make debug settings persist properly
- [x] Implement proper debug levels (errors, warnings, info, details)
- [x] Add proper category filtering
- [ ] Ensure debug output is useful and organized

### 4. Core Functionality
- [ ] Move encoding/decoding functions to Base64.lua
- [ ] Refactor OSD.lua for better clarity and organization
- [ ] Set up syncing system for reliable data sharing
- [ ] Implement proper raid detection and updates

### 5. Import/Export Features
- [ ] Complete data import functionality
- [ ] Implement data export (including CSV format)
- [ ] Add example data generation
- [ ] Handle data validation properly

### 6. Documentation
- [ ] Create comprehensive README.md
- [ ] Add comments to complex code sections
- [ ] Document API for potential extensions
- [ ] Create usage guide for end users

## Code Structure Improvements
- Move constants from individual files to Constants.lua
- Organize utility functions more logically
- Improve error handling throughout the codebase
- Add additional validation for user inputs

## Future Features
- Integration with raid markers
- Auto-targeting based on assignments
- Whisper commands for assignment lookup
- Statistical tracking of performance
