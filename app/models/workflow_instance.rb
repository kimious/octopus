class WorkflowInstance < ApplicationRecord
  belongs_to :workflow

  enum :status, { idle: "idle", running: "running", failed: "failed", stopped: "stopped" }

  def current_nodes = state.keys

  def node_inputs(node_name)
    inputs = {}
    schema[node_name]["inputs"].each do |name, config|
      case config["type"]
      in "static"
        inputs[name] = config["value"]
      in "context"
        inputs[name] = context.dig(*config["value"].split("."))
      end
    end
    inputs
  end

  def save_context!(node_name, inputs, outputs)
    self.class.connection.execute(
      <<-SQL.squish)
        UPDATE workflow_instances SET
          context = context || #{self.class.connection.quote(self.class.sanitize_sql({ node_name => { inputs:, outputs: } }.to_json))}::jsonb
      SQL
  end
end
