class Movie
  include Mongoid::Document
  include Mongoid::Timestamps

  field :source_title, type: String
  field :watchmi_pid, type: String

  validates_presence_of :source_title

  def self.conn
    Faraday.new(:url => 'http://tvhackday2013.lab.watchmi.tv') do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
      faraday.options.params_encoder = Faraday::FlatParamsEncoder
      faraday.use FaradayMiddleware::EncodeJson
      faraday.use FaradayMiddleware::ParseJson
    end
  end

  def self.find
    params = {
      field: ["tit", "cat"]
    }
    url = 'api/example.com/broadcasts/format/json/primetime'
    url += "?" + params.to_param.gsub("%5B%5D", "") if params.any?
    response = conn.get url, {}, {'Accept' => 'application/json'}
    body = response.body["results"]
    body.each{|data|
      internal = data["epgData"]

      next unless %w(Spielfilm Serie).include?( internal["cat"].first["value"] )

      movie = Movie.find_or_initialize_by(watchmi_pid: internal["pid"])
      titles = internal["tit"] || []
      title = titles.select{|x| x["orig"] == 1 }.first
      title ||= titles.select{|x| x["lang"] == "eng" }.first
      title ||= titles.select{|x| x["lang"] == "deu" }.first
      movie.source_title = title["value"]
      movie.save!
    }
  end
end
