module Nodes
  class HelloWorld < Node
    describe "A node say hello to someone"
    has_input :name, description: "Person name to say hello to"
    has_output :greetings, description: "The greeting message"

    def perform(name)
      { greetings: "hello world #{name}" }
    end
  end
end
