class Engine
  def self.start(workflow, params)
    instance = workflow.create_instance!(params)
    EngineJob.perform_async(instance.id, workflow.initial_node, params.deep_stringify_keys)
    instance
  end
end
