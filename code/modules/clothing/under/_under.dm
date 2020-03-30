/obj/item/clothing/under
	icon = 'icons/obj/clothing/uniforms.dmi'
	name = "under"
	body_parts_covered = CHEST|GROIN|LEGS|ARMS
	permeability_coefficient = 0.9
	slot_flags = ITEM_SLOT_ICLOTHING
	armor = list("melee" = 0, "bullet" = 0, "laser" = 0,"energy" = 0, "bomb" = 0, "bio" = 0, "rad" = 0, "fire" = 0, "acid" = 0)
	mutantrace_variation = STYLE_DIGITIGRADE
	var/fitted = FEMALE_UNIFORM_FULL // For use in alternate clothing styles for women
	var/has_sensor = HAS_SENSORS // For the crew computer
	var/random_sensor = TRUE
	var/sensor_mode = NO_SENSORS
	var/can_adjust = TRUE
	var/adjusted = NORMAL_STYLE
	var/alt_covers_chest = FALSE // for adjusted/rolled-down jumpsuits, FALSE = exposes chest and arms, TRUE = exposes arms only
	var/dummy_thick = FALSE // is able to hold accessories on its item
	var/obj/item/clothing/accessory/attached_accessory
	var/mutable_appearance/accessory_overlay

/obj/item/clothing/under/worn_overlays(isinhands = FALSE, icon_file, style_flags = NONE)
	. = list()
	if(isinhands)
		return
	if(damaged_clothes)
		. += mutable_appearance('icons/effects/item_damage.dmi', "damageduniform")
	if(blood_DNA)
		. += mutable_appearance('icons/effects/blood.dmi', "uniformblood", color = blood_DNA_to_color())
	if(accessory_overlay)
		. += accessory_overlay
	if(hasprimary)	//checks if overlays are enabled
		var/mutable_appearance/primary_worn = mutable_appearance(icon_file, "[icon_state]-primary")	//automagical sprite selection
		primary_worn.color = primary_color	//colors the overlay
		. += primary_worn	//adds the overlay onto the buffer list to draw on the mob sprite.
	if(hassecondary)
		var/mutable_appearance/secondary_worn = mutable_appearance(icon_file, "[icon_state]-secondary")
		secondary_worn.color = secondary_color
		. += secondary_worn
	if(hastertiary)
		var/mutable_appearance/tertiary_worn = mutable_appearance(icon_file, "[icon_state]-tertiary")
		tertiary_worn.color = tertiary_color
		. += tertiary_worn

/obj/item/clothing/under/attackby(obj/item/I, mob/user, params)
	if((has_sensor == BROKEN_SENSORS) && istype(I, /obj/item/stack/cable_coil))
		var/obj/item/stack/cable_coil/C = I
		C.use(1)
		has_sensor = HAS_SENSORS
		to_chat(user,"<span class='notice'>You repair the suit sensors on [src] with [C].</span>")
		return 1
	if(!attach_accessory(I, user))
		return ..()

/obj/item/clothing/under/update_clothes_damaged_state(damaging = TRUE)
	..()
	if(ismob(loc))
		var/mob/M = loc
		M.update_inv_w_uniform()
	if(has_sensor > NO_SENSORS)
		has_sensor = BROKEN_SENSORS

/obj/item/clothing/under/New()
	if(random_sensor)
		//make the sensor mode favor higher levels, except coords.
		sensor_mode = pick(SENSOR_OFF, SENSOR_LIVING, SENSOR_LIVING, SENSOR_VITALS, SENSOR_VITALS, SENSOR_VITALS, SENSOR_COORDS, SENSOR_COORDS)
	..()

/obj/item/clothing/under/equipped(mob/user, slot)
	..()
	if(adjusted)
		adjusted = NORMAL_STYLE
		fitted = initial(fitted)
		if(!alt_covers_chest)
			body_parts_covered |= CHEST

	if(attached_accessory && slot != SLOT_HANDS && ishuman(user))
		var/mob/living/carbon/human/H = user
		attached_accessory.on_uniform_equip(src, user)
		if(attached_accessory.above_suit)
			H.update_inv_wear_suit()

/obj/item/clothing/under/dropped(mob/user)
	if(attached_accessory)
		attached_accessory.on_uniform_dropped(src, user)
		if(ishuman(user))
			var/mob/living/carbon/human/H = user
			if(attached_accessory.above_suit)
				H.update_inv_wear_suit()

	..()

/obj/item/clothing/under/proc/attach_accessory(obj/item/I, mob/user, notifyAttach = 1)
	. = FALSE
	if(istype(I, /obj/item/clothing/accessory))
		var/obj/item/clothing/accessory/A = I
		if(attached_accessory)
			if(user)
				to_chat(user, "<span class='warning'>[src] already has an accessory.</span>")
			return
		if(dummy_thick)
			if(user)
				to_chat(user, "<span class='warning'>[src] is too bulky and cannot have accessories attached to it!</span>")
			return
		else
			if(user && !user.temporarilyRemoveItemFromInventory(I))
				return
			if(!A.attach(src, user))
				return

			if(user && notifyAttach)
				to_chat(user, "<span class='notice'>You attach [I] to [src].</span>")

			if((flags_inv & HIDEACCESSORY) || (A.flags_inv & HIDEACCESSORY))
				return TRUE

			var/accessory_color = attached_accessory.icon_state
			accessory_overlay = mutable_appearance('icons/mob/clothing/accessories.dmi', "[accessory_color]")
			accessory_overlay.alpha = attached_accessory.alpha
			accessory_overlay.color = attached_accessory.color

			if(ishuman(loc))
				var/mob/living/carbon/human/H = loc
				H.update_inv_w_uniform()
				H.update_inv_wear_suit()

			return TRUE

/obj/item/clothing/under/proc/remove_accessory(mob/user)
	if(!isliving(user))
		return
	if(!can_use(user))
		return

	if(attached_accessory)
		var/obj/item/clothing/accessory/A = attached_accessory
		attached_accessory.detach(src, user)
		if(user.put_in_hands(A))
			to_chat(user, "<span class='notice'>You detach [A] from [src].</span>")
		else
			to_chat(user, "<span class='notice'>You detach [A] from [src] and it falls on the floor.</span>")

		if(ishuman(loc))
			var/mob/living/carbon/human/H = loc
			H.update_inv_w_uniform()
			H.update_inv_wear_suit()


/obj/item/clothing/under/examine(mob/user)
	. = ..()
	if(can_adjust)
		if(adjusted == ALT_STYLE)
			. += "Alt-click on [src] to wear it normally."
		else
			. += "Alt-click on [src] to wear it casually."
	if (has_sensor == BROKEN_SENSORS)
		. += "Its sensors appear to be shorted out."
	else if(has_sensor > NO_SENSORS)
		switch(sensor_mode)
			if(SENSOR_OFF)
				. += "Its sensors appear to be disabled."
			if(SENSOR_LIVING)
				. += "Its binary life sensors appear to be enabled."
			if(SENSOR_VITALS)
				. += "Its vital tracker appears to be enabled."
			if(SENSOR_COORDS)
				. += "Its vital tracker and tracking beacon appear to be enabled."
	if(attached_accessory)
		. += "\A [attached_accessory] is attached to it."

/obj/item/clothing/under/rank
	dying_key = DYE_REGISTRY_UNDER
