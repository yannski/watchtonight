collection @movies

attributes :movie_id
attributes :source_title => :title, :source_description => :description, :source_production_year => :production_year, :source_production_country => :production_country, :source_broadcast_time => :broadcast_time
node {|obj|
  {imdb: {rating: obj.imdb_rating, url: obj.imdb_url}}
}
