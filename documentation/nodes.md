`transcripts`:
* Description: A node to retrieve transcripts for multiple YouTube videos
* Inputs:
  - `videos`:
    * Description: The list of videos including the id for each
    * Type: Array<{ id: String, title: String, published_at: DateTime, view_count: Integer }>
    * Required: true
* Outputs:
  - `transcript_ids`:
    * Description: The list of transcript IDs for each video
    * Type: Array<Integer>

--

`top_videos`:
* Description: A node to retrieve the 5 most viewed videos in the last 3 months for multiple YouTube channels
* Inputs:
  - `channels`:
    * Description: The list of YouTube channels to fetch videos from
    * Type: Array<{ title: String, subscriber_count: Integer, playlist_id: String }>
    * Required: true
* Outputs:
  - `videos`:
    * Description: The list of videos
    * Type: Array<{ id: String, title: String, published_at: DateTime, view_count: Integer }>

--

`script_generator`:
* Description: A node to generate a YouTube video script based on the analysis of other video scripts
* Inputs:
  - `analysis_ids`:
    * Description: The list of analysis IDs to use as strategic principles
    * Type: Array<Integer>
    * Required: true
  - `video_prompt`:
    * Description: The prompt that describes the video to make
    * Type: String
    * Required: true
* Outputs:
  - `script_id`:
    * Description: ID of the newly generated script
    * Type: Integer

--

`script_analyzer`:
* Description: A node to analyze the structure and strategy of a YouTube script
* Inputs:
  - `transcript_ids`:
    * Description: The list of transcript IDs to analyze
    * Type: Array<Integer>
    * Required: true
* Outputs:
  - `analysis_ids`:
    * Description: The list of IDs of generated analysis for each transcript
    * Type: Array<Integer>

--

`http_request`:
* Description: A node to make an HTTP request
* Inputs:
  - `url`:
    * Description: URL where to send the HTTP request
    * Type: String
    * Required: true
  - `method`:
    * Description: HTTP method to use in the HTTP request
    * Type: Enum { GET, POST, PUT, PATCH, DELETE }
    * Required: false
    * Default: GET
  - `query_params`:
    * Description: Query parameters to use in the HTTP request
    * Type: Hash
    * Required: false
    * Default: {}
  - `body`:
    * Description: Body of the HTTP request
    * Type: Hash
    * Required: false
    * Default: {}
  - `headers`:
    * Description: Headers of the HTTP request
    * Type: Hash
    * Required: false
    * Default: {}
* Outputs:
  - `response`:
    * Description: Response of the HTTP request
    * Type: Hash

--

`hello_world`:
* Description: A node say hello to someone
* Inputs:
  - `name`:
    * Description: Person name to say hello to
    * Type: String
    * Required: true
* Outputs:
  - `greetings`:
    * Description: The greeting message
    * Type: String

--

`channel_info`:
* Description: A node to fetch information about YouTube channels
* Inputs:
  - `urls`:
    * Description: The list of YouTube channel URLs
    * Type: Array<String>
    * Required: true
* Outputs:
  - `channels`:
    * Description: The list of Youtube channels
    * Type: Array<{ title: String, subscriber_count: Integer, playlist_id: String }>
