# Methods
--------------------
### update
```lua
Dropdown:update()
```
Forces the dropdown to update colors, text alignment. If the dropdown is visible when this is called, the dropdown will be hidden.

--------------------
### set
```lua
Dropdown:set(setting,value)
```
Sets the specified setting to the passed value.

--------------------
### isOpen
```lua
Dropdown:isOpen()
```
Returns a bool indicating if the dropdown is open or not.

--------------------
### hide
```lua
Dropdown:hide()
```
Hides the dropdown.

--------------------
### show
```lua
Dropdown:show(position)
```
Shows the dropdown at the passed Vector2 position, if ``position`` is nil the dropdown will be displayed automatically at the icon.

--------------------
### newOption
```lua
Dropdown:newOption(config)
```
Creates a new option in the dropdown.

Example of how an option could be set up:
```lua
    local config = {
        name = "My option",
        icon = "http://www.roblox.com/asset/?id=4943948171",
        order = 2,
        clicked = function()
            print("🍕+🍍=😍")
        end,
        events = {myIcon.selected}
    }
```

--------------------
### removeOption
```lua
Dropdown:removeOption(name)
```
Destroys the option with the name passed.

--------------------
### destroy
```lua
Dropdown:destroy()
```
Destroys all instances, connections and signals associcated with the dropdown.

--------------------



<br>



--------------------
# Properties

--------------------
### icon
{read-only}
```lua
Dropdown.objects
```
The icon the dropdown is associated with.

--------------------
### options
{read-only}
```lua
Dropdown.theme
```
Not to be confused with ``Dropdown.settings``
An array with the dropdown's options, use ``Dropdown:newOption()`` to create a new one.

--------------------
### settings
{read-only}
```lua
Dropdown.settings
```
A dictionary with the dropdown's settings, use ``Dropdown:set()`` to change.