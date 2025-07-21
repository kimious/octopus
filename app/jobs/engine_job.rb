class EngineJob
  include Sidekiq::Job

  def perform(workflow_instance_id, node_name, params)
    instance = WorkflowInstance.find(workflow_instance_id)
    node_class = Nodes.const_get(node_name.split("__")[0].camelize)
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
