var PlayPlay = {};

$(document).ready(function() {

  PlayPlay.message = function(text) {
    $('#messages').removeClass('has-error');
    $('#messages').fadeOut('slow', function() {
      $('#messages').fadeIn('slow').html(text)
    });
  };

  PlayPlay.errorMessage = function(message) {
    PlayPlay.message(message)
    $('#messages').addClass('has-error');
  };

  PlayPlay.register = function(text) {
    $('.navbar').fadeOut('slow');
    $('header').fadeOut('slow');
    $('section').fadeOut('slow');
    $('#register').show();
  };

  PlayPlay.error = function(xhr) {
    var message;
    if (xhr.responseText) {
      var rc = JSON.parse(xhr.responseText);
      if (rc && rc.error) {
        message = rc.error;
      } else if (rc && rc.message) {
        message = rc.message;
        if (message == 'invalid_code') {
          message = 'The code returned from the OAuth workflow was invalid.'
        } else if (message == 'code_already_used') {
          message = 'The code returned from the OAuth workflow has already been used.'
        }
      }
    }

    PlayPlay.message(message || xhr.statusText || xhr.responseText || 'Unexpected Error');
    $('#messages').addClass('has-error');
  };
});
