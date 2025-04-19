/**
 * TWRA Google Spreadsheet Integration Script
 * 
 * This script provides functions to generate Base64-encoded data for the 
 * TWRA (Turtle WoW Raid Assignments) addon.
 */

// Define abbreviation mappings for more compact strings
var ABBREVIATION_MAPPINGS = {
  // Icon column abbreviations
  "Star": "1",
  "Circle": "2",
  "Diamond": "3",
  "Triangle": "4",
  "Moon": "5",
  "Square": "6",
  "Cross": "7",
  "Skull": "8",
  "GUID": "9",
  "Warning": "!",
  "Note": "?",
  
  // Class and group abbreviations
  "Druids": "D",
  "Hunters": "H",
  "Mages": "M",
  "Paladins": "Pa",
  "Priests": "Pr",
  "Rogues": "R",
  "Shamans": "S",
  "Warriors": "W",
  "Warlocks": "Wl",
  "Group": "G",
  "Groups": "Gr",
  "Group 1": "G1",
  "Group 2": "G2",
  "Group 3": "G3",
  "Group 4": "G4",
  "Group 5": "G5",
  "Group 6": "G6",
  "Group 7": "G7",
  "Group 8": "G8",
  
  // Header abbreviations
  "Tank": "T",
  "Heal": "H",
  "Healer": "He",
  "Interrupt": "I",
  "Banish": "B",
  "Decurse": "Dc",
  "Depoison": "Dp",
  "Dispell": "Ds",
  "Dedisease": "Dd",
  "Ranged Interrupt": "Ri",
  "Pull": "P",
  "Kite": "K"
};

// Define pattern-based replacements for more flexible abbreviation matching
var PATTERN_REPLACEMENTS = [
  // Match "Group X" pattern where X is any number not explicitly defined above
  { pattern: /^Group (\d+)$/, replacement: function(match, groupNum) { return "G" + groupNum; } }
];

// Reverse mapping to decode abbreviations (used for display/debugging)
var REVERSE_ABBREVIATION = {};
for (var key in ABBREVIATION_MAPPINGS) {
  REVERSE_ABBREVIATION[ABBREVIATION_MAPPINGS[key]] = key;
}

/**
 * Enhanced implementation with abbreviation mappings and optimized empty value handling
 * 
 * @param {...String} sheetNames - Sheet names to include in the export
 * @param {Boolean} preferShortKeys - Optional. If true, uses shorter key names for even more compact code (default: false)
 * @param {Boolean} useAbbreviations - Optional. If true, uses abbreviations for icons, classes, and headers (default: true)
 * @return {String} - Base64 encoded import string
 * @customfunction
 */
