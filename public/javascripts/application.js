// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  $('input#server_search').quicksearch('#server_list ol li');
  $(".sortable").tablesorter();
  
  $("#search").bind("keyup", function() {
    var url = $(this).attr("action"); // grab the URL from the form's action value.
    var formData = $(this).serialize(); // grab the data in the form
    $.get(url, formData, function(html) { // perform an AJAX get, the trailing function is what happens on successful get.
      $("#listing").html(html); // replace the "results" div with the result of action taken
    });
  });
  
  $(".toggle").live('click', function(){
    $(this).find('.togglable').toggle();
  });
  $(".toggle_settings").live('click', function(){
    $('.togglable').toggle();
  });
});
