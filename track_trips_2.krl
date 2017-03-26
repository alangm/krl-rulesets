ruleset track_trips_2 {

  meta {
    name "track_trips_2"
    description << Track trips ruleset for part 2 >>
    author "Alan Moody"
    logging on
    shares new_trip, test
  }

  global {
    test = { "queries" : [],
             "events"  : [{ "domain": "car",
                            "type": "new_trip",
                            "attrs": ["mileage"] }]
    }
    long_trip = 100
  }

  rule process_trip {
    select when car new_trip
    pre {
      mileage = event:attr("mileage").as("Number")
      speed = event:attr("speed").as("Number")
    }
    fired {
      raise explicit event "trip_processed"
        attributes { "mileage" : mileage,
                     "speed"   : speed }
    }
  }

  rule find_long_trips{
  select when explicit trip_processed
    pre {
      mileage = event:attr("mileage").as("Number")
      speed = event:attr("speed").as("Number")
    }
    if(mileage >= long_trip) then
      noop()
      fired {
        raise explicit event "found_long_trip"
          attributes { "mileage" : mileage,
                       "speed"   : speed }
      }
  }
}
