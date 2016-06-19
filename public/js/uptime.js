var UptimeRobot = {};

$(document).ready(function() {

  UptimeRobot.apiKey = "m777314502-69f03be1c971aaa42aec6628";

  UptimeRobot.status = function(text, style) {
    $('#uptime').fadeOut('slow', function() {
      $('#uptime').addClass(style).fadeIn('slow');
      $('#uptime #value').html(text);
    });
  };

  var url = "https://api.uptimerobot.com/getMonitors?apiKey=" + UptimeRobot.apiKey + "&customUptimeRatio=1-7-30-365&format=json";

  $.ajax({
    url: url,
    context: document.body,
    dataType: 'jsonp'
  });
});

function jsonUptimeRobotApi(data) {
  for (var i in data.monitors.monitor) {
    monitor = data.monitors.monitor[i]
    switch (parseInt(monitor.status, 10)) {
      case 2:
        UptimeRobot.status("everything is operating normally", "up");
        break;
      default:
        UptimeRobot.status("the service is down, someone has been notified", "down");
        break;
    }
  }
};
