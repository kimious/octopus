module Nodes
  class ScriptAnalyzer < Node
    describe "A node to analyze the structure and strategy of a YouTube script"

    has_input :transcript_ids,
      batch_as: :transcript_id,
      description: "The list of transcript IDs to analyze"
    has_output :analysis_ids,
      description: "The list of IDs of generated analysis for each transcript"
    requires_credential :openai_api_key

    def perform(transcript_id)
      openai_credential = credential("openai_api_key")
      blob = Blob.find(transcript_id)

      analysis = Gpt.new(openai_credential.data["api_key"]).chat_completion(
        "
        You are an expert YouTube scriptwriter.
        You will be given a script of a video (within triple double quotes) that performed really well on YouTube.
        Explain why the script worked and identity elements, techniques and methods
        that could used or even improved in order to make another successful video.
        ",
        "\"\"\"#{blob.value}\"\"\""
      )
      analysis_blob = Blob.create!(
        kind: "yt_video_analysis",
        metadata: { transcript_id:, video_id: blob.metadata["video_id"] },
        value: analysis.choices.first&.message&.content
      )
      save_batch_result!(analysis_ids: analysis_blob.id)
    end
  end
end
