class EngineJob
  include Sidekiq::Job

  sidekiq_options retry: 0
  sidekiq_options backtrace: true

  sidekiq_retries_exhausted do |job, error|
    instance = WorkflowInstance.find(job["args"].first)
    instance.log_failure!(
      error: error.class.name,
      message: error.message,
      node_name: job["args"][1],
      params: job["args"][2],
      location: error.backtrace.first
    )
  end

  def perform(workflow_instance_id, node_name, params)
    instance = WorkflowInstance.find(workflow_instance_id)
    instance.update!(status: "running", failures: [])

    node_class = Node.node_for(node_name)
    node = node_class.new

    if node.batch?
      node.on(:success, EngineJob, { workflow_instance_id:, node_name:, params: })
      node.perform_batch(params)
    else
      node.workflow_instance = instance
      result = node.perform(*node.input_values(params))
      handle_result!(instance, node_name, params, result)
    end
  end

  def self.on_success(params)
    instance = WorkflowInstance.find(params[:workflow_instance_id])
    new.handle_result!(
      instance,
      params[:node_name],
      params[:params],
      params[:result]
    )
  end

  def handle_result!(instance, node_name, params, result)
    instance.save_context!(node_name, params, result)
    instance.reload

    next_nodes = instance.schema[node_name]["next"]

    if next_nodes.empty?
      instance.completed!
      return
    end

    next_nodes.each do |next_node|
      deps = instance.schema.keys.select { |dep_node| instance.schema[dep_node]["next"].include?(next_node) }
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
