-- Here we'll outline our desired functionality
-- On Section Change, look at our role.
-- If it matches anything inside our TWRA_DECURSIVE table we need to
-- Add target to our temporaru table.

function PopulateTargetArray()
    local targetArray = {}
    local targetCount = 0
    local targetName = ""
    
    -- Iterate through the TWRA_DECURSIVE table
    for _, target in ipairs(TWRA_DECURSIVE) do
        -- Check if the target is a valid name
        if target and type(target) == "string" then
            targetCount = targetCount + 1
            targetName = target
            table.insert(targetArray, targetName)
        end
    end
    
    -- Return the populated array and count
    return targetArray, targetCount
end

function UpdateDecursiveList()
    local targetArray, targetCount = PopulateTargetArray()
    -- run /dcrprclear
    -- Check if the target count is greater than 0
    if targetCount > 0 then
        -- Iterate through the target array and perform actions
        for i = 1, targetCount do
            local targetName = targetArray[i]
            -- Perform actions with the target name
            print("Target Name: " .. targetName)
        end
    else
        print("No valid targets found.")
    end
end
