ruleset manage_fleet {

	meta {
		name "Fleet Manager"
		description << Ruleset for fleet pico >>
		author "Alan Moody"
		logging on
		use module  b507199x5 alias wrangler
		sharing on
		provides vehicles, direct_report
	}

	global {

    vehicles = function() {
  		results = wrangler:children();
  		children = results{ "children" };
  		children;
    };

		direct_report = function(){
			ent:direct_reports;
		};

		cloud_url = "https://#{meta:host()}/sky/cloud/";

		cloud = function(eci, mod, func, params) {
			response = http:get( "#{cloud_url}#{mod}/#{func}"
                         , (params || {}).put(["_eci"], eci));
			status = response{ "status_code" };
			error_info = { "error"       : "cloud request error"
				            , "httpStatus" : { "code"    : status
				                             , "message" : response{ "status_line" }}};

			res = response{"content"}.decode();
			err = (res.typeof() eq "hash" && res{"error"}) => res{"error"} | 0;
			err_msg = (res.typeof() eq "hash" && res{"error_str"}) => res{"error_str"} | 0;
			error = error_info.put({"skyCloudError": err, "skyCloudErrorMsg": err_msg, "skyCloudReturnValue": res});
			is_bad_response = (res.isnull() || res eq "null" || err || err_msg);

			// if HTTP status was OK & the response was not null and there were no errors...
			(status eq "200" && not is_bad_response) => res | error
		};


	}

	rule create_vehicle {
		select when car new_vehicle
		pre {
		  attributes = {}
  			.put(["Prototype_rids"],"b507735x6.prod") // semicolon separated rulesets the child needs installed at creation
  			.put(["name"],event:attr("uid")) // name for child
  			.put(["uid"], event:attr("uid")); //unique id
		}
		{
			event:send({"cid":meta:eci()}, "wrangler", "child_creation")  // wrangler os event.
			with attrs = attributes.klog("attributes: "); // needs a name attribute for child
		}
		always {
			log("create child for " + child);
		}
	}

	rule delete_vehicle {
		select when car unneeded_vehicle
		pre{
			eci = event:attr("eci");
			name = event:attr("name");
		}
		{
			event:send({"cid":meta:eci()}, "wrangler", "child_deletion")
				with attrs = {}.put(["deletionTarget"], eci).klog("attributes for delete: ");
			event:send({"cid":meta:eci()}, "wrangler", "subscription_cancellation")
				with attrs = {}.put(["channel_name"], name).klog("attributes for unsubscription");
		}
	}

	rule getAllReportsDirectly {
		select when car get_direct_reports
		pre{
			attributes = {}.put(["fleet"], vehicles())//unique id
			.put(["length"], vehicles().length()).klog("Attributes from start of process: ");
		}
		{
			noop();
		}
		always {
			clear ent:direct_reports;
			set ent:direct_reports [];
			raise explicit event "direct_report_piece"
				attributes attributes;
		}
	}

	rule getOneReport {
		select when explicit direct_report_piece
		foreach event:attr("fleet") setting (v)
		pre {
			eci = v[0].klog("v[0] is: ");
			response = cloud(eci, "b507735x6.prod", "trips", {}).klog(" and respective response is: ");
		}
		if (ent:collectedTrips < 1) then {
			noop();
		}
		fired {
			set ent:direct_reports ent:direct_reports.append([response]);
			raise explicit event "direct_report_piece2"
			 attributes event:attrs();
		}
		else {
			set ent:direct_reports ent:direct_reports.append([response]);
			raise explicit event "direct_report_piece2"
			 attributes event:attrs();
		}
	}

	rule collectdirect_reports {
		select when explicit direct_report_piece2
		pre {
			desiredLength = event:attr("length");
		}
		if (ent:direct_reports.length() == desiredLength)
		then {
			send_directive("fulldirect_report") with
				report = ent:direct_reports.klog("finalReports: ")
		}
	}

rule autoAccept {
    select when wrangler inbound_pending_subscription_added
    pre{
		attributes = event:attrs().klog("subcription :");
	}
	{
		noop();
    }
    always {
		raise wrangler event 'pending_subscription_approval'
        attributes attributes;
		log("auto accepted subcription.");
    }
  }
}
