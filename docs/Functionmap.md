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

### TWRA:DecodeBase64(base64Str, syncTimestamp, noAnnounce)
Decodes Base64 data to its original format.

**Arguments:**
- base64Str: Base64 string to decode
- syncTimestamp: Optional timestamp for sync operations
- noAnnounce: Boolean to suppress announcements

**Used in:**
- TWRA.lua (LoadSavedAssignments)
- ui/Options.lua (import function)

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
- sourceString: Source identifier
- originalTimestamp: Optional timestamp
- noAnnounce: Boolean to suppress announcement

**Used in:**
- TWRA.lua
- ui/Options.lua (import)

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

## core/DataProcessing.lua
### TWRA:ProcessData(data)
Processes raw data into usable format.

**Arguments:**
- data: Raw data to process

**Used in:**
- sync/SyncHandlers.lua

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
Displays the current section in the UI.

**Used in:**
- Multiple places

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

## core/ItemLink.lua
### TWRA.Items:ProcessText(text)
Processes text to handle item links.

**Arguments:**
- text: Text to process

**Used in:**
- TWRA.lua (SendAnnouncementMessages)

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

## sync/Sync.lua
### TWRA:SendAddonMessage(message, target)
Sends an addon message.

**Arguments:**
- message: Message to send
- target: Optional target player

**Used in:**
- Multiple sync functions

### TWRA:BroadcastSectionChange(sectionIndex)
Broadcasts section change to group.

**Arguments:**
- sectionIndex: New section index

**Used in:**
- TWRA.lua (NavigateToSection)

### TWRA:OnGroupChanged()
Handles group composition changes.

**Used in:**
- TWRA.lua (event handler)


# Duplicate functions
Some functions are expected to have duplicates, the first instance is less complete version that gets called in init. But that is more of an exception than normal practice. Below we list all functions that have duplicate definition in the code base using the same structure as above and with an added description under the function name describing why there are duplicates.

## Resolved Duplications
The following functions were previously duplicated but have been consolidated:

### TWRA:SaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
**Consolidated to:** core/Core.lua

This function was duplicated in TWRA.lua and core/Core.lua, creating confusion about which implementation was used. The consolidated version combines cleaning functionality, example data handling, and section preservation.

### TWRA:NavigateToSection(targetSection, suppressSync)
**Consolidated to:** core/Core.lua

This navigation function was implemented in both TWRA.lua and core/Core.lua with different logic. The consolidated version includes messaging system integration for consistent behavior.

### TWRA:ToggleMainFrame()
**Consolidated to:** TWRA.lua

This function was duplicated in TWRA.lua and Bindings.lua. The consolidated version includes comprehensive debug output and view management functionality.

### TWRA:UpdateTanks()
**Consolidated to:** features/AutoTanks.lua

This function was duplicated in TWRA.lua and features/AutoTanks.lua. The consolidated version provides consistent error handling and debug output.

### TWRA:DisplayCurrentSection()
**Relocated to:** ui/OSD.lua

This function was previously implemented in TWRA.lua but has been moved to ui/OSD.lua as it primarily deals with OSD functionality. The function now serves as a centralized way to update both the OSD display and the main UI elements (menuButton, handlerText) when changing sections. The placement in ui/OSD.lua makes architectural sense since OSD is the component most frequently updated during section changes.

## Recommendations for resolving duplication issues:

1. **Consolidate implementations**: Move each function to a single, logical location based on its purpose.
2. **Use consistent cleaning**: Ensure data cleaning happens in one place with a unified approach.
3. **Follow clear patterns**: For functions like SaveAssignments, establish whether they belong in TWRA.lua or Core.lua.
4. **Documentation**: Keep this function map updated when refactoring to ensure new duplicates aren't introduced.
5. **Clear responsibilities**: Establish clear module responsibilities and avoid function overlap between files.