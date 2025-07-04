class Workflow < ApplicationRecord
  has_many :instances, class_name: "WorkflowInstance"

  def create_instance!
    instances.create!(
      schema:,
      status: "idle",
      state: {
        initial_node => Hash[schema[initial_node]["outputs"].keys.map { |param| [ param, nil ] }]
      },
      context: {
        initial_node => Hash[schema[initial_node]["outputs"].keys.map { |param| [ param, nil ] }]
      }
    )
  end

  def initial_node
    @initial_node ||= schema.select { |node, definition| definition["initial_node"] }.keys.first
  end


  def self.demo
    WorkflowInstance.destroy_all
    Workflow.destroy_all

    workflow = create!(
      schema: {
        node_1__0: {
          initial_node: true,
          outputs: {
            a: { node: "node_2__0", param: "x" },
            b: { node: "node_2__0", param: "y" },
            c: { node: "node_3__0", param: "x" }
          }
        },
        node_2__0: {
          outputs: {
            a: { node: "node_4__0", param: "x" }
          }
        },
        node_3__0: {
          outputs: {
            a: { node: "node_4__0", param: "y" }
          }
        },
        node_4__0: {
          outputs: {
            final_result: {}
          }
        }
      }
    )

    Engine.start(workflow, { x: 1 })
  end
end
