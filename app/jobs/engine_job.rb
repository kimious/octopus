class EngineJob < ApplicationJob
  def perform(workflow_instance_id, node_name, params)
    instance = WorkflowInstance.find(workflow_instance_id)
    node_class = Nodes.const_get(node_name.split("__")[0].camelize)
    result = node_class.new.perform(**params)

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
        EngineJob.perform_later(workflow_instance_id, output_node, params.symbolize_keys)
      end
    end
  end
end
