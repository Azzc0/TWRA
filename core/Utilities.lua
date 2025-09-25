-- Add these utility functions to your Utilities file

-- Safe function to get an array's length without using # operator
function TWRA:GetArrayLength(arr)
    if not arr or type(arr) ~= "table" then
        return 0
    end
    
    local count = 0
    local index = 1
    while arr[index] ~= nil do
        count = count + 1
        index = index + 1
    end
    return count
end

-- Safe function to check if a table has a specific number of sequential elements
function TWRA:HasExactElements(tbl, count)
    if not tbl or type(tbl) ~= "table" then
        return false
    end
    
    -- Check first 'count' elements exist
    for i = 1, count do
        if tbl[i] == nil then
            return false
        end
    end
    
    -- Make sure there's no count+1 element
    if tbl[count + 1] ~= nil then
        return false
    end
    
    return true
end

-- Safe function to iterate over array elements without relying on # operator
function TWRA:ForEachArrayElement(arr, func)
    if not arr or type(arr) ~= "table" or type(func) ~= "function" then
        return
    end
    
    local index = 1
    while arr[index] ~= nil do
        func(arr[index], index)
        index = index + 1
    end
end
