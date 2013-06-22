collection @movies

attributes :movie_id, :source_title => :title
node {|obj|
  {imdb: {rating: obj.imdb_rating, url: obj.imdb_url}}
}
