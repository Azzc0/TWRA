# TWRA Bug Tracking

## Known Issues

### Item Link Handling
- **Issue**: Infinite loop when announcing warnings with already formatted item links
- **Description**: When a warning contains an already formatted item link (e.g., `|cffa335ee|Hitem:5634:0:0:0|h[Free Action Potion]|h|r`), the announcement system gets stuck in a loop.
- **Workaround**: Use bracket notation (e.g., `[Free Action Potion]`) in spreadsheets instead of pasting formatted item links. The addon will convert these to proper clickable links.
- **Root Cause**: The link processing code attempts to process text that already contains item links, despite checks to prevent this.

## Resolved Issues

- None yet.


### Column amount is not updated on navigation (low prio)
We need to update the amount of columns when we navigate between sections. 
In our example data "Welcome" has icon, target, tank, dps and heal in the header rows.
    The amount of columns we should se when we view this section should be 4 (icon is not displayed, it's baked into target).
"Grand Widow Faerlina" has Icon, target, tank, pull, mc and heal
    The amount of columns we should se when we view this section should be 5 (icon is not displayed, it's baked into target).
Target should have a minimum width to fit in some longer boss names. since player names can only be 12 characters long we can properly set minimum width for those.
The columns should be evenly spaced to use the full width and distribute accordingly horizontally.

The current behaviour is not upsetting and this functionality has very low priority.


### Autotanks, clear tanks
Our current implementation of removing tanks from the tank table for all oRA2 users in the group needs updating. It's currently not working as expected. We'll need to dive into oRA2 code to see how to manage this. We want this to be done silently.


### Sections has to have unique names
We need to make sure that we do not forget to document this.