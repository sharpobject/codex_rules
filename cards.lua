json = require("dkjson")
require("util")

-- Most card data from disguised_monkey can be reused here.
-- So this is just the name and internal abilities.
-- Everything except the abilities is pulled from the json file.

id_to_card = {
  NSUTM = {
    name = "Timely Messenger",
    abilities = {"HASTE"},
  },
  NSUTF = {
    name = "Tenderfoot",
  },
  NSUOB = {
    name = "Older Brother",
  },
  NSUBT = {
    name = "Brick Thief",
    abilities = {"ARRIVES_TRIGGER_BRICK_THIEF"},
  },
  NSUHT = {
    name = "Helpful Turtle",
    abilities = {{"UPKEEP_TRIGGER_HEALING", 1}},
  },
  NSUGF = {
    name = "Granfalloon Flagbearer",
    abilities = {"FLAGBEARER"},
  },
  NSUFN = {
    name = "Fruit Ninja",
    abilities = {{"FRENZY", 1}},
  },
  NSSSP = {
    name = "Spark",
    abilities = {"SPELL_SPARK"},
  },
  NSSBL = {
    name = "Bloom",
    abilities = {"SPELL_BLOOM"},
  },
  NSSWI = {
    name = "Wither",
    abilities = {"SPELL_WITHER"},
  },
  NBHTB = {
    name = "Troq Bashar",
    mid_abilities = {{"ATTACK_TRIGGER_DAMAGE_BASE", 1}},
    max_abilities = {"READINESS"},
  },
  NBSWB = {
    name = "Wrecking Ball",
    abilities = {"SPELL_WRECKING_BALL"},
  },
  NBSTB = {
    name = "The Boot",
    abilities = {"SPELL_THE_BOOT"},
  },
  NBSIN = {
    name = "Intimidate",
    abilities = {"SPELL_INTIMIDATE"},
  },
  NBSFS = {
    name = "Final Smash",
    abilities = {"SPELL_FINAL_SMASH_0",
                  "SPELL_FINAL_SMASH_1",
                  "SPELL_FINAL_SMASH_2",},
  },
  NBUIM = {
    name = "Iron Man",
  },
  NBURO = {
    name = "Revolver Ocelot",
    abilities = {"SPARKSHOT"},
  },
  NBUSP = {
    name = "Sneaky Pig",
    abilities = {"HASTE", "ARRIVES_TRIGGER_SNEAKY_PIG"},
  },
  NBURR = {
    name = "Regular-sized Rhinoceros",
  },
  NBUHS = {
    name = "Hired Stomper",
    abilities = {"ARRIVES_TRIGGER_HIRED_STOMPER"},
  },
  NBUES = {
    name = "Eggship",
    abilities = {"FLYING"},
  },
  NBUHR = {
    name = "Harvest Reaper",
    abilities = {"OVERPOWER"},
  },
  NBUTD = {
    name = "Trojan Duck",
    abilities = {{"ATTACK_TRIGGER_OBLITERATE", 2},
                  "ARRIVES_TRIGGER_TROJAN_DUCK",
                  "ATTACK_TRIGGER_TROJAN_DUCK",},
  },
  NFHRM = {
    name = "River Montoya",
    mid_abilities = {"TAP_SIDELINE_0_OR_1"},
    max_abilities = {"TECH_0_DISCOUNT"},
  },
  NFSHR = {
    name = "Harmony",
    abilities = {},
  },
  NFSDI = {
    name = "Discord",
    abilities = {},
  },
  NFSTS = {
    name = "Two Step",
    abilities = {},
  },
  NFSAS = {
    name = "Appel Stomp",
    abilities = {},
  },
  NFUNF = {
    name = "Nimble Fencer",
    abilities = {}
  },
  NFUSS = {
    name = "Star-Crossed Starlet",
    abilities = {}
  },
  NFUGG = {
    name = "Grounded Guide",
    abilities = {}
  },
  NFUMA = {
    name = "Maestro",
    abilities = {}
  },
  NFUBS = {
    name = "Backstabber",
    abilities = {}
  },
  NFUCS = {
    name = "Cloud Sprite",
    abilities = {}
  },
  NFULL = {
    name = "Leaping Lizard",
    abilities = {}
  },
  NFUBM = {
    name = "Blademaster",
    abilities = {}
  },
  NFUNF = {
    name = "Nimble Fencer",
    abilities = {}
  },
  NTUDN = {
    name = "Dancer",
    abilities = {"MUSIC_TRIGGER_DANCER"},
  },
  NTUAD = {
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
