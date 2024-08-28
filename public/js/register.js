$(document).ready(function() {
  // Slack OAuth
  var code = $.url('?code')
  var game = $.url('?game')
  var version = $.url('?version')
  if (code && game && (game == 'pong' || game == 'chess' || game == 'pool' || game == 'tic-tac-toe')) {
    PlayPlay.register();
    PlayPlay.message('Working, please wait ...');
    $.ajax({
      type: "POST",
      url: "/api/teams",
      data: {
        code: code,
        game: game
      },
      success: function(data) {
        PlayPlay.message('Team successfully registered!<br>Create a #' + game + ' channel on Slack and invite @' + game + 'bot to it.');
      },
      error: PlayPlay.error
    });
  } else if (version != '1') {
    // redirect to S'Up 2
    window.location.href = "https://gamebot2.playplay.io";
  }
});
