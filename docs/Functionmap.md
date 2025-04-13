# Outline of all the functions
All functions defined in this addon should be listed in here, let's use the structure from follow the streucture from TWRA.toc

## core/Debug.lua
### TWRA_CaptureEarlyError(message)
Global error handler to capture early errors 
(Will be replaced with our proper error handler once addon is fully loaded)

Stores early messages in TWRA.earlyErrors for later processing.

**Arguments**
 - message

**Used in:**
 - core/Debug.lua

### TWRA:InitDebug()
Initializes the debug system with default settings.

**Used in:**
 - TWRA.lua (Initialize)

### TWRA:Debug(category, message, forceOutput, isDetail)
Logs a debug message to the chat window if debugging is enabled for the given category.

**Arguments:**
- category: String category name (e.g., "ui", "data", "nav", etc.)
- message: String message to display
- forceOutput: Boolean to force display regardless of settings
- isDetail: Boolean to mark as a detail message

**Used in:**
- Throughout the addon

### TWRA:Error(message)
Logs an error message.

**Arguments:**
- message: String error message

**Used in:**
- Throughout the addon

### TWRA:ToggleDebug()
Toggles global debug mode on/off.

**Used in:**
- TWRA.lua (slash command)

### TWRA:ToggleDebugCategory(category)
Toggles a specific debug category on/off.

**Arguments:**
- category: Debug category name

**Used in:**
- TWRA.lua (slash command)

### TWRA:ListDebugCategories()
Lists all available debug categories in chat.

**Used in:**
- TWRA.lua (slash command)

## core/Constants.lua
*Contains constant definitions, no functions*

## core/Utils.lua
### TWRA:SplitString(str, delimiter)
Splits a string by delimiter.

**Arguments:**
- str: String to split
- delimiter: Character to split on

**Used in:**
- TWRA.lua (HandleSectionCommand)
- sync/SyncHandlers.lua

### TWRA:DeepCopy(orig)
Makes a deep copy of a table or value.

**Arguments:**
- orig: Value to copy

**Used in:**
- Throughout the addon

### TWRA:PrintTable(tbl, indent, maxDepth, currentDepth)
Prints a table's structure to chat for debugging.

**Arguments:**
- tbl: Table to print
- indent: String indent for formatting
- maxDepth: Max recursion depth
- currentDepth: Current recursion depth

**Used in:**
- Debug functions

### TWRA:ScheduleTimer(func, delay)
Creates a timer that calls func after delay seconds.

**Arguments:**
- func: Function to call
- delay: Time in seconds

**Used in:**
- TWRA.lua (SendAnnouncementMessages)
- ui/Frame.lua

### TWRA:CancelTimer(timer)
Cancels a scheduled timer.

**Arguments:**
- timer: Timer object to cancel

**Used in:**
- Various UI components

## core/Base64.lua
### TWRA:EncodeBase64(data)
Encodes data to Base64 format.

**Arguments:**
- data: Data to encode

**Used in:**
- ui/Options.lua (export function)
- sync/Sync.lua

### TWRA:DecodeBase64(base64Str, syncTimestamp, noAnnounce)
Decodes Base64 data to its original format.

**Arguments:**
- base64Str: Base64 string to decode
- syncTimestamp: Optional timestamp for sync operations (defaults to nil)
- noAnnounce: Boolean to suppress announcements (defaults to nil)

**Returns:**
- Decoded data table or nil if decoding failed

**Notes:**
- When syncTimestamp is provided, automatically saves the data with that timestamp
- Used for both manual imports and sync operations

**Used in:**
- TWRA.lua (LoadSavedAssignments)
- ui/Options.lua (import function)
- sync/SyncHandlers.lua (data synchronization)

### TWRA:EnsureCompleteRows(data)
Ensures that all rows in the data structure have entries for all columns, filling empty cells with empty strings.

**Arguments:**
- data: Data structure to process

**Returns:**
- Processed data structure with complete rows

**Used in:**
- TWRA:DecodeBase64() (when processing new format data)

### TWRA:TableToLuaString(tbl)
Converts a table to a Lua code string representation.

**Arguments:**
- tbl: Table to convert

**Returns:**
- String containing Lua code that recreates the table

**Used in:**
- TWRA:TableToBase64()

