json = require("dkjson")
require("util")
require("stridx")

-- Most card data from disguised_monkey can be reused here.
-- So this is just the name and internal abilities.
-- Everything except the abilities is pulled from the json file.

id_to_card = {
  NBABBA = {
    name = "Base",
  },
  NBABT1 = {
    name = "Tech I Building",
  },
  NBABT2 = {
    name = "Tech II Building",
  },
  NBABT3 = {
    name = "Tech III Building",
  },
  NBABTL = {
    name = "Tech Lab",
  },
  NBABHH = {
    name = "Heroes' Hall",
  },
  NBABTW = {
    name = "Tower",
  },
  NBABSU = {
    name = "Surplus",
  },
  NSTUTM = {
    name = "Timely Messenger",
    abilities = {"HASTE"},
  },
  NSTUTF = {
    name = "Tenderfoot",
  },
  NSTUOB = {
    name = "Older Brother",
  },
  NSTUBT = {
    name = "Brick Thief",
    abilities = {"ARRIVES_TRIGGER_BRICK_THIEF", 
                 "DIES_TRIGGER_BRICK_THIEF"},
  },
  NSTUHT = {
    name = "Helpful Turtle",
    abilities = {{"UPKEEP_TRIGGER_HEALING", 1}},
  },
  NSTUGF = {
    name = "Granfalloon Flagbearer",
    abilities = {"FLAGBEARER"},
  },
  NSTUFN = {
    name = "Fruit Ninja",
    abilities = {{"FRENZY", 1}},
  },
  NSTSSP = {
    name = "Spark",
    abilities = {"SPELL_SPARK"},
  },
  NSTSBL = {
    name = "Bloom",
    abilities = {"SPELL_BLOOM"},
  },
  NSTSWI = {
    name = "Wither",
    abilities = {"SPELL_WITHER"},
  },
  NBAHTB = {
    name = "Troq Bashar",
    mid_abilities = {{"ATTACK_TRIGGER_DAMAGE_BASE", 1}},
    max_abilities = {"READINESS"},
  },
  NBASWB = {
    name = "Wrecking Ball",
    abilities = {"SPELL_WRECKING_BALL"},
  },
  NBASTB = {
    name = "The Boot",
    abilities = {"SPELL_THE_BOOT"},
  },
  NBASIN = {
    name = "Intimidate",
    abilities = {"SPELL_INTIMIDATE"},
  },
  NBASFS = {
    name = "Final Smash",
    abilities = {"SPELL_FINAL_SMASH_0",
                  "SPELL_FINAL_SMASH_1",
                  "SPELL_FINAL_SMASH_2",},
  },
  NBAUIM = {
    name = "Iron Man",
  },
  NBAURO = {
    name = "Revolver Ocelot",
    abilities = {"SPARKSHOT"},
  },
  NBAUSP = {
    name = "Sneaky Pig",
    abilities = {"HASTE", "ARRIVES_TRIGGER_SNEAKY_PIG"},
  },
  NBAURR = {
    name = "Regular-sized Rhinoceros",
  },
  NBAUHS = {
    name = "Hired Stomper",
    abilities = {"ARRIVES_TRIGGER_HIRED_STOMPER"},
  },
  NBAUES = {
    name = "Eggship",
    abilities = {"FLYING"},
  },
  NBAUHR = {
    name = "Harvest Reaper",
    abilities = {"OVERPOWER"},
  },
  NBAUTD = {
    name = "Trojan Duck",
    abilities = {{"ATTACK_TRIGGER_OBLITERATE", 2},
                  "ARRIVES_TRIGGER_TROJAN_DUCK",
                  "ATTACK_TRIGGER_TROJAN_DUCK",},
  },
  NFIHRM = {
    name = "River Montoya",
    mid_abilities = {"TAP_SIDELINE_0_OR_1"},
    max_abilities = {"CONT_COST_TECH_0_DISCOUNT"},
  },
  NFISHR = {
    name = "Harmony",
    abilities = {},
  },
  NFISDI = {
    name = "Discord",
    abilities = {},
  },
  NFISTS = {
    name = "Two Step",
    abilities = {},
  },
  NFISAS = {
    name = "Appel Stomp",
    abilities = {},
  },
  NFIUNF = {
    name = "Nimble Fencer",
    abilities = {"CONT_BUFF1_VIRTUOSO_HASTE"},
  },
  NFIUSS = {
    name = "Star-Crossed Starlet",
    abilities = {},
  },
  NFIUGG = {
    name = "Grounded Guide",
    abilities = {},
  },
  NFIUMA = {
    name = "Maestro",
    abilities = {},
  },
  NFIUBS = {
    name = "Backstabber",
    abilities = {},
  },
  NFIUCS = {
    name = "Cloud Sprite",
    abilities = {},
  },
  NFIULL = {
    name = "Leaping Lizard",
    abilities = {},
  },
  NFIUBM = {
    name = "Blademaster",
    abilities = {},
  },
  NFIUNF = {
    name = "Nimble Fencer",
    abilities = {},
  },
  NTOUDN = {
    name = "Dancer",
    abilities = {"MUSIC_TRIGGER_DANCER"},
  },
  NTOUAD = {
    name = "Angry Dancer",
    abilities = {"UNSTOPPABLE"},
  },
}

spec_to_color = {}

local filenames = {"white", "blue", "black", "red", "green", "purple", "neutral", "heroes"}
local name_to_card = {}
for _,name in pairs(filenames) do
  local cards = json.decode(file_contents(name..".json"))
  for _,card in pairs(cards) do
    if not name_to_card[card.name] then
      name_to_card[card.name] = card
    end
  end
end

local accept_fields = arr_to_set{
    "ATK",
    "ATK_1",
    "ATK_2",
    "ATK_3",
    "HP",
    "HP_1",
    "HP_2",
    "HP_3",
    "color",
    "cost",
    "max_level",
    "mid_level",
    "spec",
    "starting_zone",
    "subtype",
    "tech_level",
    "type",
  }
for id,card in pairs(id_to_card) do
  local read_card = name_to_card[card.name]
  for k,v in pairs(read_card) do
    if accept_fields[k] then
      if type(v) == "string" then
        v = v:lower()
      end
      card[k] = v
    end
  end
end

for id,card in pairs(id_to_card) do
  if card.spec then
    if spec_to_color[card.spec] then
      assert(spec_to_color[card.spec] == card.color)
    end
    spec_to_color[card.spec] = card.color
  end

  if card.type == "hero" then
    card.subtype = nil
  end

  local types = card.type:split(" ")
  for k,v in ipairs(types) do
    if v == "legendary" then
      card.legendary = true
    elseif v == "ongoing" then
      card.ongoing = true
    elseif v == "ultimate" then
      card.ultimate = true
    elseif v == "tech" then
      card.tech_building = true
    elseif v == "add-on" then
      card.addon = true
    elseif v == "minor" then
      -- Don't actually care about the "minor" supertype
    else
      card.type = v
    end
  end

  if card.type == "unit" or card.type == "spell" then
    local subtypes = {}
    if card.subtype then
      subtypes = card.subtype:split(" ")
    end
    card.subtypes = subtypes
  end
  card.subtype = nil
end
