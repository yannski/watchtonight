module ApplicationHelper

  def production_details(movie)
    res = []
    res << movie.source_production_country
    res << movie.source_production_year
    res << "#{ movie.duration_in_minutes }mn"
    "(" + res.delete_if{|x| x.blank?}.join(", ") + ")"
  end

  def channel_details(movie)
    res = []
    res << movie.source_channel
    res << movie.source_broadcast_time.try(:strftime, "%H:%M")
    res.delete_if{|x| x.blank?}.join(", ")
  end
end