### TWRA:TableToBase64(tbl)
Converts a table to a Base64 encoded string (for export).

**Arguments:**
- tbl: Table to convert

**Returns:**
- Base64 encoded string representing the table

**Used in:**
- ui/Options.lua (export function)

## Example.lua
### TWRA:LoadExampleData()
Loads example raid assignment data.

**Used in:**
- TWRA.lua (LoadSavedAssignments fallback)
- ui/Options.lua (example button)

## TWRA.lua
### TWRA:NavigateHandler(delta)
Handles navigation between sections with a given delta.

**Arguments:**
- delta: Number of sections to move (+1 for next, -1 for previous)

**Used in:**
- Keybindings
- ui/Frame.lua (navigation buttons)

### TWRA:RebuildNavigation()
Rebuilds the navigation handlers based on current data.

**Used in:**
- TWRA.lua (LoadSavedAssignments, SaveAssignments)
- HandleTableAnnounce

### TWRA:UpdateUI()
Updates all UI elements based on current data.

**Used in:**
- Various UI update points

### TWRA:Initialize()
Main initialization function, called once on addon load.

**Used in:**
- TWRA.lua (end of file)

### TWRA:CleanAssignmentData(data, isTableFormat)
Cleans assignment data by removing empty sections and rows.

**Arguments:**
- data: Data to clean
- isTableFormat: Boolean indicating if data is in table format

**Used in:**
- TWRA.lua (SaveAssignments, LoadSavedAssignments, HandleTableAnnounce)

### TWRA:SaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
Saves assignment data to SavedVariables with several options.

**Arguments:**
- data: Assignment data to save
- sourceString: Source identifier (original Base64 string or special identifiers like "example_data")
- originalTimestamp: Optional timestamp (defaults to current time, or 0 for example data)
- noAnnounce: Boolean to suppress announcement (defaults to false)

**Notes:**
- Handles timestamp tracking for sync operations
- Sets timestamp to 0 for example data if not specified
- Rebuilds navigation after saving
- Broadcasts to group if not suppressed and in a group

**Used in:**
- TWRA.lua (manual imports)
- ui/Options.lua (import and example data)
- sync/SyncHandlers.lua (sync operations)

### TWRA:LoadSavedAssignments()
Loads saved assignments from SavedVariables.

**Used in:**
- TWRA.lua (Initialize)
- Bindings.lua

### TWRA:IsExampleData(data)
Checks if the given data is example data.

**Arguments:**
- data: Data to check

**Used in:**
- TWRA.lua (SaveAssignments)

### TWRA:GetPlayerStatus(name)
Gets a player's status (in group, online).

**Arguments:**
- name: Player name to check

**Used in:**
- ui/Frame.lua (player status highlighting)

### TWRA:UpdateTanks()
Updates tank assignments in oRA2.

**Used in:**
- features/AutoTanks.lua
- TWRA.lua (NavigateToSection)

### TWRA:AnnounceAssignments()
Announces the current section assignments to the appropriate channel.

**Used in:**
- ui/Frame.lua (announce button)

### TWRA:SendAnnouncementMessages(messageQueue)
Sends prepared announcement messages with throttling.

**Arguments:**
- messageQueue: Array of message objects

**Used in:**
- TWRA.lua (AnnounceAssignments)

### TWRA:GetAnnouncementChannels()
Determines which channels to use for announcements.

**Used in:**
- TWRA.lua (SendAnnouncementMessages)

### TWRA:HandleSectionCommand(args, sender)
Handles section change commands from sync.

**Arguments:**
- args: Command arguments
- sender: Command sender

**Used in:**
- sync/SyncHandlers.lua

### TWRA:HandleTableAnnounce(tableData, timestamp, sender)
Handles table announcement commands from sync.

**Arguments:**
- tableData: Table data received
- timestamp: Data timestamp
- sender: Data sender

**Used in:**
- sync/SyncHandlers.lua

### TWRA:SectionDropdownSelected(index)
Handles selection of sections in dropdown.

**Arguments:**
- index: Selected section index

**Used in:**
- ui/Frame.lua (dropdown)

### TWRA:NavigateToSection(targetSection, suppressSync)
Navigates to a specific section with options.

**Arguments:**
- targetSection: Section to navigate to (index or name)
- suppressSync: Boolean to suppress sync broadcast

