# Data Structure Analysis

## Current Structure
Currently we use a flat array of arrays where each inner array contains section name and assignment details. This has several drawbacks:
- Section names are repeated in every row, wasting bandwidth during sync
- Header information is mixed with data
- No explicit structure for special rows like headers
- Processing to identify relevant rows is done repeatedly

## Proposed Structure
The proposed nested structure offers several key advantages:

### Benefits
1. **More efficient storage and transmission**
   - Section name stored once per section, not per row
   - Structured organization reduces data duplication
   - Estimated 20-30% reduction in string length for typical raid assignments

2. **Improved code readability and maintainability**
   - Clear separation between headers and data
   - Explicit indexing of relevant rows
   - Pre-formatted assignments ready for display

3. **Better runtime performance**
   - Pre-calculated "Formated Assignments" eliminates processing time when displaying
   - "Relevant Rows" allows immediate highlight without parsing
   - Reduced calculations during OSD display and announcements

4. **Enhanced extensibility**
   - Additional metadata can be easily added to each section
   - Possible support for section-specific settings
   - Room for future features like notes, strategy links, etc.

### Implementation Impact
1. **Import Process**
   - Base64 decoding unchanged
   - Additional formatting step to organize data
   - One-time processing cost during import, benefits afterward

2. **UI Display**
   - Simplified lookup for section names and headers
   - Straightforward row highlighting using Relevant Rows index
   - Cleaner grid rendering logic

3. **OSD/Announcements**
   - Direct use of pre-formatted assignments
   - No need for parsing during announcements
   - More control over formatting specifics

4. **Sync Impact**
   - Same Base64 encoding/decoding process
   - Shorter strings to transmit due to reduced redundancy
   - No changes to chunking mechanism needed

## Migration Strategy
1. ~~Create new import processing function that converts old format to new~~
2. Update UI rendering to support both formats during transition
3. ~~Modify export function to use new format only~~
4. ~~Implement version flag in saved data to handle backward compatibility~~

## Conclusion
The proposed restructuring offers substantial improvements in efficiency, readability, and extensibility with minimal downsides. The one-time cost of refactoring is justified by the long-term benefits to performance and maintainability.

The biggest advantage comes from pre-processing the data during import rather than repeatedly during runtime operations, making the addon more responsive and efficient.
