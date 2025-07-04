class Engine
  def self.start(workflow, params)
    instance = workflow.create_instance!
    EngineJob.perform_later(instance.id, workflow.initial_node, params)
    instance
  end
end
