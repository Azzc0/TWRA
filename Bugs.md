# TWRA Bug Tracking

## Known Issues

### Item Link Handling
- **Issue**: Infinite loop when announcing warnings with already formatted item links
- **Description**: When a warning contains an already formatted item link (e.g., `|cffa335ee|Hitem:5634:0:0:0|h[Free Action Potion]|h|r`), the announcement system gets stuck in a loop.
- **Workaround**: Use bracket notation (e.g., `[Free Action Potion]`) in spreadsheets instead of pasting formatted item links. The addon will convert these to proper clickable links.
- **Root Cause**: The link processing code attempts to process text that already contains item links, despite checks to prevent this.

## Resolved Issues

- None yet.

Import should bring us back to MainView
Example button does not load example data

Le