**Used in:**
- TWRA.lua (NavigateHandler)
- ui/Frame.lua

### TWRA:ToggleMainFrame()
Toggles the main frame visibility.

**Used in:**
- Bindings.lua
- TWRA.lua (slash command)

### TWRA:ShowOptionsView()
Shows the options view.

**Used in:**
- ui/Frame.lua (options button)

### TWRA:ShowMainView()
Shows the main view.

**Used in:**
- ui/Frame.lua (back button)
- ui/Options.lua (after loading example)

### TWRA:GetPlayerRelevantRows(sectionData)
Gets rows relevant to the current player.

**Arguments:**
- sectionData: Section data to search

**Used in:**
- ui/OSDContent.lua

### TWRA:ClearData()
Clears all current data.

**Used in:**
- ui/Options.lua (before import)

### TWRA:ShouldShowOSD()
Helper function that determines if the On-Screen Display should be shown based on current UI state.

**Arguments:**
- None

**Returns:**
- Boolean indicating whether OSD should be shown

**Used in:**
- TWRA:DisplayCurrentSection()

## core/Core.lua
### TWRA:OnLoad()
Handler for addon load event.

**Used in:**
- core/Core.lua (frame OnLoad script)

### TWRA:OnEvent(event, arg1, arg2, ...)
Handler for various events.

**Arguments:**
- event: Event name
- arg1, arg2, ...: Event arguments

**Used in:**
- core/Core.lua (frame OnEvent script)

### TWRA:SaveCurrentSection(name)
Saves the current section to SavedVariables.

**Arguments:**
- name: Optional section name

**Used in:**
- TWRA.lua (NavigateToSection, HandleSectionCommand)

### TWRA:SendMessage(message, arg1, arg2, ...)
Sends an internal message to registered handlers.

**Arguments:**
- message: Message name
- arg1, arg2, ...: Message arguments

**Used in:**
- TWRA.lua (NavigateToSection)

### TWRA:RegisterMessageHandler(message, callback)
Registers a handler for internal messages.

**Arguments:**
- message: Message name
- callback: Handler function

**Used in:**
- ui/OSD.lua

### TWRA:BuildNavigationFromNewFormat()
Builds navigation structure from the new data format.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:SaveAssignments()
- TWRA:LoadSavedAssignments()

### TWRA:CreateMinimapButton()
Creates the minimap button for the addon.

**Arguments:**
- None

**Returns:**
- The created minimap button frame

**Used in:**
- core/Core.lua (initialization)

### TWRA:RegisterSlashCommand(command, handler)
Registers a custom slash command.

**Arguments:**
- command: Command string without the slash
- handler: Function to handle the command

**Returns:**
- None

**Used in:**
- Various modules for registering commands

### TWRA:InitializeUI()
Initializes the UI systems.

**Arguments:**
- None

**Returns:**
- None

**Used in:**
- core/Core.lua (initialization)

### TWRA:EnsureUIUtils() 
Ensures UI utilities exist and are properly initialized.

**Arguments:**
- None

**Returns:**
- Boolean indicating success

**Used in:**
- core/Core.lua (initialization)

### TWRA:DebugOptions()
Debugs the options system state.

**Arguments:**
- None

**Returns:**
- Boolean indicating success

**Used in:**
- Debug slash commands

### TWRA:ResetUI()
Performs an emergency UI reset.

**Arguments:**
- None

**Returns:**
- None

**Used in:**
- Debug commands
- Error recovery

### TWRA:OnUnload()
Handles addon unloading, saving state.

**Arguments:**
- None

**Returns:**
- None

**Used in:**
- PLAYER_LOGOUT event

## core/DataProcessing.lua
### TWRA:ProcessData(data)
Processes raw data into usable format.

**Arguments:**
- data: Raw data to process

**Used in:**
- sync/SyncHandlers.lua

### TWRA:ProcessLoadedData(data)
Processes loaded data including scanning for GUIDs.

**Arguments:**
- data: The loaded data to process

**Used in:**
- core/Core.lua (after loading data)

### TWRA:ProcessPlayerInfo()
Processes player-specific information for all sections, handling both static and dynamic information.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:UpdatePlayerInfo()
- TWRA:ProcessLoadedData()

### TWRA:ProcessStaticPlayerInfo()
Processes player information that doesn't change when group composition changes (name and class-based matches).

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:ProcessPlayerInfo()

