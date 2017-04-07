ruleset track_trips_2 {

  meta {
    name "track_trips_2"
    description << Track trips ruleset for part 2 >>
    author "Alan Moody"
    logging on
    sharing on
    provides long_trip
  }
  global {
    long_trip = 100
  }

  rule process_trip {
    select when car new_trip
    pre {
      mileage = event:attr("mileage").klog("mileage: ");
    }
    send_directive("trip") with
      length = mileage
  }

  rule find_long_trips {
    select when explicit trip_processed
    pre {
      mileage = event:attr("mileage").klog("mileage: ");
    }
    noop();
    fired {
      raise explicit event found_long_trip if (mileage >= long_trip)
    }
  }

  rule found_long_trip {
    select when explicit found_long_trip
    noop();
  }

}
