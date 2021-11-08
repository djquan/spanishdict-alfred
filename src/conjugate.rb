require "net/http"
require "cgi"
require "json"
require "uri"

return unless ARGV[0] != nil

CACHE_DIR = ENV["alfred_workflow_cache"] || "/tmp"
CACHE_PREFIX = CACHE_DIR + "/spanishdict-alfred"

Dir.mkdir(CACHE_DIR) unless Dir.exist?(CACHE_DIR)

def get_cached(type, key)
  cache_key = "#{CACHE_PREFIX}-#{type}-#{key}"

  if File.exist?(cache_key)
    return File.read(cache_key)
  end

  query_url = case type
    when :conjugate
      "https://www.spanishdict.com/conjugate/#{key}"
    when :suggestion
      "https://suggest1.spanishdict.com/dictionary/translate_es_suggest?q=#{key}&v=0"
    end

  response = Net::HTTP.get(URI.parse(query_url))
  File.write(cache_key, response)
  return response
end

response = get_cached(:suggestion, ARGV[0])
results = JSON.parse(response)

results[:items] = results.delete("results").map do |v|
  next if v.include?(" ")
  response = get_cached(:conjugate, v)
  next if response.include?("Redirecting to")

  {
    title: v,
    arg: v,
  }
end.compact

puts results.to_json

Dir.glob(CACHE_PREFIX + "*").each do |x|
  if File.stat(x).mtime < (Time.now - 604800)
    File.delete(x)
  end
end
