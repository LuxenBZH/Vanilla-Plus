Project Divine Game Master Changelog
=======
# 0.8.1.5
* Initial Release

# 0.8.3.5
* Fixed Hothead description and trigger.
* Fixed Leadership range tooltip.
* Rebalanced Peace of Mind since attributes works differently.
* Removed level requirements for All Skilled Up and Duelist (Bigger and better)
* Changed requirement for Duck Duck Goose
* Changed Firebrand requirements

# 0.8.4.6
* Fixed additional various localization strings.
* Changed Vacuum Touch : increased damage.
* Changed Venom Aura : decreased memory requirement, nullified SP cost but increased AP cost.
* Changed Ricochet : increased effective zone at a cost of a slight damage decrease.
* Changed Reactive Armour : increased damage.

# 0.8.5.10
* Changed Corpse explosion : decreased damage and increased cooldown
* Changed Firebrand : increased damage
* Fixed the poisoned potions inflicting damage to undeads
* Fixed skill tooltip damages 
* Fixed various localization strings (credits to Frasdoge)
* Decreased backstab Critical Chance to Damage rate to 1 instead of 2
* Decreased global damage bonus of attributes from 3 to 2
* Refactored code to make values easily modifiable from ExtraData

# 0.8.6.12
* Removed remnant testing code removing Demon and providing a talent point when using Flesh Sacrifice (no more cheese with elfs, Ego and Mhono :>)
* Made important changes concerning damage curve over levels. Armor ratio reduced to 0.33 from 0.4, VitalityToDamageRatio reduced to 7 from 7.5 and VitalityToDamageRatioGrowth reduced to 0.7 from 0.2. This change should ensure a constant damage ratio across levels.
* Decreased Constitution bonus on Vitality to 7% from 10% (back to original)
* Fixed damage not going through armor for surfaces and under certain conditions
* Fixed custom bonus for weapon abilities
* Fixed an issue where the console would display an error message on characters that doesn't belong to the normal gameplay
* Fixed an error where hovering Boucing Shield with the mouse and any skill using something less than BaseLevelDamage and AverageLevelDamage would display an error in the console
* Fixed skills using fixed damage values (anything else than BaseLevelDamage and AverageLevelDamage) would be boosted by attributes
* Changed Wind-up toy requirements and reduced AP cost
* Increased Mass Corpse Explosion cooldown
* Reduced SingleHanded of incarnate normal and champion by 3
* Reduced totems corresponding elemental school by 2
* All Skilled Up no longer apply on skills that have 1 turn cooldown
* Increased Corrosive Spray cooldown
* Reversed cooldown on Corpse Explosion

# 0.8.7.13
* Reworked damage scaling. Armor ratio set to 0.45 from 0.33, VitalityToDamageRatio reduced to 6 from 7, VitalityToDamageRatioGrowth increased from 0.07 to 0.023. Damages should now be fair at all level.

# 0.9.9.16 (Stingtail)
Fixes
* Single Handed should now provide Magic Resistance correctly.
* Pet Pal should not affect totems anymore, and it should trigger on both summons only when the second is summoned.
* Dodge Fatigue should not be triggered out of combat anymore.

Balance
* Greatly reduced classic and champion incarnate attributes
* Reduced Champion incarnate Vitality from 35 to 30
* Reduced Champion incarnate SingleHanded from 3 to 2
* Reduced classic and champion incarnate raw damage by 20%, and get 1% more penalty per level
* Reduced Incarnate Vitality from 25 to 20
* Reduced Incarnate SingleHanded from 2 to 1
* Reduced Totems raw damage by 20%
* Reduced Duelist AP Max bonus to 1 from 2.
* PDGM now replace automatically all statuses (including in other activated mods!) that provide a bonus to weapon with a BaseLevelDamage scaling if they have AverageLevelDamage or MonsterWeaponDamage scaling, meaning that weapon-enhancing skill should scale in the same way than weapon and don't bloat when reaching high levels
* Reworked Dodge Fatigue to make it more fair towards dodge builds. Low accuracy attackers (accuracy inferior to their base) should not proc Dodge fatigue anymore.
* Uncanny Evasion now prevent Dodge Fatigue to stack when active.
* Increased Momentum and Lingering duration to 2 turns from 1
* Confused do not increase AP cost anymore, it instead reduce AP Recovery and AP Max during different steps
* Reduced Ballistic Shot damage grow per meter to 3% from 5%
* Reduced Overpower SP cost to 2, but increased the cooldown to 6 turns.
* Added Potion Fatigue : when you drink a 3rd potion in the same turn, you loose all your remaining APs and get a -3AP recovery penalty for the next turn.
* Reduced Healing Elixir HP regain from 20% to 10%.
* Parry Master now let you delay the Dodge fatigue by one dodge per turn.
* Changed damage and armor scaling : VitalityToDamageRatio increased from 6.5 to 7, VitalityToDamageRatioGrowth increased from 0.22 to 0.28, ArmortoVitalityRatio reduced from 0.45 to 0.40
* Constitution now increase HP by 9% instead of 7%.

