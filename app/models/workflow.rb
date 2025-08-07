class Workflow < ApplicationRecord
  has_many :instances, class_name: "WorkflowInstance"

  def create_instance!(inputs = {})
    instances.create!(
      schema:,
      status: "idle",
      context: {
        params: inputs
      }
    )
  end

  def initial_node
    @initial_node ||= schema.select { |node, definition| definition["initial_node"] }.keys.first
  end

  def required_params
    schema.values.flat_map do |node|
      node["inputs"].values.map do |input|
        input["source"] == "context" && input["path"].starts_with?("params") ? input["path"].split(".").last : nil
      end
    end.compact
  end

  def required_credentials
    schema.values.flat_map { |node| node["credentials"].keys }.uniq
  end

  def configure_credential!(credential)
    schema.values.each do |node|
      if node["credentials"].key?(credential.kind)
        node["credentials"][credential.kind] = credential.id
      end
    end
    save!
  end

  def credentials_configured?
    schema.values.all? do |node|
      node["credentials"].all? { |type, credential_id| !credential_id.nil? }
    end
  end

  def missing_credentials
    schema.values.flat_map { |node| node["credentials"].select { |_, id| id.nil? }.keys }.uniq
  end

  def self.demo
    Credential.destroy_all
    Blob.destroy_all
    WorkflowInstance.destroy_all
    Workflow.destroy_all

    json = <<-JSON.squish
      {
        "params": [ "http_test_url", "urls", "video_prompt" ],
        "nodes": {
          "channel_info#0": {
            "initial_node": true,
            "inputs": {
              "urls": { "source": "context", "path": "params.urls" }
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
              "video_prompt": { "source": "context", "path": "params.video_prompt" }
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
      yt_credential = Credential.create!(
        kind: "youtube_api_key", data: { "api_key": ENV.fetch("YOUTUBE_API_KEY") }
      )
      openai_credential = Credential.create!(
        kind: "openai_api_key", data: { "api_key": ENV.fetch("OPENAI_API_KEY") }
      )
      workflow.configure_credential!(yt_credential)
      workflow.configure_credential!(openai_credential)
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