### TWRA:ProcessDynamicPlayerInfo()
Processes player information that changes when group composition changes (group-based matches).

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:ProcessPlayerInfo()
- TWRA:RefreshPlayerInfo()

### TWRA:GetAllGroupRowsForSection(section)
Gets all rows in a section that contain any group references.

**Arguments:**
- section: Section data to analyze

**Returns:**
- Array of row indices containing group references

**Used in:**
- TWRA:ProcessDynamicPlayerInfo()

### TWRA:GetPlayerRelevantRowsForSection(section)
Identifies rows in a section that are relevant to the current player by name or class.

**Arguments:**
- section: Section data to analyze

**Returns:**
- Array of row indices relevant to the player

**Used in:**
- TWRA:ProcessStaticPlayerInfo()
- ui/OSDContent.lua

### TWRA:GetGroupRowsForSection(section)
Identifies rows in a section that are relevant to the player's current group.

**Arguments:**
- section: Section data to analyze

**Returns:**
- Array of row indices relevant to the player's group

**Used in:**
- TWRA:ProcessDynamicPlayerInfo()

### TWRA:FindTankRoleColumns(section)
Identifies columns in a section header that represent tank roles.

**Arguments:**
- section: Section data to analyze

**Returns:**
- Array of column indices representing tank roles

**Used in:**
- TWRA:ProcessStaticPlayerInfo()
- TWRA:GenerateOSDInfoForSection()

### TWRA:UpdatePlayerInfo()
Updates player information for all sections in the data.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:RefreshPlayerInfo()
- TWRA.lua (after data changes)

### TWRA:RefreshPlayerInfo()
Refreshes player information when data or group composition changes, focusing on only updating dynamic information.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA.lua (group composition changes)
- features/AutoTanks.lua (tank assignments)

### TWRA:GenerateOSDInfoForSection(section, relevantRows, isGroupAssignments)
Creates a compact representation of player's assignments for OSD display, using nested arrays for each assignment.

**Arguments:**
- section: Section data
- relevantRows: Array of row indices relevant to the player
- isGroupAssignments: Boolean indicating if these are group-based assignments

**Returns:**
- Array of formatted assignment data for OSD, with each entry being an array of role, icon, target, and tank names

**Used in:**
- TWRA:ProcessStaticPlayerInfo()
- TWRA:ProcessDynamicPlayerInfo()
- ui/OSDContent.lua

### TWRA:IsCellRelevantToPlayer(cellValue)
Helper function to determine if a cell contains information relevant to the current player.

**Arguments:**
- cellValue: Cell content to check

**Returns:**
- Boolean indicating if the cell is relevant to the player

**Used in:**
- TWRA:GenerateOSDInfoForSection()
- TWRA:GetPlayerRelevantRowsForSection()

### TWRA:IsCellContainingPlayerNameOrClass(cellValue)
Helper function to check if a cell contains the player's name or class group.

**Arguments:**
- cellValue: Cell content to check

**Returns:**
- Boolean indicating if the cell contains player's name or class

**Used in:**
- TWRA:GenerateOSDInfoForSection()

### TWRA:IsCellContainingPlayerGroup(cellValue)
Helper function to check if a cell contains the player's current group.

**Arguments:**
- cellValue: Cell content to check

**Returns:**
- Boolean indicating if the cell contains player's group

**Used in:**
- TWRA:GenerateOSDInfoForSection()

### TWRA:UpdateOSDWithPlayerInfo()
Updates the OSD with new player information.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:UpdatePlayerInfo()
- ui/OSD.lua

## core/DataUtility.lua

### TWRA:IsNewDataFormat()
Checks if the addon is using the new structured data format.

**Arguments:**
- None

**Returns:**
- Boolean indicating if new format is being used

**Used in:**
- Multiple functions that need format-specific handling
- TWRA:DisplayCurrentSection()

### TWRA:GetCurrentSectionData()
Retrieves the data for the current section in the new format.

**Arguments:**
- None

**Returns:**
- Table containing the current section data or nil if not found

**Used in:**
- TWRA:DisplayCurrentSection()
- TWRA:AnnounceAssignments()
- ui/OSD.lua

