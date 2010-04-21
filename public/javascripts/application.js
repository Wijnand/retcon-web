// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
$(document).ready(function() {
  $('input#server_search').quicksearch('#server_list ol li');
  $(".sortable").tablesorter();
});
TopUp.images_path = "/images/top_up/";
TopUp.players_path = "/players/";
TopUp.addPresets({
  ".commandstable tbody tr td a": {
    group: "commands",
    type: "ajax",
    layout: "quicklook",
    title: "command",
    x: "0",
    y: "0",
    effect: "flip",
    shaded: 1
  }
});