module Nodes
  class Node1
    def perform(x:)
      sleep rand(10) + 1
      {
        a: x,
        b: x * 2,
        c: x ** 2
      }
    end
  end
end
