# Engine-level pause node. When reached, the workflow halts and
# `WorkflowInstance#status` flips to `waiting_approval`. The chat UI / admin
# resumes via `WorkflowInstance#approve!(gate_ref)` or
# `#reject_with_feedback!(gate_ref, text)`. On rejection, the engine clears
# the gate plus all downstream context and re-enqueues the configured
# `re_runs` node (default: the gate's immediate predecessor) with the
# feedback text injected as a `feedback` input.
#
# Inputs are dynamic: the workflow JSON can wire any artifact from upstream
# (e.g. `script`, `documents`) into the gate purely so the chat UI can
# display what is being approved. Downstream nodes should wire their inputs
# from the original producing node, not from the gate; the gate's `next`
# chain is set explicitly in the workflow JSON via `"next": [...]`.
#
# Supported `config` keys (set per-gate in the workflow JSON):
#   - `re_runs` (String, optional): node ref to re-enqueue on rejection.
#     Defaults to the gate's immediate predecessor.
#   - `max_iterations` (Integer, optional): cap on the number of rejections
#     allowed for this gate. Omitted / nil means infinite. Exceeding the cap
#     raises `WorkflowInstance::MaxIterationsExceeded`.
module Nodes
  class ApprovalGate < ::Node
    describe "Pauses the workflow until a user approves or rejects with feedback"

    has_output :decision, type: String, description: "approved | pending"

    def self.pauses? = true

    # Accept any input name so workflows can wire arbitrary artifacts in for display.
    def self.valid_input?(_input) = true

    # Accept any output name so downstream nodes can wire from the gate's
    # pass-through outputs (e.g. `approval_gate#0.outputs.script`). The actual
    # schema outputs list is populated by `WorkflowBuilder` as inputs are
    # wired in.
    def self.valid_output?(_output) = true

    def perform(*)
      { decision: "pending" }
    end
  end
end
