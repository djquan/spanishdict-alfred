require "net/http"
require "cgi"
require "json"
require "uri"

return unless ARGV[0] != nil

CACHE_DIR = ENV["alfred_workflow_cache"] || "/tmp"
CACHE_PREFIX = CACHE_DIR + "/spanishdict-alfred"
Dir.mkdir(CACHE_DIR) unless Dir.exist?(CACHE_DIR)

def make_cached_request(url)
  cache_key = "#{CACHE_PREFIX}-#{CGI.escape(url)}"

  if File.exist?(cache_key)
    return File.read(cache_key)
  end

  response = Net::HTTP.get(URI.parse(url))
  File.write(cache_key, response)
  response
end

def get_suggestions(word)
  url = "https://suggest1.spanishdict.com/dictionary/translate_es_suggest?q=#{word}&v=0"
  response = make_cached_request(url)
  results = JSON.parse(response)

  results[:items] = results.delete("results").map do |v|
    {
      title: v,
      arg: v,
    }
  end
  results
end

def main(action)
  unencoded = ARGV[0]
  word = CGI.escape(unencoded)
  results = get_suggestions(word)
  case action
  when :translation_suggestion
    unless results[:items].any? { |item| item[:title].unicode_normalize == unencoded.unicode_normalize }
      results[:items] << {
        title: unencoded,
        arg: unencoded,
      }
    end
  when :conjugation_suggestion
    results[:items] = results[:items].select do |item|
      next if item[:title].include?(" ")
      query_url = "https://www.spanishdict.com/conjugate/#{item[:title]}"
      response = make_cached_request(query_url)
      !response.include?("Redirecting to")
    end
  end

  results
end

puts main(:translation_suggestion).to_json

if rand(5) == 3
  Dir.glob(CACHE_PREFIX + "*").each do |x|
    if File.stat(x).mtime < (Time.now - 604800)
      File.delete(x)
    end
  end
end
