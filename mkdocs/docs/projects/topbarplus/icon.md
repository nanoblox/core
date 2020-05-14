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
### setToggleMenu
```lua
Icon:setToggleMenu(guiObject)
```
Binds the GuiObject so that its visibility is toggled on and off accordingly when ``Icon:select()`` and ``Icon:deselect()`` are called (i.e. when the icon is selected and deselected).

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
Sets a function that is called when the icon is (un)highlighted
!!! warning
    This method is likely to change. It's recommended not to use for the time being.

--------------------
### setTheme
```lua
Icon:setTheme(themeDetails)
```
Applies the specified theme to the icon. See ``Icon.theme`` for details on creating a theme.

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
Icon.updated:Connect(function())

end)
```

--------------------
### selected
```lua
Icon.selected
```
Fired when the icon is selected.
```lua
Icon.selected:Connect(function())

end)
```

--------------------
### deselected
```lua
Icon.deselected
```
Fired when the icon is deselected.
```lua
Icon.deselected:Connect(function())

end)
```

--------------------
### endNotifications
```lua
Icon.endNotifications
```
Fired when the icons notifcations are cleared.
```lua
Icon.endNotifications:Connect(function())

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
}
```



--------------------
### toggleStatus
*(read only)*
```lua
Icon.toggleStatus
```
A string describing the toggle status: "selected" or "deselected". To change, use ``Icon:select()`` and ``Icon:deselect()``.

--------------------
### name
*(read only)*
```lua
Icon.name
```
The icon creation name.

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