// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  $(".hide_js").toggle();
  $("#includes").toggle();
  $("#excludes").toggle();
  $("#splits").toggle();
  $('#toggle_includes').click(function(){
  	$('#includes').toggle();
	});
  $('#toggle_excludes').click(function(){
  	$('#excludes').toggle();
	});
	$('#toggle_splits').click(function(){
  	$('#splits').toggle();
	});
});