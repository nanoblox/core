# Constructors
--------------------
### new
```lua
Icon.new(name, imageId, order)
```
Constructs a new icon where ``name`` is a unique string identifying the icon, ``imageId`` an int representing the icons image, and ``order``, a number defining how the icon should be positioned in relation to neighbouring icons.



<br>



# Methods
--------------------
### setTip
```lua
Icon:setTip(tip)
```
Sets the tip that is shown when hovering over the icon, ``nil`` or "" will result in no tip shown.

--------------------
### setControllerTip
```lua
Icon:setControllerTip(tip)
```
Overrides the normal tip, if the player is in controller mode.

--------------------
### createDropdown
```lua
Icon:createDropdown(options)
```
Creates a dropdown that will be shown when the icon is right-clicked or long-pressed on mobile. Returns the dropdown created. If there already is a ``Icon.dropdown``, ``Icon:destroyDropdown()`` will be called before creating a new one.

--------------------
### destroyDropdown
```lua
Icon:destroyDropdown()
```
Destroys the dropdown and disconnects all connections to the ``Icon.dropdown``

--------------------
### setImage
```lua
Icon:setImage(imageId)
```
Sets the icons image, where ``imageId`` can be an int representing an asset id (such as ``4882428756``), or a string representing an assets pathway (such as ``"rbxasset://textures/ui/TopBar/chatOff.png"``).

--------------------
### setOrder
```lua
Icon:setOrder(order)
```
Sets the icons priority order, determining whether it will appear before or after other icons.

--------------------
### setLeft
```lua
Icon:setLeft()
```
Aligns the icon on the left-side of the topbar (this happens by default). The greater the ``order``, the further *rightward* the icon will appear relative to other icons set-left.

--------------------
### setRight
```lua
Icon:setRight()
```
Aligns the icon on the right-side of the topbar. The greater the ``order``, the further *leftward* the icon will appear relative to other icons set-right.

--------------------
### setMid
```lua
Icon:setMid()
```
Aligns the icon in the middle of the topbar. The greater the ``order``, the further *rightward* the icon will appear relative to other icons set-middle.

--------------------
### setImageSize
```lua
Icon:setImageSize(width, height)
```
Sets the image size in pixels. Height will equal width if not specified.

--------------------
### setEnabled
```lua
Icon:setEnabled(bool)
```
Sets the icons visibility.

--------------------
### setCellSize
```lua
Icon:setCellSize(pixels)
```
Changes the size of the icon, the icon will be sized in an aspect ratio of 1:1, meaning it will be the same width and height as the argument ``pixels``.
Default is 32px.

--------------------
### setBaseZIndex
```lua
Icon:setBaseZIndex(int)
```
Calculates the difference between the existing baseZIndex (i.e. the ``object.container.ZIndex``) and new value, then updates the ZIndex of all objects within the icon accoridngly using this difference.

--------------------
### setToggleMenu
```lua
Icon:setToggleMenu(guiObject)
```
Binds the GuiObject so that its visibility is toggled on and off accordingly when ``Icon:select()`` and ``Icon:deselect()`` are called (i.e. when the icon is selected and deselected).
!!! info Info
    You must ensure the GuiObject has 'ResetOnSpawn' set to ``false``, or that you are calling ``Icon:setToggleMenu(guiObject)`` every time the player respawns, for the menu to persist.

--------------------
### setToggleFunction
```lua
Icon:setToggleFunction(toggleFunction)
```
Sets a function that is called every time the icon is selected and deselected.

--------------------
### setHoverFunction
```lua
Icon:setHoverFunction(hoverFunction)
```
Whenver the icon gets highlighted or unhighlighted, the function set is called and a boolean is passed telling if the icon got highlighted or unhighlighted.

--------------------
### setTheme
```lua
Icon:setTheme(themeDetails)
```
Applies the specified theme to the icon. See ``Icon.theme`` for details on creating a theme.

--------------------
### applyThemeToObject
```lua
Icon:applyThemeToObject(objectName, toggleStatus)
```
Used internally to apply the theme set to the object, in ``Icon.objects``, with the name passed.

--------------------
### applyThemeToAllObjects
```lua
Icon:applyThemeToAllObjects()
```
Used internally to apply the set theme to all objects.

--------------------
### select
```lua
Icon:select()
```
Selects the icon.

--------------------
### deselect
```lua
Icon:deselect()
```
Deselects the icon.

--------------------
### notify
```lua
Icon:notify(clearNoticeEvent)
```
Prompts a notification that appears in the top-right corner of the icon. Specifiy ``clearNoticeEvent`` with an event to determine when to end the notifcation. If not specified, ``clearNoticeEvent`` defaults to ``Icon.deselected``.

--------------------
### clearNotifications
```lua
Icon:clearNotifications()
```
Clears all notifications.

--------------------
### destroy
```lua
Icon:destroy()
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
*(read only)*
```lua
Icon.theme
```
A dictionary describing the icons theme. To change, use ``Icon:setTheme()``.

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
### toggleStatus {static}
```lua
Icon.toggleStatus
```
A string describing the toggle status: "selected" or "deselected". To change, use ``Icon:select()`` and ``Icon:deselect()``.

--------------------
### name
{read-only}{static}

```lua
Icon.name
```
The icon creation name.

--------------------
### tip
*(read only)*
```lua
Icon.tip
```
The tip shown when the icon is highlighted (mouse hovering over the icon or gamepad selection has the icon selected).

--------------------
### controllerTip
*(read only)*
```lua
Icon.controllerTip
```
The controller tip that overrides the normal tip when the player is in controller mode.

--------------------
### imageId
*(read only)*
```lua
Icon.imageId
```
The icons imageId. To change, use ``Icon:setImage()``.

--------------------
### imageSize
*(read only)*
```lua
Icon.imageSize
```
A Vector2 representing the images size. To change, use ``Icon:setImageSize()``.
Default: 20px

--------------------
### order
*(read only)*
```lua
Icon.order
```
The icons order. This determines whether the icon comes before or after other icons. Defaults to ``1``. To change, use ``Icon:setOrder()``.

--------------------
### enabled
*(read only)*
```lua
Icon.order
```
A bool describing whether the icon is enabled or not. To change, use ``Icon:setEnabled()``.

--------------------
### alignment
*(read only)*
```lua
Icon.alignment
```
A string describing the alignment of the icon, there are three alignments: ``left``, ``mid``, ``right``

--------------------
### totalNotifications
*(read only)*
```lua
Icon.totalNotifications
```
An int representing the amount of active notifications.

--------------------
### toggleMenu
*(read only)*
```lua
Icon.toggleFunction 
```
A GuiObject binded by ``Icon:setToggleMenu()``.

--------------------
### toggleFunction 
*(read only)*
```lua
Icon.toggleFunction 
```
A custom function called during ``Icon:select()`` and ``Icon:deselect()``. To change, use ``Icon:setToggleFunction()``.

--------------------
### hoverFunction 
*(read only)*
```lua
Icon.hoverFunction 
```
A custom function called when the icon is (un)highlighted. To change, use ``Icon:setHoverFunction()``.

--------------------
### deselectWhenOtherIconSelected 
```lua
Icon.toggleFunction 
```
A bool deciding whether the icon will be deselected when another icon is selected. Defaults to ``true``.