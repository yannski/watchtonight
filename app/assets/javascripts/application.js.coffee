#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require jquery.turbolinks
#= require bootstrap

$(document).ready ->
  current_width = $("li.movie").first().width()
  current_height = (current_width * 750) / 500
  $("li.movie").height(current_height)