Quality of Life
* The damage value on the character sheet is now correct, and the attribute bonuses are shown in the tooltip.
* Attribute and abilities tooltips should now display the custom bonuses dynamically.
* Added damage on some skill description lacking it, and fixed description for Elemental Weapons (former Elemental Arrowheads)
* Added some content on tooltips to make skills effects more clear
* Changed Savage Sortilege description that was incorrect
* Changed Strength description that was incorrect (it increase weapon-based attacks, not Physical damages)

# 0.10.10.17 (Griff)
Fixes
* Changed Overpower SP cost to 2, was never meant to be 1
* Changed Challenge AP cost to 1, was never meant to stay at 0
* The incarnate melee hit should now have correct damage
* Increased scale of Living Wall to make it block vision properly on even ground
* Momentum and Lingering are now available to the Game Master to apply (useful for boss combats)
* Attribute scaling no longer apply on Unstable.
* Perseverance armor recovery is fixed.

Balance
* Constitution now provide 10% Vitality instead of 9%
* Potion fatigue now have an additionnal step that begin at the second potion drink on the same turn (-1 AP Recovery for the next turn)
* Potion restoration scaling is now different (20/30/40/50/60) and Giant healing potion is also back. Prices have been reduced accordingly
* Knockdown arrows cost now 3 AP.
* Hit chance formula have been replaced (now it's hitChance = attacker.Accuracy - target.Dodge). Accuracy isn't multiplicative with dodge, which mean that at high dodge Accuracy will still have an influence.
* In accordance with hit chance formula change, Intelligence now gives +1 Accuracy per point instead of +2.
* Two Handed now provide +1 Accuracy instead of +2 Chance to Hit
* Confused penalty on accuracy is now -15 instead of -25 per stage.
* Breathing Bubble no longer provide +2m Range, but provide +15 Accuracy instead.
* Erratic Wisp now provide 20% Dodge.
* Suffocating now reduce Accuracy by 15.
* Drunk now reduce Accuracy by 10 instead of 5 and increase Dodge by 10 instead of 5.
* Acid now reduce Physical and Piercing resistances by 15%.
* Deflecting barrier now reduce movement by 20%.
* Sparks damage multiplier is now 80 instead of 100, but they scale with attributes.
* Finesse give an additional 1% for all damages, for a total of +3% for all damages.
* Daggers base damage reduced from 55 to 52.
* Bows damage range reduced from 20 to 15 and base damage reduced from 90 to 85.
* Tornado AP cost reduced to from 2 to 1, its cooldown from 5 to 4 and its memorization requirement from Aerotheurge 3 to Aerotheurge 2.
* Totems of the Necromancer SP cost reduced from 3 to 2 and Memory cost from 3 to 2
* Enrage now reduce Dodging by 100% and both maximum Physical and Magic Armor by 20%
* Movement bonus from items are reduced by half.
* Last Rites now deals 50% of the maximum Vitality of the caster.
* Warfare physical damage bonus is reduced to 3 from 5 (less blind Warfare pumping)
* Perseverance Vitality regeneration isn't done per turn anymore but each time the character recover from a hard CC. Perseverance now also apply when Staggered and Confused statuses are removed, though the effect is halved.
* Ranged range bonus reduce to 0.3m instead of 0.5m
* Apportation requirement set to 1 Aero instead of 2
* Shields Up now reduce damage going through armor for 1 turn.
* Reduced Vaporize cooldown from 4 to 2 and increased radius from 2 meters to 4 meters.
* Reduced Turn To Oil cooldown from 4 to 2

Quality of Life
* Staves and ranged weapon now display their particularities when hovering the mouse on it
* Added information on some skills description lacking it.
* Damage tooltip should display the bonus from attributes and the reduction of the offhand penalty from Dual Wielding

Miscelleanous
* Removed some console debug prints

# 0.10.11.18 hotfix (Griff potato)
Fixes
* Fixed an issue with skill tooltip display
* Fixed an issue with Damage tooltip display
* Added damage tooltip support for active defense skills (Flaming tongue, Demonic tutelage, ...)

Balance
* Terrify now apply Fear for 1 turn instead of 2 turns

# 0.11.12.19 (Atusa)
Fixes
* Fixed multi elemental damage tooltips
* Fixed status tooltips
* The custom bonuses provided by attributes (Movement, CC for Finesse and Accuracy for Intelligence, also various custom bonus for weapon abilities) are now provided by statuses generated on the fly instead of changing the permaboosts of the character. This has a great incidence in GM mode where PDGM used to share the same boost pool with the GM and could make it really confusing for the GM to manage.

Balance
* Reduced global damage scaling by 15% to follow the armor reduction
* Changed the Vitality scaling to provide a constant growth and a higher number start for more reliable low percentage bonuses. The gap between levels is lower, from a median of 22% to 15%, which makes the early game much more fair and gives more granularity for the GM concerning levels.
* Scoundrel Movement bonus reduced from 0.3m to 0.1m
* Finesse Movement bonus increased from 0.15m to 0.2m
* Finesse now provide 1% Critical Chance per point
* Strength does not increase DoT anymore, but ignore 1% of enemy Resistance per point (if it's under 100)
* Wits now improve DoT by 10% per point
* Backstab Critical Chance convertion rate is reduced from 1% CC = 1% Damage to 1% CC = 0.5% Damage

