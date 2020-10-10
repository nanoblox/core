Topbar+ is a lightweight application that expands upon Roblox's topbar to give you greater control and customisability. Create additional icons and themes with ease; utilise a once underused space.

# Resources
- [Repository](https://github.com/1ForeverHD/HDAdmin/tree/master/Projects)
- [MainModule](https://www.roblox.com/library/4874365424/Topbar)
- [Playground](https://www.roblox.com/games/4871625933/Topbar)
- [Thread](https://devforum.roblox.com/t/topbar/573313)

# Collaborate
Topbar+ is an open-source project; all contributions are much appreciated. You're welcome to report bugs, suggest features and make pull requests at our repository.

# Referencing
After requiring the MainModule, Topbar+ modules can be referenced on the client under the HDAdmin directory in ReplicatedStorage.

| Location                 | Pathway            |
| :--------------     |:--------------   |
| Client       | ``ReplicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Topbar+")``   |

# Example
In a ``Script`` within ``ServerScriptService``:
```lua
require(4874365424) -- Initiate Topbar+
```

In a ``LocalScript`` within ``StarterPlayerScripts``:
```lua
-- Require the IconController
local replicatedStorage = game:GetService("ReplicatedStorage")
local topbarPlus = replicatedStorage:WaitForChild("HDAdmin"):WaitForChild("Topbar+")
local iconController = require(topbarPlus.IconController)

-- Create a shop menu
local player = game.Players.LocalPlayer
local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
local shop = Instance.new("Frame")
shop.BackgroundColor3 = Color3.fromRGB(200, 66, 0)
shop.BackgroundTransparency = 0.1
shop.BorderSizePixel = 0
shop.Name = "Shop"
shop.AnchorPoint = Vector2.new(0.5, 0.5)
shop.Position = UDim2.new(0.5, 0, 0.5, 0)
shop.Size = UDim2.new(0.25, 0, 0.6, 0)
shop.Visible = false
shop.Parent = gui
gui.Parent = player.PlayerGui

-- Create an icon called 'Shop', with image '4882429582' and order of 1
local shopIcon = iconController:createIcon("Shop", 4882429582, 1)
shopIcon:setToggleMenu(gui.Shop) -- Set the shop menu to be toggled by the icon
shopIcon:notify() -- Prompt a notification
```

!!!warning
    The topbar client (local script) has to go within StarterPlayerScripts or a ScreenGui that has ‘ResetOnSpawn’ set to false, otherwise it won’t persist when the player respawns.

!!!warning
    Likewise, if using a 'toggle menu', you must ensure its ScreenGui has ``ResetOnSpawn`` set to ``false``, or that you are calling Icon:setToggleMenu(guiObject) every time the player respawns, for the menu to persist.

----------------------------------------------

# Captions
A caption is a box that appears below the icon when highlighted on computer and console.

<a><img src="https://doy2mn9upadnk.cloudfront.net/uploads/default/optimized/4X/a/0/2/a02488b53cb7361458c9564686608342e4b615b6_2_828x452.gif" width="50%"/></a>

To apply a caption, simply do:
```lua
icon:setCaption(text)
```
To remove a caption, set its text to ``""`` or ``nil``:
```lua
icon:setCaption(nil)
```

----------------------------------------------

# Tips
A tip is a label containing a short message that appears when an icon is highlighted on computer and console.

<a><img src="https://i.ibb.co/0GszjkF/icon-tip.png" width="50%"/></a>

To apply a tip, simply do:
```lua
icon:setTip(message)
```
To remove a tip, set its message to ``""`` or ``nil``:
```lua
icon:setTip(nil)
```
To apply a specific message for controller mode, do:
```lua
icon:setControllerTip(message)
```

<a><img src="https://i.ibb.co/ZxbR9yK/icon-controller-Tip.png" width="50%"/></a>

To test controller mode on PC, simply plug-in a controller and press the console icon that pops up to the right of the topbar.

----------------------------------------------

# Dropdowns
A dropdown is a collection of 'options' that appear when an icon is right-clicked on PC or long-pressed on mobile:

<a><img src="https://i.ibb.co/2gvtccV/icon-dropdown.png" width="50%"/></a>

```lua
icon:createDropdown({
	{
		name = "About",
		icon = "rbxassetid://2746077483",
		clicked = function()
			print("Navigate to About")
		end,
		events = {}
	},
	{
		name = "Commands",
		icon = "rbxassetid://2746074974",
		clicked = function()
			icon:select()
		end,
		events = {icon.selected}
	},
	{
		name = "Roles",
		icon = "rbxassetid://2746105644",
		clicked = function()
			print("Navigate to Roles")
		end,
		events = {}
	},
	{
		name = "Settings",
		icon = "rbxassetid://2746112353",
		clicked = function()
			print("Navigate to Settings")
		end,
		events = {}
	},
})
```

For more information on creating and utilising a dropdown, see ``Icon:createDropdown()``.

----------------------------------------------

# Labels
A label is a piece of text that sits next to the icons image. 

<a><img src="https://i.imgur.com/TyDnzQg.png" width="50%"/></a>

To apply a label, simply do:
```lua
icon:setLabel(text)
```
To remove a label, set its text to ``""`` or ``nil``:
```lua
icon:setLabel(nil)
```

----------------------------------------------

# Themes
Themes are easily adaptable tables of information that can be applied to icons to enhance their appearance and behaviour.

You can break down a theme into three sections:

1. The appearance of the icon when 'selected'  (i.e. ``objectName.selected``)
2. The appearance of the icon when 'deselected'  (i.e. ``objectName.deselected``)
3. How the icon transitions between these appearances when toggled (i.e. ``toggleTweenInfo``)

An 'object' is simply a gui component that makes up the icon, such as the icons background (an ImageButton), its image (an ImageLabel), its notification background, etc. You can view the names and description of these [here](https://1foreverhd.github.io/HDAdmin/projects/topbarplus/icon/#objects).

For example, to make an icon have a blue background, we simply say 'I want the icon to look blue (i.e. ``Color3.fromRGB(0, 170, 255)``) when it's selected and deselected':

```lua
["button"] = {
    selected = {
        ImageColor3 = Color3.fromRGB(0, 170, 255),
    },
    deselected = {
        ImageColor3 = Color3.fromRGB(0, 170, 255),
    },
},
```

<a><img src="https://doy2mn9upadnk.cloudfront.net/uploads/default/original/4X/d/b/5/db58739e7ff8395d5d00b4615d0d88e5b3fc165a.png" width="30%"/></a>

If a property is not specified for a 'toggle state' (i.e. the ``selected`` and ``deselected`` dictionaries), then it's automatically filled in with the default topbar properties.

You then apply this theme by doing:
```lua
icon:setTheme(theme)
```

A theme can be applied to all icons at once by doing:
```lua
IconController:setGameTheme(theme)
```
or
```lua
local icons = IconController:getAllIcons()
for _, icon in pairs(icons) do
	icon:setTheme(theme)
end
```


For further details, visit [Icon.objects](https://1foreverhd.github.io/HDAdmin/projects/topbarplus/icon/#objects) and [Icon.theme](https://1foreverhd.github.io/HDAdmin/projects/topbarplus/icon/#theme).

Here's some examples of custom themes you can create:

----------------------------------------------

### Roblox Mimic
<details>
  <summary>View</summary>
  
```lua
local theme = {
	-- TOGGLE EFFECT
	["toggleTweenInfo"] = TweenInfo.new(0, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	
	-- OBJECT PROPERTIES
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
}
```
  
</details>

<a><img src="https://i.imgur.com/BJOC952.gif" width="100%"/></a>

----------------------------------------------



### Blue Gradient

<details>
  <summary>View</summary>
  
```lua
local selectedColor = Color3.fromRGB(0, 170, 255)
local selectedColorDarker = Color3.fromRGB(0, 120, 180)
local theme = {
	
    -- TOGGLE EFFECT
    ["toggleTweenInfo"] = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

    -- OBJECT PROPERTIES
    ["button"] = {
        selected = {
            ImageTransparency = 0.1,
            ImageColor3 = Color3.fromRGB(255, 255, 255)--selectedColor,
        },
    },
    ["image"] = {
        selected = {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        },
        deselected = {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        },
    },
    ["notification"] = {
        selected = {
            Image = "http://www.roblox.com/asset/?id=4882430005",
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        },
        deselected = {
            Image = "http://www.roblox.com/asset/?id=4882430005",
            ImageColor3 = selectedColor,

        },
    },
    ["amount"] = {
        selected = {
            TextColor3 = selectedColor,
        },
        deselected = {
            TextColor3 = Color3.fromRGB(255, 255, 255),
		},
	},
	["gradient"] = {
		selected = {
			Color = ColorSequence.new(selectedColor, selectedColorDarker),
			Rotation = 90,
        },
	},
	["label"] = {
		selected = {
			TextColor3 = Color3.fromRGB(255, 255, 255),
        },
    },
}
iconController:setGameTheme(theme)
```
  
</details>

<a><img src="https://i.ibb.co/KDhcgC1/icon-gradient-example.png" width="100%"/></a>

----------------------------------------------



### Rainbow Pop

<details>
  <summary>View</summary>
  
```lua
local function getTheme(primaryColor)
	local secondaryColor = Color3.fromRGB(255, 255, 255)
	return {
	-- TOGGLE EFFECT
	["toggleTweenInfo"] = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),

	-- OBJECT PROPERTIES
	["button"] = {
		selected = {
			Position = UDim2.new(-0.1, 0, -0.1, 0),
			Size = UDim2.new(1.2, 0, 1.2, 0),
			ImageColor3 = primaryColor,
		},
		deselected = {
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(1, 0, 1, 0),
		},
	},
	["image"] = {
		selected = {
			ImageColor3 = secondaryColor
		},
		deselected = {
			ImageColor3 = secondaryColor
		},
	},
	["notification"] = {
		selected = {
			Image = "http://www.roblox.com/asset/?id=4882430005",
			ImageColor3 = secondaryColor
		},
		deselected = {
			Image = "http://www.roblox.com/asset/?id=4882430005",
			ImageColor3 = primaryColor,
		},
	},
	["amount"] = {
		selected = {
			TextColor3 = primaryColor,
		},
		deselected = {
			TextColor3 = secondaryColor
		},
	},
}
end
```
  
</details>

<a><img src="https://i.imgur.com/FXVoIS9.gif" width="100%"/></a>

----------------------------------------------




### Mint
by [ViniDalvino](https://www.roblox.com/users/54904403/profile)

<details>
  <summary>View</summary>
  
```lua
local theme = {
    -- TOGGLE EFFECT
    ["toggleTweenInfo"] = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),

    -- OBJECT PROPERTIES
    ["button"] = {
        selected = {
            ImageTransparency = 0.35,
            ImageColor3 = Color3.fromRGB(0, 255, 200),
        },
        deselected = {
            ImageTransparency = 0.35,
			ImageColor3 = Color3.fromRGB(15,15,15)
        },
    },
    ["image"] = {
        selected = {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        },
        deselected = {
            ImageColor3 = Color3.fromRGB(255, 255, 255),
        },
    },
    ["notification"] = {
        selected = {
            Image = "http://www.roblox.com/asset/?id=4882430005",
			ImageColor3 = Color3.fromRGB(70, 133, 107),
        },
        deselected = {
            Image = "http://www.roblox.com/asset/?id=4882430005",
            ImageColor3 = Color3.fromRGB(55, 145, 103),

        },
    },
    ["amount"] = {
        selected = {
            TextColor3 = Color3.fromRGB(255,255,255),
        },
        deselected = {
            TextColor3 = Color3.fromRGB(255, 255, 255),
        },
    },
}
```
  
</details>

<a><img src="https://i.imgur.com/zTf9IFa.png" width="100%"/></a>