module Nodes
  class HttpRequest < Node
    has_input :url, description: "URL where to send the HTTP request"
    has_input :method, default: "GET", enum: %w[GET POST PUT PATCH DELETE]
    has_input :query_params, default: {}
    has_input :body, default: {}
    has_input :headers, default: {}

    has_output :response

    def self.valid_output?(output) = output.start_with?("response")

    def perform(url, method, query_params, body, headers)
      uri = query_params.any? ? URI("#{url}?#{URI.encode_www_form(query_params)}") : URI(url)
      use_ssl = url.start_with?("https")
      request = Net::HTTP.const_get(method.capitalize).new(uri, headers)
      request.body = body.to_json if body.any?
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl:) { |http| http.request(request) }

      {
        response: {
          headers: response.each_header.to_h,
          code: response.code,
          body: (JSON.parse(response.body) rescue response.body)
        }
      }
    end
  end
end
