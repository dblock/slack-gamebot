$(document).ready(function() {

  $.ajax({
    type: "GET",
    url: "/api/status",
    success: function(data) {
      var active_teams_count = 0;
      var users_count = 0;
      var matches_count = 0;
      for (var game in data.games) {
        game = data.games[game];
        active_teams_count += game.active_teams_count;
        users_count += game.users_count;
        matches_count += game.matches_count;
      }
      $('#active_teams_count').hide().text(
        active_teams_count + " active teams with " + matches_count + ' games played by ' + users_count + " players!"
      ).fadeIn('slow');
    },
  });

});
