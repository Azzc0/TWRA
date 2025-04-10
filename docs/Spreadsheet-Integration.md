# TWRA Spreadsheet Integration

This document explains how the TWRA addon integrates with Google Sheets to import raid assignments.

## Table of Contents
1. [Data Structure](#data-structure)
2. [Spreadsheet Setup](#spreadsheet-setup)
3. [Google Apps Script Functions](#google-apps-script-functions)
4. [Usage Guide](#usage-guide)
5. [Troubleshooting](#troubleshooting)

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