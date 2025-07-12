class EngineJob
  include Sidekiq::Job

  def self.on_success(params)
    new.handle_result!(
      params[:workflow_instance_id],
      params[:node_name],
      params[:result]
    )
  end

  def perform(workflow_instance_id, node_name, params)
    node_class = Nodes.const_get(node_name.split("__")[0].camelize)
    node = node_class.new

    if node.batch?
      node.on(:success, EngineJob, { workflow_instance_id:, node_name: })
      node.batch(**(params.deep_symbolize_keys))
    else
      result = node.perform(**(params.deep_symbolize_keys))
      handle_result!(workflow_instance_id, node_name, result)
    end
  end

  def handle_result!(workflow_instance_id, node_name, result)
    instance = WorkflowInstance.find(workflow_instance_id)

    result.each do |param, value|
      instance.state[node_name][param.to_s] = value
    end

    instance.save_state!(node_name)
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
        EngineJob.perform_async(workflow_instance_id, output_node, params)
      end
    end
  end
end