### TWRA:BuildNavigationFromNewFormat()
Builds navigation structure from the new data format.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:SaveAssignments()
- TWRA:LoadSavedAssignments()

## ui/UIUtils.lua
*Contains UI utility functions, helpers for creating frames and UI elements*

### TWRA:CreateFrame(frameType, parent, width, height)
Creates a standardized frame.

**Arguments:**
- frameType: Frame type
- parent: Parent frame
- width: Frame width
- height: Frame height

**Used in:**
- ui/Frame.lua
- ui/OSD.lua

## ui/Frame.lua
### TWRA:CreateMainFrame()
Creates the main addon window.

**Used in:**
- TWRA.lua (ToggleMainFrame)

### TWRA:RefreshAssignmentTable()
Refreshes the assignment table in the UI.

**Used in:**
- TWRA.lua (ToggleMainFrame)

### TWRA:DisplayCurrentSection()
**Status: Duplicated** (in TWRA.lua and ui/OSD.lua)

Centralized function that displays the current section in all UI components, including the main frame and OSD.

**Arguments:**
- None

**Used in:**
- Multiple places throughout the addon

**Resolution needed:** 
The function currently exists in both TWRA.lua and ui/OSD.lua with different implementations. 
The ui/OSD.lua version should be the canonical implementation as it properly coordinates updates
to both the main UI and OSD components. The TWRA.lua version should be removed or replaced with
a call to the OSD.lua version.

### TWRA:CreateOptionsInMainFrame()
Creates the options interface within the main frame.

**Used in:**
- TWRA.lua (ShowOptionsView)

### TWRA:ClearRows()
Clears all rows in the assignment table.

**Used in:**
- TWRA.lua (ShowOptionsView, ClearData)

### TWRA:ClearFooters()
Clears footer elements.

**Used in:**
- TWRA.lua (ShowOptionsView, ClearData)

### TWRA:FilterAndDisplayHandler(sectionName)
Filters and displays a specific section.

**Arguments:**
- sectionName: Section name to display

**Used in:**
- TWRA.lua (NavigateToSection)

### TWRA:ApplyRowHighlights(sectionData, displayData)
Applies row highlights based on section data to rows in displayData, handling both name/class matches and group matches.

**Arguments:**
- sectionData: The section data containing player relevance information
- displayData: The displayed data to highlight

**Returns:**
- None

**Used in:**
- TWRA:FilterAndDisplayHandler()

## ui/OSD.lua
### TWRA:InitOSD()
Initializes the On-Screen Display.

**Used in:**
- TWRA.lua (Initialize)

### TWRA:UpdateOSDContent(sectionName, sectionIndex, totalSections)
Updates OSD content with current section information.

**Arguments:**
- sectionName: Current section name
- sectionIndex: Current section index
- totalSections: Total number of sections

**Used in:**
- TWRA.lua (DisplayCurrentSection)

### TWRA:ToggleOSD()
Toggles OSD visibility.

**Used in:**
- Keybindings

### TWRA:ShouldShowOSD()
Helper function that determines if OSD should be shown.

**Used in:**
- DisplayCurrentSection

### TWRA:DisplayCurrentSection()
Centralized function that displays the current section in all UI components, including the main frame and OSD.

**Arguments:**
- None

**Used in:**
- Multiple places throughout the addon

### TWRA:UpdateOSDWithFormattedData()
Updates the OSD display with formatted data from the current section.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:UpdateOSDContent()
- TWRA:RefreshOSDContent()

### TWRA:GetOSDFrame()
Creates or retrieves the OSD frame.

**Arguments:**
- None

**Returns:**
- Frame object for the OSD

**Used in:**
- Multiple OSD functions

### TWRA:ShowOSDPermanent()
Shows the OSD permanently without auto-hiding.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:ToggleOSD()
- ui/Options.lua

### TWRA:RefreshOSDContent()
Refreshes the OSD content with the current section information.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:UpdatePlayerInfo()
- TWRA:NavigateToSection()

### TWRA:AdjustOSDFrameHeight()
Helper function to adjust the OSD frame height based on content.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:UpdateOSDWithFormattedData()

### TWRA:ShowOSD(duration)
Shows the OSD with optional auto-hide.

**Arguments:**
- duration: Optional time in seconds before auto-hiding

**Returns:**
- Boolean indicating success or failure

