module Nodes
  class Node4
    def perform(x:, y:)
      sleep rand(10) + 1
      { final_result: x + y }
    end
  end
end
