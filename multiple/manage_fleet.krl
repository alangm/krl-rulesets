ruleset manage_fleet {

	meta {
		name "Fleet Manager"
		description << Ruleset for fleet pico >>
		author "Alan Moody"
		logging on
		sharing on
		provides vehicles, subscriptions, fleet_trips, fleet_trips_gather
		use module v1_wrangler alias wranglerOS
	}
	global{
		vehicles = function() {
			results = wranglerOS:children();
			children = results{"children"};
			children;
		};

		subscriptions = function() {
			results = wranglerOS:subscriptions();
			subscriptions = results{"subscriptions"};
			list = subscriptions{"subscribed"};
			list;
		};

		fleet_trips = function() {
			all_trips = vehicles().map(function(vehicle) {
				cloud_url = "https://cs.kobj.net/sky/cloud/";
				mod = "b507764x8.prod";
				func = "trips";
				response = http:get("#{cloud_url}#{mod}/#{func}", (params || {}).put(["_eci"], vehicle[0]));

				status = response{"status_code"};

				response{"content"}.decode();
			});
			all_trips;
		}

		fleet_trips_gather = function() {
			trips = ent:reports;
			trips;
		}

		num_cars_in_report = function(cid) {
			report = ent:reports{[cid]};
			trips.length();
		}
	}
	rule create_vehicle {
		select when car new_vehicle
		pre {
			name = event:attr("vehicle_name");
			attributes = {}
				.put(["Prototype_rids"],"b507963x6.prod;b507963x8.prod;b507963x12.prod") //track_trips_part_2;trip_store;subscription_request
				.put(["name"],name)
				.put(["parent_eci"], "4A51D364-130D-11E7-B8AD-64F1E71C24E1")
				;
		}
		{
			event:send({"cid":meta:eci()}, "wrangler", "child_creation")
				with attrs = attributes.klog("attributes: ");
		}
		always {
			log("create child for " + child);
		}
	}

	rule autoAccept {
		select when wrangler inbound_pending_subscription_added
		pre {
			attributes = event:attrs().klog("subscription: ");
		}
		{
			noop();
		}
		always {
			raise wrangler event "pending_subscription_approval"
				attributes attributes;
				log("auto accepted subscription.")
		}
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
		pre {
			eci = event:attr("target_eci").klog("Pulled target_eci: ");
			channel_name = event:attr("channel_name").klog("Pulled channel_name: ");
			attributes = {}
				.put(["deletionTarget"],eci)
				.put(["channel_name"],channel_name)
				;
		}
		{
			noop();
		}
		always {
			raise wrangler event "child_deletion"
				attributes attributes.klog("attributes: ");
			raise wrangler event "subscription_cancellation"
				attributes attributes.klog("attributes: ");
		}
	}

	rule report_scatter {
		select when car report_scatter
			foreach subscriptions() setting (subscription)
		pre {
			event_eci = subscription.pick("$..event_eci").klog("Event eci: ");
			mycid = random:uuid();
			attr = {}
				.put(["mycid"], mycid)
				;
		}
		{
			event:send({"cid":event_eci},"explicit","report_requested")
				with attrs = attr.klog("attributes: ")
		}
		{
			log("Sent event to: " + event_eci + " with mycid: " + mycid + " with attr: " + attr);
		}
	}

	rule gather_reports {
		select when explicit gather_reports
		pre {
			cid = event:attr("cid");
			report = event:attr("report");
			num_reported = num_cars_in_report(cid);
		}
		always {
			set ent:reports{[cid]} ent:reports{[cid]}.append(report);
		}
	}
}
