$(document).ready(function() {
  player_hit();
  player_stay();
  player_double();
});

function player_hit () {
  $(document).on("click", ".btn#hit_button", function() {  
    setTimeout(function() {
      $.ajax({
        type: "GET",
        url: "/game/player_hit"
      }).done(function(msg) {
        $("#game").replaceWith(msg)
      });      
    }, 500);

    return false;
  });
}

function player_stay () {
  $(document).on("click", ".btn#stay_button", function() {  
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
    $.ajax({
      type: "GET",
      url: "/game/player_double"
    }).done(function(msg) {
      $("#game").replaceWith(msg)
    });

    return false;
  });
}