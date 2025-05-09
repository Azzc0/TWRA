-- Test file for simulating sync failures in SendAllSections
TWRA = TWRA or {}

-- Function to simulate the processing of section messages 
-- for monitoring purposes (helps understand which section messages were actually sent)
local function LogSyncMessage(prefix, message, isSkipped)
    local status = isSkipped and "|cFFFF0000SKIPPED|r" or "|cFF00FF00SENT|r"
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r " .. status .. " - " .. prefix .. ": " .. message)
end

-- Modified SendAllSections for testing sync issues
-- @param skipRandomSection - Number or true to skip a random section (if true, picks one randomly)
-- @param skipLastSection - True to skip the last section
-- @param skipStructure - True to skip the structure message
function TWRA:SendAllSectionsTest(skipRandomSection, skipLastSection, skipStructure)
    self:Debug("sync", "TEST: Sending all sections with simulated failures")
    
    -- Show test configuration in chat
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA SYNC TEST]|r Test configuration:")
    DEFAULT_CHAT_FRAME:AddMessage("  Skip Random Section: " .. tostring(skipRandomSection))
    DEFAULT_CHAT_FRAME:AddMessage("  Skip Last Section: " .. tostring(skipLastSection))
    DEFAULT_CHAT_FRAME:AddMessage("  Skip Structure: " .. tostring(skipStructure))
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("error", "Cannot send sections - not in a group")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r Not in a group")
        return false
    end
    
    -- Make sure we have compressed assignments data
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        self:Debug("error", "No compressed sections available to send")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r No compressed sections available")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_Assignments and TWRA_Assignments.timestamp then
        timestamp = TWRA_Assignments.timestamp
    end
    
    -- Count how many sections we have
    local sectionCount = 0
    local sectionIndices = {}
    for sectionIndex, _ in pairs(TWRA_CompressedAssignments.sections) do
        if type(sectionIndex) == "number" then
            sectionCount = sectionCount + 1
            table.insert(sectionIndices, sectionIndex)
        end
    end
    
    if sectionCount == 0 then
        self:Debug("error", "No sections found to send")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r No sections found")
        return false
    end
    
    self:Debug("sync", "Found " .. sectionCount .. " sections to send in test mode")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Found " .. sectionCount .. " sections to send")
    
    -- Sort section indices numerically
    table.sort(sectionIndices)
    
    -- Determine which section to skip for random skip test
    local sectionToSkip = nil
    if skipRandomSection then
        if type(skipRandomSection) == "number" then
            -- Skip a specific section if a number is provided
            sectionToSkip = skipRandomSection
        else
            -- Generate a random section index to skip
            sectionToSkip = sectionIndices[math.random(1, table.getn(sectionIndices))]
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Will skip section: " .. sectionToSkip)
    end
    
    -- Also skip the last section if requested
    local lastSectionIndex = nil
    if skipLastSection and table.getn(sectionIndices) > 0 then
        lastSectionIndex = sectionIndices[table.getn(sectionIndices)]
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Will skip last section: " .. lastSectionIndex)
    end
    
    -- Mark that we're about to send bulk sections
    self.SYNC.sendingBulkSections = true
    self.SYNC.bulkSectionCount = sectionCount
    self.SYNC.bulkSectionsSent = 0
    
    -- OPTIMIZATION: Pre-generate all messages and pre-determine which need chunking
    self:Debug("sync", "Pre-generating all section messages")
    local preparedMessages = {}
    local usesChunking = {}
    
    -- First prepare all section messages
    for i, sectionIndex in ipairs(sectionIndices) do
        local sectionData = TWRA_CompressedAssignments.sections[sectionIndex]
        
        if sectionData and sectionData ~= "" then
            -- Create bulk section message
            local message = self:CreateBulkSectionMessage(timestamp, sectionIndex, sectionData)
            
            -- Pre-determine if it needs chunking and save this info
            local messageLength = string.len(message)
            if messageLength > 2000 then
                usesChunking[i] = true
                -- For chunked messages, store the prefix and data separately
                preparedMessages[i] = {
                    prefix = self.SYNC.COMMANDS.BULK_SECTION .. ":" .. timestamp .. ":" .. sectionIndex .. ":",
                    data = sectionData,
                    sectionIndex = sectionIndex
                }
            else
                -- For normal messages, just store the complete message
                preparedMessages[i] = {
                    message = message,
                    sectionIndex = sectionIndex
                }
            end
        else
            -- Mark empty sections
            preparedMessages[i] = {
                isEmpty = true,
                sectionIndex = sectionIndex
            }
        end
    end
    
    -- REVERSED ORDER: Send sections first WITHOUT delay
    self:Debug("sync", "TEST: Sending all sections first (with test failures)")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Sending all sections first")
    
    local sentCount = 0
    local emptyCount = 0
    local errorCount = 0
    local skippedCount = 0
    
    -- Send all sections in a single batch
    for i, prepared in ipairs(preparedMessages) do
        local sectionIndex = prepared.sectionIndex
        
        -- Check if this section should be skipped for testing
        local shouldSkip = (sectionToSkip and sectionIndex == sectionToSkip) or 
                           (lastSectionIndex and sectionIndex == lastSectionIndex)
        
        -- Skip empty sections
        if prepared.isEmpty then
            emptyCount = emptyCount + 1
            LogSyncMessage("Section " .. sectionIndex, "Empty section", true)
        else
            if shouldSkip then
                -- Deliberately skip this section for testing
                skippedCount = skippedCount + 1
                LogSyncMessage("Section " .. sectionIndex, "Deliberately skipped for testing", true)
            else
                local success = false
                
                -- Handle chunked messages differently
                if usesChunking[i] then
                    if self.chunkManager then
                        success = self.chunkManager:SendChunkedMessage(prepared.data, prepared.prefix)
                        if success then
                            LogSyncMessage("Section " .. sectionIndex, "Chunked message sent", false)
                        else
                            LogSyncMessage("Section " .. sectionIndex, "Failed to send chunked message", true)
                            errorCount = errorCount + 1
                        end
                    else
                        self:Debug("error", "Chunk manager not available for large bulk section data")
                        LogSyncMessage("Section " .. sectionIndex, "Chunk manager not available", true)
                        errorCount = errorCount + 1
                    end
                else
                    -- Send regular messages directly
                    success = self:SendAddonMessage(prepared.message)
                    if success then
                        LogSyncMessage("Section " .. sectionIndex, "Regular message sent", false)
                    else
                        LogSyncMessage("Section " .. sectionIndex, "Failed to send regular message", true)
                        errorCount = errorCount + 1
                    end
                end
                
                if success then
                    sentCount = sentCount + 1
                end
            end
        end
    end
    
    -- Report section sending results
    local resultMsg = "Completed sending sections. Successfully sent " .. 
             sentCount .. " out of " .. sectionCount .. " sections. " .. 
             emptyCount .. " empty sections skipped. " .. 
             skippedCount .. " sections deliberately skipped for testing. " ..
             errorCount .. " errors."
             
    self:Debug("sync", resultMsg)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r " .. resultMsg)
    
    -- REVERSED ORDER: Now get the structure data and send it LAST
    local structureData = self:GetCompressedStructure()
    if not structureData then
        self:Debug("error", "No structure data available to send at end of bulk sync")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r No structure data available")
        return false
    end
    
    -- Check if we should skip structure for testing
    if skipStructure then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Deliberately skipping structure message for testing")
        -- Clear the bulk sending flags
        self.SYNC.sendingBulkSections = nil
        self.SYNC.bulkSectionCount = nil
        self.SYNC.bulkSectionsSent = 0
        
        -- Clear the temporary message cache to free memory
        preparedMessages = nil
        usesChunking = nil
        
        -- Final user notification
        TWRA:Debug("sync", "TEST: Bulk sync simulation completed WITHOUT structure message!", true)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Bulk sync simulation completed WITHOUT structure message!")
        
        collectgarbage("collect")
        return true
    end
    
    -- Create the bulk structure message - using the BULK_STRUCTURE command
    local structureMessage = self:CreateBulkStructureMessage(timestamp, structureData)
    
    -- Check if structure message needs chunking
    if string.len(structureMessage) > 2000 then
        self:Debug("sync", "Structure data too large, using chunk manager for final structure message")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Structure data too large, using chunk manager")
        
        if self.chunkManager then
            local prefix = self.SYNC.COMMANDS.BULK_STRUCTURE .. ":" .. timestamp .. ":"
            local success = self.chunkManager:SendChunkedMessage(structureData, prefix)
            if success then
                self:Debug("sync", "Successfully sent final structure message via chunk manager")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Successfully sent final structure message via chunk manager")
            else
                self:Debug("error", "Failed to send final structure message via chunk manager")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r Failed to send final structure message via chunk manager")
                return false
            end
        else
            self:Debug("error", "Chunk manager not available for large structure data")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r Chunk manager not available for large structure data")
            return false
        end
    else
        -- Send the structure message directly
        local success = self:SendAddonMessage(structureMessage)
        if success then
            self:Debug("sync", "Successfully sent final structure message")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Successfully sent final structure message")
        else
            self:Debug("error", "Failed to send final structure message")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r Failed to send final structure message")
            return false
        end
    end
    
    -- Clear the bulk sending flags
    self.SYNC.sendingBulkSections = nil
    self.SYNC.bulkSectionCount = nil
    self.SYNC.bulkSectionsSent = 0
    
    -- Clear the temporary message cache to free memory
    preparedMessages = nil
    usesChunking = nil
    
    -- Final user notification
    TWRA:Debug("sync", "TEST: Bulk sync simulation completed!", true)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Bulk sync simulation completed!")
    
    collectgarbage("collect")
    return true
