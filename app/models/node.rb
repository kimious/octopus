class Node
  include Sidekiq::Job

  def batch? = respond_to?(:batch)

  def batch_result(bid) = REDIS.lrange("#{bid}_result", 0, -1)

  def save_batch_result!(result)
    REDIS.lpush("#{bid}_result", result)
  end

  def on(status, listener, params = {})
    @callbacks ||= {}
    @callbacks[status] = { listener:, params: }
  end

  def notify!(status, result)
    callback = @callbacks[status]
    callback[:listener].constantize.send("on_#{status}", callback[:params].merge(result:))
  end
end
