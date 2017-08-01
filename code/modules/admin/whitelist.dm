/client/verb/add_to_whitelist(pckey as text)
	set category = "OOC"
	set name = "Invite to Whitelist"

	if (!pckey)
		return

	var/response = alert(src, "Are you sure you want to invite [pckey] to the whitelist?", "You may invite only 2 users.", "Yes", "No")

	var/host = ckey
	if(response == "Yes")
		if (add_to_WL(pckey, host))
			to_chat(usr,"Successfuly added [pckey] into the whitelist.")
		else
			to_chat(usr,"Unable to add [pckey] into the whitelist.")

/client/proc/cmd_admin_add_to_wl(pckey as text)
	set category = "Whitelist"
	set name = "Add to Whitelist"

	if(!check_rights(R_WL))	return

	add_to_WL(pckey)

/client/proc/cmd_admin_remove_from_wl(pckey as text)
	set category = "Whitelist"
	set name = "Remove from Whitelist"

	if(!check_rights(R_WL))	return

	remove_from_WL(pckey)

/client/proc/cmd_admin_ban_from_wl(pckey as text)
	set category = "Whitelist"
	set name = "Ban from Whitelist"

	if(!check_rights(R_WL))	return

	ban_from_WL(pckey)

/client/proc/cmd_admin_add_all()
	set category = "Whitelist"
	set name = "Add all last seen players (60 days)"

	var/DBQuery/query_inactive = dbcon.NewQuery("SELECT ckey, lastseen FROM erro_player WHERE datediff(Now(), lastseen) < 60")
	query_inactive.Execute()
	while(query_inactive.NextRow())
		var/cur_ckey = query_inactive.item[1]
		add_to_WL(cur_ckey)

/proc/InWL(pckey)
	var/dbckey = sql_sanitize_text(pckey)
	var/DBQuery/select_query = dbcon.NewQuery("SELECT ckey, host FROM whitelist WHERE (ckey = '[dbckey]')")
	select_query.Execute()
	var/ckey
	var/host
	while(select_query.NextRow())
		ckey = select_query.item[1]
		host = select_query.item[2]
	if(ckey && host != "banned")
		return 1
	return 0

/proc/IsBannedWL(pckey)
	var/dbckey = sql_sanitize_text(pckey)
	var/DBQuery/select_query = dbcon.NewQuery("SELECT host FROM whitelist WHERE (ckey = '[dbckey]')")
	select_query.Execute()

	var/host
	while(select_query.NextRow())
		host = select_query.item[1]
	if(host && host == "banned")
		return 1
	return 0

/proc/add_to_WL(pckey as text, host=null as text)
	if(!pckey)
		return 0

	establish_db_connection()
	if(!dbcon.IsConnected())
		return 0

	if(InWL(pckey))	return 0
	if(IsBannedWL(pckey)) return 0

	var/dbhost
	if(host)
		dbhost = sql_sanitize_text(host)
		var/DBQuery/select_query = dbcon.NewQuery("SELECT * FROM whitelist WHERE (host = '[dbhost]')")
		select_query.Execute()
		var/counter = 0
		while(select_query.NextRow())
			counter++
		if(counter > 1)
			return 0

	var/dbckey = sql_sanitize_text(pckey)
	var/DBQuery/query = dbcon.NewQuery("INSERT INTO whitelist (ckey, host) VALUES ('[dbckey]', '[host? "[dbhost]" : "root"]')")
	query.Execute()

	var/log = "[pckey] was added into the whitelist by [usr] ([host ? "user" : "admin"])."
	message_admins(log)
	log_admin(log)
	whitelist_log_save(log)

	return 1

/proc/remove_from_WL(pckey as text)
	if(!pckey)
		return 0

	establish_db_connection()
	if(!dbcon.IsConnected())
		return 0

	if(!InWL(pckey))	return 0

	var/dbckey = sql_sanitize_text(pckey)
	var/DBQuery/select_query = dbcon.NewQuery("SELECT ckey FROM whitelist WHERE (host = '[dbckey]')")
	select_query.Execute()
	var/ckey
	while(select_query.NextRow())
		ckey = select_query.item[1]
		if(ckey)
			var/DBQuery/query = dbcon.NewQuery("UPDATE whitelist SET (host = 'root') WHERE (ckey = '[ckey]')")
			query.Execute()

	var/DBQuery/query = dbcon.NewQuery("DELETE * FROM whitelist WHERE (ckey = '[pckey]')")
	query.Execute()

	var/log = "[pckey] has been removed from the whitelist by [usr]."
	message_admins(log)
	log_admin(log)
	whitelist_log_save(log)

	return 1

/proc/ban_from_WL(pckey as text, branch = 0)
	if(!pckey)
		return 0

	establish_db_connection()
	if(!dbcon.IsConnected())
		return 0

	if(!InWL(pckey))	return 0

	var/dbckey = sql_sanitize_text(pckey)
	var/DBQuery/select_query = dbcon.NewQuery("SELECT ckey FROM whitelist WHERE (host = '[dbckey]')")
	select_query.Execute()
	var/ckey1
	while(select_query.NextRow())
		ckey1 = select_query.item[1]

		if(ckey1)
			ban_from_WL(ckey1, 1)

	if(!branch)
		var/DBQuery/query = dbcon.NewQuery("UPDATE whitelist SET (host = 'banned') WHERE (ckey = '[dbckey]')")
		query.Execute()

		var/log = "[pckey] has been banned from the whitelist by [usr]."
		message_admins(log)
		log_admin(log)
		whitelist_log_save(log)
	else
		var/DBQuery/query = dbcon.NewQuery("DELETE * FROM whitelis WHERE (ckey = '[dbckey]')")
		query.Execute()

		var/log = "[pckey] has been removed from the whitelist automaticly."
		message_admins(log)
		log_admin(log)
		whitelist_log_save(log)

	return 1

/proc/whitelist_log_save(var/formatted_log)
	text2file(formatted_log,"data/whitelist.txt")