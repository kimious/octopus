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
          "params": [ "http_test_url", "urls", "video_prompt" ]
        },
        "nodes": {
          "http_request#0": {
            "initial_node": true,
            "inputs": {
              "url": { "source": "context", "path": "trigger.http_test_url" }
            }
          },
          "channel_info#0": {
            "inputs": {
              "urls": { "source": "context", "path": "trigger.urls" },
              "min_subscribers": { "source": "context", "path": "http_request#0.response.body.min_subscribers" }
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
          http_test_url: "http://localhost:3000/test_api",
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
