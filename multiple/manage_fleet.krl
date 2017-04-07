ruleset manage_fleet {

  meta {
    name "Fleet Manager"
    description << Ruleset for fleet pico >>
    author "Alan Moody"
    logging on
    sharing on

    use module  b507199x5 alias wrangler
    provides vehicles

  }
  global {
    
    vehicles = function() {
      wranglerSubscriptions = wrangler:subscriptions();
      subscriptions = wranglerSubs{"subscriptions"};
      vehicles = subscriptions{"subscribed"};
      vehicles2 = vehicles.map(function(vehicle){
                vals = vehicle.values();
                vals.head();
      });
      filtered_subscriptions = vehicles2.filter(function(obj) {
          obj{"status"} eq "subscribed" && obj{"relationship"} eq "Fleet" && obj{"name_space"} eq "Fleet_Subscriptions"
        });
      filtered_subscriptions;
    }


  rule create_vehicle {
    select when car new_vehicle
    pre {
      name = "Vehicle-" + ent:wtf.as(str);
      attributes = {}
                    .put(["Prototype_rids"],"b507782x4.dev;b507782x2.dev;b507782x3.dev") 
                    .put(["name"], name) 
                    .put(["parent_eci"],"C098478E-0507-11E6-BD6B-81ADE71C24E1")
                    ;

    }
    {
      event:send({"cid":meta:eci()}, "wrangler", "child_creation")  
      with attrs = attributes.klog("attributes: "); 
    }
    always{
      set ent:wtf 0 if not ent:wtf;
      set ent:wtf ent:wtf + 1;
      log("create child for " + child);
    }
  }

  rule delete_vehicle {
        select when car unneeded_vehicle
            pre {
                eci = event:attr("eci").klog("delete: ");
                attributes = {}
                            .put(["toDelete"], eci)
                            ;
                back_channel_eci = get_back_channel_eci_by_eci(eci);
                bc_attributes = {}
                                    .put(["eci"], back_channel_eci)
                                    ;
            }

            if (eci neq '') then {
                event:send({"cid":meta:eci()}, "wrangler", "child_deletion")
                    with attrs = attributes.klog("del attributes: ");
                event:send({"cid":meta:eci()}, "wrangler", "subscription_removal")
                    with attrs = bc_attributes.klog("bc_attributes: ");
            }
    }


}
