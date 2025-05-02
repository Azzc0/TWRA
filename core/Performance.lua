-- TWRA Performance Monitoring File
-- This file provides performance monitoring tools to track and identify bottlenecks

TWRA = TWRA or {}
TWRA.Performance = TWRA.Performance or {}

-- Performance monitoring settings
TWRA.Performance.enabled = false
TWRA.Performance.threshold = 0.005 -- Default 5ms threshold for slow operations
TWRA.Performance.samples = {} -- Store performance samples
TWRA.Performance.stats = {} -- Store performance statistics
TWRA.Performance.maxSamples = 1000 -- Maximum number of samples to keep

-- Initialize performance monitoring
function TWRA:InitializePerformance()
    self:Debug("perf", "Initializing performance monitoring system")
    
    -- Create our stats table
    self.Performance.stats = {
        functionCalls = {},  -- Track function call counts and times
        pcallErrors = {},    -- Track pcall errors by function name
        eventStats = {},     -- Track event processing times
        slowestFunctions = {},  -- Track slowest function calls
        totalTracked = 0     -- Total number of tracked function calls
    }
    
    -- Register slash command handler
    self.HandlePerfCommand = function(self, args)
        if not args or table.getn(args) == 0 then
            -- Show help
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Performance Monitoring|r:")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra perf on - Enable performance monitoring")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra perf off - Disable performance monitoring")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra perf status - Show current status")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra perf report - Show performance report")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra perf clear - Clear performance data")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra perf threshold X - Set slow function threshold to X ms")
            return
        end
        
        local cmd = args[1]
        
        if cmd == "on" then
            self.Performance.enabled = true
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Performance monitoring enabled")
            -- Hook critical functions when enabling
            self:HookCriticalFunctions()
        elseif cmd == "off" then
            self.Performance.enabled = false
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Performance monitoring disabled")
        elseif cmd == "status" then
            local status = self.Performance.enabled and "enabled" or "disabled"
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Performance monitoring is " .. status)
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Slow function threshold: " .. (self.Performance.threshold * 1000) .. " ms")
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Tracked " .. self.Performance.stats.totalTracked .. " function calls")
        elseif cmd == "report" then
            self:GeneratePerformanceReport()
        elseif cmd == "clear" then
            self:ClearPerformanceData()
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Performance data cleared")
        elseif cmd == "threshold" and args[2] and tonumber(args[2]) then
            -- Convert from ms to seconds
            self.Performance.threshold = tonumber(args[2]) / 1000
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Slow function threshold set to " .. args[2] .. " ms")
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Unknown performance command: " .. cmd)
        end
    end
    
    -- Create a frame to monitor framerate
    self.Performance.frameRateFrame = CreateFrame("Frame")
    self.Performance.frameRateFrame:SetScript("OnUpdate", function()
        if not TWRA.Performance.enabled then return end
        
        -- Track frame rate once per second
        TWRA.Performance.frameTime = TWRA.Performance.frameTime or GetTime()
        TWRA.Performance.frameCount = (TWRA.Performance.frameCount or 0) + 1
        
        local now = GetTime()
        if now - TWRA.Performance.frameTime >= 1 then
            local fps = TWRA.Performance.frameCount / (now - TWRA.Performance.frameTime)
            TWRA.Performance.lastFPS = fps
            
            -- If FPS drops below 15, start more aggressive monitoring
            if fps < 15 and not TWRA.Performance.aggressiveMonitoring then
                TWRA:Debug("perf", "Low FPS detected (" .. string.format("%.1f", fps) .. "), enabling aggressive monitoring")
                TWRA.Performance.aggressiveMonitoring = true
                -- Hook additional functions or lower thresholds here
            elseif fps >= 20 and TWRA.Performance.aggressiveMonitoring then
                TWRA:Debug("perf", "FPS recovered to " .. string.format("%.1f", fps) .. ", disabling aggressive monitoring")
                TWRA.Performance.aggressiveMonitoring = false
            end
            
            -- Store FPS sample
            if table.getn(TWRA.Performance.samples) >= TWRA.Performance.maxSamples then
                table.remove(TWRA.Performance.samples, 1)
            end
            table.insert(TWRA.Performance.samples, {time = now, fps = fps})
            
            -- Reset counters
            TWRA.Performance.frameTime = now
            TWRA.Performance.frameCount = 0
        end
    end)
    
    -- Success
    return true
