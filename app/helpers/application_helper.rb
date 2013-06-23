module ApplicationHelper

  def production_details(movie)
    res = []
    res << movie.source_production_country
    res << movie.source_production_year
    res << "#{ movie.duration_in_minutes }mn"
    "(" + res.delete_if{|x| x.blank?}.join(", ") + ")"
  end
end
