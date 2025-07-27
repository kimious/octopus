class Engine
  def self.trigger(workflow, inputs)
    # TODO: fail if missing trigger inputs
    instance = workflow.create_instance!(inputs)
    inputs = instance.node_inputs(workflow.initial_node)
    EngineJob.perform_async(instance.id, workflow.initial_node, inputs)
    instance
  end
end
