#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require jquery.turbolinks
#=# require bootstrap

window.recalculateHeight = () ->
  current_width = $(".movie .cardContainer").first().width()
  current_height = (current_width * 750) / 500
  $(".movie .cardContainer").height(current_height)


$(document).ready ->
  window.recalculateHeight()

  $(window).on 'resize', () ->
    window.recalculateHeight()
