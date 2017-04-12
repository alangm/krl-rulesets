ruleset trip_store {

  meta {
    name "trip_store"
    description << Track trips ruleset for part 2 >>
    author "Alan Moody"
    logging on
    shares trips, long_trips, short_trips
  }

  global {
      trips = function() {
        trips;
      }
      long_trips = function(){
        long_trips;
      }
      short_trips = function(){
        short_trips = ent:trips.filter(function(k,v){ent:trips{k} != ent:long_trips{k}});
        short_trips;
      }
  }

  rule collect_trips {
    select when explicit trip_processed
    pre {
      mileage = event:attr("mileage").klog("mileage: ");
    }
    fired {
      set ent:trip_store{time:now()} miles;
    }
  }

  rule collect_long_trips {
    select when explicit found_long_trip
    pre {
      mileage = event:attr("mileage").klog("mileage: ");
    }
    fired{
      set ent:long_trip_store{time:now()} miles;
    }
  }

  rule clear_trips {
    select when car trip_reset
    always{
      clear ent:trip_store;
      clear ent:long_trip_store;
    }
  }
}
