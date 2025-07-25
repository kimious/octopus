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

    json = <<-JSON.squish
      {
        "trigger": {
          "params": [ "urls", "video_prompt" ]
        },
        "nodes": {
          "channel_info#0": {
            "initial_node": true,
            "inputs": {
              "urls": { "source": "context", "path": "trigger.urls" },
              "min_subscribers": { "source": "static", "value": 5000 }
            }
          },
          "top_videos#0": {
            "inputs": {
              "channels": { "source": "context", "path": "channel_info#0.channels" }
            }
          },
          "transcripts#0": {
            "inputs": {
              "videos": { "source": "context", "path": "top_videos#0.videos" }
            }
          },
          "script_analyzer#0": {
            "inputs": {
              "transcript_ids": { "source": "context", "path": "transcripts#0.transcript_ids" }
            }
          },
          "script_generator#0": {
            "inputs": {
              "analysis_ids": { "source": "context", "path": "script_analyzer#0.analysis_ids" },
              "video_prompt": { "source": "context", "path": "trigger.video_prompt" }
            }
          }
        }
      }
    JSON

    builder = WorkflowBuilder.new
    builder.parse_json!(json)

    if builder.errors?
      puts builder.error_messages
    else
      workflow = Workflow.create!(schema: builder.schema)
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
end
