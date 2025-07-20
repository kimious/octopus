class EngineJob
  include Sidekiq::Job

  def self.on_success(params)
    instance = WorkflowInstance.find(params[:workflow_instance_id])
    new.handle_result!(
      instance,
      params[:node_name],
      params[:params],
      params[:result]
    )
  end

  def perform(workflow_instance_id, node_name, params)
    instance = WorkflowInstance.find(workflow_instance_id)
    node_class = Nodes.const_get(node_name.split("__")[0].camelize)
    node = node_class.new
    params = instance.filter_node_inputs(node_name, params)

    if node.batch?
      node.on(:success, EngineJob, { workflow_instance_id:, node_name:, params: })
      node.perform_batch(**(params.merge(workflow_instance_id:).deep_symbolize_keys))
    else
      node.workflow_instance = instance
      result = node.perform(params)
      handle_result!(instance, node_name, params, result)
    end
  end

  def handle_result!(instance, node_name, params, result)
    result.each do |param, value|
      instance.state[node_name][param.to_s] = value
    end

    instance.save_state!(node_name, params)
    instance.reload

    puts "### state after completing #{node_name}: #{instance.state} (completed: #{instance.state_completed?})"
    if instance.state_completed?
      return if instance.workflow_completed?

      output_results = instance.output_results
      instance.prepare_next_state!

      # TODO:
      # - use Sidekiq batches to handle parellel execution of nodes.
      # - check if state is completed in the batch completion callback
      output_results.each do |output_node, params|
        EngineJob.perform_async(instance.id, output_node, params)
      end
    end
  end
end
