# README

## TL;DR
Check `Workflow::demo`

## WorkflowBuilder

```ruby
json = <<-JSON.squish
  {
    "params": ["test_api_url"],
    "nodes":{
      "http_request#0":{
        "initial_node":true,
        "inputs": {
          "url":{ "source":"context","path":"params.test_api_url"}
        }
      },
      "hello_world#0":{
        "inputs":{
          "input_field": {
            "source":"context","path":"http_request#0.response"
          }
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
| `nonexistent_node_input` | When a input does not exist in a node |
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
        "channels": { "source": "context" }
      }
    },
    "top_videos#1": {
      "inputs": {
        "channels": { "source": "static" }
      }
    },
    "top_videos#2": {
      "inputs": {
        "channels": { "source": "context", "path": "fail" }
      }
    },
    "top_videos#3": {
      "inputs": {
        "channels": { "source": "context", "path": "unknown#0.fail" }
      }
    },
    "top_videos#4": {
      "inputs": {
        "channels": { "source": "context", "path": "channel_info#0.fail" }
      }
    },
    "top_videos#5": {
      "inputs": {
        "channels": { "source": "context", "path": "params.fail" }
      }
    },
    "top_videos#6": {
      "inputs": {
        "channels": { "source": "context", "path": "top_videos#6.channels" }
      }
    },
    "top_videos#7": {
      "inputs": {
        "channels": { "source": "fail", "path": "channel_info#0.channels" }
      }
    },
    "top_videos#8": {
      "inputs": {
        "foo": { "source": "static", "value": "bar" }
      }
    },
  }
}
```

| Code | Key | Value | Message |
| - | - | - | - |
| `invalid_node_ref` | `nodes.fail#fail` | | node 'fail#fail' in object 'nodes' is not a valid node reference (valid node references must match regexp /Aw+#d+z/) |
| `missing_input_source_path` | `nodes.top_videos#0.inputs.channels` | | property 'path' is missing in object 'nodes.top_videos#0.inputs.channels' (context source inputs must define a path) |
| `missing_source_value` | `nodes.top_videos#1.inputs.channels` | | property 'value' is missing in object 'nodes.top_videos#1.inputs.channels' (static source inputs must define a value) |
| `invalid_input_source_path` | `nodes.top_videos#2.inputs.channels.path` | `fail` | value 'fail' of property 'nodes.top_videos#2.inputs.channels.path' is not a valid input path (valid input path must match regexp /A((w+#d+)|params)(.w+)+z/) |
| `nonexistent_source_node` | `nodes.top_videos#3.inputs.channels.path` | `unknown#0` | node reference 'unknown#0' does not exist in object 'nodes' |
| `nonexistent_source_node_output` | `nodes.top_videos#4.inputs.channels.path` | `channel_info#0.fail` | output 'fail' does not exist in node 'ChannelInfo' |
| `nonexistent_workflow_param` | `nodes.top_videos#5.inputs.channels.path` | `workflow.fail` | workflow parameter 'fail' does not exist |
| `self_referencing_node` | `nodes.top_videos#6.inputs.channels.path` | `top_videos#6` | path 'top_videos#6.channels' in 'nodes.top_videos#6.inputs.channels.path' cannot reference node 'top_videos#6' (self-referencing is not allowed) |
| `nonexistent_node_input` | `nodes.top_videos#8.inputs.foo` | `foo` | input 'gfoo' does not exist in node 'top_videos#8' |
****
