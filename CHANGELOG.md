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
* Reduced global damage scaling by 15% to follow the hit armor reduction from vanilla
* Changed the Vitality scaling to provide a constant growth and a higher number start for more reliable low percentage bonuses. The gap between levels is lower, from a median of 22% to 15%, which makes the early game much more fair and gives more granularity for the GM concerning levels.
* Scoundrel Movement bonus reduced from 0.3m to 0.1m
* Finesse Movement bonus increased from 0.15m to 0.2m
* Finesse now provide 1% Critical Chance per point
* Strength does not increase DoT anymore, but ignore 1% of enemy Resistance per point (if it's under 100)
* Wits now improve DoT by 10% per point
* Backstab Critical Chance convertion rate is reduced from 1% CC = 1% Damage to 1% CC = 0.5% Damage
* Single Handed ability Accuracy bonus is reduced from 5 to 2 according to the new chance to hit formula

# 0.11.13.20 (Verdas)
Fixes
* Fixed an issue where traps would not apply damage through armors
* Fixed an issue with Wits not increasing DoT damages
* Fixed an issue where statuses have 1% chance to not apply even though they have 100% chance to apply
* Fixed Uncanny Evasion not preventing Dodge Fatigue
* Fixed the issue with Mnemonics not removing the Memory bonus when entering the Magic mirror, which was giving infinite amount of Memory
* Fixed the Charmed status not giving Lingering after expiration
* Removed spamming warnings in the console when loading a GM maps and when dealing with summons during battle
* Fixed Favourable Wind not giving the same bonuses on the caster than the aura effect
* Fixed vanilla bug where Sucker Punch cooldown reset when equipping-unequipping weapons
* Fixed Ambidextrous not refunding AP when equipping items
* Fixed All Skilled Up reducing cooldown of skills having a 1 turn cooldown whereas it should not
* Morning Person custom effect should be more reliabe now

Balances
* Restored vanilla base memory slots growth (1 every two levels) and reduced base memory slots from 5 to 4 (vanilla is 3)
* Removed the AP refund feature on consecutive dodging. It is not relevant anymore with the recent changes for Dodge.
* Grenades base weight reduced from 1000g to 350g
* Vitality restored bonus from Hydrosophist increased from 5% to 8%
* Sabotage cooldown increased from 1 to 3 turns
* Minor attribute potion base attribute value increased from 1 to 3
* Tentacle Lash now scale with Strength too

New Features
* You can now mix attribute potions with the same type of potion to obtain greater attribute potions, and not just by using augmentor. You can now also use all kind of augmentors for obtaining medium sized, and ultimate augmentor for large sized potions.
* Perseverance now also triggers when a Staggered or Confused effect expires, but its effect is halved.

# 0.11.14.22 (Septa)
Fixes
* Un-fixed the fix for Perseverance since it has been fixed in the base game (finally!)
* Jump skills have their cooldown correctly increased as planned
* Fixed issues with damage ranges on tooltip with the v51 of the extender

Balance
* Confused now reduce AP recovery by 1 on all stages, and reduce max AP by 2/3/4
* Staggered now reduce Movement Speed by 25/50/75 and does not reduce Initiative anymore
* Arcane Stitch AP cost reduced to 2 from 3
* Sleeping now trigger Lingering when expering and do apply Confused when Lingering is on

Modules
* Introducing modules. Modules are part of the mod you can enable and disable at will. By default, all modules derivating too much from vanilla will be deactivated. In the long run, you'll be able to activate and deactivate full parts of PDGM to customize your experience.
* Introducing the first Module: Real Jumps. You can convert jump skills to a Projectile equivalent, which mean jumping isn't a teleport but a real jump, in the same manner than Fly
* Introducing console commands to enable and disable modules

# 0.11.16.24 (Kniles)
Fixes
* Removed the Cloak and Dagger projectile impact in the Real Jump modules

Balance
* Food bonuses have been changed, and now scale with level. See the google sheet for the changes.
* Attribute potions now provide +3/+6/+9
* Attribute potions now need 3 units to make a greater one through crafting
* Memory potions (GM mode only) now last 100 turns
* Crossbows base damage reduced from 110 to 105
* Crossbows range reduced from 1400 to 1300 (return to vanilla)
* Staffs base damage increased from 95 to 105
* Wands base damage increased from 63 to 67
* Armor to vitality ratio increased from 0.4 to 0.45 (Base armor +12.5%)
* Normalized the price of damaging attributes potion ingredients to 80
* Increased the price of Puffball from 5 to 30
* Minor resistance potions now provide 25% resistance instead of 15%
* Resist all potions now provide 15%/30%/60% resistance to elements instead of 15%/50%/75%

# 0.11.17.25 (Knile's chastity)
Fixes
* Fixed cup and bottle of water not clearing food poisoning

Balance
* Food regeneration now restore vitality only during combat to avoid repetitive and unnecessary permanent healing effects

#0.11.18.26 (Vasnya)
Fixes
* Fixed a bug related to skills tooltip that was clutering the console
* Fixed a typo in Escapist description (thanks to our grammar nazi)

Balance
* Reduced Explosion damage by half (still 1.5x vanilla)
* Crossbows movement penalty is now scaled with crossbow level, starting from -1.0m at level 1 and decrease the Movement by 0.08m per additional level.
* Bull Horns now give 2 Retribution
* Medusa Head aura now apply Slowed instead of Petrified and radius is increased to 4 meters from 3
* Breathing Bubble now give Lingering for 1 turn, give a high amount of Wits (5 base) but doesn't give Accuracy anymore
* Mass Corpse explosion AP cost increased from 1 to 2 and cooldown from 4 to 6
* Elemental skins duration increased from 2 turns to 3 and provide 1 turn of Momentum and Lingering
* Reduced Two Handed swords accuracy boost from 10% to 5%
* Reduced One handed swords accuracy boost from 5% to 2%
* Cup of milk provide Well fed 1 instead of Well fed 2
* Cup of honey milk now correctly provide Well fed 2

Modules
* Included a new module : Fall damage (!DGM_Module_FallDamage on|off). This module enable fall damage when using Jump, Projectiles and when being victim of a Force effect (e.g. Blowback skill in GM mode).
	- Damage starts after 5 meters high, you get knocked down after 12 meters and death is guaranteed after 15 meters.
	- Scoundrel increase all those values by 0.5m per point
	- If you have Wings or Pure, you are immune to fall damage
	- /!\ CAUTION : The AI is unable to take fall damage into account. Enabling this against AI isn't recommended at all. This module is designed for the GM to play opponents.
	
#0.11.19.27 (Trompdoy)
Fixes
* Fixed Walk it Off description not being correct
* Fixed an issue where talents special effects would not be applied when reloading a game

Balance
* Reduced Bows and Crossbows critical multiplier from 150 to 130
* Reduced Bows base damage from 85 to 70
* Reduced Crossbows base damage from 105 to 90
* Reduced Bows range from 1300 to 1100
* Reduced Crossbows range from 1300 to 1250
* Reduced Elemental Weapon base damage bonus from 40 to 25 for elements and 30 to 15 for blood

Modules
* Changed the fall damage formula. Starts at 20% HP at 5 meters and go up to 100% at 15 meters
* Scoundrel now increase fall distance tolerance by 0.4m per point instead of 0.5m

#0.12.20.29 (Han)
Fixes
* Improved performance on the server side, which was causing desyncs to the host itself and also to clients
* Walk it off status does not get back to the first stage after reaching the third one
* Fixed Walk it off not triggering in certain conditions
* Fixed an issue in the Fall damage module where fall damage would be randomly applied during inappropriate moments
* Fixed skillbooks with spells requirements that have been lowered not appearing and with wrong requirements
* Fixed some skills damage not displaying correctly
* Reflection damage shouldn't be scaled with attributes anymore

Balance
* (V53+) Story mode : NPCs stats have been adjusted to take into account damage from all attributes, so they should all have less Strength, Finesse and Intelligence for similar damage compared to vanilla.
* Breathing Bubble now give 15% Accuracy (again)
* Medusa Head slow aura now go through magic armor
* Increased Bows base damage from 70 to 75 and critical multiplier from 130 to 140
* Increased Crossbows base damage from 90 to 95 and critical multiplier from 130 to 140
* Two Handed does not provide Accuracy anymore
* Changed Damage and Armors calculations for a number of hits to take a character down similar to vanilla.
	- VitalityToDamageRatio : 6.5 > 8.0
	- VitalityToDamageRatioGrowth : 0.2 > 0.3
	- ArmorToVitality : 0.45 > 0.35

Modules
* Added an option to the Fall damage module to disable jump fall damage (in that case, only fall damage from Force skills will work)

#0.13.21.30 (Claud)
Fixes
* Staggered and Confused are not triggered if the target have remaining armor anymore
* Fixed Mnemonics not refreshing correctly
* Fixed Perseverance not giving HP
* Fixed Perseverance not giving HP and armors after Staggered/Confused expiration
* Fixed Ice King not giving the proper Water Resistance
* Fixed an issue where walking on surfaces giving CCs through armor (Frozen surfaces) would not apply Staggered/Confused when having Momentum/Lingering with magic armor
* Fixed an issue with custom bonuses not refreshing correctly
* Tweaked Strength and Intelligence descriptions to be more clear about their behavior on skills

Balance
* Encourage Constitution bonus lowered from base 3 to base 2
* Story Mode : slightly decreased the attributes and damage debuff
* Condor Vitality increased from 40 to 60
* Condor armors increased from 0 to 20
* Increased Bows range from 1100 to 1200
* Increased Crossbow range from 1250 to 1300
* Enraged does not reduce armors anymore, but provide a -15 Accuracy penalty instead
* Breathing Bubble accuracy bonus reduced from 15 to 10
* Demon doesn't increase damage from burning statuses anymore but grants immunity to Burning and Necrofire instead
* Ice King now also give Chilled immunity
* Cursed frozen surfaces have now 50% chance per 2m to set Frozen for 1 turn instead of 75% per 2m to set Frozen for 2 turns
* Cursed electrified surfaces now have 50% chance per 2m to set Stunned for 1 turn (through magic armor). It also set Shocked if you don't have magic armor.
* Cursed electrified clouds now have 50% chance per 2m to set Stunned for 1 turn (through magic armor). It also set Shocked if you don't have magic armor.
* Cursed electrified surfaces does not de-electrify when someone get stunned or shocked anymore
* Normal electrified surfaces and cloud now apply Shocked as a keep alive status - which mean the status duration won't progress until the character get out of the surface. Getting shocked doesn't de-electrify the surface anymore.
* Two Handed weapons now have higher attribute requirements (12 > 14)
* Executioner now provide Hasted for 1 turn when dealing a killing blow (unless the character already have Hasted)

