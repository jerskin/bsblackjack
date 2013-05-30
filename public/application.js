$(document).ready(function() {
  player_hit();
  player_stay();
  player_double();
});

function player_hit () {
  $(document).on("click", ".btn#hit_button", function() {  
    alert("player hits!");
    $.ajax({
      type: "GET",
      url: "/game/player_hit"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
}

function player_stay () {
  $(document).on("click", ".btn#stay_button", function() {  
    alert("player stays!");
    $.ajax({
      type: "GET",
      url: "/game/player_stay"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
}

function player_double () {
  $(document).on("click", ".btn#double_button", function() {  
    alert("player doubles down!");
    $.ajax({
      type: "GET",
      url: "/game/player_double"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
}