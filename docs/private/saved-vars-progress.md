# SavedVariables Migration Progress

This document tracks progress of migrating from `TWRA_SavedVariables.assignments` to direct use of `TWRA_Assignments`.

## Completed Files

1. `/home/azzco/tmp/TWRA/core/DataUtility.lua` - Updated references to use `TWRA_Assignments` directly
2. `/home/azzco/tmp/TWRA/ui/OSD.lua` - Updated references to use `TWRA_Assignments.currentSectionName` directly
3. `/home/azzco/tmp/TWRA/ui/Frame.lua` - Updated code to look for section data in `TWRA_Assignments.data`
4. `/home/azzco/tmp/TWRA/TWRA.lua` - Updated section navigation and persistence code
5. `/home/azzco/tmp/TWRA/features/AutoNavigate.lua` - Updated auto-navigation feature to use `TWRA_Assignments.data` directly
6. `/home/azzco/tmp/TWRA/sync/SyncHandlers.lua` - Updated sync handlers to use `TWRA_Assignments.timestamp`
7. `/home/azzco/tmp/TWRA/core/DataProcessing.lua` - Updated player data processing to use `TWRA_Assignments.data`

## Files Remaining To Check

1. `/home/azzco/tmp/TWRA/core/Core.lua` - Need to check RebuildNavigation and related functions
2. `/home/azzco/tmp/TWRA/ui/OSDContent.lua` - Need to check OSD content generation
3. `/home/azzco/tmp/TWRA/Example.lua` - Need to update example data loading
4. `/home/azzco/tmp/TWRA/core/Base64.lua` - Needs to be checked
5. `/home/azzco/tmp/TWRA/core/Compression.lua` - May contain references in compression functions