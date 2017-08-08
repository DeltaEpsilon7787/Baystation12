#define REFRESH_FREQUENCY 5
/obj/sound_player
	// Virtual object
	// It's the one used to modify shit
	var/range = 15
	var/volume = 100
	var/volume_falloff_exponent = 1 / 1.3
	var/forced_sound_in = 4
	var/falloff = 2
	var/three_dimensional_sound = 1
	var/virtual_environment_selected = -1

	var/datum/synthesized_song/song
	var/datum/instrument/instrument
	var/obj/actual_instrument

	var/list/mob/present_listeners = list()
	var/list/turf/stored_locations = list()
	var/last_updated_listeners = 0

	New(obj/where, datum/instrument/what)
		song = new (src, what)
		actual_instrument = where
		src.loc = where

	Destroy()
		song.playing = 0
		sleep(1)
		for (var/channel in song.musical_free_channels)
			global.musical_free_channels += channel // Deoccupy channels
		qdel(song)
		..()

/obj/sound_player/proc/apply_modifications_for(mob/who, sound/what, note_num, which_line, which_note) // You don't need to override this
	var/mod = (get_dist_euclidian(who, get_turf(src))-1) / src.range
	what.volume = volume / (100**mod**src.volume_falloff_exponent)
	what.environment = src.virtual_environment_selected
	if (get_turf(who) in stored_locations)
		what.volume /= 10 // Twice as low

	if (three_dimensional_sound)
		what.falloff = falloff
		var/turf/source = get_turf(src)
		var/turf/receiver = get_turf(who)
		var/dx = source.x - receiver.x // Hearing from the right/left
		what.x = dx

		var/dz = source.y - receiver.y // Hearing from infront/behind
		what.z = dz
	return

/obj/sound_player/proc/store_blocked()
	src.stored_locations = range(src.range, get_turf(src)) - view(src.range, get_turf(src))

/obj/sound_player/proc/who_to_play_for() // Find suitable mobs to annoy with music
	if (world.time - src.last_updated_listeners > REFRESH_FREQUENCY)
		src.present_listeners.Cut()
		for (var/mob/some_hearer in range(src.range, get_turf(src))) // Apparently hearers only works for local things -- so if something's inside a closet, only things inside this closet can hear it
			if (!(some_hearer.client && some_hearer.mind))
				continue
			if (isdeaf(some_hearer))
				continue
			if (some_hearer.ear_deaf > 0)
				continue
			var/dist = get_dist(some_hearer, src)
			if (!some_hearer.is_preference_enabled(/datum/client_preference/hear_instruments) && dist > forced_sound_in)
				continue
			src.present_listeners += some_hearer
			last_updated_listeners = world.time
	return src.present_listeners

/obj/sound_player/proc/shouldStopPlaying(mob/user)
	return actual_instrument:shouldStopPlaying(user)

/obj/sound_player/proc/channel_overload()
	// Cease playing
	return 0