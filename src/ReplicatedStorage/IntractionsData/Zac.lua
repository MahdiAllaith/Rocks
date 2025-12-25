local Dialog = {
	NPC = "Fuckerrrrrr",

	-- Default/initial NPC greeting
	npcText = function(player)
		if player then
			return "Back again, traveler? Looking for supplies or gossip?"
		else
			return "Well now! A fresh face. Welcome to my corner of the market!"
		end
	end,

	-- Root-level options
	options = {
		{
			id = "opt_greeting",
			text = function(player)
				return player and "How's business today?" or "Who are you?"
			end,
			next = "node_intro"
		},

		{
			id = "opt_buy",
			text = "Show me what you're selling.",
			next = "node_openShop"
		},

		{
			id = "opt_rumors",
			text = "Heard any rumors lately?",
			next = "node_rumors"
		},

		{
			id = "opt_exit",
			text = "Goodbye.",
			next = "node_exit"
		},
	},

	-- Dialog nodes
	nodes = {

		---------------------------------------------------
		-- INTRO (branching)
		---------------------------------------------------
		node_intro = {
			npcText = "I'm Marra, merchant of goods both legal and... less inspected.",
			options = {
				{ id = "intro_1", text = "What do you sell?", next = "node_openShop" },
				{ id = "intro_2", text = "Less inspected?", next = "node_shady" },
				{ id = "intro_3", text = "Nice to meet you.", next = "node_exit" },
			}
		},


		---------------------------------------------------
		-- RUMORS
		---------------------------------------------------
		node_rumors = {
			npcText = "Rumors? Oh plenty! But information has a price.",
			options = {
				{
					id = "rumor_pay",
					text = "Fine, tell me one.",
					next = "node_rumorDetail"
				},
				{
					id = "rumor_nevermind",
					text = "Never mind then.",
					next = "node_exit"
				},
			}
		},

		node_rumorDetail = {
			npcText = "People say a strange glowing beast has been seen near the cliffs at night.",
			options = {
				{
					id = "rumor_exit",
					text = "Interesting.",
					next = "node_exit"
				}
			}
		},


		---------------------------------------------------
		-- SHADY GOODS
		---------------------------------------------------
		node_shady = {
			npcText = "Hey, don't look at me like that. Everyone has hobbies.",
			options = {
				{
					id = "shady_1",
					text = "I want to see your 'hobby' items.",
					next = "node_openShop"
				},
				{
					id = "shady_2",
					text = "I'm just browsing.",
					next = "node_exit"
				}
			}
		},


		---------------------------------------------------
		-- SHOP UI NODE (CALLBACK)
		---------------------------------------------------
		node_openShop = {
			npcText = "Take a look. Finest goods this side of the desert.",
			options = {
				{
					id = "open_shop",
					text = "Open Shop",
					onSelect = function(player)
						-- This is where your shop GUI opens
						local ui = player:FindFirstChild("PlayerGui"):FindFirstChild("ShopUI")
						if ui then
							ui.Enabled = true
						end
					end,
					next = "node_exit"
				}
			}
		},


		---------------------------------------------------
		-- EXIT NODE (SHARED CALLBACK)
		---------------------------------------------------
		node_exit = {
			npcText = "Safe travels, friend.",
			options = {
				{
					id = "exit_final",
					text = "Goodbye.",
					onExit = function(player)
						-- This runs when the player leaves the conversation
						player = true
					end,
					next = nil
				}
			}
		}
	}
}

return Dialog
