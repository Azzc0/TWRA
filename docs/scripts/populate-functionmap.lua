-- filepath: /home/azzco/tmp/TWRA/docs/populate-functionmap.lua
-- Execute from TWRA/
-- Read list of files in TWRA.toc
-- Write all found functions in docs/functionmap.md (in the format we currently have)
-- After that go for each function listed in docs/functionmap.md find all references in files listed in TWRA.toc

local function readFile(path)
    local file = io.open(path, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return content
end

local function writeFile(path, content)
    local file = io.open(path, "w")
    if not file then return false end
    file:write(content)
    file:close()
    return true
end

-- Read the TOC file to get all addon files
local function getAddonFiles()
    local tocContent = readFile("TWRA.toc")
    if not tocContent then
        print("Error: Could not read TWRA.toc")
        return {}
    end
    
    local files = {}
    for line in tocContent:gmatch("[^\r\n]+") do
        -- Skip comment lines and empty lines
        if not line:match("^%s*#") and not line:match("^%s*$") and not line:match("^%s*##") then
            -- Extract the file path
            local file = line:match("^%s*(.+)%s*$"):gsub("\\", "/")
            if file then
                table.insert(files, file)
            end
        end
    end
    
    return files
end

-- Parse a Lua file to find all TWRA functions 
local function parseFunctions(filePath)
    local content = readFile(filePath)
    if not content then
        print("Error: Could not read file: " .. filePath)
        return {}
    end
    
    local functions = {}
    local lineNumber = 0
    
    -- Process each line
    for line in content:gmatch("[^\r\n]+") do
        lineNumber = lineNumber + 1
        
        -- Look for function definitions like: function TWRA:FunctionName( or function TWRA.FunctionName(
        local funcName = line:match("function%s+TWRA[:.](.-)[%(%s]")
        if funcName then
            -- Clean up function name
            funcName = funcName:gsub("%s+", "")
            
            table.insert(functions, {
                name = funcName,
                line = lineNumber,
                path = filePath
            })
        end
    end
    
    return functions
end

-- Find references to a function in all addon files
local function findReferences(functionName, files)
    local references = {}
    
    for _, filePath in ipairs(files) do
        local content = readFile(filePath)
        if content then
            local lineNumber = 0
            
            -- Process each line
            for line in content:gmatch("[^\r\n]+") do
                lineNumber = lineNumber + 1
                
                -- Look for function calls like: TWRA:FunctionName( or self:FunctionName(
                -- This is a simplified approach, might miss some references
                if line:match("TWRA[:.:]" .. functionName .. "[%(%s]") or 
                   line:match("self[:.:]" .. functionName .. "[%(%s]") then
                    table.insert(references, {
                        path = filePath,
                        line = lineNumber,
                        context = line:match("(.-)TWRA[:.:]" .. functionName) or 
                                  line:match("(.-)self[:.:]" .. functionName) or ""
                    })
                end
            end
        end
    end
    
    return references
end

-- Generate Markdown for function map
local function generateFunctionMap(allFunctions, addonFiles)
    local md = "# TWRA Function Map\n\n"
    md = md .. "This document maps all functions in the TWRA addon, showing where they are defined and where they are referenced throughout the codebase.\n\n"
    
    -- Group functions by file
    local fileGroups = {}
    for _, func in ipairs(allFunctions) do
        if not fileGroups[func.path] then
            fileGroups[func.path] = {}
        end
        table.insert(fileGroups[func.path], func)
    end
    
    -- Sort files by categories based on folder structure
    local categoryOrder = {
        ["Core Files"] = {"TWRA.lua", "core/"},
        ["UI Files"] = {"ui/"},
        ["Feature Files"] = {"features/"},
        ["Sync Files"] = {"sync/"},
        ["Library Files"] = {"libs/"}
    }
    
    -- Write sections for each category
    local categoryIndex = 1
    for categoryName, pathPatterns in pairs(categoryOrder) do
        local categoryFiles = {}
        
        -- Find files that match this category
        for filePath, funcs in pairs(fileGroups) do
            for _, pattern in ipairs(pathPatterns) do
                if filePath:match(pattern) then
                    table.insert(categoryFiles, {path = filePath, functions = funcs})
                    break
                end
            end
        end
        
        -- If we found files in this category, write the section
        if #categoryFiles > 0 then
            md = md .. "## " .. categoryIndex .. ". " .. categoryName .. "\n\n"
            categoryIndex = categoryIndex + 1
            
            -- Sort files within category
            table.sort(categoryFiles, function(a, b) return a.path < b.path end)
            
            -- Write each file's functions
            local fileIndex = 1
            for _, fileInfo in ipairs(categoryFiles) do
                md = md .. "### " .. (categoryIndex-1) .. "." .. fileIndex .. " " .. fileInfo.path .. "\n\n"
                fileIndex = fileIndex + 1
                
                -- Sort functions by line number
                table.sort(fileInfo.functions, function(a, b) return a.line < b.line end)
                
                -- Add each function with its references
                for _, func in ipairs(fileInfo.functions) do
                    local refs = findReferences(func.name, addonFiles)
                    
                    md = md .. "- `TWRA:" .. func.name .. "()` - Line " .. func.line .. "\n"
                    
                    if #refs > 0 then
                        md = md .. "  - Referenced in:\n"
                        for _, ref in ipairs(refs) do
                            -- Skip self-references (function definition)
                            if not (ref.path == func.path and ref.line == func.line) then
                                md = md .. "    - " .. ref.path .. ":" .. ref.line
                                
                                -- Add context if it exists and is meaningful
                                local context = ref.context:match("[^%s]+.*")
                                if context and #context > 0 and #context < 40 then
                                    md = md .. " (in " .. context:gsub("^%s*", "") .. ")"
                                end
                                
                                md = md .. "\n"
                            end
                        end
                    else
                        md = md .. "  - Not referenced elsewhere in the codebase\n"
                    end
                    
                    md = md .. "\n"
                end
            end
        end
    end
    
    -- Add section for duplicate functions
    md = md .. "## " .. categoryIndex .. ". Duplicate Functions\n\n"
    
    -- Find duplicate function names
    local functionNames = {}
    local duplicateFunctions = {}
    
    for _, func in ipairs(allFunctions) do
        if functionNames[func.name] then
            if not duplicateFunctions[func.name] then
                duplicateFunctions[func.name] = {functionNames[func.name]}
            end
            table.insert(duplicateFunctions[func.name], func)
        else
            functionNames[func.name] = func
        end
    end
    
    -- If we found duplicates, list them
    local hasDuplicates = false
    for name, instances in pairs(duplicateFunctions) do
        hasDuplicates = true
        md = md .. "- `TWRA:" .. name .. "()` is defined in multiple locations:\n"
        for _, func in ipairs(instances) do
            md = md .. "  - " .. func.path .. ":" .. func.line .. "\n"
        end
        md = md .. "\n"
    end
    
    if not hasDuplicates then
        md = md .. "No duplicate function definitions found.\n\n"
    end
    
    return md
end

-- Main execution
local function main()
    print("Starting TWRA Function Map generation...")
    
    -- Get list of addon files from TOC
    local addonFiles = getAddonFiles()
    if #addonFiles == 0 then
        print("Error: No files found in TWRA.toc")
        return
    end
    
    print("Found " .. #addonFiles .. " files in TWRA.toc")
    
    -- Parse functions from all files
    local allFunctions = {}
    for _, filePath in ipairs(addonFiles) do
        local functions = parseFunctions(filePath)
        for _, func in ipairs(functions) do
            table.insert(allFunctions, func)
        end
    end
    
    print("Found " .. #allFunctions .. " functions in codebase")
    
    -- Generate the function map
    local functionMap = generateFunctionMap(allFunctions, addonFiles)
    
    -- Write the function map to file
    local outputPath = "docs/Functionmap.md"
    if writeFile(outputPath, functionMap) then
        print("Function map successfully written to " .. outputPath)
    else
        print("Error: Could not write to " .. outputPath)
    end
end

-- Run the main function
main()
