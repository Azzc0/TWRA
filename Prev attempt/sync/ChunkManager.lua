-- TWRA Chunk Manager - Handles splitting and reassembling large messages
TWRA = TWRA or {}
TWRA.CHUNK_MANAGER.activeTransfers = TWRA.CHUNK_MANAGER.activeTransfers or {}

-- Initialize chunk manager
function TWRA:InitializeChunkManager()
    -- Create progress display
    self.CHUNK_MANAGER.progressFrame = nil
    
    -- Initialize chunks storage
    self.CHUNK_MANAGER.activeTransfers = {}
    
    self:Debug("sync", "Chunk manager initialized")
end

-- Split data into chunks for sending
function TWRA:SplitDataIntoChunks(data, timestamp, command)
    if not data or data == "" then
        self:Debug("error", "Cannot split empty data")
        return nil
    end
    
    local dataLength = string.len(data)
    local chunks = {}
    
    -- If small enough, send as one message
    if dataLength <= self.CHUNK_MANAGER.MAX_CHUNK_SIZE then
        chunks[1] = {
            data = data,
            message = string.format("%s:%d:%s", command, timestamp, data)
        }
        self:Debug("sync", "Data fits in one chunk (" .. dataLength .. " bytes)")
        return chunks, 1
    end
    
    -- Split into chunks
    local numChunks = math.ceil(dataLength / self.CHUNK_MANAGER.MAX_CHUNK_SIZE)
    self:Debug("sync", "Splitting data into " .. numChunks .. " chunks")
    
    for i = 1, numChunks do
        local start = (i-1) * self.CHUNK_MANAGER.MAX_CHUNK_SIZE + 1
        local finish = math.min(i * self.CHUNK_MANAGER.MAX_CHUNK_SIZE, dataLength)
        local chunkData = string.sub(data, start, finish)
        
        -- Format: COMMAND:timestamp:chunkNum:totalChunks:chunkData
        local message = string.format("%s:%d:%d:%d:%s", 
                                     command,
                                     timestamp,
                                     i,
                                     numChunks,
                                     chunkData)
        
        chunks[i] = {
            data = chunkData,
            message = message,
            chunkNum = i,
            totalChunks = numChunks
        }
    end
    
    return chunks, numChunks
end

-- Send data in chunks with throttling
function TWRA:SendDataInChunks(data, timestamp, command, callback)
    local chunks, numChunks = self:SplitDataIntoChunks(data, timestamp, command)
    
    if not chunks then
        self:Debug("error", "Failed to split data into chunks")
        return false
    end
    
    -- Send first chunk immediately
    self:Debug("sync", "Sending chunk 1 of " .. numChunks)
    self:SendAddonMessage(chunks[1].message)
    
    -- Send remaining chunks with delay
    for i = 2, numChunks do
        self:ScheduleTimer(function()
            self:Debug("sync", "Sending chunk " .. i .. " of " .. numChunks)
            self:SendAddonMessage(chunks[i].message)
            
            -- If this is the last chunk and we have a callback, call it
            if i == numChunks and callback then
                callback()
            end
        end, (i-1) * self.CHUNK_MANAGER.CHUNK_DELAY)
    end
    
    -- If only one chunk and we have a callback, call it immediately
    if numChunks == 1 and callback then
        callback()
    end
    
    return true
end

-- Process incoming chunk
function TWRA:ProcessChunk(command, timestamp, chunkNum, totalChunks, chunkData, sender)
    timestamp = tonumber(timestamp)
    chunkNum = tonumber(chunkNum)
    totalChunks = tonumber(totalChunks)
    
    if not timestamp or not chunkNum or not totalChunks then
        self:Debug("error", "Invalid chunk format from " .. sender)
        return
    end
    
    -- Create a unique transfer ID using command + timestamp + sender
    local transferId = command .. "_" .. timestamp .. "_" .. sender
    
    -- Initialize transfer if it's new
    if not self.CHUNK_MANAGER.activeTransfers[transferId] then
        self.CHUNK_MANAGER.activeTransfers[transferId] = {
            command = command,
            timestamp = timestamp,
            chunks = {},
            receivedChunks = 0,
            totalChunks = totalChunks,
            sender = sender,
            startTime = GetTime()
        }
        
        -- Set up timeout for this transfer
        self:ScheduleTimer(function()
            self:CheckTransferTimeout(transferId)
        end, self.CHUNK_MANAGER.TIMEOUT)
    end
    
    local transfer = self.CHUNK_MANAGER.activeTransfers[transferId]
    
    -- Store this chunk
    transfer.chunks[chunkNum] = chunkData
    transfer.receivedChunks = transfer.receivedChunks + 1
    
    -- Calculate progress percentage
    local progress = math.floor((transfer.receivedChunks / totalChunks) * 100)
    
    -- Update progress display
    self:ShowSyncProgress(progress, sender, transfer.receivedChunks, totalChunks)
    
    -- Check if transfer is complete
    if transfer.receivedChunks == totalChunks then
        -- Combine all chunks
        local completeData = self:ReassembleChunks(transferId)
        
        if completeData then
            -- Return the completed data for processing
            self:Debug("sync", "Transfer complete: " .. transferId)
            return completeData
        end
    end
    
    -- Not complete yet
    return nil
end

