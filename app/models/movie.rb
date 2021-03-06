class Movie
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Paperclip

  field :source_pid, type: String
  field :source_title, type: String
  field :source_category, type: String
  field :source_description, type: String
  field :source_production_year, type: Integer
  field :source_production_country, type: String
  field :source_broadcast_time, type: Time
  field :source_genres, type: Array, default: []
  field :source_channel, type: String
  field :source_channel_code, type: String

  field :imdb_match, type: Mongoid::Boolean, default: false
  field :imdb_rating, type: Float
  field :imdb_title, type: String
  field :imdb_id, type: String

  validates_presence_of :source_title

  has_mongoid_attached_file :poster

  def movie_id
    id.to_s
  end

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

  def self.fetch
    params = {
      field: ["tit", "cat", "shsyn", "prdct", "time", "genrenames", "chanlong", "chanshort"]
    }
    url = 'api/example.com/broadcasts/format/json/primetime'
    url += "?" + params.to_param.gsub("%5B%5D", "") if params.any?
    response = conn.get url, {}, {'Accept' => 'application/json'}
    body = response.body["results"]
    body.inject([]) {|memo, data|
      internal = data["epgData"]

      category = internal["cat"].try(:first).try(:fetch, "value")
      description = internal["shsyn"].try(:first).try(:fetch, "value")
      production_country = internal["prdct"] ? internal["prdct"]["cntr"] : nil
      production_year = internal["prdct"] ? internal["prdct"]["yfst"].to_i : nil
      broadcast_time = internal["time"] && internal["time"]["strt"] ? Time.at(internal["time"]["strt"].to_s[0..-4].to_i) : nil

      next memo unless %w(Spielfilm Serie).include?( category )

      movie = Movie.find_or_initialize_by(source_pid: internal["pid"])
      titles = internal["tit"] || []
      title = titles.select{|x| x["orig"] == 1 }.first
      title ||= titles.select{|x| x["lang"] == "eng" }.first
      title ||= titles.select{|x| x["lang"] == "deu" }.first
      movie.source_title = title["value"]
      movie.source_category = category
      movie.source_description = description
      movie.source_production_country = production_country
      movie.source_production_year = production_year
      movie.source_broadcast_time = broadcast_time
      movie.source_genres = data["genreTitles"]
      movie.source_channel = data["channelNameLong"]
      movie.source_channel_code = data["channelNameShort"]
      if movie.save
        memo << movie
      end
      memo
    }
  end

  def fetch_imdb_infos!
    fetch_imdb_infos
    save
  end

  def fetch_tmdb_poster!
    fetch_tmdb_poster
    save
  end

  def fetch_tmdb_poster
    ary = Tmdb::Movie.find(self.source_title)
    if (match = ary[0])
      configuration = Tmdb::Configuration.new
      url = configuration.base_url + "w500" + match.poster_path
      self.poster = url.present? && url.is_valid_url? ? URI.parse(url) : nil
    end
  end

  def fetch_imdb_infos
    conn = Faraday.new(:url => 'http://www.imdbapi.com')
    response = conn.get '/', {:t => self.source_title}

    imdb_movie = JSON.parse(response.body)

    if !imdb_movie || imdb_movie["Title"].blank?

      ary = Tmdb::Movie.find(self.source_title)

      if ary.any?
        temp_title = ary.first.original_title

        response = conn.get '/', {:t => temp_title}

        imdb_movie = JSON.parse(response.body)

        if !imdb_movie || imdb_movie["Title"].blank?
          i = Imdb::Search.new(temp_title)
          if (res = i.movies.first)
            imdb_movie = {
              "Title" => res.title,
              "imdbID" => "tt#{res.id}",
              "imdbRating" => res.rating
            }
          end
        end
      end
    end

    if imdb_movie && imdb_movie["Title"]

      poster_url = imdb_movie["Poster"]

      self.imdb_title = imdb_movie["Title"]
      self.imdb_id = imdb_movie["imdbID"]
      self.imdb_rating = imdb_movie["imdbRating"]
      self.poster = poster_url.present? && poster_url.is_valid_url? ? URI.parse(poster_url) : nil
      self.imdb_match = true
    end
  end

  def imdb_url
    imdb_id.present? ? "http://www.imdb.com/title/#{imdb_id}" : nil
  end

  def poster_url
    poster.url
  end

  def duration_in_minutes
    120
  end
end
