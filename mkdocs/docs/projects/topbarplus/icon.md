# Properties

--------------------
### objects
```lua
Icon.objects
```
A dictionary of Instances that make up the Icon.



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
A dictionary describing the Icons theme. Set using the ``Icon:setTheme()`` method.

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
A string describing the toggle status: "selected" or "deselected". Set using the ``Icon:select()`` and ``Icon:deselect()`` methods.

--------------------
### name
*(read only)*
```lua
Icon.name
```
The Icon creation name.

--------------------
### imageId
*(read only)*
```lua
Icon.imageId
```
The Icons imageId. Set using the ``Icon:setImage()`` method.

--------------------
### imageScale
*(read only)*
```lua
Icon.imageScale
```
The scale of the Icon image. A value between 0 and 1. Set using the ``Icon:setImageScale()`` method.

--------------------
### order
*(read only)*
```lua
Icon.order
```
The Icons order. This determines whether the Icon comes before or after other Icons. Set using the ``Icon:setOrder()`` method.

--------------------
### enabled
*(read only)*
```lua
Icon.order
```
A bool describing whether the icon is enabled or not. Set using the ``Icon:setEnabled()`` method.

--------------------
### totalNotifications
*(read only)*
```lua
Icon.totalNotifications
```
An integer representing the amount of active notifications.

--------------------
### toggleFunction 
*(read only)*
```lua
Icon.toggleFunction 
```
A custom function called during ``Icon:select()`` and ``Icon:deselect()``. Set using the ``Icon:setToggleFunction()`` method.

--------------------
### deselectWhenOtherIconSelected 
```lua
Icon.toggleFunction 
```
A bool deciding whether the icon will be deselected when another icon is selected.


<br>


# Events
--------------------
### updated
```lua
Icon.updated
```
Fired when the Icon causes a position shift of other icons.
```lua
Icon.updated:Connect(function())

end)
```

--------------------
### selected
```lua
Icon.selected
```
Fired when the Icon is selected.
```lua
Icon.selected:Connect(function())

end)
```

--------------------
### deselected
```lua
Icon.deselected
```
Fired when the Icon is deselected.
```lua
Icon.deselected:Connect(function())

end)
```

--------------------
### endNotifications
```lua
Icon.endNotifications
```
Fired when the Icons notifcations are cleared.
```lua
Icon.endNotifications:Connect(function())

end)
```


<br>


# Methods
--------------------
### setImage
```lua
Icon:setImage(imageId)
```
Sets the icons image.

--------------------
### setOrder
```lua
Icon:setOrder(order)
```
Sets the icons priority order, determining whether it will appear before or after other icons.

--------------------
### setImageScale
```lua
Icon:setImageScale(scale)
```
Sets the scale of the image based on a value between 0 and 1.

--------------------
### setEnabled
```lua
Icon:setEnabled(bool)
```
Sets the Icons visibility.

--------------------
### setToggleFunction
```lua
Icon:setToggleFunction(toggleFunction)
```
Sets a function that is called every time the Icon is selected and deslected.

--------------------
### setTheme
```lua
Icon:setTheme(themeDetails)
```
Applies the specified theme to the Icon. See ``Icon.theme`` for details on creating a theme.

--------------------
### select
```lua
Icon:select()
```
Selects the Icon.

--------------------
### deselect
```lua
Icon:deselect()
```
Deselects the Icon.

--------------------
### notify
```lua
Icon:notify(clearNoticeEvent)
```
Prompts a notification that appears in the top-right corner of the Icon. Specifiy ``clearNoticeEvent`` with an event to determine when to end the notifcation. If not specified, ``clearNoticeEvent`` defaults to ``Icon.deselected``.

--------------------
### clearNotifications
```lua
Icon:clearNotifications()
```
Clears the Icons notifications.

--------------------
### destroy
```lua
Icon:destroy()
```
Destroys all objects and events associcated with the Icon.

--------------------