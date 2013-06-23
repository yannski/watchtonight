class MoviesController < ApplicationController

  def index
    @movies = Movie.all.desc(:imdb_rating)

    respond_to do |format|
      format.html
      format.json
    end
  end
end