**Used in:**
- TWRA:DisplayCurrentSection()
- TWRA:RefreshOSDContent()

### TWRA:HideOSD()
Hides the OSD.

**Arguments:**
- None

**Returns:**
- Boolean indicating success or failure

**Used in:**
- Timer callback after auto-hide duration
- TWRA:ToggleOSD()

### TWRA:ToggleOSDEnabled(enabled)
Toggles the OSD enabled state.

**Arguments:**
- enabled: Optional explicit enabled state (true/false)

**Returns:**
- Current enabled state

**Used in:**
- ui/Options.lua (OSD options)

### TWRA:ToggleOSDOnNavigation(enabled)
Toggles showing OSD on section navigation.

**Arguments:**
- enabled: Optional explicit enabled state (true/false)

**Returns:**
- Current setting state

**Used in:**
- ui/Options.lua (OSD options)

### TWRA:UpdateOSDSettings()
Updates OSD display settings (scale, position, etc).

**Arguments:**
- None

**Returns:**
- Boolean indicating success

**Used in:**
- ui/Options.lua (after changing OSD settings)

### TWRA:ResetOSDPosition()
Resets the OSD position to the default center position.

**Arguments:**
- None

**Returns:**
- Boolean indicating success

**Used in:**
- ui/Options.lua (reset position button)

### TWRA:ShowSectionNameOverlay(sectionName, sectionIndex, totalSections)
Shows section name in a temporary overlay.

**Arguments:**
- sectionName: Name of the section
- sectionIndex: Index of the section
- totalSections: Total number of sections

**Returns:**
- Boolean indicating success

**Used in:**
- TWRA:NavigateToSection() in certain contexts

### TWRA:DebugOSDElements()
Debugs the OSD elements and their state.

**Arguments:**
- None

**Returns:**
- None

**Used in:**
- Debug commands

### TWRA:UpdateOSDFooters(footerContainer, sectionName)
Updates the footer area of the OSD with warnings and notes.

**Arguments:**
- footerContainer: Footer frame container
- sectionName: Current section name

**Returns:**
- Height of the created footer content

**Used in:**
- TWRA:UpdateOSDWithFormattedData()

## ui/OSDContent.lua
### TWRA:PrepOSD(sectionData)
Prepares OSD data from section data.

**Arguments:**
- sectionData: Section data to prepare

**Used in:**
- ui/OSD.lua

### TWRA:GetSectionData(sectionName)
Gets data for a specific section.

**Arguments:**
- sectionName: Section name to get data for

**Used in:**
- ui/OSD.lua

### TWRA:DatarowsOSD(contentContainer, sectionData)
Creates OSD data rows from section data.

**Arguments:**
- contentContainer: Container frame
- sectionData: Section data

**Used in:**
- ui/OSD.lua

### TWRA:FooterOSD(footerContainer)
Creates the OSD footer.

**Arguments:**
- footerContainer: Footer container frame

**Used in:**
- ui/OSD.lua

### TWRA:GetRoleBasedAssignments(sectionData)
Extracts player assignments with role information.

**Arguments:**
- sectionData: Section data

**Used in:**
- ui/OSDContent.lua

### TWRA:DebugFormattedData(formattedData)
Debugs formatted OSD data.

**Arguments:**
- formattedData: Data to debug

**Used in:**
- ui/OSDContent.lua

## ui/Options.lua
### TWRA:InitOptions()
Initializes options with defaults.

**Used in:**
- core/Core.lua (OnLoad)

### TWRA:ApplyInitialSettings()
Applies initial settings from saved variables.

**Used in:**
- core/Core.lua (OnLoad)

### TWRA:CreateExportImportInterface(parent)
Creates the export/import interface.

**Arguments:**
- parent: Parent frame

**Used in:**
- ui/Options.lua

### TWRA:ImportString(importString, isSync, syncTimestamp)
Imports a Base64 encoded string into the addon, supporting both manual and sync operations.

**Arguments:**
- importString: The Base64 encoded string to import
- isSync: Boolean indicating if this is a sync operation (default: false)
- syncTimestamp: Optional timestamp to use for sync operations

**Returns:**
- Boolean indicating success or failure

**Notes:**
- Generates a timestamp for manual imports
- Uses provided timestamp for sync operations
- Cleans the import box and switches to main view after successful imports
- Broadcasts data to group for manual imports if in a group

