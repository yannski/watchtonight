class Catchup
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
  field :content_url, type: String

  field :imdb_match, type: Mongoid::Boolean, default: false
  field :imdb_rating, type: Float
  field :imdb_title, type: String
  field :imdb_id, type: String

  validates_presence_of :source_title

  has_mongoid_attached_file :poster

  def movie_id
    id.to_s
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

  def imdb_url
    "http://www.imdb.com/title/#{imdb_id}"
  end

  def poster_url
    poster.url
  end

  def duration_in_minutes
    120
  end

  def source_broadcast_time
    x  = read_attribute :source_broadcast_time
    Time.at(x)
  end

  def poster_url
    self["imageUrl"]
  end
end
