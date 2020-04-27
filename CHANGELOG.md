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