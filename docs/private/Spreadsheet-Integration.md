# TWRA Spreadsheet Integration

This document explains how the TWRA addon integrates with Google Sheets to import raid assignments.

## Table of Contents
1. [Data Structure](#data-structure)
2. [Spreadsheet Setup](#spreadsheet-setup)
3. [Google Apps Script Functions](#google-apps-script-functions)
4. [Usage Guide](#usage-guide)
5. [Optimization Options](#optimization-options)
6. [Data Processing](#data-processing)
7. [Troubleshooting](#troubleshooting)

## Data Structure

TWRA uses a structured Lua table format for raid assignments with the following hierarchy:

```lua
TWRA_ImportString = {
  ["data"] = {
    [1] = {
      ["Section Name"] = "Boss or Encounter Name",
      ["Section Header"] = {
        [1] = "Icon",
        [2] = "Target",
        [3] = "Tank",
        [4] = "Healer",
        -- Additional headers as needed
      },
      ["Section Rows"] = {
        [1] = {
          [1] = "Skull",
          [2] = "Boss Name",
          [3] = "Tank Player",
          [4] = "Healer Player",
          -- Additional assignments
        },
        -- Additional rows
      }
    },
    -- Additional sections
  }
}
```

### Key Components:
- **Section Name**: Represents an encounter, boss, or logical group of assignments
- **Section Header**: Column titles defining the role or purpose of each column
- **Section Rows**: Individual assignments with icons, targets, and player assignments

## Spreadsheet Setup

### Structure
1. **Section Organization**:
   - Row 1: Empty in column A, section name in column B
   - Row 2: Empty (spacer)
   - Row 3: Header row with column descriptions
   - Row 4+: Data rows with assignments
   - Empty row separating sections

2. **Icon Handling**:
   - Icon cells use formulas like `=Skull` referencing named cells with icons
   - Use dropdown validation to ensure consistent icon names

### Example Layout

| A | B | C | D | E | F |
|---|---|---|---|---|---|
|   | **Spider Wing** |   |   |   |   |
|   |   |   |   |   |   |
| Icon | Target | Tank | Heal | Heal  | DPS |
| =Skull | Anub'Rekhan | MainTank | Heal1 | Healer2 | DPS1 |
| =Cross | Scarabs | OffTank | Heal2  |  | DPS2 |

## Google Apps Script Functions

The following functions are available in the TWRA Google Sheets integration:

### GENERATE_TWRA Function

```js
/**
 * Custom function to generate TWRA import string for specified sheets in Lua table format and encode in Base64
 * @param {...String} sheetNames - One or more sheet names to include in the import
 * @return {String} - Base64 encoded TWRA import string in Lua table format
 * @customfunction
 */
function GENERATE_TWRA() {
  // Function implementation
  // ...
}
```

#### Usage Examples:
- `=GENERATE_TWRA("Spider Wing")` - Generate import string for a single sheet
- `=GENERATE_TWRA("Spider Wing", "Plague Wing")` - Generate for multiple sheets
- `=GENERATE_TWRA("Spider Wing", true, true))` - Uses abbreviations, a more compact string will be generated

### DECODE_TWRA Function

```js
/**
 * Helper function to decode a base64 TWRA import string
 * @param {String} base64String - The base64 encoded string
 * @return {String} - Decoded import string
 * @customfunction
 */
function DECODE_TWRA(base64String) {
  // Function implementation
  // ...
}
```

#### Usage:
- `=DECODE_TWRA(A1)` - Decode the base64 string in cell A1

## Usage Guide

1. **Setup Spreadsheet**:
   - Create sheets for each raid wing or encounter group
   - Follow the section organization format described above
   - Use formulas for raid icons

2. **Generate Import String**:
   - In a cell, use `=GENERATE_TWRA("Sheet Name")` 
   - For multiple sections: `=GENERATE_TWRA("Sheet1", "Sheet2", "Sheet3")`
   - Copy the resulting Base64 string

3. **Import in Game**:
   - Open TWRA options
   - Paste the Base64 string in the import field
   - Click Import

## Optimization Options

To improve import performance, two approaches are recommended:

### 1. Compact Encoding Option

Add a compact option to GENERATE_TWRA to produce smaller Base64 strings:

```js
/**
 * Generate a compact import string with minimal whitespace
 * @param {String} sheetName - Sheet to include
 * @return {String} - Compact Base64 encoded string
 * @customfunction
 */
function GENERATE_TWRA_COMPACT(sheetName) {
  // Use the same logic as GENERATE_TWRA but omit all unnecessary whitespace
  // Example implementation in the Apps Script section
}
```

Usage: `=GENERATE_TWRA_COMPACT("Spider Wing")`

### 2. Format Updates

Update the current GENERATE_TWRA function to:
- Remove newlines and indentation (most impactful)
- Use shorter field names
- Optimize string concatenation

The compact format can reduce Base64 string size by 30-50% and significantly improve import performance.

## Data Processing

TWRA includes robust data processing to ensure data integrity and consistency across different formats and sections.

### EnsureCompleteRows Function

This function guarantees that all rows have the correct number of indices, which prevents nil reference errors when working with the data:

```lua
function TWRA:EnsureCompleteRows(data)
    -- For new data format
    if data.data and type(data.data) == "table" then
        -- Process each section
        for sectionIdx, section in pairs(data.data) do
            -- Skip if not a proper section
            if type(section) ~= "table" then goto continue end
            
            -- Process section header first to determine column count
            local maxColumns = 0
            if section["Section Header"] and type(section["Section Header"]) == "table" then
                maxColumns = table.getn(section["Section Header"])
            end
            
            -- Process section rows if they exist
            if section["Section Rows"] and type(section["Section Rows"]) == "table" then
                for rowIdx, rowData in ipairs(section["Section Rows"]) do
                    -- Handle special rows and regular rows differently
                    if rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
                        -- Special rows need exactly 2 columns
                        if not rowData[1] then rowData[1] = "" end
                        if not rowData[2] then rowData[2] = "" end
                    else
                        -- Normal rows - ensure all columns up to maxColumns exist
                        for i = 1, maxColumns do
                            if not rowData[i] then
                                rowData[i] = ""
                            end
                        end
                    end
                end
            end
            
            ::continue::
        end
    end

    -- Similar handling for legacy format
    -- ...

    return data
end
```

### Key Benefits:
1. **Error Prevention**: Prevents nil reference errors when accessing row indices
2. **Consistency**: Ensures all rows within a section have the same number of columns
3. **Special Row Handling**: Properly formats special rows like Notes, Warnings, and GUIDs
4. **Robustness**: Handles both new and legacy data formats
5. **Import Reliability**: Used during the import process to normalize data

This function is automatically applied during important data operations such as saving assignments and importing data.

## Troubleshooting

If you encounter issues with your spreadsheet integration:

1. **Import String Too Large**:
   - Split into multiple smaller imports
   - Use compact encoding option
   - Remove empty rows/columns from your spreadsheet

2. **Formatting Problems**:
   - Ensure section names are in the correct row/column
   - Check for consistent spacing between sections
   - Verify all header rows are correctly formatted

3. **Decoding Issues**:
   - Use `=DECODE_TWRA()` to check the output structure
   - Ensure no extra characters are added when copying the string
   - Try the `/run TWRA:VerifyImportString()` debug command in-game

4. **Missing Data or Nil Errors**:
   - The addon now includes robust row processing via `EnsureCompleteRows`
   - Make sure your spreadsheet columns are consistent across all rows
   - When creating custom import strings, ensure all rows have the same number of elements