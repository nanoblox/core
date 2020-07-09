# Constructors
--------------------
### new
```lua
local icon = Icon.new(name, imageId, order)
```
Constructs a new icon where ``name`` is a unique string identifying the icon, ``imageId`` an int representing the icons image, and ``order``, a number defining how the icon should be positioned in relation to neighbouring icons.



<br>



# Methods
--------------------
### setTip
```lua
icon:setTip(tip)
```
Sets a tip that is displayed when hovering over the icon. Setting a tip to ``nil`` or ``""`` will remove the tip.

--------------------
### setControllerTip
```lua
icon:setControllerTip(tip)
```
Overrides the normal tip, if the player is in controller mode.

--------------------
### createDropdown
```lua
local dropdown = icon:createDropdown(options)
```
Creates a dropdown that will be shown when the icon is right-clicked or long-pressed on mobile. Returns the dropdown created. If there already is an ``Icon.dropdown``, ``icon:removeDropdown()`` will be called before creating a new one.

See ``Dropdown.options`` for more details, and ``About`` for an example.

--------------------
### removeDropdown
```lua
icon:removeDropdown()
```
Destroys and removes all references of ``Icon.dropdown``.

--------------------
### setImage
```lua
icon:setImage(imageId)
```
Sets the icons image, where ``imageId`` can be an int representing an asset id (such as ``4882428756``), or a string representing an assets pathway (such as ``"rbxasset://textures/ui/TopBar/chatOff.png"``).

--------------------
### setOrder
```lua
icon:setOrder(order)
```
Sets the icons priority order, determining whether it will appear before or after other icons.

--------------------
### setLeft
```lua
icon:setLeft()
```
Aligns the icon on the left-side of the topbar (this happens by default). The greater the ``order``, the further rightward the icon will appear relative to other icons set-left.

--------------------
### setMid
```lua
icon:setMid()
```
Aligns the icon in the middle of the topbar. The greater the ``order``, the further rightward the icon will appear relative to other icons set-mid.

--------------------
### setRight
```lua
icon:setRight()
```
Aligns the icon on the right-side of the topbar, next to the leaderboard/emotes/inventory toggle. The greater the ``order``, the further rightward the icon will appear relative to other icons set-right.

--------------------
### setImageSize
```lua
icon:setImageSize(width, height)
```
Sets the image size in pixels. Height will equal width if not specified.

--------------------
### setEnabled
```lua
icon:setEnabled(bool)
```
Sets the icons visibility.

--------------------
### setCellSize
```lua
icon:setCellSize(pixels)
```
Changes the container size of icon to be ``X pixels`` by ``Y pixels``. Defaults to 32.

--------------------
### setBaseZIndex
```lua
icon:setBaseZIndex(int)
```
Calculates the difference between the existing baseZIndex (i.e. the ``object.container.ZIndex``) and new value, then updates the ZIndex of all objects within the icon accoridngly using this difference.

--------------------
### setToggleMenu
```lua
icon:setToggleMenu(guiObject)
```
Binds the GuiObject so that its visibility is toggled on and off accordingly when ``icon:select()`` and ``icon:deselect()`` are called (i.e. when the icon is selected and deselected).
!!! info Info
    You must ensure the GuiObject has 'ResetOnSpawn' set to ``false``, or that you are calling ``icon:setToggleMenu(guiObject)`` every time the player respawns, for the menu to persist.

--------------------
### setToggleFunction
```lua
icon:setToggleFunction(toggleFunction)
```
Sets a function that is called every time the icon is selected and deselected.

--------------------
### setHoverFunction
```lua
icon:setHoverFunction(hoverFunction)
```
Whenver the icon gets highlighted or unhighlighted, the function set is called and a boolean is passed telling if the icon got highlighted or unhighlighted.

--------------------
### setTheme
```lua
icon:setTheme(themeDetails)
```
Applies the specified theme to the icon. See ``Icon.theme`` for details on creating a theme.

--------------------
### applyThemeToObject
```lua
icon:applyThemeToObject(objectName, toggleStatus)
```
Used internally to apply the theme set to the object, in ``Icon.objects``, with the name passed.

--------------------
### applyThemeToAllObjects
```lua
icon:applyThemeToAllObjects()
```
Used internally to apply the set theme to all objects.

--------------------
### select
```lua
icon:select()
```
Selects the icon.

--------------------
### deselect
```lua
icon:deselect()
```
Deselects the icon.

--------------------
### notify
```lua
icon:notify(clearNoticeEvent)
```
Prompts a notification that appears in the top-right corner of the icon. Specifiy ``clearNoticeEvent`` with an event to determine when to end the notifcation. If not specified, ``clearNoticeEvent`` defaults to ``Icon.deselected``.

--------------------
### clearNotifications
```lua
icon:clearNotifications()
```
Clears all notifications.

--------------------
### destroy
```lua
icon:destroy()
```
Destroys all instances, connections and signals associcated with the icon.

--------------------



<br>



# Events
--------------------
### updated
```lua
Icon.updated
```
Fired when the icon causes a position shift of other icons.
```lua
Icon.updated:Connect(function()

end)
```

--------------------
### selected
```lua
Icon.selected
```
Fired when the icon is selected.
```lua
Icon.selected:Connect(function()

end)
```

