/*

Zone Air System:

This air system divides the station into impermeable areas called zones.
When something happens, i.e. a door opening or a wall being taken down,
zones equalize and eventually merge. Making an airtight area closes the connection again.

Control Flow:
Every air tick:
	Marked turfs are updated with update_air_properties(), followed by post_update_air_properties().
	Edges, including those generated by connections in the previous step, are processed. This is where gas is exchanged.
	Fire is processed.
	Marked zones have their air archived.

Important Functions:

SSair.mark_for_update(turf)
	When stuff happens, call this. It works on everything. You basically don't need to worry about any other
	functions besides CanPass().

Notes for people who used ZAS before:
	There is no connected_zones anymore.
	To get the zones that are connected to a zone, use this loop:
	for(var/connection_edge/zone/edge in zone.edges)
		var/zone/connected_zone = edge.get_connected_zone(zone)

==========================
======  Controller  ======
==========================

Overview:
	The air controller does everything. There are tons of procs in here.

Class Vars:
	zones - All zones currently holding one or more turfs.
	edges - All processing edges.

	tiles_to_update - Tiles scheduled to update next tick.
	zones_to_update - Zones which have had their air changed and need air archival.
	active_hotspots - All processing fire objects.

	active_zones - The number of zones which were archived last tick. Used in debug verbs.
	next_id - The next UID to be applied to a zone. Mostly useful for debugging purposes as zones do not need UIDs to function.

Class Procs:

	mark_for_update(turf/T)
		Adds the turf to the update list. When updated, update_air_properties() will be called.
		When stuff changes that might affect airflow, call this. It's basically the only thing you need.

	add_zone(zone/Z) and remove_zone(zone/Z)
		Adds zones to the zones list. Does not mark them for update.

	air_blocked(turf/A, turf/B)
		Returns a bitflag consisting of:
		AIR_BLOCKED - The connection between turfs is physically blocked. No air can pass.
		ZONE_BLOCKED - There is a door between the turfs, so zones cannot cross. Air may or may not be permeable.

	has_valid_zone(turf/T)
		Checks the presence and validity of T's zone.
		May be called on unsimulated turfs, returning 0.

	merge(zone/A, zone/B)
		Called when zones have a direct connection and equivalent pressure and temperature.
		Merges the zones to create a single zone.

	connect(turf/simulated/A, turf/B)
		Called by turf/update_air_properties(). The first argument must be simulated.
		Creates a connection between A and B.

	mark_zone_update(zone/Z)
		Adds zone to the update list. Unlike mark_for_update(), this one is called automatically whenever
		air is returned from a simulated turf.

	equivalent_pressure(zone/A, zone/B)
		Currently identical to A.air.compare(B.air). Returns 1 when directly connected zones are ready to be merged.

	get_edge(zone/A, zone/B)
	get_edge(zone/A, turf/B)
		Gets a valid connection_edge between A and B, creating a new one if necessary.

	has_same_air(turf/A, turf/B)
		Used to determine if an unsimulated edge represents a specific turf.
		Simulated edges use connection_edge/contains_zone() for the same purpose.
		Returns 1 if A has identical gases and temperature to B.

	remove_edge(connection_edge/edge)
		Called when an edge is erased. Removes it from processing.

*/
