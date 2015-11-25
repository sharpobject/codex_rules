require("cards")
require("class")
require("queue")

Player = class(function(self, specs, idx)
    local main_spec = specs[1]
    assert(main_spec, "No specs provided")
    self.idx = idx
    self.codex = {}
    self.discard = {}
    self.deck = {}
    self.hand = {}
    self.command = {}
    self.field = {}
    self.patrol = {}
    self.future = {}
    self.workers = 4
    if self.idx > 1 then
      self.workers = 5
    end
    self.base_hp = 20
    for _,spec in ipairs(specs) do
      assert(spec_to_color[spec], spec .. " is not a spec")
      for id, card in pairs(id_to_card) do
        if card.spec == spec then
          if card.starting_zone == "codex" then
            self.codex[id] = (self.codex[id] or 0) + 2
          elseif card.starting_zone == "command" then
            self.command[#self.command+1] = {id=id, cooldown=0}
          end
        end
      end
    end
    local main_color = spec_to_color[main_spec]
    for id, card in pairs(id_to_card) do
      if card.color == main_color and card.starting_zone == "deck" then
        self.discard[#self.discard+1] = id
      end
    end
    self:draw(5)
  end)

function Player:draw(n)
  n = n or 1
  for i=1,n do
    if #self.deck == 0 and #self.discard > 0 then
      if self.remaining_reshuffles == nil then
        self.deck, self.discard = self.discard, self.deck
        shuffle(self.deck)
      elseif self.remaining_reshuffles > 0 then
        self.deck, self.discard = self.discard, self.deck
        shuffle(self.deck)
        self.remaining_reshuffles = self.remaining_reshuffles - 1
      end
    end
    if #self.deck > 0 then
      local card = self.deck[#self.deck]
      self.deck[#self.deck] = nil
      self.hand[#self.hand+1] = card
    end
  end
end

Game = class(function(self, specs1, specs2)
    self.players = {Player(specs1, 1), Player(specs2, 2)}
    self.extra_turns = 0
    self.next_actions = Queue()
    self.next_steps = Queue()
    self.active_player = 0
    self:start_turn(1)
  end)

function Game:start_turn(idx)
  self.active_player = idx
  self.next_steps:push("STEP_UPKEEP")
end

function Game:get_derived_state()
  -- Get the derived state of the game
  -- That's the state after applying ongoing effects and stuff
  
end

function Game:update()

  -- 
end

print(json.encode(Game({"Bashing"},{"Finesse"})))
