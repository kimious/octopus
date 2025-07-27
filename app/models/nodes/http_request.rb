module Nodes
  class HttpRequest < Node
    def_input :url
    def_input :method, default: "GET", enum: %w[GET POST PUT PATCH DELETE]
    def_input :query_params, default: {}
    def_input :body, default: {}
    def_input :headers, default: {}

    def_output :response

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
