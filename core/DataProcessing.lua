-- Handle loading of data including scanning for GUIDs
function TWRA:ProcessLoadedData(data)

    
    -- After processing data, setup section navigation
    self:RebuildNavigation()
    
    -- If AutoNavigate is enabled, we should prepare any GUID information
    if self.AUTONAVIGATE and self.AUTONAVIGATE.enabled then
        -- This helps the mob scanning system have up-to-date section information
        self:Debug("nav", "Refreshing section navigation for AutoNavigate")
        
        -- Force GUID refresh if needed
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Data loaded, refreshed GUID mappings")
            -- Reset last marked GUID to force new scan
            self.AUTONAVIGATE.lastMarkedGuid = nil  
        end
    end
    
end
