`transcripts`:
* Description: A node to retrieve transcripts for multiple YouTube videos
* Inputs:
  - `videos`:
    * Description: The list of videos including the id for each
    * Required: true
* Outputs:
  - `transcript_ids`:
    * Description: The list of transcript IDs for each video

--

`top_videos`:
* Description: A node to retrieve the 5 most viewed videos in the last 3 months for multiple YouTube channels
* Inputs:
  - `channels`:
    * Description: The list of YouTube channels to fetch videos from
    * Required: true
* Outputs:
  - `videos`:
    * Description: The list of videos including id, title, published_at and view_count for each

--

`script_generator`:
* Description: A node to generate a YouTube video script based on the analysis of other video scripts
* Inputs:
  - `analysis_ids`:
    * Description: The list of analysis IDs to use as strategic principles
    * Required: true
  - `video_prompt`:
    * Description: The prompt that describes the video to make
    * Required: true
* Outputs:
  - `script_id`:
    * Description: ID of the newly generated script

--

`script_analyzer`:
* Description: A node to analyze the structure and strategy of a YouTube script
* Inputs:
  - `transcript_ids`:
    * Description: The list of transcript IDs to analyze
    * Required: true
* Outputs:
  - `analysis_ids`:
    * Description: The list of IDs of generated analysis for each transcript

--

`http_request`:
* Description: A node to make an HTTP request
* Inputs:
  - `url`:
    * Description: URL where to send the HTTP request
    * Required: true
  - `method`:
    * Description: HTTP method to use in the HTTP request
    * Required: false
    * Default: GET
  - `query_params`:
    * Description: Query parameters to use in the HTTP request
    * Required: false
    * Default: {}
  - `body`:
    * Description: Body of the HTTP request
    * Required: false
    * Default: {}
  - `headers`:
    * Description: Headers of the HTTP request
    * Required: false
    * Default: {}
* Outputs:
  - `response`:
    * Description: Response of the HTTP request

--

`hello_world`:
* Description: A node say hello to someone
* Inputs:
  - `name`:
    * Description: Person name to say hello to
    * Required: true
* Outputs:
  - `greetings`:
    * Description: The greeting message

--

`channel_info`:
* Description: A node to fetch information about YouTube channels
* Inputs:
  - `urls`:
    * Description: The list of YouTube channel URLs
    * Required: true
* Outputs:
  - `channels`:
    * Description: The list of Youtube channels including title, subscriber_count and playlist_id for each
