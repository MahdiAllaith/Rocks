local Dialog = {
	NPC = "Zac",

	-- Default/initial NPC greeting
	npcText = function(player)
		if player then
			return "Back again, peasant? Fell off already?"
		else
			return "Ah. A new peasant. Try not to disappoint."
		end
	end,

	-- Root-level options
	options = {
		{
			id = "opt_intro",
			text = function(player)
				return player and "What do you even do?" or "Who are you?"
			end,
			next = "node_intro"
		},

		{
			id = "opt_teleport",
			text = "Send me to the Grand Challenge.",
			onSelect = function(player)
				local ReplicatedStorage = game:GetService("ReplicatedStorage")
				local EventManagerService = require(ReplicatedStorage.Services["EventManager-Service"])
				EventManagerService.StartGrandChallange()
			end,
			next = nil
		},

		{
			id = "opt_why",
			text = "Why are you the teleporter?",
			next = "node_why_zac"
		},

		{
			id = "opt_exit",
			text = "I'm leaving.",
			next = "node_exit"
		},
	},

	nodes = {

		---------------------------------------------------
		-- INTRO
		---------------------------------------------------
		node_intro = {
			npcText = "Zac. Magician. I send peasants to fail the Challenge.",
			options = {
				{ id = "intro_1", text = "You control the teleport?", next = "node_teleport_explain" },
				{ id = "intro_2", text = "How did you get this job?", next = "node_how_position" },
				{ id = "intro_3", text = "Figures.", next = "node_exit" },
			}
		},

		---------------------------------------------------
		-- WHY ZAC
		---------------------------------------------------
		node_why_zac = {
			npcText = "Because teleporting peasants safely takes skill.",
			options = {
				{ id = "why_1", text = "You're the best?", next = "node_best" },
				{ id = "why_2", text = "What if it fails?", next = "node_wrong" },
			}
		},

		node_best = {
			npcText = "Not the best. Just the only survivor.",
			options = {
				{ id = "best_exit", text = "Good to know.", next = "node_exit" }
			}
		},

		node_wrong = {
			npcText = "Then you vanish. Briefly painful.",
			options = {
				{ id = "wrong_exit", text = "Comforting.", next = "node_exit" }
			}
		},

		---------------------------------------------------
		-- HOW HE GOT THE POSITION
		---------------------------------------------------
		node_how_position = {
			npcText = "I beat the Challenge. Now I guard it.",
			options = {
				{ id = "position_1", text = "You completed it?", next = "node_completed" },
				{ id = "position_2", text = "That sounds awful.", next = "node_unfair" },
			}
		},

		node_completed = {
			npcText = "Yes. Unlike most peasants.",
			options = {
				{ id = "completed_exit", text = "We'll see.", next = "node_exit" }
			}
		},

		node_unfair = {
			npcText = "Life is unfair. Step on the rune.",
			options = {
				{ id = "unfair_exit", text = "Fine.", next = "node_exit" }
			}
		},

		---------------------------------------------------
		-- TELEPORT
		---------------------------------------------------
		node_teleport_explain = {
			npcText = "Ready to fail again, peasant?",
			options = {
				{
					id = "teleport_now",
					text = "Send me.",
					onSelect = function(player)
						local ReplicatedStorage = game:GetService("ReplicatedStorage")
						local EventManagerService = require(ReplicatedStorage.Services["EventManager-Service"])
						EventManagerService.StartGrandChallange()
					end,
					next = nil
				},
				{ id = "teleport_later", text = "Not yet.", next = "node_exit" }
			}
		},

		---------------------------------------------------
		-- EXIT
		---------------------------------------------------
		node_exit = {
			npcText = "Come back when you’re ready to lose.",
			options = {
				{
					id = "exit_final",
					text = "Goodbye.",
					onExit = function(player)
						player = true
					end,
					next = nil
				}
			}
		}
	}
}

return Dialog
