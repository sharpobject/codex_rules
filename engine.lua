require("cards")
require("class")

Player = class(function(self, specs)
    local main_spec = specs[1]
    assert(main_spec, "No specs provided")
    self.codex = {}
    self.discard = {}
    self.deck = {}
    self.hand = {}
    self.command = {}
    self.field = {}
    self.patrol = {}
    self.future = {}
    self.trash = {}
    self.workers = 4
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
    if #self.deck == 0 then
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

print(json.encode(Player({"Bashing", "Finesse"})))
