require("cards")
require("class")
require("queue")
require("util")
local dipswitches = require("dipswitches")
local Action = require("action")

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

    self.spec_choices = {}
    
    self.gold = 0
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

    for id, card in pairs(id_to_card) do
      if card.type == "building" and card.starting_zone == "command" then
        self.command[#self.command+1] = self:make_card(id)
        self.command[#self.command+1] = self:make_card(id)
      end
    end

    --[[local colors = {}
    for _,spec in pairs(specs) do
      local color = spec_to_color[spec]
      if color ~= "neutral" then
        colors[color] = true
      end
    end
    local ncolors = 0
    for k,v in pairs(colors) do
      ncolors = ncolors + 1
    end
    if ncolors > 1 then
      self.multicolor = true
    end--]]

    --for k,v in pairs(self.id_to_next_uid) do
    --  self.id_to_next_uid[k] = nil
    --end

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

function Player:gain_gold(n)
  self.gold = math.min(self.gold + n, dipswitches.MAX_GOLD)
end

Game = class(function(self, specs1, specs2)
    self.next_timestamp = 1
    self.players = {Player(specs1, 1), Player(specs2, 2)}
    self.field = {}
    for idx, player in ipairs(self.players) do
      self:to_field(player:make_card("NBABBA"))
      player.hand[#player.hand+1] = player:make_card("NTOUDN")
    end
    self:to_field(self.players[1]:make_card("NBAHTB"))
    self.field[3].runes = {plus=1, minus=1}
    self.field[3].damage = 99
    self.field[2].just_took_combat_damage = true
    self.extra_turns = 0
    self.high_priority_triggers = Queue()
    self.triggers = Queue()
    self.low_priority_triggers = Queue()
    self.next_steps = Queue()
    self.active_player = 0
    self.worker_cost = dipswitches.WORKER_COST
    self:start_turn(1)
  end)
require("steps")(Game)

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
  self.made_a_worker_this_turn = nil
  self.made_a_building_this_turn = nil
  self.this_turn_time = self:get_timestamp()
  self.next_steps:push("STEP_READY")
end

local function uid_to_owner(card_uid)
  return tonumber(card_uid[7])
end

local function uid_to_identity(card_uid)
  return card_uid:sub(1,6)
end

local function is_token(card)
  card = id_to_card[uid_to_identity(card.uid)]
  return card.starting_zone == "trash"
end

function Game:get_addon(player_idx)
  local state = self.derived_state
  for k,v in pairs(state.field) do
    if v.addon and v.controller == player_idx then
      return v.uid
    end
  end
end

function Game:to_field(card, controller)
  if type(card) == "string" then
    card = {uid = card}
  end
  if not card.controller then
    card.controller = uid_to_owner(card.uid)
  end
  self.field[#self.field+1] = card
end

function Game:process_deaths(uids)
  uids = arr_to_set(uids)
  i = 1
  n = #self.field
  -- TODO: Replacement effects that replace death
  -- TODO: Triggered abilities that happen on death
  -- Probably triggered abilities will work using a general system for
  -- watching zone transitions, so this needs to make a zone transition
  -- thing and give that to whatever is listening.
  -- TODO: When a tech building or add-on dies, its base takes 2 damage.
  while i <= n do
    local card = self.field[i]
    if card.you_are_on_the_way_to_destruction then
      local owner = uid_to_owner(card.uid)
      local discard = self.players[owner].discard
      discard[#discard + 1] = card.uid
      table.remove(self.field, i)
      n = n - 1
    else
      i = i + 1
    end
  end
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

  ret.id = card_id

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

  ret.ongoing = orig_card.ongoing
  ret.legendary = orig_card.legendary
  ret.ultimate = orig_card.ultimate
  ret.tech_building = orig_card.tech_building
  ret.addon = orig_card.addon

  if card.ready == nil then
    ret.ready = true
  end

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
    ret.players[i].can_play_tech = {[0] = true}
    for _,zone in ipairs({"codex", "discard", "deck", "hand", "command", "future"}) do
      ret.players[i][zone] = {}
      for j=1,#self.players[i][zone] do
        local card = get_basic_card_state(self.players[i][zone][j])
        ret.players[i][zone][j] = card
      end
    end
  end
  ret.field = {}
  for i=1,#self.field do
    local card = get_basic_card_state(self.field[i])
    ret.field[i] = card
    -- TODO: not sure what I was thinking with this one
    -- if card.id == ""
  end

  -- TODO: apply +1/+1 counters, -1/-1 counters,
  -- TODO: apply ongoing effects like two step
  -- TODO: have a working game

  return ret
end

function Game:get_state_based_actions()
  local state = self.derived_state
  local bail_out = false
  local changes = {}

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


  -- If a permanent is in play, ensure that it has an "arrived" timestamp,
  -- a "came under control" timestamp, a "established identity" timestamp,
  -- and for heroes mid level or higher, also timestamps for their mid and
  -- max level abilities.
  -- If the controller changed, the identity changed, or the hero leveled
  -- down, update those timestamps appropriately.
  local timestamp = nil

  for k,v in pairs(state.field) do
    if not v.arrived_time then
      if not timestamp then
        bail_out = true
        timestamp = self:get_timestamp()
      end
      changes[#changes+1] = v.uid
      self.field[k].arrived_time = timestamp
    end

    if not v.controller then
      if not timestamp then
        bail_out = true
        timestamp = self:get_timestamp()
      end
      v.controller = uid_to_owner(v.uid)
      self.field[k].controller = v.controller
    end

    if (not v.controller_time) or v.controller_time.controller ~= v.controller then
      if not timestamp then
        bail_out = true
        timestamp = self:get_timestamp()
      end
      changes[#changes+1] = v.uid
      v.controller_time = {controller = v.controller, time = timestamp}
      self.field[k].controller_time = v.controller_time
    end

    if not v.identity then
      if not timestamp then
        bail_out = true
        timestamp = self:get_timestamp()
      end
      v.identity = uid_to_identity(v.uid)
      self.field[k].identity = v.identity
    end

    if (not v.identity_time) or v.identity_time.identity ~= v.identity then
      if not timestamp then
        bail_out = true
        timestamp = self:get_timestamp()
      end
      changes[#changes+1] = v.uid
      v.identity_time = {identity = v.identity, time = timestamp}
      self.field[k].identity_time = v.identity_time
    end

    -- TODO: Stuff about hero midband/max band timestamps
    if false then
    end
  end

  if bail_out then
    print("Set timestamps for cards: "..json.encode(uniquify(changes)))
    return true
  end


  -- TODO
  -- If a player has two or more of the same Legendary permanent,
  -- all but one are trashed. The one that survives is the one that
  -- has had that identity for the longest time.
  -- So every permanent has to keep track of its last known identity
  -- and how long it has had that.
  -- (actually, only UNITS can copy things, so maybe all this stuff
  -- is just for Legendary Units)


  -- If a token is in any zone other than in play or the future it is trashed.
  -- The same is true for tech buildings and addons
  for i=1,#state.players do
    for _,zone in ipairs({"codex", "discard", "deck", "hand"}) do
      for j=#state.players[i][zone],1,-1 do
        local card = state.players[i][zone][j]
        if is_token(card) or card.tech_building or card.addon then
          bail_out = true
          local token = table.remove(self.players[i][zone], j)
          changes[#changes+1] = card.uid
        end
      end
    end
  end

  if bail_out then
    print("Trashed tokens/tech buildings/addons for being in the wrong zone: "..json.encode(changes))
    return true
  end

  -- If a hero is in the discard, it goes to command on cooldown.
  for i=1,#state.players do
    for j=#state.players[i].discard,1,-1 do
      local card = state.players[i].discard[j]
      if card.type == "hero" then
        bail_out = true
        local uid = table.remove(self.players[i].discard, j)
        -- Cooldown should be 2 if the hero dies on its own turn.
        local hero = {uid = uid, cooldown = 1}
        if i == self.active_player then
          hero.cooldown = 2
        end
        self.players[i].command[#self.players[i].command + 1] = hero
        changes[#changes+1] = uid
      end
    end
  end

  if bail_out then
    print("Moved dead heroes to command zone: "..json.encode(changes))
    return true
  end

  -- Lame hack: Players play tech buildings and addons from their command zone.
  -- So put those from discard to command too.
  for i=1,#state.players do
    for j=#state.players[i].discard,1,-1 do
      local card = state.players[i].discard[j]
      if card.type == "building" and card.starting_zone == "command" then
        bail_out = true
        local uid = table.remove(self.players[i].discard, j)
        self.players[i].command[#self.players[i].command + 1] = uid
        changes[#changes+1] = uid
      end
    end
  end

  if bail_out then
    print("Moved dead tech buildings and addons to command zone: "..json.encode(changes))
    return true
  end


  -- TODO
  -- If a player has no base, the game is over.
  -- Note that some other abilities can cause the game to end,
  -- So this isn't the only place where game over happens.
  -- Update: I'll just make those abilities destroy your base whatever man.


  -- TODO
  -- If an effect says it should expire, it expires.
  -- Some effects do stuff when they expire (other than just stop applying).
  -- Effects that granted armor take armor away on expiration.
  -- Aura effects (like Soul Stone) kill the attached spell card on expiration.


  -- If a permanent has 0 of a type of rune, stop tracking it.
  for k,v in pairs(state.field) do
    if v.runes then
      local keep_runes = false
      for rune_type, count in pairs(v.runes) do
        if count == 0 then
          bail_out = true
          changes[#changes+1] = v.uid
          self.field[k].runes[rune_type] = nil
        else
          keep_runes = true
        end
      end
      if not keep_runes then
        self.field[k].runes = nil
      end
    end
  end

  if bail_out then
    print("Stopped tracking some runes for cards: "..json.encode(uniquify(changes)))
    return true
  end

  -- If a permanent has both +1/+1 and -1/-1 runes, they cancel
  for k,v in pairs(state.field) do
    if v.runes and v.runes.plus and v.runes.minus then
      bail_out = true
      changes[#changes+1] = v.uid
      local net_amount = v.runes.plus - v.runes.minus
      if net_amount > 0 then
        self.field[k].runes.plus = net_amount
        self.field[k].runes.minus = 0
      else
        self.field[k].runes.plus = 0
        self.field[k].runes.minus = -net_amount
      end
    end
  end

  if bail_out then
    print("Cancelled +1/+1 and -1/-1 runes for cards: "..json.encode(changes))
    return true
  end

  --[[
    If a unit or hero or building has damage marked on it greater than or
      equal to its HP, it is on the way to destruction.
    If a unit or hero has just taken damage from a thing that has deathtouch,
      it is on the way to destruction.
    The following two things apply to deaths in general, but we have to
      do them here to make sure we don't make no-op state based actions.
      (that would cause an infinite loop)
    If it has the Glaxx ability and its controller has gold and
      it has not just taken combat damage, it doesn't die.
    If it is indestructible and has 0 or less HP and is already tapped,
      and has no damage or attachements, nothing happens.

    Here are some other things that replace dying in general, but which
      we DON'T need code for here. The code for this stuff should go
      somewhere else where it can handle all deathy things, including
      doom grasp:
        If it has Soul Stone, instead do the Soul Stone thing.
        If it has the Brave Knight ability and it has just taken combat damage,
          it goes to the owner's hand.
        If it is indestructible you do the indestructible thing instead.
  --]]
  for k,v in pairs(state.field) do
    if (v.HP <= 0 or (v.HP and v.damage and v.damage >= v.HP)
        or v.just_took_deathtouch_damage)
        and not v.you_are_on_the_way_to_destruction then
      -- TODO:
      -- Stuff about glaxx and indestructible
      bail_out = true
      changes[#changes+1] = v.uid
      self.field[k].you_are_on_the_way_to_destruction = true
    end
  end

  if bail_out then
    print("Marked lethal damage for cards: "..json.encode(changes))
    return true
  end

  -- If anything is on the way to destruction, it dies.
  for k,v in pairs(state.field) do
    if v.you_are_on_the_way_to_destruction then
      bail_out = true
      changes[#changes+1] = v.uid
    end
  end

  if bail_out then
    print("Killing cards: "..json.encode(changes))
    self:process_deaths(changes)
    return true
  end

  -- If a unit or hero is marked as "just took combat damage"
  -- or "just took deathtouch damage", unmark it.
  for k,v in pairs(state.field) do
    if v.just_took_combat_damage or v.just_took_deathtouch_damage then
      bail_out = true
      self.field[k].just_took_combat_damage = nil
      self.field[k].just_took_deathtouch_damage = nil
      changes[#changes+1] = v.uid
    end
  end

  if bail_out then
    print("Unset combat damage indicator for cards: "..json.encode(changes))
    return true
  end

  -- TODO: look for state triggers
  -- These aren't really state-based actions (?) but they should happen here
  -- more or less. Like, any time you finish fixing the state, and there's a guy
  -- with a Hardened Mox and a Tech 2 unit, and the Hardened Mox trigger isn't in
  -- the queue yet, it should go in the queue.
end

function Game:update(input)
  local prompt = false
  while not prompt do
    self.derived_state = self:get_derived_state()
    while self:get_state_based_actions() do
      self.derived_state = self:get_derived_state()
    end
    local action = nil
    if self.high_priority_triggers:len() > 0 then
      action = self.high_priority_triggers:pop()
    elseif self.triggers:len() > 0 then
      action = self.triggers:pop()
    elseif self.low_priority_triggers:len() > 0 then
      action = self.low_priority_triggers:pop()
    elseif self.next_steps:len() > 0 then
      action = self.next_steps:pop()
    end
    assert(action, "RAN OUT OF STUFF TO DO")
    action = Action(action)
    prompt = action:prompt(self, input)
    if not prompt then
      print(action, self, input)
      print("RUNNING ".. action.id)
      action:run(self, input)
      input = nil
    end
  end
  return prompt
end

local game = Game({"bashing"}, {"finesse"})
local prompt = game:update()
print(json.encode(prompt))

--print(json.encode(game:get_derived_state()))
