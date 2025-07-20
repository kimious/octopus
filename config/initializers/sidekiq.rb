class WorkflowMiddleware
  include Sidekiq::ServerMiddleware

  # @param [Object] job_instance the instance of the job that was queued
  # @param [Hash] job_payload the full job payload
  #   * @see https://github.com/sidekiq/sidekiq/wiki/Job-Format
  # @param [String] queue the name of the queue the job was pulled from
  # @yield the next middleware in the chain or worker `perform` method
  # @return [Void]
  def call(job_instance, job_payload, queue)
    first_arg = job_payload["args"].first

    if first_arg.is_a?(Hash) && first_arg.key?("workflow_instance_id")
      workflow_instance_id = first_arg["workflow_instance_id"]
      if workflow_instance_id
        job_instance.workflow_instance = WorkflowInstance.find(workflow_instance_id)
      end
    end
    yield
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add WorkflowMiddleware
  end
end
