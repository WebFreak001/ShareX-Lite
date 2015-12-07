# Cross Platform ShareX clone

Currently WIP

Supported platforms for sure: Linux

## Installation:

Install dub, gtk dev, x11 dev

First run `dub build :selector` to create the screenshot capture utility

Then run `dub build` to create the actual program

Running it will create the config folder (~/.sharex/)

Example script for .sharex/scripts/ folder:

```lua
-- simple.lua
-- Example Workflow

sleep(500)
bitmap = captureObjects()
path = saveImage(bitmap)
runWait("gimp " .. path)
url = uploadImage(path)
copyText(url)
```