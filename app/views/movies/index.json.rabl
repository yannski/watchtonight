collection @movies

attributes :movie_id, :poster_url
attributes :source_title => :title, :source_description => :description, :source_production_year => :production_year, :source_production_country => :production_country, :source_broadcast_time => :broadcast_time, :source_genres => :genres
node {|obj|
  {imdb: {rating: obj.imdb_rating, url: obj.imdb_url}}
}
