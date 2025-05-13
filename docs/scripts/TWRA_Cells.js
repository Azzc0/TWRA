/**
 * Generate TWRA import string from a specified cell range
 * This function updates automatically when cells in the range change
 * Always uses short keys and abbreviations for maximum efficiency
 * 
 * @param {Range} dataRange - The range containing section data (must include section names, headers, and rows)
 * @return {String} - Base64 encoded TWRA import string
 * @customfunction
 */
function GENERATE_TWRA_FROM_RANGE(dataRange) {
    var startTime = new Date().getTime();
    
    // Always use short keys and abbreviations for maximum efficiency
    var preferShortKeys = true;
    var useAbbreviations = true;
    
    // Key mappings for section data
    var sectionNameKey = "sn";
    var sectionHeaderKey = "sh";
    var sectionRowsKey = "sr";
    
    // Extract data from range
    var data = [];
    var formulas = [];
    
    try {
      // Handle case where dataRange is a string (likely formula format error)
      if (typeof dataRange === 'string') {
        return "Error: The formula was entered as text. Please make sure to start with '=' and select a valid range.";
      }
      
      // Handle case where dataRange is not a valid Range object
      if (!dataRange || typeof dataRange.getValues !== 'function') {
        // Try to get the active sheet's data range as fallback
        try {
          var sheet = SpreadsheetApp.getActiveSheet();
          if (sheet) {
            Logger.log("Invalid range provided, falling back to active sheet's data range");
            dataRange = sheet.getDataRange();
          } else {
            return "Error: Invalid range provided and couldn't fall back to active sheet.";
          }
        } catch (e) {
          return "Error: Invalid range. Please select a valid cell range.";
        }
      }
      
      // Get values and formulas from the provided range
      data = dataRange.getValues();
      formulas = dataRange.getFormulas();
    } catch (e) {
      return "Error: " + e.toString() + ". Please provide a valid range.";
    }
    
    // Initialize output
    var chunks = [];
    chunks.push("TWRA_ImportString={[\"data\"]={");
    
    // Process the data from the range
    var currentSection = null;
    var sectionIndex = 1;
    var sectionsFound = {};
    var validSectionCount = 0;
    var row = 0;
    
    while (row < data.length) {
      // Skip empty rows
      if (isRowEmpty(data[row], formulas[row])) {
        row++;
        continue;
      }
      
      // Check for section header (name in column B, row 1 of each section)
      if (data[row][0] === "" && data[row][1] !== "" && typeof data[row][1] === "string") {
        currentSection = data[row][1];
        Logger.log("Found section in range: " + currentSection + " at row " + (row + 1));
        
        // Skip empty row after section name if one exists
        if (row + 1 < data.length && isRowEmpty(data[row + 1], formulas[row + 1])) {
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
        var headerColumns = [];
        var maxCol = data[headerRow].length;
        
        // Always include the Icon column in position 1
        headerColumns.push("Icon");
        
        // Find the actual header columns with content, stopping at first empty column
        var sectionWidth = 1; // Start with icon column (column A or index 0)
        for (var col = 1; col < maxCol; col++) {
          if (data[headerRow][col] === "") {
            // Stop at the first empty column - this defines section boundary
            Logger.log("Found section boundary at column " + (col + 1) + " for section: " + currentSection);
            break;
          }
          
          var headerValue = data[headerRow][col];
          
          // Apply abbreviation to header
          headerValue = applyAbbreviation(headerValue);
          
          headerColumns.push(headerValue);
          sectionWidth++; // Increment section width
        }
        
        Logger.log("Section width for " + currentSection + ": " + sectionWidth + " columns");
        
        // Skip to first data row
        row++;
        
        // Temporary storage for section rows
        var sectionRows = [];
        
        // Continue until we find a new section or end of data
        while (row < data.length) {
          // Check if this is an empty row
          if (isRowEmpty(data[row].slice(0, sectionWidth), formulas[row].slice(0, sectionWidth))) {
            row++;
            continue;
          }
          
          // Check if this is a new section starting (only look within section width)
          var isNewSection = data[row][0] === "" && 
                            data[row][1] !== "" && 
                            typeof data[row][1] === "string" && 
                            isRowEmpty(data[row].slice(2, sectionWidth), formulas[row].slice(2, sectionWidth));
          
          if (isNewSection) {
            break; // End of this section
          }
          
          // This is a data row - process it (only within section width)
          var rowData = {};
          var hasContent = false;
          
          // Process column A (icon)
          if (data[row][0] !== "") {
            var iconValue = data[row][0];
            if (formulas[row][0] !== "") {
              var formula = formulas[row][0];
              if (formula.startsWith("=")) {
                iconValue = formula.substring(1);
              }
            }
            
            iconValue = applyAbbreviation(iconValue);
            
            rowData[1] = iconValue;
            hasContent = true;
          }
          
          // Process the rest of the columns (only within section width)
          for (var col = 1; col < sectionWidth; col++) {
            if (data[row][col] === "") {
              continue;
            }
            
            var cellValue = data[row][col];
            
            if (typeof cellValue === 'string') {
              cellValue = applyAbbreviation(cellValue);
            } else if (typeof cellValue !== 'string') {
              try {
                cellValue = String(cellValue);
              } catch (e) {
                continue;
              }
            }
            
            rowData[col + 1] = cellValue;
            hasContent = true;
          }
          
          // Only add row if it has actual content
          if (hasContent) {
            sectionRows.push(rowData);
          }
          
          row++;
        }
        
        // Only add sections that have data rows
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
        }
      } else {
        row++; // Move to next row if not a section start
      }
    }
    
    chunks.push("}}");
    
    // Join all chunks
    var luaString = chunks.join("");
    
    // Base64 encode the string
    var encoded = Utilities.base64Encode(luaString, Utilities.Charset.UTF_8);
    
    // Calculate and log processing time
    var endTime = new Date().getTime();
    var processingTime = endTime - startTime;
    Logger.log("TWRA range processing time: " + processingTime + "ms");
    Logger.log("TWRA range processing completed with " + validSectionCount + " valid sections");
    
    return encoded;
  }