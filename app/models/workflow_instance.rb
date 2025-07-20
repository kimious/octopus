class WorkflowInstance < ApplicationRecord
  belongs_to :workflow

  enum :status, { idle: "idle", running: "running", failed: "failed", stopped: "stopped" }

  def current_nodes = state.keys

  def filter_node_inputs(node_name, inputs)
    inputs.slice(*schema[node_name]["inputs"])
  end

  def output_results
    current_nodes.reduce({}) do |output_nodes, current_node|
      schema[current_node]["outputs"].each do |param, transition|
        output_nodes[transition["node"]] ||= {}
        output_nodes[transition["node"]][transition["param"]] = state[current_node][param]
      end
      output_nodes
    end
  end

  def state_completed?
    state.keys.all? do |node|
      state[node].values.all? { |value| !value.nil? }
    end
  end

  def workflow_completed? = output_results.keys.compact.size.zero?

  def save_state!(node_name, params)
    self.class.connection.execute(
      <<-SQL.squish)
        UPDATE workflow_instances SET
          state = state || '#{self.class.sanitize_sql({ node_name => state[node_name] }.to_json)}'::jsonb,
          context = context || '#{self.class.sanitize_sql({ node_name => { inputs: params, outputs: state[node_name] } }.to_json)}'::jsonb
      SQL
  end

  def prepare_next_state!
    self.state = output_results.keys.reduce({}) do |next_state, output_node|
      next_state.merge(output_node => Hash[schema[output_node]["outputs"].keys.map { |param| [ param, nil ] }])
    end
    save!
  end
end
