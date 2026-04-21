class Engine
  class MissingParameters < StandardError
    attr_reader :workflow_id, :missing_parameters

    def initialize(message, workflow_id, missing_parameters)
      super(message)
      @workflow_id = workflow_id
      @missing_parameters = missing_parameters
    end
  end

  class MissingCredentials < StandardError
    attr_reader :workflow_id, :missing_credentials

    def initialize(message, workflow_id, missing_credentials)
      super(message)
      @workflow_id = workflow_id
      @missing_credentials = missing_credentials
    end
  end

  def self.trigger(workflow, inputs)
    unless workflow.credentials_configured?
      raise MissingCredentials.new(
        "workflow id=#{workflow.id} is missing credentials #{workflow.missing_credentials.to_sentence}",
        workflow.id,
        workflow.missing_credentials
      )
    end

    missing_params = (workflow.required_params - inputs.keys.map(&:to_s))
    if missing_params.any?
      raise MissingParameters.new(
        "workflow id=#{workflow.id} is missing parameters #{missing_params.to_sentence}",
        workflow.id,
        missing_params
      )
    end

    instance = workflow.create_instance!(inputs)
    inputs = instance.node_inputs(workflow.initial_node)
    EngineJob.perform_async(instance.id, workflow.initial_node, inputs)
    instance
  end

  # Resumes a paused workflow by enqueuing nodes downstream of `node_ref`.
  # Mirrors the downstream-enqueue logic in `EngineJob#handle_result!`.
  def self.continue_after(instance, node_ref)
    next_nodes = instance.schema[node_ref]["next"] || []
    return if next_nodes.empty?

    next_nodes.each do |next_node|
      deps = instance.schema.keys.select { |dep_node| (instance.schema[dep_node]["next"] || []).include?(next_node) }
      deps_ready = deps.all? do |dep|
        instance.context.dig(dep, "outputs")&.keys&.sort == instance.schema[dep]["outputs"].sort
      end

      if deps_ready
        inputs = instance.node_inputs(next_node)
        EngineJob.perform_async(instance.id, next_node, inputs)
      end
    end
  end
end
