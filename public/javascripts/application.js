// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  $('input#server_search').quicksearch('#server_list ol li');
  $(".sortable").tablesorter();
});