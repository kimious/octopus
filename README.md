# README

Check `Workflow.demo` method

## TODO

### NOW
- Save inputs and outputs in the context
- Add a helper method to read the context
- Prototype vanilla node
  - HTTP request
  - Dynamic expressions in nodes (e.g expression to define a URL)
- WorkflowBuilder to be used by an LLM
  - metadata in nodes to build a workflow (inputs, ouputs, ...)
- Helper method to generate the %perform_batch% method
- Produce the following result at the end of the worklow:
  - ```Sur la base de ces chaines youtube : <URLS>, et de ces vidéos : <VIDEO_IDS>, coici le script que je te propose: <SCRIPT>```

### NEXT
- Error Handling: https://github.com/sidekiq/sidekiq/wiki/Error-Handling
- Queue handling

### LATER
- UI integration
- Credentials abstraction
- Blob improvements
