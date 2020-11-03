# Methods
--------------------
### set
```lua
dropdown:set(setting, value)
```
Sets the specified setting to the given value. For example:
```lua
dropdown:set("backgroundColor", Color3.fromRGB(100, 100, 100))
```

--------------------
### update
```lua
dropdown:update()
```
Forces the dropdown to update colors and text alignment. If the dropdown is visible when this is called, the dropdown will be hidden.

--------------------
### hide
```lua
dropdown:hide()
```
Hides the dropdown.

--------------------
### show
```lua
dropdown:show(position)
```
Displays the dropdown at the passed Vector2 position. If ``position`` is not defined, the dropdown will appear automatically at the icon.

--------------------
### createOption
```lua
local updatedOption = dropdown:createOption(option)
```
Creates an option menu based on the given ``option`` details, and returns the passed ``option`` table.

--------------------
### removeOption
```lua
dropdown:removeOption(nameOrIndex)
```
Destroys an option with the given name or index.

--------------------
### destroy
```lua
dropdown:destroy()
```
Destroys all instances, connections and signals associcated with the dropdown.

--------------------



<br>



--------------------
# Properties

--------------------
### icon
*(read only)*
```lua
dropdown.objects
```
The icon the dropdown is associated with.

--------------------
### isOpen
*(read only)*
```lua
dropdown.isOpen
```
The icon the dropdown is associated with.

--------------------
### options
*(read only)*
```lua
dropdown.theme
```
An array containing dictionaries that describe an option:

| Key                 | Value            | Desc                                           |
| :--------------     |:--------------   | :----------------------------------------------|
| **name** | *String*      | The option name that will appear in the dropdown. |
| **icon**       | *String*  | *(Optional)* An image that appears to the left of the name                                |
| **clicked**          | *Function*  | A function called when the option is pressed                                  |
| **events**           | *Array*  | An array of ``signals`` or ``events`` that bind to ``Icon:notify()`` to create a notification prompt to the right of the option name                                    |

--------------------
### settings
*(read only)*
```lua
dropdown.settings
```
A dictionary containing the dropdowns settings. Use ``dropdown:set()`` to change a setting.

| Key                 | Value            | Desc                                           |
| :--------------     |:--------------   | :----------------------------------------------|
| **canHidePlayerlist** | *Bool*      | Hides the playerlist if overlapping the dropdown |
| **canHideChat**       | *Bool*  | Hides the chat if overlapping the dropdown |
| **chatDefaultDisplayOrder**          | *Int*  | Forces the chats DisplayOrder to this value                                    |
| **tweenSpeed**          | *Float*  | How fast the dropdown appears/disppear |
| **easingDirection**           | *Enum.EasingDirection*  | Affects how the dropdown appears/disppears |
| **easingStyle**    | *Enum.EasingStyle*  | Affects how the dropdown appears/disppears |
| **backgroundColor**        | *Color3*  | The background color of dropdown options |
| **textColor**          | *Color3*  | The name color of dropdown options |
| **imageColor**        | *Color3*  | The icon color of dropdown options |