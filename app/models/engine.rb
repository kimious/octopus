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
end
