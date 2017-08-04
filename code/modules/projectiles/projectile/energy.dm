/obj/item/projectile/energy
	name = "energy"
	icon_state = "spark"
	damage = 0
	damage_type = BURN
	check_armour = "energy"
	mob_hit_sound = list('sound/effects/gore/sear.ogg')


//releases a burst of light on impact or after travelling a distance
/obj/item/projectile/energy/flash
	name = "chemical shell"
	icon_state = "bullet"
	fire_sound = 'sound/weapons/gunshot/gunshot_pistol.ogg'
	damage = 5
	agony = 10
	kill_count = 15 //if the shell hasn't hit anything after travelling this far it just explodes.
	muzzle_type = /obj/effect/projectile/bullet/muzzle
	var/flash_range = 1
	var/brightness = 7
	var/light_colour = "#ffffff"
	var/stun_strength = 2

/obj/item/projectile/energy/flash/on_impact(var/atom/A)
	var/turf/T = flash_range? src.loc : get_turf(A)
	if(!istype(T)) return

	// Blind adjacent people
	for (var/mob/living/carbon/M in viewers(T, flash_range))
		var/eye_safety = M.eyecheck()
		var/dist = get_dist_euclidian(M, src)

		if (eye_safety < FLASH_PROTECTION_MODERATE)
			M.flash_eyes()
			M.Stun(stun_strength * (1 - flash_range / (dist+1)))

	// Deafen adjacent people
	var/sound_range = max(round(flash_range*1.5), 1)
	for (var/mob/living/carbon/M in viewers(T, sound_range))
		var/ear_safety = 0
		if (ishuman(M)) // Copied from flashbang.dm
			if(istype(M:l_ear, /obj/item/clothing/ears/earmuffs) || istype(M:r_ear, /obj/item/clothing/ears/earmuffs))
				ear_safety += 2
			if(HULK in M.mutations)
				ear_safety += 1
			if(istype(M:head, /obj/item/clothing/head/helmet))
				ear_safety += 1
		var/dist = get_dist_euclidian(M, src)
		var/ear_power = 2 * src.stun_strength * max(1 - ear_safety / 2, 0) * (1 - (dist / sound_range))
		if (ear_power > 0)
			M << "<span class='danger'>Your ears ring!</span>"
			M.Weaken(ear_power)
			M.ear_deaf += rand(ear_power / 2, ear_power)
			M.ear_damage += rand(0, ear_power / 2)

	//snap pop
	playsound(src, 'sound/effects/bang.ogg', 50, 1)
	src.visible_message("<span class='warning'>\The [src] explodes in a bright flash with loud sound!</span>")

	var/datum/effect/effect/system/spark_spread/sparks = new /datum/effect/effect/system/spark_spread()
	sparks.set_up(2, 1, T)
	sparks.start()

	new /obj/effect/decal/cleanable/ash(src.loc) //always use src.loc so that ash doesn't end up inside windows
	new /obj/effect/effect/smoke/illumination(T, 5, brightness, brightness, light_colour)

//blinds people like the flash round, but in a small area and can also be used for temporary illumination
/obj/item/projectile/energy/flash/flare
	damage = 10
	fire_sound = 'sound/weapons/gunshot/shotgun.ogg'
	flash_range = 4 // Half a flashbang
	brightness = 15
	stun_strength = 5

/obj/item/projectile/energy/flash/flare/on_impact(var/atom/A)
	light_colour = pick("#e58775", "#ffffff", "#90ff90", "#a09030")

	..() //initial flash

	//residual illumination
	new /obj/effect/effect/smoke/illumination(src.loc, rand(190,240) SECONDS, range=8, power=3, color=light_colour) //same lighting power as flare

/obj/item/projectile/energy/electrode
	name = "electrode"
	icon_state = "spark"
	fire_sound = 'sound/weapons/Taser.ogg'
	mob_hit_sound = list('sound/weapons/tase.ogg')
	nodamage = 1
	taser_effect = 1
	agony = 40
	stun = 5 // It's a STUNNING weapons for fuck sake. This much time should be enough to close in and stun criminal scum with proper tools.
	damage_type = PAIN
	//Damage will be handled on the MOB side, to prevent window shattering.

/obj/item/projectile/energy/electrode/stunshot
	nodamage = 0
	damage = 10
	agony = 60
	stun = 7
	damage_type = BURN

/obj/item/projectile/energy/declone
	name = "decloner beam"
	icon_state = "declone"
	fire_sound = 'sound/weapons/pulse3.ogg'
	damage = 30
	damage_type = CLONE
	irradiate = 40


/obj/item/projectile/energy/dart
	name = "dart"
	icon_state = "toxin"
	damage = 5
	damage_type = TOX
	weaken = 5


/obj/item/projectile/energy/bolt
	name = "bolt"
	icon_state = "cbbolt"
	damage = 10
	damage_type = TOX
	nodamage = 0
	agony = 40
	stutter = 10


/obj/item/projectile/energy/bolt/large
	name = "largebolt"
	damage = 20
	agony = 60


/obj/item/projectile/energy/neurotoxin
	name = "neuro"
	icon_state = "neurotoxin"
	damage = 5
	damage_type = TOX
	weaken = 5

/obj/item/projectile/energy/phoron
	name = "phoron bolt"
	icon_state = "energy"
	fire_sound = 'sound/effects/stealthoff.ogg'
	damage = 20
	damage_type = TOX
	irradiate = 20

/obj/item/projectile/energy/plasmastun
	name = "plasma pulse"
	icon_state = "plasma_stun"
	fire_sound = 'sound/weapons/blaster.ogg'
	armor_penetration = 10
	kill_count = 4
	damage = 5
	agony = 70
	damage_type = BURN
	vacuum_traversal = 0

/obj/item/projectile/energy/plasmastun/proc/bang(var/mob/living/carbon/M)

	to_chat(M, "<span class='danger'>You hear a loud roar.</span>")
	var/ear_safety = 0
	var/mob/living/carbon/human/H = M
	if(iscarbon(M))
		if(ishuman(M))
			if(istype(H.l_ear, /obj/item/clothing/ears/earmuffs) || istype(H.r_ear, /obj/item/clothing/ears/earmuffs))
				ear_safety += 2
			if(HULK in M.mutations)
				ear_safety += 1
			if(istype(H.head, /obj/item/clothing/head/helmet))
				ear_safety += 1
	if(ear_safety == 1)
		M.make_dizzy(120)
	else if (ear_safety > 1)
		M.make_dizzy(60)
	else if (!ear_safety)
		M.make_dizzy(300)
		M.ear_damage += rand(1, 10)
		M.ear_deaf = max(M.ear_deaf,15)
	if (M.ear_damage >= 15)
		to_chat(M, "<span class='danger'>Your ears start to ring badly!</span>")
		if (prob(M.ear_damage - 5))
			to_chat(M, "<span class='danger'>You can't hear anything!</span>")
			M.sdisabilities |= DEAF
	else
		if (M.ear_damage >= 5)
			to_chat(M, "<span class='danger'>Your ears start to ring!</span>")
	M.update_icons()

/obj/item/projectile/energy/plasmastun/on_hit(var/atom/target)
	bang(target)
	. = ..()