**Used in:**
- ui/Options.lua (import button handler)
- sync/SyncHandlers.lua (sync operations)

## features/AutoTanks.lua
### TWRA:InitializeTankSync()
Initializes tank synchronization.

**Used in:**
- core/Core.lua (after options init)

### TWRA:IsORA2Available()
Checks if oRA2 addon is available.

**Used in:**
- TWRA.lua (UpdateTanks)

## features/AutoNavigate.lua
### TWRA:InitializeAutoNavigate()
Initializes auto-navigation feature.

**Used in:**
- TWRA.lua (Initialize)

### TWRA:CheckTargetGUID()
Checks current target GUID for auto-navigation.

**Used in:**
- core/Debug.lua (debug command)

### TWRA:CheckSuperWoWSupport(quiet)
Checks if SuperWoW features are available.

**Arguments:**
- quiet: Boolean to suppress debug messages

**Returns:**
- Boolean indicating SuperWoW support

**Used in:**
- TWRA:InitializeAutoNavigate()

### TWRA:StartAutoNavigateScan()
Starts periodic scanning for marked targets.

**Arguments:**
- None

**Returns:**
- Boolean indicating success

**Used in:**
- TWRA:InitializeAutoNavigate()
- core/Core.lua (initialization)

### TWRA:StopAutoNavigateScan()
Stops periodic scanning for marked targets.

**Arguments:**
- None

**Returns:**
- Boolean indicating success

**Used in:**
- TWRA:ToggleAutoNavigate()

### TWRA:ToggleAutoNavigate(enable)
Toggles auto-navigation functionality.

**Arguments:**
- enable: Optional boolean to explicitly enable/disable

**Returns:**
- Current state after toggle

**Used in:**
- ui/Options.lua (checkbox)

### TWRA:ScanForMarkedTarget()
Scans for marked targets and attempts to match with GUIDs.

**Arguments:**
- None

**Returns:**
- Boolean indicating if a match was found

**Used in:**
- Timer callback during scanning

## core/ItemLink.lua
### TWRA.Items:ProcessText(text)
Processes text to handle item links.

**Arguments:**
- text: Text to process

**Used in:**
- TWRA.lua (SendAnnouncementMessages)

### TWRA.Items:Initialize()
Initializes the item processing system.

**Arguments:**
- None

**Returns:**
- None

**Used in:**
- core/Core.lua (initialization)

### TWRA.Items:FindItems(text)
Finds item links in a text string.

**Arguments:**
- text: Text to search for item links

**Returns:**
- Table of found item links

**Used in:**
- TWRA.Items:ProcessText()

### TWRA.Items:ColorizeItem(itemLink, itemName, itemQuality)
Adds color to an item name based on quality.

**Arguments:**
- itemLink: Original item link
- itemName: Item name without formatting
- itemQuality: Item quality (0-4)

**Returns:**
- Colorized item text

**Used in:**
- TWRA.Items:ProcessText()

## sync/SyncHandlers.lua
### TWRA:HandleAddonMessage(message, channel, sender)
Handles incoming addon messages.

**Arguments:**
- message: Message content
- channel: Message channel
- sender: Message sender

**Used in:**
- TWRA.lua (event handler)

### TWRA:HandleAnnounceCommand(args, sender)
Handles announcement commands.

**Arguments:**
- args: Command arguments
- sender: Command sender

**Used in:**
- sync/SyncHandlers.lua

### TWRA:HandleVersionCommand(args, sender)
Handles version check commands.

**Arguments:**
- args: Command arguments
- sender: Command sender

**Used in:**
- sync/SyncHandlers.lua

### TWRA:HandleDataRequestCommand(args, sender)
Handles data request commands.

**Arguments:**
- args: Command arguments
- sender: Command sender

**Used in:**
- sync/SyncHandlers.lua

### TWRA:HandleDataResponseCommand(args, sender)
Handles data response commands.

**Arguments:**
- args: Command arguments
- sender: Command sender

**Used in:**
- sync/SyncHandlers.lua

### TWRA:StartSync()
Begins synchronization with the group.

**Arguments:**
- None

**Returns:**
- Boolean indicating if sync was started

**Used in:**
- ui/Options.lua (sync button)

### TWRA:StopSync()
Stops synchronization with the group.

