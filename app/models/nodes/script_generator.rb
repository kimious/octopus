module Nodes
  class ScriptGenerator < Node
    node_inputs :analysis_ids

    def perform(params)
      analysis_ids = params["analysis_ids"]
      analysis_list = Blob.find(analysis_ids)

      video_prompt = read_input("root.video_prompt")

      generated_script = Gpt.new.chat_completion(
        "
        You are an expert YouTube scriptwriter.
        Write a title and script for #{video_prompt} using the analysis below:
        ",
        analysis_list.map { |a| "\"\"\"#{a.value}\"\"\"" }.join("\n")
      )

      urls = read_input("channel_playlists__0.urls")
      video_ids = read_ouput("top_videos__0.video_ids")
      result = "
        Sur la base de ces chaines youtube : #{urls},\n
        de ces vidéos : #{video_ids}\n
        et de ce prompt : \"#{video_prompt}\",\n
        voici le script que je te propose:\n
        \"\"\"#{generated_script.choices.first&.message&.content}\"\"\"
      "

      script_blob = Blob.create!(
        kind: "yt_generated_script",
        metadata: { analysis_ids: },
        value: result
      )

      { script_id: script_blob.id }
    end
  end
end
