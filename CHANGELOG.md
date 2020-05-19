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
* Changed damage and armor scaling : VitalityToDamageRatio ratio increased from 6.5 to 7, VitalityToDamageRatioGrowth increased from 0.22 to 0.28, ArmortoVitalityRatio reduced from 0.45 to 0.40
* Constitution now increase HP by 9% instead of 7%.

Quality of Life
* The damage value on the character sheet is now correct, and the attribute bonuses are shown in the tooltip.
* Attribute and abilities tooltips should now display the custom bonuses dynamically.
* Added damage on some skill description lacking it, and fixed description for Elemental Weapons (former Elemental Arrowheads)
* Added some content on tooltips to make skills effects more clear
* Changed Savage Sortilege description that was incorrect
* Changed Strength description that was incorrect (it increase weapon-based attacks, not Physical damages)

