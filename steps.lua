return function(Game)
function Game:STEP_READY()
  -- TODO: Expire effects.
  local state = self.derived_state
  local player_idx = self.active_player
  for k,v in pairs(state.field) do
  	if v.disabled then
  	  self.field[k].disabled = nil
  	elseif not v.ready then
  	  self.field[k].ready = true
  	  print("Marking "..k.." as ready!")
  	end
  end

  self.next_steps:push("STEP_UPKEEP")
end


function Game:STEP_UPKEEP()
  -- TODO: Expire effects.
  -- TODO: Upkeep triggers lol!
  local player = self.players[self.active_player]

  -- TODO: Slow time generator
  player:gain_gold(player.workers)
  self.next_steps:push("STEP_MAIN")
end

function Game:STEP_MAIN()
  self.low_priority_triggers:push("MAIN_PROMPT")
  self.low_priority_triggers:push("MAIN_ACT")
end

function Game:STEP_END()
end
end