--------------------
### deselected
```lua
Icon.deselected
```
Fired when the icon is deselected.
```lua
Icon.deselected:Connect(function()

end)
```

--------------------
### endNotifications
```lua
Icon.endNotifications
```
Fired when the icons notifcations are cleared.
```lua
Icon.endNotifications:Connect(function()

end)
```



<br>



--------------------
# Properties

--------------------
### objects
```lua
Icon.objects
```
A dictionary of instances that make up the icon.



| Key                 | Value            | Desc                                           |
| :--------------     |:--------------   | :----------------------------------------------|
| **container**       | *Frame*          | The icon container.                            |
| **button**          | *ImageButton*    | The icon background.                           |
| **image**           | *ImageLabel*     | The icon image.                                |
| **notification**    | *ImageLabel*     | The notification container and background.     |
| **amount**          | *TextLabel*      | The notification amount text.                  |
| **gradient**        | *UIGradient*     | The gradient used to make the icon look fancy. |



--------------------
### theme
{read-only}
```lua
Icon.theme
```
A dictionary describing the icons theme. To change, use ``icon:setTheme()``.

| Key                 | Value            | Desc                                           |
| :--------------     |:--------------   | :----------------------------------------------|
| **toggleTweenInfo** | *TweenInfo*      | How object properties transition when toggled. |
| **container**       | *ToggleDetails*  | (See below)                                    |
| **button**          | *ToggleDetails*  | (See below)                                    |
| **image**           | *ToggleDetails*  | (See below)                                    |
| **notification**    | *ToggleDetails*  | (See below)                                    |
| **amount**          | *ToggleDetails*  | (See below)                                    |
| **gradient**        | *ToggleDetails*  | (See below)                                    |

***ToggleDetails***

A dictionary containing the objects toggle-state properties.

| Key                 | Value            | Desc                                           |
| :--------------     |:--------------   | :----------------------------------------------|
| **selected**        | *PropertyDetails*| (See below)                                    |
| **deselected**      | *PropertyDetails*| (See below)                                    |

***PropertyDetails***

A dictionary containing the objects properties for that particular toggle-state.

| Key             | Value           |
| :-------------- |:--------------  |
| [propertyName]  | [propertyValue] |
| ...             | ...             |

Default theme example:
```lua
defaultThemeDetails = {
    -- TOGGLE EFFECT
    ["toggleTweenInfo"] = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    
    -- OBJECT PROPERTIES
    ["container"] = {
        selected = {},
        deselected = {},
    },
    ["button"] = {
        selected = {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        },
        deselected = {
            ImageColor3 = Color3.fromRGB(31, 33, 35),
        }
    },
    ["image"] = {
        selected = {
            ImageColor3 = Color3.fromRGB(57, 60, 65),
        },
        deselected = {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        }
    },
    ["notification"] = {
        selected = {},
        deselected = {},
    },
    ["amount"] = {
        selected = {},
        deselected = {},
    },
    ["gradient"] = {
        selected = {},
        deselected = {},
    },
}
```



--------------------
### toggleStatus
{read-only}
```lua
Icon.toggleStatus
```
A string describing the toggle status: "selected" or "deselected". To change, use ``icon:select()`` and ``icon:deselect()``.

--------------------
### name
{read-only}
```lua
Icon.name
```
The icon creation name.

--------------------
### tip
{read-only}
```lua
Icon.tip
```
The tip shown when the icon is highlighted (mouse hovering over the icon or gamepad selection has the icon selected).

--------------------
### controllerTip
{read-only}
```lua
Icon.controllerTip
```
The controller tip that overrides the normal tip when the player is in controller mode.

--------------------
### imageId
{read-only}
```lua
Icon.imageId
```
The icons imageId. To change, use ``icon:setImage()``.

--------------------
### imageSize
{read-only}
```lua
Icon.imageSize
```
A Vector2 representing the images size. To change, use ``icon:setImageSize()``.
Default: 20px

--------------------
### order
{read-only}
```lua
Icon.order
```
The icons order. This determines whether the icon comes before or after other icons. Defaults to ``1``. To change, use ``icon:setOrder()``.

--------------------
### enabled
{read-only}
```lua
Icon.order
```
A bool describing whether the icon is enabled or not. To change, use ``icon:setEnabled()``.

--------------------
### alignment
{read-only}
```lua
Icon.alignment
```
A string describing the alignment of the icon, there are three alignments: ``left``, ``mid``, ``right``

--------------------
### totalNotifications
{read-only}
```lua
Icon.totalNotifications
```
An int representing the amount of active notifications.

--------------------
### toggleMenu
{read-only}
```lua
Icon.toggleFunction 
```
A GuiObject binded by ``icon:setToggleMenu()``.

--------------------
### toggleFunction 
{read-only}
```lua
Icon.toggleFunction 
```
A custom function called during ``icon:select()`` and ``icon:deselect()``. To change, use ``icon:setToggleFunction()``.

--------------------
### hoverFunction 
{read-only}
```lua
Icon.hoverFunction 
```
A custom function called when the icon is (un)highlighted. To change, use ``icon:setHoverFunction()``.

--------------------
### deselectWhenOtherIconSelected 
```lua
Icon.toggleFunction 
```
A bool deciding whether the icon will be deselected when another icon is selected. Defaults to ``true``.
