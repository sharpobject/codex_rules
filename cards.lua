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
}

name_to_id = {}
for id, card in id_to_card do
  name_to_id[card.name] = card
end