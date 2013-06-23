require 'nokogiri'
require 'open-uri'

class XboxMovie
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

  def self.fetch
    base_url = "http://marketplace.xbox.com"
    relative_path = "/de-DE/Movies?pagesize=100"
    url = "#{base_url}#{relative_path}"
    doc = Nokogiri::HTML(open(url))

    memo = []
    doc.css('ol.ProductResults > li').each do |node|
      relative_path = node.css("a").first["href"]
      base_url = "http://marketplace.xbox.com"
      url = "#{base_url}#{relative_path}"
      doc2 = Nokogiri::HTML(open(url))

      duration = doc2.css("#MetaData_RunTime").first.inner_text.gsub("Laufzeit:", "").strip

      # duration should be at least one hour
      if duration =~ /St./
        source_title = doc2.css(".MovieDetails h1").first.content.split("(").first
        genre = doc2.css("#MetaData_Genre a").first["title"]
        source_genres = [genre]
        source_description = doc2.css("p.ProductMeta").first.content.strip

        ary = Tmdb::Movie.find(source_title)
        if (match = ary.first)
          configuration = Tmdb::Configuration.new
          url = match.poster_path.present? ? (configuration.base_url + "w500" + match.poster_path) : nil
          movie = self.find_or_initialize_by(source_title: source_title)
          movie.source_genres = source_genres
          movie.source_description = source_description
          movie.source_channel = "Xbox Videos"
          movie.source_channel_code = "XBOX"
          movie.poster = url.present? && url.is_valid_url? ? URI.parse(url) : nil
          movie.source_production_country = match.production_countries.present? && match.production_countries.any? ? match.production_countries.map{|x| x["name"]}.join(", ") : nil
          movie.source_production_year = match.release_date.to_date.year
          movie.imdb_id = match.imdb_id
          if movie.save
            memo << movie
          end
        end
      end
    end
    memo
  end

  def fetch_imdb_infos!
    fetch_imdb_infos
    save
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

      self.imdb_title = imdb_movie["Title"]
      self.imdb_id = imdb_movie["imdbID"]
      self.imdb_rating = imdb_movie["imdbRating"]
      # poster_url = imdb_movie["Poster"]
      # self.poster = poster_url.present? && poster_url.is_valid_url? ? URI.parse(poster_url) : nil
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
