class Movie
  include Mongoid::Document
  include Mongoid::Timestamps

  field :source_title, type: String
  field :watchmi_pid, type: String
  field :watchmi_cat, type: String

  field :imdb_match, type: Mongoid::Boolean, default: false
  field :imdb_rating, type: Float
  field :imdb_title, type: String
  field :imdb_id, type: String

  validates_presence_of :source_title

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
      field: ["tit", "cat"]
    }
    url = 'api/example.com/broadcasts/format/json/primetime'
    url += "?" + params.to_param.gsub("%5B%5D", "") if params.any?
    response = conn.get url, {}, {'Accept' => 'application/json'}
    body = response.body["results"]
    number = 0
    body.each{|data|
      internal = data["epgData"]

      cat = internal["cat"].first["value"]

      next unless %w(Spielfilm Serie).include?( cat )

      movie = Movie.find_or_initialize_by(watchmi_pid: internal["pid"])
      titles = internal["tit"] || []
      title = titles.select{|x| x["orig"] == 1 }.first
      title ||= titles.select{|x| x["lang"] == "eng" }.first
      title ||= titles.select{|x| x["lang"] == "deu" }.first
      movie.source_title = title["value"]
      movie.watchmi_cat = cat
      movie.fetch_imdb_infos
      if movie.save
        number += 1
      end
    }
    number
  end

  def fetch_imdb_infos
    conn = Faraday.new(:url => 'http://www.imdbapi.com')
    response = conn.get '/', {:t => self.source_title}

    imdb_movie = JSON.parse(response.body)

    if !imdb_movie || imdb_movie["Title"].blank?
      Tmdb::Api.key(ENV["TMDB_API_KEY"])

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
      self.imdb_title = imdb_movie["Title"]
      self.imdb_id = imdb_movie["imdbID"]
      # m.original_title = movie_source.title
      # m.cover_url = imdb_movie["Poster"]
      self.imdb_rating = imdb_movie["imdbRating"]
      self.imdb_match = true
      # m.description = imdb_movie["Plot"]
    end
  end

  def imdb_url
    "http://www.imdb.com/title/#{imdb_id}"
  end
end
