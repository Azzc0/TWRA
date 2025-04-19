/**
 * TWRA Menu System
 * 
 * This script adds a custom menu system to the TWRA Google Spreadsheet,
 * allowing users to generate import strings for specific raid content.
 * 
 * It relies on the GENERATE_TWRA function from TWRA_Spreadsheet.js
 * but doesn't modify that core file.
 */

/**
 * Creates a custom menu when the spreadsheet is opened
 */
function onOpen() {
    var ui = SpreadsheetApp.getUi();
    var menu = ui.createMenu('TWRA');
    
    // Add top-level items
    //menu.addItem('Update Strings', 'updateAllStrings');
    
    // Replace Tower of Karazhan submenu with a single item since there's only one sheet
    menu.addItem('Tower of Karazhan', 'generateTowerOfKarazhan');
    
    // Add Naxxramas submenu with nested wings
    menu.addSubMenu(ui.createMenu('Naxxramas')
      .addItem('Full Instance', 'generateNaxxFull')
      .addItem('Spider Wing', 'generateNaxxSpider')
      .addItem('Abomination Wing', 'generateNaxxAbomination')
      .addItem('Military Wing', 'generateNaxxMilitary')
      .addItem('Plague Wing', 'generateNaxxPlague')
      .addItem('Frostwyrm\'s Lair', 'generateNaxxFrostwyrm'));
    
    // Add new raid items as single menu entries
    menu.addItem('Temple of Ahn\'Qiraj', 'generateTempleAQ');
    menu.addItem('Blackwing Lair', 'generateBlackwingLair');
    menu.addItem('Molten Core', 'generateMoltenCore');
    menu.addItem('Onyxia\'s Lair', 'generateOnyxia');
    menu.addSubMenu(ui.createMenu('20m Raids')
      .addItem('Ruins of Ahn\'Qiraj', 'generateRuinsAQ')
      .addItem('Zul\'Gurub', 'generateZulGurub');
    menu.addSubMenu(ui.createMenu('10m Content')
      .addItem('Lower Karazhan Halls', 'generateLowerKarazhanHalls')
      .addItem('Upper Blackrock Spire', 'generateUpperBlackrockSpire');
    
    // Add the menu to the UI
    menu.addToUi();
}

/**
 * Updates all TWRA string outputs in the spreadsheet
 */
function updateAllStrings() {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    
    // Find cells with GENERATE_TWRA formula and force recalculation
    var sheets = ss.getSheets();
    var counterCell = null;
    
    try {
      // First, find or create our counter cell
      var found = false;
      
      // Look for cell with note "TWRA_COUNTER"
      for (var i = 0; i < sheets.length && !found; i++) {
        var sheet = sheets[i];
        var notes = sheet.getNotes();
        
        for (var row = 0; row < notes.length && !found; row++) {
          for (var col = 0; col < notes[row].length && !found; col++) {
            if (notes[row][col] === "TWRA_COUNTER") {
              counterCell = sheet.getRange(row + 1, col + 1);
              found = true;
              break;
            }
          }
        }
      }
      
      // If not found, create it in the first sheet
      if (!found) {
        var firstSheet = ss.getSheets()[0];
        // Put it in column Z row 1
        counterCell = firstSheet.getRange("Z1");
        counterCell.setNote("TWRA_COUNTER");
        counterCell.setValue(1);
        counterCell.setFontColor("#ffffff"); // White text to hide it
        counterCell.setBackground("#ffffff"); // White background
      }
      
      // Increment the counter to trigger recalculation
      var currentValue = counterCell.getValue();
      var newValue = (typeof currentValue === "number") ? currentValue + 1 : 1;
      counterCell.setValue(newValue);
      
      SpreadsheetApp.getUi().alert("All TWRA strings updated successfully!");
    } catch (e) {
      Logger.log("Error updating strings: " + e);
      SpreadsheetApp.getUi().alert("Error updating strings: " + e);
    }
  }
  
  /**
   * Generate strings for specific raid content and show in popup
   */
  function generateTowerOfKarazhan() {
    showGeneratedTWRAPopup("Tower of Karazhan", ["Tower of Karazhan"]);
  }
  
  function generateNaxxFull() {
    // Generate popup with all Naxx wings combined - fix the Frostwyrm's Lair name
    showGeneratedTWRAPopup("Naxxramas Full Instance", ["Spider Wing", "Plague Wing", "Abomination Wing", "Military Wing", "Frostwyrm's Lair"]);
  }
  
  function generateNaxxSpider() {
    showGeneratedTWRAPopup("Naxxramas Spider Wing", ["Spider Wing"]);
  }
  
  function generateNaxxAbomination() {
    showGeneratedTWRAPopup("Naxxramas Abomination Wing", ["Abomination Wing"]);
  }
  
  function generateNaxxMilitary() {
    showGeneratedTWRAPopup("Naxxramas Military Wing", ["Military Wing"]);
  }
  
  function generateNaxxPlague() {
    showGeneratedTWRAPopup("Naxxramas Plague Wing", ["Plague Wing"]);
  }
  
  function generateNaxxFrostwyrm() {
    // Fix the name here too
    showGeneratedTWRAPopup("Naxxramas Frostwyrm's Lair", ["Frostwyrm's Lair"]);
  }

  /**
   * Generate new raid string handlers
   */
  function generateTempleAQ() {
    showGeneratedTWRAPopup("Temple of Ahn'Qiraj", ["Temple of Ahn'Qiraj"]);
  }

  function generateBlackwingLair() {
    showGeneratedTWRAPopup("Blackwing Lair", ["Blackwing Lair"]);
  }

  function generateMoltenCore() {
    showGeneratedTWRAPopup("Molten Core", ["Molten Core"]);
  }

  function generateRuinsAQ() {
    showGeneratedTWRAPopup("Ruins of Ahn'Qiraj", ["Ruins of Ahn'Qiraj"]);
  }

  function generateOnyxia() {
    showGeneratedTWRAPopup("Onyxia's Lair", ["Onyxia's Lair"]);
  }

  function generateZulGurub() {
    showGeneratedTWRAPopup("Zul'Gurub", ["Zul'Gurub"]);
  }

  function generateLowerKarazhanHalls() {
    showGeneratedTWRAPopup("Lower Karazhan Halls", ["Lower Karazhan Halls"]);
  }

  function generateUpperBlackrockSpire() {
    showGeneratedTWRAPopup("Upper Blackrock Spire", ["Upper Blackrock Spire"]);
  } 
  
  /**
   * Helper function to generate TWRA string from named wings and show in popup
   * 
   * @param {String} title - Title for the popup
   * @param {Array} sheetNames - Array of sheet names to include
   */
  function showGeneratedTWRAPopup(title, sheetNames) {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var ui = SpreadsheetApp.getUi();
    
    try {
      // Call GENERATE_TWRA directly with all wings as parameters
      var args = sheetNames.slice();
      args.push(true);  // preferShortKeys = true
      args.push(true);  // useAbbreviations = true
      var result = global_GENERATE_TWRA.apply(null, args);  // Use global reference function
      
      // Create a modal dialog with the result and a copy button
      var html = HtmlService
        .createHtmlOutput(
          '<script>' +
          'function copyToClipboard() {' +
          '  var textarea = document.getElementById("twra-string");' +
          '  textarea.select();' +
          '  document.execCommand("copy");' +
          '  document.getElementById("copy-msg").style.display = "inline";' +
          '  setTimeout(function() {' +
          '    document.getElementById("copy-msg").style.display = "none";' +
          '  }, 3000);' +
          '}' +
          '</script>' +
          '<div style="font-family: Arial, sans-serif;">' +
          '  <textarea id="twra-string" style="width:100%; height:150px; margin-bottom:10px;">' + 
          result + 
          '</textarea>' +
          '  <div style="text-align:center;">' +
          '    <button onclick="copyToClipboard()" style="padding:8px 16px; background:#4285f4; color:white; border:none; border-radius:4px; cursor:pointer;">Copy to Clipboard</button>' +
          '    <span id="copy-msg" style="margin-left:10px; color:green; display:none;">Copied!</span>' +
          '  </div>' +
          '  <div style="margin-top:10px; font-size:12px; color:#666;">' +
          '    Length: ' + result.length + ' characters' +
          '  </div>' +
          '</div>'
        )
        .setWidth(600)
        .setHeight(250);
      
      // Display the dialog
      ui.showModalDialog(html, title + ' - TWRA String Generated');
      
    } catch (e) {
      ui.alert('Error', 'Failed to generate TWRA string: ' + e.toString(), ui.ButtonSet.OK);
      Logger.log('Error generating TWRA popup: ' + e);
    }
  }
  
  /**
   * Generates a TWRA string directly by calling the GENERATE_TWRA function with wing parameters
   * 
   * @param {Array} wings - Array of wing names to include in the TWRA string
   * @return {String} - Generated Base64 encoded TWRA string
   */
  function generateTWRAWithWings(wings) {
    // Find sheets that contain these wing names
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheets = ss.getSheets();
    var sheetNames = [];
    
    // First try to find exact sheet matches
    for (var i = 0; i < sheets.length; i++) {
      var sheetName = sheets[i].getName();
      // If a sheet name exactly matches one of our wings, add it
      if (wings.indexOf(sheetName) !== -1) {
        sheetNames.push(sheetName);
      }
    }
    
    // If we didn't find exact matches for all wings, try to find sheets that contain wing names
    if (sheetNames.length < wings.length) {
      // Reset and try a different approach - find any sheet that might contain our wings
      sheetNames = [];
      
      // Look for named ranges that match our wing names
      for (var i = 0; i < wings.length; i++) {
        // Try to find a named range with a standardized name format
        var rangeName = wings[i].replace(/\s+/g, '_');
        var namedRange = ss.getRangeByName(rangeName);
        
        if (!namedRange) {
          // Try with instance name prefix
          rangeName = "Naxxramas_" + rangeName;
          namedRange = ss.getRangeByName(rangeName);
          
          if (!namedRange && wings[i].includes("Frostwyrm")) {
            // Special case for Frostwyrm's Lair - try alternative spellings
            rangeName = "Naxxramas_Frostwyrm";
            namedRange = ss.getRangeByName(rangeName);
          }
        }
        
        if (namedRange) {
          var sheet = namedRange.getSheet();
          if (sheetNames.indexOf(sheet.getName()) === -1) {
            sheetNames.push(sheet.getName());
          }
        }
      }
    }
    
    // If we still didn't find any sheets, use the active sheet
    if (sheetNames.length === 0) {
      sheetNames.push(ss.getActiveSheet().getName());
      Logger.log("Couldn't find sheets matching wings, using active sheet instead");
    }
    
    // Call the GENERATE_TWRA function with the sheet names
    var args = sheetNames.slice();
    args.push(true);  // preferShortKeys = true
    args.push(true);  // useAbbreviations = true
    
    // Use Function.prototype.apply to call GENERATE_TWRA with our array of arguments
    return global_GENERATE_TWRA.apply(null, args);  // Use global reference function
  }
  
  /**
   * Helper function to generate TWRA string from a named range
   * NOTE: This is the original function that creates a cell with a formula
   * 
   * @param {String} rangeName - The name of the range to generate string from
   */
  function generateFromNamedRange(rangeName) {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var namedRange = ss.getRangeByName(rangeName);
    
    if (!namedRange) {
      SpreadsheetApp.getUi().alert("Named range '" + rangeName + "' not found. Please create it first.");
      return;
    }
    
    try {
      // Get the sheet containing the named range
      var sheet = namedRange.getSheet();
      var sheetName = sheet.getName();
      
      // Create or find a cell to put the generated string
      var outputCell = null;
      var outputRangeName = rangeName + "_Output";
      var outputRange = ss.getRangeByName(outputRangeName);
      
      if (outputRange) {
        outputCell = outputRange;
      } else {
        // If no output range exists, create one near the named range
        var rangeRow = namedRange.getRow();
        var rangeLastRow = rangeRow + namedRange.getNumRows();
        outputCell = sheet.getRange(rangeLastRow + 2, 1); // Two rows below the named range
        
        // Create a named range for the output
        ss.setNamedRange(outputRangeName, outputCell);
      }
      
      // Get counter cell for recalculation
      var counterCell = getCounterCell();
      
      // Set the formula in the output cell
      outputCell.setFormula('=GENERATE_TWRA("' + sheetName + '", ' + counterCell.getA1Notation() + ', true, true)');
      
      // Force recalculation by updating the counter
      var currentValue = counterCell.getValue();
      counterCell.setValue(currentValue + 1);
      
      // Format the output cell
      outputCell.setNote("TWRA String for " + rangeName);
      
      // Activate the cell and sheet
      sheet.setActiveRange(outputCell);
      ss.setActiveSheet(sheet);
      
      SpreadsheetApp.getUi().alert("Generated TWRA string for " + rangeName);
    } catch (e) {
      Logger.log("Error generating string from named range: " + e);
      SpreadsheetApp.getUi().alert("Error generating string from named range: " + e);
    }
  }
  
  /**
   * Helper function to get or create the counter cell
   */
  function getCounterCell() {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheets = ss.getSheets();
    var counterCell = null;
    
    // Look for cell with note "TWRA_COUNTER"
    for (var i = 0; i < sheets.length; i++) {
      var sheet = sheets[i];
      var notes = sheet.getNotes();
      
      for (var row = 0; row < notes.length; row++) {
        for (var col = 0; col < notes[row].length; col++) {
          if (notes[row][col] === "TWRA_COUNTER") {
            return sheet.getRange(row + 1, col + 1);
          }
        }
      }
    }
    
    // If not found, create it in the first sheet
    var firstSheet = ss.getSheets()[0];
    counterCell = firstSheet.getRange("Z1");
    counterCell.setNote("TWRA_COUNTER");
    counterCell.setValue(1);
    counterCell.setFontColor("#ffffff"); // White text to hide it
    counterCell.setBackground("#ffffff"); // White background
    
    return counterCell;
  }