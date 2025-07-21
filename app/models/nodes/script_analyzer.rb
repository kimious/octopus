module Nodes
  class ScriptAnalyzer < Node
    def_input :transcript_ids, batch_as: :transcript_id
    def_output :analysis_ids

    def perform(transcript_id)
      blob = Blob.find(transcript_id)

      analysis = Gpt.new.chat_completion(
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
