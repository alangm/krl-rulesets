ruleset track_trips_2 {

  meta {
    name "track_trips_2"
    description << Track trips ruleset for part 2 >>
    author "Alan Moody"
    logging on
    shares long_trip
  }
  global {
    long_trip = 100
  }

  rule process_trip {
    select when car new_trip
    send_directive("trip") with
      length = event:attr("mileage");
  }

  rule find_long_trips {
    select when explicit trip_processed
    noop();
    fired {
      raise explicit event found_long_trip if (event:attr("mileage") >= long_trip)
    }
  }

  rule found_long_trip {
    select when explicit found_long_trip
    noop();
  }

}
