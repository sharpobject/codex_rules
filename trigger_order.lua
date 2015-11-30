require("util")

upkeep_trigger = {
  "UPKEEP_TRIGGER_WORKERS",
  "UPKEEP_TRIGGER_SURPLUS",
  "UPKEEP_TRIGGER_HEALING",
  "UPKEEP_TRIGGER_STAR_CROSSED_STARLET",
}



general_trigger = {
  "ARRIVES_TRIGGER_HIRED_STOMPER",
  "ARRIVES_TRIGGER_TROJAN_DUCK",
  "ARRIVES_TRIGGER_BRICK_THIEF",
  "ARRIVES_TRIGGER_SNEAKY_PIG",
  "ATTACK_TRIGGER_OBLITERATE",
  "ATTACK_TRIGGER_TROJAN_DUCK",
  "DIES_TRIGGER_SCAVENGER",
  "DIES_TECHNICIAN",
  "SPELL_TRIGGER_HARMONY",
  "MUSIC_TRIGGER_DANCER",
}

-- All abilities that cause a thing to leave the discard right after getting
-- there happen right away. So there's a higher priority queue for those.

-- Triggered abilities that make a thing leave the discard right after getting there.
trigger_leave_discard = {
  "DIES_TRIGGER_BRICK_THIEF",
}