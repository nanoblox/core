# Methods

--------------------
### createIcon
```lua
IconController:createIcon(name, imageId, order)
```
Creates, stores and returns an icon, where ``name`` is a unique string identifying the icon, ``imageId`` an int representing the icons image, and ``order``, a number defining how the icon should be positioned in relation to neighbouring icons, greater values being shifted rightward.

--------------------
### createFakeChat
```lua
IconController:createFakeChat(theme)
```
Disables the default core chat icon, and creates and returns a new icon imitating it. The icon can be enabled and disabled by doing ``icon:setEnabled(bool)`` *or* ``StarterGui:SetCoreGuiEnabled("Chat", bool)``.

--------------------
### removeFakeChat
```lua
IconController:removeFakeChat()
```
Destroys and removes references of the fake chat icon.

--------------------
### setTopbarEnabled
```lua
IconController:setTopbarEnabled(bool)
```
When set to false, hides all icons created with Topbar+. This can also be achieved by doing ``StarterGui:SetCore("TopbarEnabled", bool)``.

--------------------
### setGameTheme
```lua
IconController:setGameTheme(theme)
```
Sets the default theme which is applied to all existing and future icons.

--------------------
### setDisplayOrder
```lua
IconController:setDisplayOrder(int)
```
Changes the DisplayOrder of the Topbar+ ScreenGui to the given value.

--------------------
### getIcon
```lua
IconController:getIcon(name)
```
Returns an icon of the corresponding name.

--------------------
### getAllIcons
```lua
IconController:getAllIcons()
```
Returns an array containing every icon.

--------------------
### removeIcon
```lua
IconController:removeIcon(name)
```
Destroys and removes references of the corresponding icon.