function GENERATE_TWRA() {
  var startTime = new Date().getTime();
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var preferShortKeys = false;
  var useAbbreviations = true;
  
  // Check if last arguments are boolean flags
  var sheetArgs = Array.prototype.slice.call(arguments);
  
  // Handle optional parameters
  if (arguments.length > 0 && typeof arguments[arguments.length-1] === "boolean") {
    if (arguments.length > 1 && typeof arguments[arguments.length-2] === "boolean") {
      // Both flags are present
      preferShortKeys = arguments[arguments.length-2];
      useAbbreviations = arguments[arguments.length-1];
      sheetArgs = Array.prototype.slice.call(arguments, 0, arguments.length-2);
    } else {
      // Only one flag (assume it's preferShortKeys for backward compatibility)
      preferShortKeys = arguments[arguments.length-1];
      sheetArgs = Array.prototype.slice.call(arguments, 0, arguments.length-1);
    }
  }
  
  // Key mappings for section data
  var sectionNameKey = preferShortKeys ? "sn" : "Section Name";
  var sectionHeaderKey = preferShortKeys ? "sh" : "Section Header";
  var sectionRowsKey = preferShortKeys ? "sr" : "Section Rows";
  
  // Pre-allocate string buffer with estimated size
  var chunks = [];
  chunks.push("TWRA_ImportString={[\"data\"]={");
  
  // We no longer include ICON_INDICES or ABBREVIATION_MAPPINGS in the string - both sides have static mappings
  
  // Process each sheet name passed as an argument
  var sectionIndex = 1;
  var sectionsFound = {};
  var validSectionCount = 0;
  
  for (var i = 0; i < sheetArgs.length; i++) {
    var sheetName = sheetArgs[i];
    var sheet = ss.getSheetByName(sheetName);
    
    if (!sheet) {
      Logger.log("Sheet not found: " + sheetName);
      continue; // Skip if sheet not found
    }
    
    // Get sheet data - optimized to only get the used range
    var usedRange = sheet.getDataRange();
    var data = usedRange.getValues();
    var formulas = usedRange.getFormulas(); // Get the actual formulas in cells
    
    // Track sections parsed in this sheet
    var sectionsInSheet = [];
    
    // Track consecutive empty rows to detect end of sheet
    var emptyRowCount = 0;
    
    // Process sections in the sheet
    var row = 0;
    while (row < data.length) {
      // Check if this is an empty row
      if (isRowEmpty(data[row])) {
        emptyRowCount++;
        
        // If we have two consecutive empty rows, we've reached the end of the sheet
        if (emptyRowCount >= 2) {
          Logger.log("Detected end of sheet after two consecutive empty rows at row " + (row + 1));
          break;
        }
        
        row++;
        continue;
      }
      
      // Not an empty row, reset empty row counter
      emptyRowCount = 0;
      
      // Check for section header (name in column B, row 1 of each section)
      if (data[row][0] === "" && data[row][1] !== "" && typeof data[row][1] === "string") {
        var currentSection = data[row][1];
        sectionsInSheet.push(currentSection);
        
        Logger.log("Found section: " + currentSection + " at row " + (row + 1));
        
        // Skip empty row after section name if one exists
        if (row + 1 < data.length && isRowEmpty(data[row + 1])) {
          row++;
        }
        
        // Move to expected header row
        row++;
        
        // Verify we have enough rows for header
        if (row >= data.length) {
          continue;
        }
        
        // Process header row
        var headerRow = row;
        
        // Find the headers, starting from column 1 (B in spreadsheet)
        var headerColumns = [];
        var maxCol = data[headerRow].length;
        
        // Always include the Icon column in position 1
        headerColumns.push("Icon");
        
        // Find the actual header columns with content
        for (var col = 1; col < maxCol; col++) {
          if (data[headerRow][col] !== "") {
            var headerValue = data[headerRow][col];
            
            // Apply abbreviation to header if available and enabled
            if (useAbbreviations) {
              headerValue = applyAbbreviation(headerValue);
              Logger.log("Abbreviated header: " + data[headerRow][col] + " -> " + headerValue);
            }
            
            headerColumns.push(headerValue);
          }
        }
        
        // Skip to first data row
        row++;
        
        // Temporary storage for section rows
        var sectionRows = [];
        var rowIndex = 1;
        
        // Continue until we find a new section or end of data
        while (row < data.length) {
          // Check if this is an empty row (all columns are empty)
          var currentRowEmpty = true;
          
          // Check all columns up to the maximum used in headers
          for (var col = 0; col < headerColumns.length + 1; col++) {  // +1 to include column A (Icon)
            if (col < data[row].length && data[row][col] !== "") {
              currentRowEmpty = false;
              break;
            }
          }
          
          if (currentRowEmpty) {
            Logger.log("Found empty row at " + (row + 1) + " - end of section " + currentSection);
            break;
          }
          
          // Check if this is a new section starting
          var isNewSection = data[row][0] === "" && 
                             data[row][1] !== "" && 
                             typeof data[row][1] === "string" && 
                             col >= 2 && 
                             isRowEmpty(data[row].slice(2));  // Check if columns C onwards are empty
          
          if (isNewSection) {
            Logger.log("Found new section at row " + (row + 1) + " while processing " + currentSection);
            break; // End of this section
          }
          
          // This is a data row - process it
          var rowData = {};
          var hasContent = false;
          
          // Process column A (icon) - index 0 in data array, index 1 in output
          if (data[row][0] !== "") {
            // Check if this cell has a formula (like =Skull) and extract the icon name
            var iconValue = data[row][0];
            if (formulas[row][0] !== "") {
              // Formula cell - extract the actual icon name
              var formula = formulas[row][0];
              if (formula.startsWith("=")) {
                // Extract the icon name from the formula (remove the = sign)
                iconValue = formula.substring(1);
              }
            }
            
            // Apply abbreviation to icon if available and enabled
            if (useAbbreviations) {
              iconValue = applyAbbreviation(iconValue);
              Logger.log("Abbreviated icon: " + data[row][0] + " -> " + iconValue);
            }
            
            rowData[1] = iconValue;
            hasContent = true;
          }
          
          // Process the rest of the columns based on header columns
          for (var col = 1; col < maxCol; col++) {
            // Skip empty cells to reduce export string size
            if (data[row][col] === "") {
              continue;
            }
              
            // Column B in spreadsheet is index 1 in data array, becomes index 2 in output
            var cellValue = data[row][col];
              
            // Apply abbreviation to cell value if available and enabled
            if (useAbbreviations) {
              cellValue = applyAbbreviation(cellValue);
              Logger.log("Abbreviated value: " + data[row][col] + " -> " + cellValue);
            }
              
            rowData[col + 1] = cellValue;
            hasContent = true;
          }
          
          // Only add row if it has actual content in any column
          if (hasContent) {
            sectionRows.push(rowData);
            rowIndex++;
          }
          
          row++;
        }
        
        // Only add sections that actually have data rows
        if (sectionRows.length > 0) {
          // Prepare the section data
          chunks.push("[" + sectionIndex + "]={");
          chunks.push("[\"" + sectionNameKey + "\"]=\"" + escapeString(currentSection) + "\",");
          
          // Process header row
          chunks.push("[\"" + sectionHeaderKey + "\"]={");
          for (var h = 0; h < headerColumns.length; h++) {
            chunks.push("[" + (h + 1) + "]=\"" + escapeString(headerColumns[h]) + "\",");
          }
          chunks.push("},");
          
          // Process data rows
          chunks.push("[\"" + sectionRowsKey + "\"]={");
          
          for (var r = 0; r < sectionRows.length; r++) {
            chunks.push("[" + (r + 1) + "]={");
            
            // Add all non-empty data in the row
            var columnKeys = Object.keys(sectionRows[r]);
            for (var k = 0; k < columnKeys.length; k++) {
              var colIndex = columnKeys[k];
              var value = sectionRows[r][colIndex];
              chunks.push("[" + colIndex + "]=\"" + escapeString(value) + "\",");
            }
            
            chunks.push("},");
          }
          
          chunks.push("},");
          chunks.push("},");
          
          sectionsFound[currentSection] = sectionIndex;
          sectionIndex++;
          validSectionCount++;
        } else {
          Logger.log("Skipping empty section: " + currentSection);
        }
        
        // Continue processing (row will be at the next section or empty row)
      } else {
        row++; // Move to next row if not a section start
      }
    }
    
    Logger.log("Found " + validSectionCount + " valid sections in sheet: " + sheetName);
  }
  
  chunks.push("}}");
  
  // Join all chunks
  var luaString = chunks.join("");
  
  // Base64 encode the string with explicit UTF-8 encoding
  var encoded = Utilities.base64Encode(luaString, Utilities.Charset.UTF_8);
  
  // Calculate and log processing time
  var endTime = new Date().getTime();
  var processingTime = endTime - startTime;
  Logger.log("TWRA processing time: " + processingTime + "ms");
  Logger.log("TWRA completed with " + validSectionCount + " valid sections");
  
  var sectionNames = Object.keys(sectionsFound).sort(function(a, b) {
    return sectionsFound[a] - sectionsFound[b];
  });
  Logger.log("Sections processed: " + sectionNames.join(", "));
  
  return encoded;
}

