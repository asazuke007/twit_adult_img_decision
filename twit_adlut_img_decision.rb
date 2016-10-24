require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'open-uri'
require 'deep_fetch'
require 'twitter'
require 'time'

CONSUMER_KEY = ''
CONSUMER_SECRET = ''
ACCESS_TOKEN = ''
ACCESS_TOKEN_SECRET = ''

VISION_API_URL = "https://vision.googleapis.com/v1/images:annotate"
API_KEY        = ""
URL            = "#{VISION_API_URL}?key=#{API_KEY}"

#TWEET_TIME = "2016-10-01 00:00:00 +0000"


loop{
  sleep(30)

  #imgAnalyze
  def imgAnalyze(filepass)
    begin
      uri           = URI.parse(URL)
      https         = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      req                 = Net::HTTP::Post.new(uri.request_uri)
      req["Content-Type"] = "application/json"
      param               = {
        "requests" =>
        [
          {
            "image" =>
            {
              "content" => Base64.strict_encode64(open(filepass).read)
            },
            "features" =>
            [
              {
                "type"       => "SAFE_SEARCH_DETECTION",
                "maxResults" => 10
              }
            ]
          }
        ]
      }
      req.body = param.to_json
      res      = https.request(req)

      case res
      when Net::HTTPSuccess
        $str = res.body
        hash1 = JSON.parse($str)
        answer = hash1.dig("responses",0,"safeSearchAnnotation","adult")
        return answer
      else
        res.error!
      end
    rescue => e
      puts "error = #{e.message}"
    end

  end

  #ツイッター関連
  client = Twitter::REST::Client.new do |config|
    config.consumer_key        = CONSUMER_KEY
    config.consumer_secret     = CONSUMER_SECRET
    config.access_token        = ACCESS_TOKEN
    config.access_token_secret = ACCESS_TOKEN_SECRET
   end

   #画像付きリプライを取得
   query = '@asazuke007'
   str = ""
   count = 0
   client.search(query, :result_type => "recent", :exclude => "retweets" ,:include_entities => true).each do |tweet|
     tweet.media.each do |media|
       break if count > 5
       media_url = media.media_url
       answer = imgAnalyze(media_url)
       case answer
       when "VERY_LIKELY" then
         str = "とてもエッチです"
       when "LIKELY" then
         str = "エッチです"
       when "POSSIBLE" then
         str = "エッチかもしれないです"
       when "UNLIKELY" then
         str = "エッチじゃないです"
       when "VERY_UNLIKELY" then
         str = "全然エッチじゃないです"
       else
         str = "よくわからないです"
       end

       #ツイートする文字列を作成
       user_name = tweet.user.screen_name
       tweet_str = "@" + user_name + " " + str
       id = tweet.id
       #ツイートする
       client.update(tweet_str,in_reply_to_status_id: id)
       #コンソール表示
       p tweet_str
       count += 1
      end
    end

}
