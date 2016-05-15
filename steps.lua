return function(Game)
function Game:STEP_READY(self)
  -- TODO: Expire effects.
  -- TODO: Upkeep triggers lol!
  local player = self.players[self.active_player]
end


function Game:STEP_UPKEEP(self)
  -- TODO: Expire effects.
  -- TODO: Upkeep triggers lol!
  local player = self.players[self.active_player]

  -- TODO: Slow time generator
  player.gold = player.gold + player.workers
end
end