**Arguments:**
- None

**Returns:**
- None

**Used in:**
- ui/Options.lua (sync button)
- Error recovery

### TWRA:ToggleSync(enable)
Toggles sync functionality.

**Arguments:**
- enable: Optional boolean to explicitly enable/disable

**Returns:**
- Current sync state

**Used in:**
- ui/Options.lua (sync checkbox)

### TWRA:ToggleMessageMonitoring(enable)
Toggles displaying all addon messages in chat.

**Arguments:**
- enable: Optional boolean to explicitly enable/disable

**Returns:**
- Current monitoring state

**Used in:**
- Debug commands

## sync/ChunkManager.lua
### TWRA:InitChunkManager()
Initializes the chunk manager for large data sync.

**Used in:**
- core/Core.lua (after options init)

### TWRA:SendDataInChunks(data, prefix)
Sends data in manageable chunks.

**Arguments:**
- data: Data to send
- prefix: Message prefix

**Used in:**
- sync/SyncHandlers.lua

### TWRA:ChunkString(str, chunkSize)
Splits a string into manageable chunks.

**Arguments:**
- str: String to split
- chunkSize: Size of each chunk

**Returns:**
- Table of string chunks

**Used in:**
- TWRA:SendDataInChunks()

### TWRA:ReassembleChunks(chunks)
Reassembles string chunks into the original string.

**Arguments:**
- chunks: Table of string chunks

**Returns:**
- Reassembled string

**Used in:**
- TWRA:HandleDataResponseCommand()

## sync/Sync.lua
### TWRA:SendAddonMessage(message, target)
Sends an addon message.

**Arguments:**
- message: Message to send
- target: Optional target player

**Used in:**
- Multiple sync functions

### TWRA:BroadcastSectionChange(sectionIndex, timestamp)
Broadcasts section change to group.

**Arguments:**
- sectionIndex: New section index
- timestamp: Timestamp of the data for sync comparison

**Notes:**
- Formats message with section name, index and timestamp
- Only broadcasts if in a group (raid or party)
- Enhanced to include timestamp for sync comparison
- Returns true/false indicating success

**Used in:**
- core/Core.lua (NavigateToSection)

### TWRA:OnGroupChanged()
Handles group composition changes.

**Used in:**
- TWRA.lua (event handler)

# Duplicate functions
Some functions may have multiple implementations across different files. Below are functions that need attention regarding their duplication or special handling.

## Current Duplications

### TWRA:DisplayCurrentSection()
**Location:** TWRA.lua and ui/OSD.lua

This function exists in both files with different implementations. The ui/OSD.lua version is more comprehensive as it properly coordinates updates to both the main UI and OSD components.

**Recommendation:** 
- Keep the implementation in ui/OSD.lua as the canonical version
- Replace the TWRA.lua version with a call to ui/OSD.lua implementation
- Add proper hooks or event handling to ensure consistent UI updates

**Resolution Plan:**
1. Update all references to use the ui/OSD.lua implementation
2. Add an aliasing function in TWRA.lua that calls the ui/OSD.lua version
3. Add debug assertions to ensure the correct version is being called

### TWRA:IsNewDataFormat() / TWRA:GetCurrentSectionData()
**Location:** TWRA.lua and core/DataUtility.lua

These utility functions exist in both the main file and utility module. Core functionality should be in the utility module with potential wrapper functions in the main file.

**Recommendation:**
- Consolidate logic to core/DataUtility.lua
- Use wrapper functions in TWRA.lua if needed for backward compatibility
- Add documentation to clearly indicate the canonical implementation

### TWRA:BuildNavigationFromNewFormat()
**Location:** TWRA.lua and core/Core.lua

Multiple implementations of navigation building for the new data format exist.

**Recommendation:**
- Consolidate to core/Core.lua implementation
- Add proper fallback handling for legacy code paths

## Special Function Handling

### Initialization Functions
Several init functions like `InitOSD()`, `InitDebug()`, etc. have simple initial implementations that are called early, with more complete versions loaded later.

**Note:** This is an intentional design pattern for handling load order dependencies. These aren't true duplications and should be preserved.

### Event Handlers
Functions like `OnEvent()` exist in multiple files but handle different event contexts.

**Note:** These should be documented for clarity but aren't true duplications as they serve different purposes.