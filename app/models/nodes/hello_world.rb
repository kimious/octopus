module Nodes
  class HelloWorld < Node
    has_input :name, description: "Person name to say Hi to"

    has_output :greetings

    def perform(name)
      { greetings: "hello world #{name}" }
    end
  end
end