end

-- Slash command to trigger the test function
SLASH_TWRATEST1 = "/twratest"
SlashCmdList["TWRATEST"] = function(msg)
    local args = {}
    for arg in string.gfind(msg, "([^%s]+)") do
        table.insert(args, arg)
    end
    
    local skipRandomSection = false
    local skipLastSection = false
    local skipStructure = false
    
    -- Parse arguments
    for _, arg in ipairs(args) do
        if arg == "random" or arg == "r" then
            skipRandomSection = true
        elseif arg == "last" or arg == "l" then
            skipLastSection = true
        elseif arg == "structure" or arg == "s" then
            skipStructure = true
        elseif tonumber(arg) then
            -- If it's a number, use it as the specific section to skip
            skipRandomSection = tonumber(arg)
        end
    end
    
    -- If no args, show help
    if msg == "" or msg == "help" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Usage:")
        DEFAULT_CHAT_FRAME:AddMessage("  /twratest [options]")
        DEFAULT_CHAT_FRAME:AddMessage("  Options:")
        DEFAULT_CHAT_FRAME:AddMessage("    random, r - Skip a random section")
        DEFAULT_CHAT_FRAME:AddMessage("    last, l - Skip the last section")
        DEFAULT_CHAT_FRAME:AddMessage("    structure, s - Skip the structure message")
        DEFAULT_CHAT_FRAME:AddMessage("    <number> - Skip a specific section number")
        DEFAULT_CHAT_FRAME:AddMessage("  Examples:")
        DEFAULT_CHAT_FRAME:AddMessage("    /twratest random - Skip a random section")
        DEFAULT_CHAT_FRAME:AddMessage("    /twratest 3 - Skip section 3")
        DEFAULT_CHAT_FRAME:AddMessage("    /twratest last structure - Skip last section and structure")
        return
    end
    
    -- Run the test
    TWRA:SendAllSectionsTest(skipRandomSection, skipLastSection, skipStructure)
