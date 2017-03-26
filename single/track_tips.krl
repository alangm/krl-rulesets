ruleset track_trips {

  meta {
    name "track_trips"
    description << Track tips ruleset for part 1 >>
    author "Alan Moody"
    logging on
    sharing on
  }

  global {}

  rule process_trip {
    select when echo message
    pre {
      mileage = event:attr("mileage")
    }
    send_directive("trip") with
      trip_length = mileage
  }
}
