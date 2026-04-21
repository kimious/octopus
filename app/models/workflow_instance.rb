class WorkflowInstance < ApplicationRecord
  # Raised by `reject_with_feedback!` when an `ApprovalGate`'s
  # `config.max_iterations` cap is reached. Typed so the chat tool / admin
  # controller can decide the UX (force-fail, force-approve, surface a
  # message, etc.) — this layer just refuses to advance.
  class MaxIterationsExceeded < StandardError
    attr_reader :workflow_instance_id, :gate_ref, :max_iterations

    def initialize(message, workflow_instance_id, gate_ref, max_iterations)
      super(message)
      @workflow_instance_id = workflow_instance_id
      @gate_ref = gate_ref
      @max_iterations = max_iterations
    end
  end

  belongs_to :workflow

  enum :status, {
    idle: "idle",
    running: "running",
    waiting_approval: "waiting_approval",
    failed: "failed",
    completed: "completed"
  }

  def current_nodes = state.keys

  # Resolves the runtime input hash for a node from the workflow context.
  # Optional `feedback` input: if the node declares `has_input :feedback` and
  # the context has `context["<node_ref>"]["feedback"]["text"]` (set by
  # `reject_with_feedback!`), it overrides whatever the schema would resolve.
  def node_inputs(node_name)
    inputs = {}
    node_class = Node.node_for(node_name)
    schema[node_name]["inputs"].each do |name, config|
      case config["source"]
      in "static"
        inputs[name] = config["value"]
      in "context"
        inputs[name] = context.dig(*config["path"].split("."))
      in nil
        inputs[name] = node_class.inputs[name.to_sym][:default]
      end
    end

    if node_class.inputs.key?(:feedback)
      feedback = context.dig(node_name, "feedback", "text")
      inputs["feedback"] = feedback if feedback.present?
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

  # Called from chat tool / UI when a user approves a paused gate.
  # Flips the gate's `decision` output from "pending" to "approved" while
  # preserving its pass-through outputs, then resumes downstream nodes.
  def approve!(gate_ref)
    inputs = context.dig(gate_ref, "inputs") || {}
    outputs = (context.dig(gate_ref, "outputs") || {}).merge("decision" => "approved")
    save_context!(gate_ref, inputs, outputs)
    reload
    update!(status: "running")
    Engine.continue_after(self, gate_ref)
  end

  # Called from chat tool / UI when a user rejects a paused gate with
  # feedback. Clears the rejected node and any downstream nodes from the
  # context, injects the feedback for the re_runs target, and re-enqueues
  # that target.
  #
  # Honors the gate's `config.max_iterations` cap if set (positive integer):
  # raises `MaxIterationsExceeded` when the next rejection would exceed it.
  # Omitted / nil means infinite — the default for backwards compatibility.
  def reject_with_feedback!(gate_ref, text)
    re_runs = resolve_re_runs_target(gate_ref)
    raise "no re_runs target resolvable for #{gate_ref}" if re_runs.blank?

    prior_iteration = context.dig(re_runs, "feedback", "iteration") || 0
    next_iteration = prior_iteration + 1

    max_iterations = schema.dig(gate_ref, "config", "max_iterations")
    if max_iterations.is_a?(Integer) && next_iteration > max_iterations
      raise MaxIterationsExceeded.new(
        "approval gate #{gate_ref} has reached its max_iterations=#{max_iterations} cap",
        id, gate_ref, max_iterations
      )
    end

    feedback_payload = { "text" => text, "iteration" => next_iteration }

    nodes_to_clear = [ gate_ref ] + downstream_refs(re_runs)
    new_context = context.dup.except(*nodes_to_clear)
    new_context[re_runs] = (new_context[re_runs] || {}).merge("feedback" => feedback_payload)

    update!(context: new_context, status: "running")
    EngineJob.perform_async(id, re_runs, node_inputs(re_runs))
  end

  private

  def resolve_re_runs_target(gate_ref)
    explicit = schema.dig(gate_ref, "config", "re_runs")
    return explicit if explicit.present?

    schema.find { |_ref, definition| (definition["next"] || []).include?(gate_ref) }&.first
  end

  def downstream_refs(node_ref)
    seen = []
    queue = (schema.dig(node_ref, "next") || []).dup
    while (current = queue.shift)
      next if seen.include?(current)

      seen << current
      queue.concat(schema.dig(current, "next") || [])
    end
    seen
  end
end
