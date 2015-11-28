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
    self.patrol = {}
    self.future = {}
    self.workers = 4
    if self.idx > 1 then
      self.workers = 5
    end
    self.base_hp = 20
    self.id_to_next_uid = {}
    for _,spec in ipairs(specs) do
      assert(spec_to_color[spec], spec .. " is not a spec")
      for id, card in pairs(id_to_card) do
        if card.spec == spec then
          if card.starting_zone == "codex" then
            self.codex[#self.codex+1] = self:make_card(id)
            self.codex[#self.codex+1] = self:make_card(id)
          elseif card.starting_zone == "command" then
            self.command[#self.command+1] = {uid=self:make_card(id), cooldown=0}
          end
        end
      end
    end
    local main_color = spec_to_color[main_spec]
    for id, card in pairs(id_to_card) do
      if card.color == main_color and card.starting_zone == "deck" then
        self.discard[#self.discard+1] = self:make_card(id)
      end
    end
    for k,v in pairs(self.id_to_next_uid) do
      self.id_to_next_uid[k] = nil
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
    self.next_timestamp = 1
    self.players = {Player(specs1, 1, self), Player(specs2, 2, self)}
    self.field = {}
    self.extra_turns = 0
    self.next_actions = Queue()
    self.next_steps = Queue()
    self.active_player = 0
    self:start_turn(1)
  end)

function Player:make_card(card_id)
  local this_uid = self.id_to_next_uid[card_id] or 1
  local this_uid_str = this_uid .. ""
  if card_id[2] == "T" then
    while #this_uid_str < 5 do
      this_uid_str = "0" .. this_uid_str
    end
  end
  self.id_to_next_uid[card_id] = this_uid + 1
  return card_id .. self.idx .. this_uid_str
end

function Game:get_timestamp()
  local ret = self.next_timestamp .. ""
  while #ret < 6 do
    ret = "0" .. ret
  end
  self.next_timestamp = self.next_timestamp + 1
  return "TS" .. ret
end

function Game:start_turn(idx)
  self.active_player = idx
  self.next_steps:push("STEP_UPKEEP")
end

-- Just takes the internal state of a card and adds
-- The stuff you would get by reading the card.
-- Doesn't apply ongoing effects or w/e.
local function get_basic_card_state(card)
  local ret = {}
  if type(card) == "string" then
    ret = {uid = card}
  else
    for k,v in pairs(card) do
      ret[k] = v
    end
  end
  local card_id = ret.uid:sub(1, 6)
  local orig_card = id_to_card[card_id]

  ret.type = orig_card.type
  ret.ATK = orig_card.ATK
  ret.HP = orig_card.HP
  ret.color = orig_card.color
  ret.cost = orig_card.cost
  ret.name = orig_card.name
  ret.spec = orig_card.spec
  ret.tech_level = orig_card.tech_level

  if orig_card.subtypes then
    ret.subtypes = {}
    for k,v in ipairs(orig_card.subtypes) do
      ret.subtypes[k] = v
    end
  end

  ret.abilities = deepcpy(orig_card.abilities or {})

  if orig_card.type == "hero" then
    ret.mid_level = orig_card.mid_level
    ret.max_level = orig_card.max_level
    ret.ATK_1 = orig_card.ATK_1
    ret.ATK_2 = orig_card.ATK_2
    ret.ATK_3 = orig_card.ATK_3
    ret.HP_1 = orig_card.HP_1
    ret.HP_2 = orig_card.HP_2
    ret.HP_3 = orig_card.HP_3

    ret.level = ret.level or 1
    ret.ATK = ret.ATK_1
    ret.HP = ret.HP_1

    if ret.level >= ret.mid_level then
      ret.ATK = ret.ATK_2
      ret.HP = ret.HP_2
      for _,ability in ipairs(orig_card.mid_abilities) do
        ret.abilities[#ret.abilities+1] = deepcpy(ability)
      end
    end

    if ret.level >= ret.max_level then
      ret.ATK = ret.ATK_3
      ret.HP = ret.HP_3
      for _,ability in ipairs(orig_card.max_abilities) do
        ret.abilities[#ret.abilities+1] = deepcpy(ability)
      end
    end
  end

  return ret
end

function Game:get_derived_state()
  -- Get the derived state of the game
  -- That's the state after applying ongoing effects and stuff
  local ret = {}
  ret.players = {}
  for i=1,#self.players do
    ret.players[i] = {}
    for _,zone in ipairs({"codex", "discard", "deck", "hand", "command", "future"}) do
      ret.players[i][zone] = {}
      for j=1,#self.players[i][zone] do
        ret.players[i][zone][j] = get_basic_card_state(self.players[i][zone][j])
      end
    end
  end
  ret.field = {}
  for i=1,#self.field do
    ret.field[i] = get_basic_card_state(self.field[i])
  end
  return ret
end

function Game:update()

  -- 
end

print(json.encode(Game({"bashing"},{"finesse"}):get_derived_state()))
