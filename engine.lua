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
    self.players = {Player(specs1, 1), Player(specs2, 2)}
    self.field = {}
    for idx, player in ipairs(self.players) do
      self:to_field(player:make_card("NBABBA"))
    end
    self.extra_turns = 0
    self.high_priority_triggers = Queue()
    self.triggers = Queue()
    self.low_priority_triggers = Queue()
    self.next_steps = Queue()
    self.active_player = 0
    self:start_turn(1)
  end)

function Player:make_card(card_id)
  local this_uid = self.id_to_next_uid[card_id] or 1
  local this_uid_str = this_uid .. ""
  if card_id:sub(2,3) == "TO" then
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

local function get_card_owner(card_uid)
  return tonumber(card_uid[7])
end

function Game:to_field(card)
  if type(card) == "string" then
    card = {uid = card}
  end
  if not card.controller then
    card.controller = get_card_owner(card)
  end
  self.field[#self.field+1] = card
end

-- Just takes the internal state of a card and adds
-- The stuff you would get by reading the card.
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

  ret.subtypes = deepcpy(orig_card.subtypes)
  ret.abilities = deepcpy(orig_card.abilities) or {}

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
    end

    if ret.level >= ret.max_level then
      ret.ATK = ret.ATK_3
      ret.HP = ret.HP_3
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

  -- TODO: apply +1/+1 counters, -1/-1 counters,
  -- TODO: apply ongoing effects like two step
  -- TODO: have a working game

  return ret
end

local function get_state_based_actions(state)
  --[[
    Only the first section that has any actions gets its actions run.

    This makes deaths that should be simultaneous simultaneous when you
    cast Sickness targeting Doubling Barbarbarian with a +1/+1 rune
    and some other thing...

    It also ruins killing undying units with Sickness, but undying
    is not an ability in Codex.

    MtG has some sections we don't have but could:
      - The legend rule in Codex does not allow two of the same Legend to
        ever be under a player's control, so we don't need it here.
        TODO: Make sure that's true with e.g. feral strike for 2x degrey
      - Update: We DO need a legend rule here, because the expiration of a
        copy effect could also cause a player to have 2 of the same legend.
        So that sucks.
      - The rule about auras not attached to things dying will probably be
        handled by an action on the expiration of the effect that binds
        an aura to a thing.
  --]]


  -- TODO
  -- If a permanent is in play, ensure that it has an "arrived" timestamp,
  -- a "came under control" timestamp, a "established identity" timestamp,
  -- and for heroes mid level or higher, also timestamps for their mid and
  -- max level abilities.
  -- If the controller changed, the identity changed, or the hero leveled
  -- down, update those timestamps appropriately.
  for k,v in pairs(state.field) do
    
  end


  -- TODO
  -- If a player has two or more of the same Legendary permanent,
  -- all but one are trashed. The one that survives is the one that
  -- has had that identity for the longest time.
  -- So every permanent has to keep track of its last known identity
  -- and how long it has had that.
  -- (actually, only UNITS can copy things, so maybe all this stuff
  -- is just for Legendary Units)


  -- TODO
  -- If a token is in any zone other than in play, it is trashed.


  -- TODO
  -- If a player has no base, the game is over.
  -- Note that some other abilities can cause the game to end,
  -- So this isn't the only place where game over happens.


  -- TODO
  -- If an effect says it should expire, it expires.
  -- Some effects do stuff when they expire (other than just stop applying).
  -- Effects that granted armor take armor away on expiration.
  -- Aura effects (like Soul Stone) kill the attached spell card on expiration.


  -- TODO
  -- If a unit or hero has both +1/+1 and -1/-1 runes, they cancel


  -- TODO
  --[[
    If a unit or hero or building has damage marked on it greater than or
      equal to its HP, it dies.
    If a unit or hero has just taken damage from a thing that has deathtouch,
      it dies.
    The following two things apply to deaths in general, but we have to
      do them here to make sure we don't make no-op state based actions.
      (that would cause an infinite loop)
    If it has the Glaxx ability and its controller has gold and
      it has not just taken combat damage, it doesn't die.
    If it is indestructible and has 0 or less HP and is already tapped,
      and has no damage, nothing happens.

    Here are some other things that replace dying in general, but which
      we DON'T need code for here. The code for this stuff should go
      somewhere else where it can handle all deathy things, including
      doom grasp:
        If it has Soul Stone, instead do the Soul Stone thing.
        If it has the Brave Knight ability and it has just taken combat damage,
          it goes to the owner's hand.
        If it is indestructible you do the indestructible thing instead.
  --]]


  -- TODO
  -- If a unit or hero is marked as "just took combat damage"
  -- or "just took deathtouch damage", unmark it.
end

function Game:update()
  local state = self:get_derived_state()
  local actions = get_sate_based_actions(state)
  while actions do
    -- TODO
    -- If the game is over, the game is over

    self:apply_state_based_actions(actions)
    state = self:get_derived_state()
    actions = get_sate_based_actions(state)
  end
end

print(json.encode(Game({"bashing"},{"finesse"}):get_derived_state()))
