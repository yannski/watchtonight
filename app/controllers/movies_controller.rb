class MoviesController < ApplicationController

  def index
    @movies_primetime = Movie.all.desc(:imdb_rating)
    @movies_catchup = Catchup.all.desc(:imdb_rating)

    respond_to do |format|
      format.html
      format.json
    end
  end
end
