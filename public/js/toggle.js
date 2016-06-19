$(document).ready(function() {
  $('#games-toggle').on('click', function(e) {
    e.preventDefault();
    $('#games-pong').fadeOut('fast', function() {
      $('#games-all').fadeIn('slow');
    });
  });
});

