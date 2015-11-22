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
  "SPELL_TRIGGER_HARMONY",
  "MUSIC_TRIGGER_DANCER",
}

-- In the final version of the rules, either all abilities that cause a thing to
-- leave the discard right after getting there can "skip the queue" or
-- all abilities that cause a reshuffle "have to wait for everything else"
-- This supports either of those two modes.

-- Triggered abilities that make a thing leave the discard right after getting there.
trigger_leave_discard = {
  "DIES_TRIGGER_BRICK_THIEF",
}

-- Triggered abilities that cause a player to reshuffle (usually by drawing cards)
trigger_reshuffle = {
  "DIES_TECHNICIAN",
  "UPKEEP_TRIGGER_SURPLUS",
}

-- For now the rule is that the stuff that can make a thing leave the discard gets
-- to cut in line.

local graveyard_cuts_in_line = true
if graveyard_cuts_in_line then
  general_trigger = append({general_trigger, trigger_reshuffle})
  trigger_reshuffle = {}
else
  general_trigger = append({trigger_leave_discard, general_trigger})
  trigger_leave_discard = {}
end