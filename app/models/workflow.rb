class Workflow < ApplicationRecord
  has_many :instances, class_name: "WorkflowInstance"

  def create_instance!(inputs = {})
    instances.create!(
      schema:,
      status: "idle",
      context: {
        trigger: inputs
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
        channel_info__0: {
          initial_node: true,
          inputs: {
            urls: { type: :context, value: "trigger.urls" },
            min_subscribers: { type: :static, value: 5_000 }
          },
          outputs: [ "channels" ],
          next: [ "top_videos__0" ]
        },
        top_videos__0: {
          inputs: {
            channels: { type: :context, value: "channel_info__0.outputs.channels" }
          },
          outputs: [ "videos" ],
          next: [ "transcripts__0" ]
        },
        transcripts__0: {
          inputs: {
            videos: { type: :context, value: "top_videos__0.outputs.videos" }
          },
          outputs: [ "transcript_ids" ],
          next: [ "script_analyzer__0" ]
        },
        script_analyzer__0: {
          inputs: {
            transcript_ids: { type: :context, value: "transcripts__0.outputs.transcript_ids" }
          },
          outputs: [ "analysis_ids" ],
          next: [ "script_generator__0" ]
        },
        script_generator__0: {
          inputs: {
            video_prompt: { type: :context, value: "trigger.video_prompt" },
            analysis_ids: { type: :context, value: "script_analyzer__0.outputs.analysis_ids" }
          },
          outputs: [ "script_id" ],
          next: []
        }
      }
    )

    Engine.trigger(
      workflow,
      {
        video_prompt: "a video in French on how to go from 0 to $1M in a startup",
        urls: [
          "https://www.youtube.com/@GuillaumeMoubeche-FR",
          "https://www.youtube.com/@GregoireGambattoSF",
          "https://www.youtube.com/@SaaSMakers"
        ]
      }
    )
  end
end
