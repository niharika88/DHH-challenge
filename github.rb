require 'net/http'
require 'uri'
require 'json'

class Github
  def initialize(git_handle, scoring_params)
    @git_handle = git_handle
    @scoring_params = scoring_params
  end

  def score
    events = get_events(build_github_url)
    puts get_score(events) unless events.nil?
  end

  private

  def build_github_url
    "https://api.github.com/users/#{@git_handle}/events/public"
  end

  def get_score(events)
    grouped = events.group_by { |h| h['type'] }.values
    score = grouped.map do |g|
      event_type = g.first['type'].strip
      event_score = @scoring_params[event_type] || 1
      event_score * g.count
    end.sum
    score
  end

  def get_events(url)
    uri = URI.parse(url)
    response = Net::HTTP.get_response uri
    response_body = JSON.parse(response.body)
    if response_body.is_a? Array
      response_body
    elsif response_body.key?('message')
      raise Exception, response_body['message']
    else
      raise Exception, 'Unknown error'
    end
  rescue Timeout::Error => e
    puts 'Request timed out'
  rescue Exception => e
    puts "Request failed with #{e.message}"
  end
end