end

-- Helper function to test missing section detection
function TWRA:TestMissingSectionDetection()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Testing missing section detection")
    
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r No compressed sections available")
        return
    end
    
    -- Count section indices
    local sectionIndices = {}
    for index, _ in pairs(TWRA_CompressedAssignments.sections) do
        if type(index) == "number" then
            table.insert(sectionIndices, index)
        end
    end
    table.sort(sectionIndices)
    
    -- Display section information
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Current sections: " .. table.concat(sectionIndices, ", "))
    
    -- Choose a random section to remove
    if table.getn(sectionIndices) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r No sections to remove")
        return
    end
    
    local randomIndex = math.random(1, table.getn(sectionIndices))
    local sectionToRemove = sectionIndices[randomIndex]
    
    -- Remove the section
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Removing section " .. sectionToRemove)
    TWRA_CompressedAssignments.sections[sectionToRemove] = nil
    
    -- Display updated section information
    local updatedIndices = {}
    for index, _ in pairs(TWRA_CompressedAssignments.sections) do
        if type(index) == "number" then
            table.insert(updatedIndices, index)
        end
    end
    table.sort(updatedIndices)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Updated sections: " .. table.concat(updatedIndices, ", "))
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Now try calling HandleBulkStructureCommand to see if it detects the missing section")
end

-- Helper function to simulate missing the structure message
function TWRA:TestMissingStructure()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Testing missing structure detection")
    
    if not TWRA_CompressedAssignments then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r |cFFFF0000ERROR:|r No compressed assignments available")
        return
    end
    
    -- Backup the structure
    local structureBackup = TWRA_CompressedAssignments.structure
    local timestamp = TWRA_CompressedAssignments.timestamp
    
    -- Remove the structure
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Removing structure data")
    TWRA_CompressedAssignments.structure = nil
    
    -- Add a bulkSyncTimestamp to simulate receiving sections without structure
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Setting bulkSyncTimestamp to " .. timestamp)
    TWRA_CompressedAssignments.bulkSyncTimestamp = timestamp
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Structure removed and bulkSyncTimestamp set")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Test the sync system to see if it requests the missing structure")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r To restore the structure, use /twrarestore")
    
    -- Add a command to restore the structure
    SLASH_TWRARESTORE1 = "/twrarestore"
    SlashCmdList["TWRARESTORE"] = function(msg)
        if structureBackup then
            TWRA_CompressedAssignments.structure = structureBackup
            TWRA_CompressedAssignments.bulkSyncTimestamp = nil
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Structure restored")
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r No structure backup available")
        end
    end
end

-- Register slash command for testing missing sections and structure
SLASH_TWRATESTMISSING1 = "/twratestmissing"
SlashCmdList["TWRATESTMISSING"] = function(msg)
    if msg == "section" or msg == "s" then
        TWRA:TestMissingSectionDetection()
    elseif msg == "structure" or msg == "str" then
        TWRA:TestMissingStructure()
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99[TWRA TEST]|r Usage:")
        DEFAULT_CHAT_FRAME:AddMessage("  /twratestmissing [option]")
        DEFAULT_CHAT_FRAME:AddMessage("  Options:")
        DEFAULT_CHAT_FRAME:AddMessage("    section, s - Remove a random section")
        DEFAULT_CHAT_FRAME:AddMessage("    structure, str - Remove the structure")
    end
end