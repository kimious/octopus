REDIS = Redis.new(url: ENV["REDIS_URL"], driver: :ruby, ssl_params: { verify_mode: OpenSSL::SSL::VERIFY_NONE })
