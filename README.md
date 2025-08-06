# README

## TL;DR
Check `Workflow::demo`

## WorkflowBuilder

```ruby
json = <<-JSON.squish
  {
    "params": [ "urls", "video_prompt" ],
    "nodes": {
      "channel_info#0": {
        "initial_node": true,
        "inputs": {
          "urls": { "source": "context", "path": "params.urls" },
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
          "video_prompt": { "source": "context", "path": "params.video_prompt" }
        }
      }
    }
  }
JSON

builder = WorkflowBuilder.new
builder.parse_json!(json)

if builder.errors?
  # builder.errors returns the raw error logs
  # builder.error_messages returns human-readable error messages
  puts builder.error_messages
else
  # builder.schema returns the parsed workflow schema
  # that can be used to create a new workflow in the database
  workflow = Workflow.create!(schema: builder.schema)
end
```

### Parsing errors
Each entry in `builder.errors` contains the following attributes:
- `code`: the error code (see the [Codes](#codes) section below for an exhaustive list of error codes)
- `key`: the key in the json where the error was detected
- `value`: the value of the key (`nil` if the key was missing)
- `message`: a human-readable version of the error

#### Codes
| Code | Description |
| - | - |
| `invalid_node_ref` | When a node reference does not match the format `<node_name>#<integer>` |
| `missing_input_source_path` | When a `path` is missing for an input with a `source` set to `context` |
| `missing_source_value` | When a `value` is missing for an input with a source set to `static` |
| `nonexistent_source_node` | When a node referenced in an input does not exist |
| `nonexistent_source_node_output` | When an node output referenced in an input does not exist |
| `nonexistent_workflow_parameter` | When a workflow parameter referenced in an input does not exist |
| `self_referencing_node` | When a self-reference is detected in an input |

#### Examples
Given the following schema:
```json
{
  "params": [ "urls", "video_prompt" ],
  "nodes": {
    "channel_info#0": {
      "initial_node": true,
      "inputs": {
        "urls": { "source": "context", "path": "params.urls" },
        "min_subscribers": { "source": "static", "value": 5000 }
      }
    },
    "fail#fail": {
      "inputs": {}
    },
    "top_videos#0": {
      "inputs": {
        "foo": { "source": "context" }
      }
    },
    "top_videos#1": {
      "inputs": {
        "foo": { "source": "static" }
      }
    },
    "top_videos#2": {
      "inputs": {
        "foo": { "source": "context", "path": "fail" }
      }
    },
    "top_videos#3": {
      "inputs": {
        "foo": { "source": "context", "path": "unknown#0.fail" }
      }
    },
    "top_videos#4": {
      "inputs": {
        "foo": { "source": "context", "path": "channel_info#0.fail" }
      }
    },
    "top_videos#5": {
      "inputs": {
        "foo": { "source": "context", "path": "params.fail" }
      }
    },
    "top_videos#6": {
      "inputs": {
        "foo": { "source": "context", "path": "top_videos#6.foo" }
      }
    },
    "top_videos#7": {
      "inputs": {
        "foo": { "source": "fail", "path": "channel_info#0.channels" }
      }
    }
  }
}
```

| Code | Key | Value | Message |
| - | - | - | - |
| `invalid_node_ref` | `nodes.fail#fail` | | node 'fail#fail' in object 'nodes' is not a valid node reference (valid node references must match regexp /Aw+#d+z/) |
| `missing_input_source_path` | `nodes.top_videos#0.inputs.foo` | | property 'path' is missing in object 'nodes.top_videos#0.inputs.foo' (context source inputs must define a path) |
| `missing_source_value` | `nodes.top_videos#1.inputs.foo` | | property 'value' is missing in object 'nodes.top_videos#1.inputs.foo' (static source inputs must define a value) |
| `invalid_input_source_path` | `nodes.top_videos#2.inputs.foo.path` | `fail` | value 'fail' of property 'nodes.top_videos#2.inputs.foo.path' is not a valid input path (valid input path must match regexp /A((w+#d+)|params)(.w+)+z/) |
| `nonexistent_source_node` | `nodes.top_videos#3.inputs.foo.path` | `unknown#0` | node reference 'unknown#0' does not exist in object 'nodes' |
| `nonexistent_source_node_output` | `nodes.top_videos#4.inputs.foo.path` | `channel_info#0.fail` | output 'fail' does not exist in node 'ChannelInfo' |
| `nonexistent_workflow_param` | `nodes.top_videos#5.inputs.foo.path` | `workflow.fail` | workflow parameter 'fail' does not exist |
| `self_referencing_node` | `nodes.top_videos#6.inputs.foo.path` | `top_videos#6` | path 'top_videos#6.foo' in 'nodes.top_videos#6.inputs.foo.path' cannot reference node 'top_videos#6' (self-referencing is not allowed) |
****
