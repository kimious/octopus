class Workflow < ApplicationRecord
  has_many :instances, class_name: "WorkflowInstance"

  def create_instance!(args = {})
    instances.create!(
      schema:,
      status: "idle",
      args:,
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
    Blob.destroy_all
    WorkflowInstance.destroy_all
    Workflow.destroy_all

    workflow = create!(
      schema: {
        channel_playlists__0: {
          initial_node: true,
          inputs: [ "urls" ],
          outputs: {
            playlist_ids: { node: "top_videos__0", param: "playlist_ids" }
          }
        },
        top_videos__0: {
          inputs: [ "playlist_ids" ],
          outputs: {
            video_ids: { node: "transcripts__0", param: "video_ids" }
          }
        },
        transcripts__0: {
          inputs: [ "video_ids" ],
          outputs: {
            transcript_ids: { node: "script_analyzer__0", param: "blob_ids" }
          }
        },
        script_analyzer__0: {
          inputs: [ "blob_ids" ],
          outputs: {
            analysis_ids: { node: "script_generator__0", param: "analysis_ids" }
          }
        },
        script_generator__0: {
          inputs: [ "analysis_ids" ],
          outputs: {
            script_id: {}
          }
        }
        # TODO vanilla nodes with dynamic expressions
        #http_request__0: {
        #  inputs: [ { url: "{'https://youtube.com/watch?v='+ouput(top_videos__0.video_ids[0])}" }]
        #}
      }
    )

    Engine.start(
      workflow,
      {
        video_prompt: "a video on how to go from 0 to $1M in a startup",
        urls: [
          "https://www.youtube.com/@GuillaumeMoubeche-FR",
          "https://www.youtube.com/@GregoireGambattoSF"
        ]
      }
    )
  end
end