-- Reassemble chunks into complete data
function TWRA:ReassembleChunks(transferId)
    local transfer = self.CHUNK_MANAGER.activeTransfers[transferId]
    if not transfer then
        self:Debug("error", "Cannot reassemble: Transfer " .. transferId .. " not found")
        return nil
    end
    
    -- Combine all chunks in correct order
    local completeData = ""
    
    for i = 1, transfer.totalChunks do
        if transfer.chunks[i] then
            completeData = completeData .. transfer.chunks[i]
        else
            self:Debug("error", "Missing chunk " .. i .. " for transfer " .. transferId)
            return nil
        end
    end
    
    self:Debug("sync", "Reassembled data, length: " .. string.len(completeData))
    
    -- Clean up this transfer
    self.CHUNK_MANAGER.activeTransfers[transferId] = nil
    
    -- Hide progress display
    self:HideSyncProgress()
    
    return completeData
end

-- Check for timed out transfers
function TWRA:CheckTransferTimeout(transferId)
    local transfer = self.CHUNK_MANAGER.activeTransfers[transferId]
    if not transfer then
        return  -- Already completed or cleaned up
    end
    
    local elapsed = GetTime() - transfer.startTime
    if elapsed >= self.CHUNK_MANAGER.TIMEOUT then
        self:Debug("error", "Transfer " .. transferId .. " timed out after " .. 
                   math.floor(elapsed) .. " seconds")
        
        -- Clean up
        self.CHUNK_MANAGER.activeTransfers[transferId] = nil
        
        -- Hide progress display and show error
        self:HideSyncProgress()
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: |cFFFF0000Data transfer from " .. transfer.sender .. 
                                      " timed out. Please try again.|r")
    end
end

-- Show sync progress in UI
function TWRA:ShowSyncProgress(progress, sender, current, total)
    -- Create progress frame if it doesn't exist
    if not self.CHUNK_MANAGER.progressFrame then
        local config = self.CHUNK_MANAGER.PROGRESS_FRAME
        
        local frame = CreateFrame("Frame", "TWRAProgressFrame", UIParent)
        frame:SetWidth(config.WIDTH)
        frame:SetHeight(config.HEIGHT)
        frame:SetPoint(config.POSITION.POINT, config.POSITION.X_OFFSET, config.POSITION.Y_OFFSET)
        frame:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
            tile = true, tileSize = 32, edgeSize = 16, 
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame:SetBackdropColor(0, 0, 0, 0.8)
        
        -- Title text
        local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        title:SetPoint("TOP", 0, -10)
        title:SetText("TWRA Sync Progress")
        frame.title = title
        
        -- Status text
        local status = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        status:SetPoint("TOP", 0, -26)
        status:SetText("Receiving data...")
        frame.status = status
        
        -- Progress bar background
        local barBg = frame:CreateTexture(nil, "ARTWORK")
        barBg:SetTexture(self.UI_LAYOUT.COLORS.PROGRESS_BG[1], 
                        self.UI_LAYOUT.COLORS.PROGRESS_BG[2],
                        self.UI_LAYOUT.COLORS.PROGRESS_BG[3],
                        self.UI_LAYOUT.COLORS.PROGRESS_BG[4])
        barBg:SetPoint("TOPLEFT", config.BAR_PADDING, -40)
        barBg:SetPoint("TOPRIGHT", -config.BAR_PADDING, -40)
        barBg:SetHeight(config.BAR_HEIGHT)
        frame.barBg = barBg
        
        -- Progress bar
        local bar = frame:CreateTexture(nil, "OVERLAY")
        bar:SetTexture(self.UI_LAYOUT.COLORS.PROGRESS_BAR[1], 
                      self.UI_LAYOUT.COLORS.PROGRESS_BAR[2],
                      self.UI_LAYOUT.COLORS.PROGRESS_BAR[3],
                      self.UI_LAYOUT.COLORS.PROGRESS_BAR[4])
        bar:SetPoint("TOPLEFT", barBg)
        bar:SetHeight(config.BAR_HEIGHT)
        bar:SetWidth(0) -- Will be set based on progress
        frame.bar = bar
        
        self.CHUNK_MANAGER.progressFrame = frame
    end
    
    local frame = self.CHUNK_MANAGER.progressFrame
    frame:Show()
    
    -- Update status text
    frame.status:SetText(string.format("Receiving from %s: %d%% (%d/%d)", 
                                      sender, progress, current, total))
    
    -- Update progress bar
    local width = (progress / 100) * (frame.barBg:GetWidth())
    frame.bar:SetWidth(width)
    
    -- Color the bar based on progress
    if progress < 25 then
        frame.bar:SetTexture(unpack(self.CHUNK_MANAGER.PROGRESS_COLORS.LOW))
    elseif progress < 75 then
        frame.bar:SetTexture(unpack(self.CHUNK_MANAGER.PROGRESS_COLORS.MEDIUM))
    else
        frame.bar:SetTexture(unpack(self.CHUNK_MANAGER.PROGRESS_COLORS.HIGH))
    end
end

-- Hide sync progress UI
function TWRA:HideSyncProgress()
    if self.CHUNK_MANAGER.progressFrame then
        self.CHUNK_MANAGER.progressFrame:Hide()
    end
end

-- Cancel all active transfers (e.g. on logout)
function TWRA:CancelAllTransfers()
    for id in pairs(self.CHUNK_MANAGER.activeTransfers) do
        self.CHUNK_MANAGER.activeTransfers[id] = nil
    end
    self:HideSyncProgress()
end

TWRA:Debug("sync", "ChunkManager module loaded")