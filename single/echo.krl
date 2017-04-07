ruleset echo {

  meta {
    name "echo"
    description << Echo ruleset for part 1 >>
    author "Alan Moody"
    logging on
  }

  global{}

  rule hello {
    select when echo hello
    send_directive("say") with
      something = "Hello World";
  }

  rule message {
    select when echo message
    pre {
      input = event:attr("input")
    }
    send_directive("say") with
      something = input
  }

}