end

-- Track execution time of a function (avoids ellipsis)
function TWRA:TrackPerformance(funcName, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    if not self.Performance.enabled then
        if arg8 then return func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
        elseif arg7 then return func(arg1, arg2, arg3, arg4, arg5, arg6, arg7)
        elseif arg6 then return func(arg1, arg2, arg3, arg4, arg5, arg6)
        elseif arg5 then return func(arg1, arg2, arg3, arg4, arg5)
        elseif arg4 then return func(arg1, arg2, arg3, arg4)
        elseif arg3 then return func(arg1, arg2, arg3)
        elseif arg2 then return func(arg1, arg2)
        elseif arg1 then return func(arg1)
        else return func() end
    end
    
    local startTime = GetTime()
    local result = {}
    
    -- Call the function with the correct number of arguments
    if arg8 then 
        result = {func(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)}
    elseif arg7 then 
        result = {func(arg1, arg2, arg3, arg4, arg5, arg6, arg7)}
    elseif arg6 then 
        result = {func(arg1, arg2, arg3, arg4, arg5, arg6)}
    elseif arg5 then 
        result = {func(arg1, arg2, arg3, arg4, arg5)}
    elseif arg4 then 
        result = {func(arg1, arg2, arg3, arg4)}
    elseif arg3 then 
        result = {func(arg1, arg2, arg3)}
    elseif arg2 then 
        result = {func(arg1, arg2)}
    elseif arg1 then 
        result = {func(arg1)}
    else 
        result = {func()}
    end
    
    local endTime = GetTime()
    local duration = endTime - startTime
    
    -- Track function performance
    local stats = self.Performance.stats.functionCalls[funcName] or {
        calls = 0,
        totalTime = 0,
        maxTime = 0,
        lastTime = 0
    }
    
    stats.calls = stats.calls + 1
    stats.totalTime = stats.totalTime + duration
    stats.lastTime = duration
    if duration > stats.maxTime then
        stats.maxTime = duration
    end
    
    self.Performance.stats.functionCalls[funcName] = stats
    self.Performance.stats.totalTracked = self.Performance.stats.totalTracked + 1
    
    -- Log slow functions
    if duration >= self.Performance.threshold then
        self:Debug("perf", "Slow function: " .. funcName .. " took " .. string.format("%.3f", duration * 1000) .. " ms")
        
        -- Store in slowest functions list
        local slowList = self.Performance.stats.slowestFunctions
        table.insert(slowList, {
            name = funcName,
            time = duration,
            timestamp = GetTime()
        })
        
        -- Keep list sorted by time (descending)
        table.sort(slowList, function(a, b) return a.time > b.time end)
        
        -- Trim list to 50 items
        while table.getn(slowList) > 50 do
            table.remove(slowList)
        end
    end
    
    -- Modified to be compatible with Lua 5.0
    if table.getn(result) == 0 then
        return
    elseif table.getn(result) == 1 then
        return result[1]
    elseif table.getn(result) == 2 then
        return result[1], result[2]
    elseif table.getn(result) == 3 then
        return result[1], result[2], result[3]
    elseif table.getn(result) == 4 then
        return result[1], result[2], result[3], result[4]
    elseif table.getn(result) == 5 then
        return result[1], result[2], result[3], result[4], result[5]
    else
        -- For more return values, add more cases if needed
        return result[1], result[2], result[3], result[4], result[5], result[6]
    end
end

-- Wrap pcall with performance tracking (avoids ellipsis)
function TWRA:SafeCall(funcName, func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    if not self.Performance.enabled then
        if arg8 then return pcall(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
        elseif arg7 then return pcall(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
        elseif arg6 then return pcall(func, arg1, arg2, arg3, arg4, arg5, arg6)
        elseif arg5 then return pcall(func, arg1, arg2, arg3, arg4, arg5)
        elseif arg4 then return pcall(func, arg1, arg2, arg3, arg4)
        elseif arg3 then return pcall(func, arg1, arg2, arg3)
        elseif arg2 then return pcall(func, arg1, arg2)
        elseif arg1 then return pcall(func, arg1)
        else return pcall(func) end
    end
    
    local startTime = GetTime()
    local success, result
    
    -- Call pcall with the correct number of arguments
    if arg8 then 
        success, result = pcall(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8)
    elseif arg7 then 
        success, result = pcall(func, arg1, arg2, arg3, arg4, arg5, arg6, arg7)
    elseif arg6 then 
        success, result = pcall(func, arg1, arg2, arg3, arg4, arg5, arg6)
    elseif arg5 then 
        success, result = pcall(func, arg1, arg2, arg3, arg4, arg5)
    elseif arg4 then 
        success, result = pcall(func, arg1, arg2, arg3, arg4)
    elseif arg3 then 
        success, result = pcall(func, arg1, arg2, arg3)
    elseif arg2 then 
        success, result = pcall(func, arg1, arg2)
    elseif arg1 then 
        success, result = pcall(func, arg1)
    else 
        success, result = pcall(func)
    end
    
    local endTime = GetTime()
    local duration = endTime - startTime
    
    -- Track function performance (same as TrackPerformance)
    local stats = self.Performance.stats.functionCalls[funcName] or {
        calls = 0,
        totalTime = 0,
        maxTime = 0,
        lastTime = 0,
        errorCount = 0
    }
    
    stats.calls = stats.calls + 1
    stats.totalTime = stats.totalTime + duration
    stats.lastTime = duration
    if duration > stats.maxTime then
        stats.maxTime = duration
    end
    
    -- Track errors if the pcall failed
    if not success then
        stats.errorCount = (stats.errorCount or 0) + 1
        
        -- Store error info
        local errors = self.Performance.stats.pcallErrors
        errors[funcName] = errors[funcName] or {}
        table.insert(errors[funcName], {
            error = result,
            time = GetTime()
        })
        
        -- Limit to last 10 errors per function
        while table.getn(errors[funcName]) > 10 do
            table.remove(errors[funcName], 1)
        end
        
        self:Debug("perf", "Error in " .. funcName .. ": " .. tostring(result))
    end
    
    self.Performance.stats.functionCalls[funcName] = stats
    self.Performance.stats.totalTracked = self.Performance.stats.totalTracked + 1
    
    -- Log slow pcalls
    if duration >= self.Performance.threshold then
        self:Debug("perf", "Slow pcall: " .. funcName .. " took " .. string.format("%.3f", duration * 1000) .. " ms")
        
        -- Store in slowest functions list (same as TrackPerformance)
        local slowList = self.Performance.stats.slowestFunctions
        table.insert(slowList, {
            name = funcName,
            time = duration,
            timestamp = GetTime(),
            isPcall = true,
            success = success
        })
        
        -- Keep list sorted by time (descending)
        table.sort(slowList, function(a, b) return a.time > b.time end)
        
        -- Trim list to 50 items
        while table.getn(slowList) > 50 do
            table.remove(slowList)
        end
    end
    
    return success, result
end

-- Hook critical functions for performance monitoring
function TWRA:HookCriticalFunctions()
    if self.Performance.hooked then
        return -- Already hooked
    end
    
    self:Debug("perf", "Hooking critical functions for performance monitoring")
    
    -- Hook event system
    if self.TriggerEvent then
        local originalTriggerEvent = self.TriggerEvent
        self.TriggerEvent = function(self, event, arg1, arg2, arg3, arg4, arg5)
            if not self.Performance.enabled then
                return originalTriggerEvent(self, event, arg1, arg2, arg3, arg4, arg5)
            end
            
            local startTime = GetTime()
            local result
            
            if arg5 then
                result = originalTriggerEvent(self, event, arg1, arg2, arg3, arg4, arg5)
            elseif arg4 then
                result = originalTriggerEvent(self, event, arg1, arg2, arg3, arg4)
            elseif arg3 then
                result = originalTriggerEvent(self, event, arg1, arg2, arg3)
            elseif arg2 then
                result = originalTriggerEvent(self, event, arg1, arg2)
            elseif arg1 then
                result = originalTriggerEvent(self, event, arg1)
            else
                result = originalTriggerEvent(self, event)
            end
            
            local endTime = GetTime()
            local duration = endTime - startTime
            
            -- Track event performance
            local eventStats = self.Performance.stats.eventStats
            eventStats[event] = eventStats[event] or {
                calls = 0,
                totalTime = 0,
                maxTime = 0
            }
            
            eventStats[event].calls = eventStats[event].calls + 1
            eventStats[event].totalTime = eventStats[event].totalTime + duration
            if duration > eventStats[event].maxTime then
                eventStats[event].maxTime = duration
            end
            
            -- Log slow events
            if duration >= self.Performance.threshold then
                self:Debug("perf", "Slow event: " .. event .. " took " .. string.format("%.3f", duration * 1000) .. " ms")
            end
            
            return result
        end
    end
    
    -- Hook navigation function
    if self.NavigateToSection then
        local originalNavigate = self.NavigateToSection
        self.NavigateToSection = function(self, index, source)
            return self:TrackPerformance("NavigateToSection", originalNavigate, self, index, source)
        end
    end
    
    -- Hook other critical functions
    if self.DisplayCurrentSection then
        local originalDisplay = self.DisplayCurrentSection
        self.DisplayCurrentSection = function(self)
            return self:TrackPerformance("DisplayCurrentSection", originalDisplay, self)
        end
    end
    
    -- Hook import and sync processes - these are causing the framerate issues
    if self.ImportAssignments then
        local originalImport = self.ImportAssignments
        self.ImportAssignments = function(self, data, source)
            return self:TrackPerformance("ImportAssignments", originalImport, self, data, source)
        end
    end
    
    if self.ImportString then
        local originalImportString = self.ImportString
        self.ImportString = function(self, importString, isSync, syncTimestamp)
            return self:TrackPerformance("ImportString", originalImportString, self, importString, isSync, syncTimestamp)
        end
    end
    
    if self.SYNC and self.SYNC.ProcessSyncData then
        local originalProcess = self.SYNC.ProcessSyncData
        self.SYNC.ProcessSyncData = function(self, data, sender)
            return TWRA:TrackPerformance("SYNC.ProcessSyncData", originalProcess, self, data, sender)
        end
    end
    
    -- Hook the SaveAssignments function which is called during import
    if self.SaveAssignments and not self.originalSaveAssignments then
        self.originalSaveAssignments = self.SaveAssignments
        self.SaveAssignments = function(self, data, sourceString, originalTimestamp, noAnnounce)
            return self:TrackPerformance("SaveAssignments", self.originalSaveAssignments, self, data, sourceString, originalTimestamp, noAnnounce)
        end
        self:Debug("perf", "Hooked SaveAssignments for performance monitoring")
    end
    
    -- Mark as hooked
    self.Performance.hooked = true
end

-- Generate a performance report
function TWRA:GeneratePerformanceReport()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Performance Report|r")
    
    -- Report current FPS
    DEFAULT_CHAT_FRAME:AddMessage("Current FPS: " .. string.format("%.1f", self.Performance.lastFPS or 0))
    
    -- Report slowest functions
    DEFAULT_CHAT_FRAME:AddMessage("Slowest Functions:")
    local slowList = self.Performance.stats.slowestFunctions
    for i = 1, math.min(5, table.getn(slowList)) do
        local func = slowList[i]
        local timeStr = string.format("%.2f ms", func.time * 1000)
        local pcallStr = func.isPcall and " (pcall" .. (func.success and "" or ", failed") .. ")" or ""
        DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. func.name .. ": " .. timeStr .. pcallStr)
    end
    
    -- Report most called functions
    DEFAULT_CHAT_FRAME:AddMessage("Most Called Functions:")
    local callCounts = {}
    for name, stats in pairs(self.Performance.stats.functionCalls) do
        table.insert(callCounts, {name = name, calls = stats.calls, time = stats.totalTime})
    end
    table.sort(callCounts, function(a, b) return a.calls > b.calls end)
    
    for i = 1, math.min(5, table.getn(callCounts)) do
        local func = callCounts[i]
        local avgTime = func.calls > 0 and (func.time / func.calls) or 0
        DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. func.name .. ": " .. func.calls .. 
            " calls, avg " .. string.format("%.2f ms", avgTime * 1000))
    end
    
    -- Report functions with most errors
    DEFAULT_CHAT_FRAME:AddMessage("Functions with Errors:")
    local errorFuncs = {}
    for name, stats in pairs(self.Performance.stats.functionCalls) do
        if stats.errorCount and stats.errorCount > 0 then
            table.insert(errorFuncs, {name = name, errors = stats.errorCount})
        end
    end
    table.sort(errorFuncs, function(a, b) return a.errors > b.errors end)
    
    if table.getn(errorFuncs) > 0 then
        for i = 1, math.min(5, table.getn(errorFuncs)) do
            local func = errorFuncs[i]
            DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ". " .. func.name .. ": " .. func.errors .. " errors")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("  No errors detected")
    end
    
    -- Total tracked function calls
    DEFAULT_CHAT_FRAME:AddMessage("Total tracked function calls: " .. self.Performance.stats.totalTracked)
end

-- Clear performance data
function TWRA:ClearPerformanceData()
    self.Performance.stats = {
        functionCalls = {},
        pcallErrors = {},
        eventStats = {},
        slowestFunctions = {},
        totalTracked = 0
    }
    self.Performance.samples = {}
    self.Performance.frameTime = nil
    self.Performance.frameCount = nil
end

-- Replace standard pcall with a version that tracks performance
function TWRA:ReplaceStandardPcall()
    -- Store the original pcall
    if not self.originalPcall then
        self.originalPcall = pcall
    end
    
    -- Replace global pcall with our tracking version
    _G.pcall = function(f, arg1, arg2, arg3, arg4, arg5, arg6)
        if not TWRA.Performance.enabled then
            if arg6 then return TWRA.originalPcall(f, arg1, arg2, arg3, arg4, arg5, arg6)
            elseif arg5 then return TWRA.originalPcall(f, arg1, arg2, arg3, arg4, arg5)
            elseif arg4 then return TWRA.originalPcall(f, arg1, arg2, arg3, arg4)
            elseif arg3 then return TWRA.originalPcall(f, arg1, arg2, arg3)
            elseif arg2 then return TWRA.originalPcall(f, arg1, arg2)
            elseif arg1 then return TWRA.originalPcall(f, arg1)
            else return TWRA.originalPcall(f) end
        end
        
        local startTime = GetTime()
        local results = {}
        
        -- Call pcall with the correct number of arguments
        if arg6 then 
            results = {TWRA.originalPcall(f, arg1, arg2, arg3, arg4, arg5, arg6)}
        elseif arg5 then 
            results = {TWRA.originalPcall(f, arg1, arg2, arg3, arg4, arg5)}
        elseif arg4 then 
            results = {TWRA.originalPcall(f, arg1, arg2, arg3, arg4)}
        elseif arg3 then 
            results = {TWRA.originalPcall(f, arg1, arg2, arg3)}
        elseif arg2 then 
            results = {TWRA.originalPcall(f, arg1, arg2)}
        elseif arg1 then 
            results = {TWRA.originalPcall(f, arg1)}
        else 
            results = {TWRA.originalPcall(f)}
        end
        
        local endTime = GetTime()
        local duration = endTime - startTime
        
        if duration >= TWRA.Performance.threshold then
            local functionName = "unknown"
            -- Try to get function name
            if debug and debug.getinfo then
                local info = debug.getinfo(f)
                if info and info.name then
                    functionName = info.name
                end
            end
            
            TWRA:Debug("perf", "Slow pcall to " .. functionName .. " took " .. 
                      string.format("%.3f", duration * 1000) .. " ms")
            
            -- Record this in our stats
            TWRA.Performance.stats.pcallErrors[functionName] = TWRA.Performance.stats.pcallErrors[functionName] or {}
            if not results[1] then
                table.insert(TWRA.Performance.stats.pcallErrors[functionName], {
                    error = results[2],
                    time = GetTime(),
                    duration = duration
                })
            end
        end
        
        -- Return the results without using unpack
        if table.getn(results) == 0 then
            return nil
        elseif table.getn(results) == 1 then
            return results[1]
        elseif table.getn(results) == 2 then
            return results[1], results[2]
        elseif table.getn(results) == 3 then
            return results[1], results[2], results[3]
        elseif table.getn(results) == 4 then
            return results[1], results[2], results[3], results[4]
        elseif table.getn(results) == 5 then
            return results[1], results[2], results[3], results[4], results[5]
        else
            return results[1], results[2], results[3], results[4], results[5], results[6]
        end
    end
    
    self:Debug("perf", "Replaced standard pcall with performance tracking version")
    return true
end

-- Initialize performance monitoring on load
TWRA:InitializePerformance()