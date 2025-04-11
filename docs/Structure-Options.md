# Options for Data Structure

## Current New Format
```lua
TWRA_ImportString = {
  ["data"] = {
    [1] = {
      ["Section Name"] = "Ghouls / Slimes",
      ["Section Header"] = { headers... },
      ["Section Rows"] = { rows... }
    }
  }
}
```

## More Compact Option
```lua
TWRA_ImportString = {
  data = {
    {
      name = "Ghouls / Slimes",
      header = { "Icon", "Target", "Tank", ... },
      rows = {
        { "Skull", "", "Azzco", ... },
        { "Cross", "", "Dhl", ... }
      }
    }
  }
}
```

## Most Compact Option
```lua
TWRA_ImportString = {
  {
    "Ghouls / Slimes", -- section name
    { "Icon", "Target", "Tank", ... }, -- header
    { -- rows
      { "Skull", "", "Azzco", ... },
      { "Cross", "", "Dhl", ... }
    }
  }
}
```
