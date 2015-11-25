json = require("dkjson")
require("util")

-- Most card data from disguised_monkey can be reused here.
-- So this is just the name and internal abilities.
-- Everything except the abilities is pulled from the json file.

id_to_card = {
  NSUM = {
    name = "Timely Messenger",
    abilities = {"HASTE"},
  },
  NSUT = {
    name = "Tenderfoot",
  },
  NSUO = {
    name = "Older Brother",
  },
  NSUB = {
    name = "Brick Thief",
    abilities = {"ARRIVES_TRIGGER_BRICK_THIEF"},
  },
  NSUH = {
    name = "Helpful Turtle",
    abilities = {{"UPKEEP_TRIGGER_HEALING", 1}},
  },
  NSUG = {
    name = "Granfalloon Flagbearer",
    abilities = {"FLAGBEARER"},
  },
  NSUN = {
    name = "Fruit Ninja",
    abilities = {{"FRENZY", 1}},
  },
  NSSS = {
    name = "Spark",
    abilities = {"SPELL_SPARK"},
  },
  NSSB = {
    name = "Bloom",
    abilities = {"SPELL_BLOOM"},
  },
  NSSW = {
    name = "Wither",
    abilities = {"SPELL_WITHER"},
  },
  NBH = {
    name = "Troq Bashar",
    mid_abilities = {{"ATTACK_TRIGGER_DAMAGE_BASE", 1}},
    max_abilities = {"READINESS"},
  },
  NBSW = {
    name = "Wrecking Ball",
    abilities = {"SPELL_WRECKING_BALL"},
  },
  NBSB = {
    name = "The Boot",
    abilities = {"SPELL_THE_BOOT"},
  },
  NBSI = {
    name = "Intimidate",
    abilities = {"SPELL_INTIMIDATE"},
  },
  NBSF = {
    name = "Final Smash",
    abilities = {"SPELL_FINAL_SMASH_0",
                  "SPELL_FINAL_SMASH_1",
                  "SPELL_FINAL_SMASH_2",},
  },
  NBUI = {
    name = "Iron Man",
  },
  NBUO = {
    name = "Revolver Ocelot",
    abilities = {"SPARKSHOT"},
  },
  NBUP = {
    name = "Sneaky Pig",
    abilities = {"HASTE", "ARRIVES_TRIGGER_SNEAKY_PIG"},
  },
  NBUR = {
    name = "Regular-sized Rhinoceros",
  },
  NBUS = {
    name = "Hired Stomper",
    abilities = {"ARRIVES_TRIGGER_HIRED_STOMPER"},
  },
  NBUE = {
    name = "Eggship",
    abilities = {"FLYING"},
  },
  NBUH = {
    name = "Harvest Reaper",
    abilities = {"OVERPOWER"},
  },
  NBUT = {
    name = "Trojan Duck",
    abilities = {{"ATTACK_TRIGGER_OBLITERATE", 2},
                  "ARRIVES_TRIGGER_TROJAN_DUCK",
                  "ATTACK_TRIGGER_TROJAN_DUCK",},
  },
  NFH = {
    name = "River Montoya",
    mid_abilities = {"TAP_SIDELINE_0_OR_1"},
    max_abilities = {"TECH_0_DISCOUNT"},
  },
  NTUD = {
    name = "Dancer",
    abilities = {"MUSIC_TRIGGER_DANCER"},
  },
  NTUA = {
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
    if card.spec then
      if spec_to_color[card.spec] then
        assert(spec_to_color[card.spec] == card.color)
      end
      spec_to_color[card.spec] = card.color
    end
  end
end

for id,card in pairs(id_to_card) do
  local read_card = name_to_card[card.name]
  for k,v in pairs(read_card) do
    assert(k ~= "abilities")
    card[k] = v
  end
end
