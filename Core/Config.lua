--[[

To modify Roles, Bans, Commands and Settings, it's recommended to do so:
   1. In-game, via the Manage panel, which provides an easy-to-use interface to modify Config.
   2. Using the HD Admin Plugin, which provides a similar interface to change Config, *and*
      syncs in-game data with this Config module. This enables you to transfer HD Admin between
      games while retaining your modifications.
      
Plugin link: 

--]]

return {

	
	
	Roles = {
		---------------------------
		["FmELlZ2YaD"] = {
			_order = 1,
			name = "Owner",
			color = Color3.fromRGB(255, 0, 0),
			giveToCreator = true,
			inheritCommandsWithTags = {"_level5"},
			limitCommandsPerInterval = false,
			limitGlobalExecutionsPerInterval = false,
			limitScale = false,
			limitGear = false,
			canBlockAll = true,
			canUseAll = true,
			canViewAll = true,
			canEditAll = true,
		},
		
		---------------------------
		["ueRXqVqe3t"] = {
			_order = 2,
			name = "Manager",
			color = Color3.fromRGB(255, 85, 0),
			inheritCommandsWithTags = {"_level4"},
			limitCommandsPerInterval = false,
			limitScale = false,
			limitGear = false,
			canBlockAll = true,
			canUseAll = true,
			canViewAll = true,
			canEditLongtermUsers = true,
			canEditBans = true,
			canEditWarnings = true,
			
		},
		
		---------------------------
		["CPVAjVKg4U"] = {
			_order = 3,
			name = "Head Admin",
			color = Color3.fromRGB(255, 0, 255),
			inheritCommandsWithTags = {"_level3"},
			commandsLimit = 200,
			scaleLimit = 100,
			canUseCmdbar1 = true,
			canUseCmdbar2 = true,
			canUseGlobalModifier = true,
			globalRefreshInterval = 60,
			globalsLimit = 1,
			canUseLoopModifier = true,
		},
		
		---------------------------
		["rc9idowbgu"] = {
			_order = 4,
			name = "Admin",
			color = Color3.fromRGB(255, 0, 255),
			inheritCommandsWithTags = {"_level3"},
			commandsLimit = 200,
			scaleLimit = 100,
			canUseCmdbar1 = true,
			canUseCmdbar2 = true,
			canUseGlobalModifier = false,
			canUseLoopModifier = true,
		},
		
		---------------------------
		["U0jS1tKiBf"] = {
			_order = 5,
			name = "Mod",
			color = Color3.fromRGB(0, 170, 255),
			inheritCommandsWithTags = {"_level2"},
			scaleLimit = 20,
			canUseCmdbar1 = true,
		},
		
		---------------------------
		["lazD41IMUu"] = {
			_order = 6,
			name = "Basic",
			color = Color3.fromRGB(0, 170, 85),
			inheritCommandsWithTags = {"_level1"},
			canUseCommandsOnOthers = false,
		},
		---------------------------
		["IF9jL5UoJZ"] = {
			_order = 7,
			name = "Player",
			color = Color3.fromRGB(175, 175, 175),
			nonadmin = true,
			inheritCommandsWithTags = {"_level0"},
			canUseCommandsOnOthers = false,
			canUseCommandsOnFriends = false,
			promptWelcomeRankNotice = false,
		},
		
		---------------------------
	},
	
	
	Bans = {
		---------------------------
		["0001"] = {
			reason = "Putting pineapple on pizza test",
		},
		
		---------------------------
		["0002"] = {
			reason = "Used facebook as a verb",
		},
		
		---------------------------
		["0003"] = {
			reason = "Test",
		},
		
		---------------------------
	},--]]
	
	
	
	Commands = {
		---------------------------
		["fly"] = {
			aliases = {},
			desc = "",
		},
		
		---------------------------
	},
	
	
	
	Settings = {
		---------------------------
		["Client"] = {
			prefixes = {","},
			argCapsule = "(%s)",
			rgbCapsule = "[%s]",
			collective = ",",
			descriptorSeparator = "",
			spaceSeparator = " ",
			batchSeparator = " ", -- " | "
			--
			previewIncompleteCommands = false,
			--
			theme = "",
			backgroundTransparency 	= 0.1,
			noticeSoundId = 2865227271,	-- The SoundId for notices.
			noticeVolume = 0.1,			-- The Volume for notices.
			noticePitch = 1,			-- The Pitch/PlaybackSpeed for notices.
			errorSoundId = 2865228021,	-- The SoundId for error notifications.
			errorVolume = 0.1,			-- The Volume for error notifications.
			errorPitch = 1,			-- The Pitch/PlaybackSpeed for error notifications.
			alertSoundId = 3140355872,	-- The SoundId for alerts.
			alertVolume = 0.5,			-- The Volume for alerts.
			alertPitch = 1,			-- The Pitch/PlaybackSpeed for alerts.
		},
		
		
		---------------------------
		["System"] = {
			-- Gear
			restrictedGear = {},
			
			-- Warning System
			warnExpiryTime = 604800, -- 1 week
			kickUsers = true,
			warnsToKick = 3,
			serverBanUsers = true,
			warnsToServerBan = 4,
			serverBanTime = 7200, -- 2 hours
			globalBanUsers = true,
			warnsToGlobalBan = 5,
			globalBanTime = 172800, -- 2 days
		}
		
		
		---------------------------
		-- These are old settings, new ones coming soon
		--[[
		
		
		["System"] = {
			Colors = {							-- The colours for ChatColors and command arguments. | Format: {"ShortName", "FullName", Color3Value},
				{"r", 		"Red",		 		Color3.fromRGB(255, 0, 0)		},
				{"o", 		"Orange",	 		Color3.fromRGB(250, 100, 0)		},
				{"y", 		"Yellow",			Color3.fromRGB(255, 255, 0)		},
				{"g", 		"Green"	,			Color3.fromRGB(0, 255, 0)		},
				{"dg", 		"DarkGreen"	, 		Color3.fromRGB(0, 125, 0)		},
				{"b", 		"Blue",		 		Color3.fromRGB(0, 255, 255)		},
				{"db", 		"DarkBlue",			Color3.fromRGB(0, 50, 255)		},
				{"p", 		"Purple",	 		Color3.fromRGB(150, 0, 255)		},
				{"pk",		"Pink",		 		Color3.fromRGB(255, 85, 185)	},
				{"bk",		"Black",		 	Color3.fromRGB(0, 0, 0)			},
				{"w",		"White",	 		Color3.fromRGB(255, 255, 255)	},
			},
			--
			ThemeColors = {						-- The colours players can set their HD Admin UI (in the 'Settings' menu). | Format: {ThemeName, ThemeColor3Value},
				{"Red", 	Color3.fromRGB(150, 0, 0),		},
				{"Orange", 	Color3.fromRGB(150, 75, 0),		},
				{"Brown", 	Color3.fromRGB(120, 80, 30),	},
				{"Yellow", 	Color3.fromRGB(130, 120, 0),	},
				{"Green", 	Color3.fromRGB(0, 120, 0),		},
				{"Blue", 	Color3.fromRGB(0, 100, 150),	},
				{"Purple", 	Color3.fromRGB(100, 0, 150),	},
				{"Pink",	Color3.fromRGB(150, 0, 100),	},
				{"Black", 	Color3.fromRGB(60, 60, 60),		},
			},
			--
			Cmdbar						= 1,			-- The minimum rank required to use the Cmdbar.
			Cmdbar2						= 3,			-- The minimum rank required to use the Cmdbar2.
			ViewBanland					= 3,			-- The minimum rank required to view the banland.
			OnlyShowUsableCommands		= false,		-- Only display commands equal to or below the user's rank on the Commands page.
			RankRequiredToViewPage		= {				-- || The pages on the main menu ||
				["Commands"]		= 0,
				["Admin"]			= 0,
				["Settings"]		= 0,
			},
			RankRequiredToViewRank		= {				-- || The rank categories on the 'Ranks' subPage under Admin ||
				["Owner"]			= 0,
				["HeadAdmin"]		= 0,
				["Admin"]			= 0,
				["Mod"]				= 0,
				["VIP"]				= 0,
			},
			RankRequiredToViewRankType	= {				-- || The collection of loader-rank-rewarders on the 'Ranks' subPage under Admin ||
				["Owner"]			= 0,
				["SpecificUsers"]	= 5,
				["Gamepasses"] 		= 0,
				["Assets"] 			= 0,
				["Groups"] 			= 0,
				["Friends"] 		= 0,
				["FreeAdmin"] 		= 0,
				["VipServerOwner"] 	= 0,
			},
			--
			WelcomeRankNotice			= true,			-- The 'You're a [rankName]' notice that appears when you join the game. Set to false to disable.
			WelcomeDonorNotice			= true,			-- The 'You're a Donor' notice that appears when you join the game. Set to false to disable.
			WarnIncorrectPrefix			= true,			-- Warn the user if using the wrong prefix | "Invalid prefix! Try using [correctPrefix][commandName] instead!"
			DisableAllNotices			= false,		-- Set to true to disable all HD Admin notices.
			--
			ScaleLimit					= 4,			-- The maximum size players with a rank lower than 'IgnoreScaleLimit' can scale theirself. For example, players will be limited to ,size me 4 (if limit is 4) - any number above is blocked.
			IgnoreScaleLimit			= 3,			-- Any ranks equal or above this value will ignore 'ScaleLimit'
			--
			VIPServerCommandBlacklist	= {"permRank", "permBan", "globalAnnouncement"},	-- Commands players are probihited from using in VIP Servers.
			GearBlacklist				= {67798397},	-- The IDs of gear items to block when using the ,gear command.
			IgnoreGearBlacklist			= 4,			-- The minimum rank required to ignore the gear blacklist.
			--
			PlayerDataStoreVersion		= "V1.0",		-- Data about the player (i.e. permRanks, custom settings, etc). Changing the Version name will reset all PlayerData.
			SystemDataStoreVersion		= "V1.0",		-- Data about the game (i.e. the banland, universal message system, etc). Changing the Version name will reset all SystemData.
			--
			CoreNotices					= {				-- Modify core notices. You can find a table of all CoreNotices under [MainModule > Client > SharedModules > CoreNotices]
				--NoticeName = NoticeDetails,
				
			}
		}--]]
		
		
	},
	
	
	
}