ruleset subscription_request {
	meta {
		name "subscription request"
		description << Ruleset for vehicle to subscribe to fleet pico >>
		author "Alan Moody"
		logging on
		sharing on
		use module v1_wrangler alias wrangler_api
	}
	global{

	}
	rule childToParent {
		select when wrangler init_events
		pre {
			parent_results = wrangler_api:parent();
			parent = parent_results{'parent'};
			parent_eci = parent[0];
			attrs = {}
				.put(["name"], "Family")
				.put(["name_space"], "subscribe")
				.put(["my_role"], "Child")
				.put(["your_role"], "Parent")
				.put(["target_eci"], parent_eci.klog("target Eci: "))
				.put(["channel_type"], "multiple_pico_lab_type")
				.put(["attrs"], "success")
				;
		}
		{
			noop();
		}
		always {
			raise wrangler event "subscription"
				attributes attrs;
		}
	}

}
