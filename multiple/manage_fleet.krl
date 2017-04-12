ruleset manage_fleet {

  meta {
    name "Fleet Manager"
    description << ruleset for fleet pico >>
    author "Alan Moody"
    logging on
    use module Subscriptions
    shares vehicles, __testing
  }


  global {

    vehicles = function(){
        ent:fleet_vehicles
    }

    get_name = function(vehicle_id) {
      "Vehicle " + vehicle_id
    }

    get_vehicle = function(vehicle_id) {
      ent:fleet_vehicles{vehicle_id}
    }

    get_subscription = function(vehicle_id){
        "Subscription" + vehicle_id
    }

    __testing = { "queries" : [ { "name"   : "vehicles" } ],
                  "events"  : [ { "domain" : "car",
                                  "type"   : "new_vehicle",
                                  "attrs"  : [ "vehicle_id" ]} ]}
  }

  rule create_vehicle {
    select when car new_vehicle
    pre {
      vehicle_id = event:attr("vehicle_id")
      eci = meta:eci
      exists = ent:fleet_vehicles >< vehicle_id
    }
    if exists then
      send_directive("vehicle exists!") with vehicle_id = vehicle_id
    fired{}
    else {
      raise pico event "new_child_request"
      attributes {
        "vehicle_id" : vehicle_id,
        "dname": get_name(vehicle_id)}
    }
  }

  rule pico_child_initialized {
    select when pico child_initialized
    pre {
      child = event:attr("new_child")
      vehicle_id = event:attr("rs_attrs"){"vehicle_id"}.klog("Howdy, Y'all!")
      eci = meta:eci
    }
    event:send(
      { "eci": child.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "rid": "Subscriptions", "vehicle_id": vehicle_id } })
    event:send(
      { "eci": child.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "rid": "trip_store", "vehicle_id": vehicle_id } } )
    event:send(
      { "eci": child.eci, "eid": "install-ruleset",
        "domain": "pico", "type": "new_ruleset",
        "attrs": { "rid": "track_trips_2", "vehicle_id": vehicle_id } } )
    event:send(
      { "eci": eci, "eid": "subscription",
        "domain": "wrangler", "type": "subscription",
        "attrs": {
          "name": get_subscription(vehicle_id),
          "name_space": "car",
          "my_role": "fleet",
          "subscriber_role": "vehicle",
          "channel_type": "subscription",
          "subscriber_eci": child.eci
        }
      }
    )
    fired {
      ent:fleet_vehicles := ent:fleet_vehicles.defaultsTo({});
      ent:fleet_vehicles{vehicle_id} := child;
    }
  }

  rule delete_vehicle {
    select when car unneeded_vehicle
    pre{
        vehicle_id = event:attr("vehicle_id")
        exists = ent:fleet_vehicles >< vehicle_id
        eci = meta:eci
        vehicle_to_delete = get_vehicle(vehicle_id)
    }
    if exists then
        send_directive("vehicle_deleted") with vehicle_id = vehicle_id
    fired {
        raise wrangler event "subscription_cancellation"
          with subscription_name = "car:" + get_subscription(vehicle_id);
        raise pico event "delete_child_request"
          attributes vehicle_to_delete;
        ent:fleet_vehicles{[vehicle_id]} := null
    }
    else {
      send_directive("vehicle unknown")
        with vehicle_id = vehicle_id
    }
  }

  rule delete_all_vehicles{
      select when fleet delete_all_vehicles
      always{
        ent:fleet_vehicles := {}
      }
  }

}
