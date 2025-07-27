class WorkflowInstance < ApplicationRecord
  belongs_to :workflow

  enum :status, { idle: "idle", running: "running", failed: "failed", completed: "completed" }

  def current_nodes = state.keys

  def node_inputs(node_name)
    inputs = {}
    schema[node_name]["inputs"].each do |name, config|
      case config["source"]
      in "static"
        inputs[name] = config["value"]
      in "context"
        inputs[name] = context.dig(*config["path"].split("."))
      in nil
        inputs[name] = Node.node_for(node_name).inputs[name.to_sym][:default]
      end
    end
    inputs
  end

  def log_failure!(failure)
    self.class.connection.execute(
      <<-SQL.squish)
        UPDATE workflow_instances
        SET status = 'failed',
            failures = failures || #{self.class.connection.quote(self.class.sanitize_sql([ failure ].to_json))}::jsonb
        WHERE id = #{id}
      SQL
  end

  def save_context!(node_name, inputs, outputs)
    self.class.connection.execute(
      <<-SQL.squish)
        UPDATE workflow_instances
        SET context = context || #{self.class.connection.quote(self.class.sanitize_sql({ node_name => { inputs:, outputs: } }.to_json))}::jsonb
        WHERE id = #{id}
      SQL
  end
end
