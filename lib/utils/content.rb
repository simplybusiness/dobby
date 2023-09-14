# frozen_string_literal: true

class Content
  def initialize(config:, ref:, path:)
    @result = config.client.contents(config.payload['repository']['full_name'], path: path, query: { ref: ref })
  rescue Octokit::NotFound => e
    puts "::error file=#{path},title=Error fetching file #{path}::#{e.message} "
    raise e
  end

  def content
    Base64.decode64(@result['content'])
  end

  def blob_sha
    @result['sha']
  end
end
