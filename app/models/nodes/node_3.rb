module Nodes
  class Node3
    def perform(x:)
      sleep rand(10) + 1
      { a: x + 1 }
    end
  end
end
