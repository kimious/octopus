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
        channel_playlists__0: {
          initial_node: true,
          outputs: {
            playlist_ids: { node: "top_videos__0", param: "playlist_ids" }
          }
        },
        top_videos__0: {
          outputs: {
            video_ids: { node: "transcripts__0", params: "video_ids" }
          }
        },
        transcripts__0: {
          outputs: {
            transcripts: {}
          }
        }
      }
    )

    Engine.start(
      workflow,
      {
        urls: [
          "https://www.youtube.com/@GuillaumeMoubeche-FR",
          "https://www.youtube.com/@patflynn"
        ]
      }
    )
  end
end
