# AI
I here I outline some restrictions and other relevant information that I might need to remind an AI of.

# Wow 1.12, Lua 5.0
This addon is in development for TurtleWoW.
This version of wow has features available in WoW 1.12 and Lua 5.0

Some missing features of note:
- ``%` - modulo operator is missing (and math.fmod). Resort to a math.floor approach instead
- `#` - use table.getn instead
- `_G` - I'm not sure if this is explicitly unavailable but let's avoid it

# Superwow
We want to add some [superwow](https://github.com/balakethelock/SuperWoW) functionality into our addon but not depend on it.
Features are outlined at: https://github.com/balakethelock/SuperWoW/wiki/Features

Notable features
- GUID accesible with UnitExists
- SUPERWOW_VERSION global variable, easy to check if superwow is enabled.

# Debugging
We're printing out things to a debug feature instead of directly to the default chat.
TWRA:Debug("category", "message", forceOutput, isDetail)

We've got these categories
- "error" for error messages
- "general" for general addon information
- "ui" for user interface updates
- "nav" for navigation events
- "osd" for on-screen display messages
- "sync" for synchronization processes
- "data" for data handling operations

forceOutput and isDetail are booleans and pretty self explanatory

# Function documentation
We're keeping a function master index in docs/Functionmap.md. It needs to be updated as we make changes