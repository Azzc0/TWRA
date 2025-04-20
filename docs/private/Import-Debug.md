# Debugging Import Process

## Common Import Issues

### Base64 Decoding
The Base64 decoding process should be robust, but occasionally whitespace or line breaks in the encoded string can cause issues. When having problems:

1. Try removing any whitespace from the beginning/end of the encoded string
2. Ensure the string isn't being truncated 
3. Check if the decoded string begins with `TWRA_ImportString =`

### String Evaluation
After decoding, the import process uses `loadstring` to convert the text to a Lua table. Issues may arise if:

1. The string contains invalid Lua syntax
2. String evaluation is being prevented by security mechanisms
3. Memory constraints limit processing large strings

### Solution
The updated DirectImportNewFormat function addresses these issues by:
1. Using a safer approach to evaluate the import string
2. Creating a local environment to prevent global variable conflicts
3. Using the proper return mechanism to extract the data
4. Adding thorough validation of the data structure

## Testing Your Import

To verify your import string is properly formatted:

1. Add `/run TWRA:VerifyImportString("your_base64_string")` to test a string
2. Check for diagnostic output in the debug console
3. If the structure is valid but import fails, use `/twra diag` to examine saved variables

## Format Requirements

For successful import, the decoded string must match this structure:
```lua
TWRA_ImportString = {
  ["data"] = {
    [1] = {
      ["Section Name"] = "Section Name Here",
      ["Section Header"] = {
        -- Header columns
      },
      ["Section Rows"] = {
        -- Data rows
      }
    },
    -- Additional sections...
  }
}
```