/**
 * Helper function to apply abbreviations with both exact matches and pattern matching
 */
function applyAbbreviation(value) {
  // First check for exact match in abbreviation mapping
  if (ABBREVIATION_MAPPINGS[value]) {
    return ABBREVIATION_MAPPINGS[value];
  }
  
  // If no exact match, try pattern matching
  for (var i = 0; i < PATTERN_REPLACEMENTS.length; i++) {
    var pattern = PATTERN_REPLACEMENTS[i].pattern;
    var match = value.match(pattern);
    
    if (match) {
      return PATTERN_REPLACEMENTS[i].replacement.apply(null, match);
    }
  }
  
  // If no match found, return original value
  return value;
}

/**
 * Helper function to check if a row is empty
 */
function isRowEmpty(rowData) {
  for (var i = 0; i < rowData.length; i++) {
    if (rowData[i] !== "") {
      return false;
    }
  }
  return true;
}

/**
 * Helper function to escape special characters in strings
 */
function escapeString(str) {
  if (str === null || str === undefined) {
    return "";
  }
  
  // Convert to string if not already
  str = String(str);
  
  return str
    .replace(/\\/g, "\\\\")
    .replace(/"/g, '\\"')
    .replace(/\n/g, "\\n")
    .replace(/\r/g, "\\r")
    .replace(/\t/g, "\\t");
}

// Maintain backward compatibility
function GENERATE_TWRA_COMPACT_V2() {
  return GENERATE_TWRA.apply(null, arguments);
}

/**
 * Helper function to decode a TWRA base64 string
 * 
 * @param {String} base64String - Base64 encoded string to decode
 * @return {String} - Decoded Lua table string
 * @customfunction
 */
function DECODE_TWRA(base64String) {
  try {
    return Utilities.newBlob(Utilities.base64Decode(base64String)).getDataAsString();
  } catch(e) {
    return "Error decoding: " + e.toString();
  }
}

/**
 * Comparison function to show size difference between normal and compact formats
 * 
 * @param {String} sheetName - Sheet to compare
 * @return {Array} - [Normal size, Compact size, % reduction]
 * @customfunction
 */
function COMPARE_TWRA_SIZE(sheetName) {
  var normalString = GENERATE_TWRA(sheetName, false, false);
  var compactString = GENERATE_TWRA(sheetName, true, true);
  
  var normalSize = normalString.length;
  var compactSize = compactString.length;
  var reduction = ((normalSize - compactSize) / normalSize * 100).toFixed(2);
  
  return [normalSize, compactSize, reduction + "%"];
}

/**
 * Generate an abbreviation report for the spreadsheet
 * 
 * @param {String} sheetName - Sheet to analyze
 * @return {Array} - Abbreviation report
 * @customfunction
 */
function ABBREVIATION_REPORT() {
  var report = [["Original", "Abbreviation"]];
  
  // Sort by longest strings first (for greatest space savings)
  var items = Object.keys(ABBREVIATION_MAPPINGS).sort(function(a, b) {
    return b.length - a.length;
  });
  
  for (var i = 0; i < items.length; i++) {
    var original = items[i];
    var abbreviated = ABBREVIATION_MAPPINGS[original];
    report.push([original, abbreviated]);
  }
  
  // Add pattern-based replacements
  report.push(["", ""]);
  report.push(["Pattern-Based Replacements", ""]);
  
  for (var i = 0; i < PATTERN_REPLACEMENTS.length; i++) {
    var pattern = PATTERN_REPLACEMENTS[i].pattern.toString();
    report.push([pattern, "Dynamic replacement"]);
  }
  
  return report;
}

/**
 * Test abbreviation functionality
 * 
 * @param {String} input - String to abbreviate
 * @return {String} - Abbreviated string or original if no abbreviation exists
 * @customfunction
 */
function TEST_ABBREVIATION(input) {
  var abbreviated = applyAbbreviation(input);
  
  if (input !== abbreviated) {
    return input + " → " + abbreviated;
  } else {
    return input + " (no abbreviation)";
  }
}

/**
 * Global reference to ensure GENERATE_TWRA is accessible across all script files
 * This function helps expose the core TWRA generator function to other files in Apps Script
 *
 * @param {...*} args - All arguments passed to GENERATE_TWRA
 * @return {String} - Base64 encoded TWRA string
 */
function global_GENERATE_TWRA() {
  return GENERATE_TWRA.apply(null, arguments);
}