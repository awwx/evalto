function log() {
  try {
    console.log(arguments);
  }
  catch (e) {}
}

function poll() {

  // setTimeout avoids spinning the page loading indicator in webkit
  // browsers.
  //
  // http://stackoverflow.com/questions/2703861/chromes-loading-indicator-keeps-spinning-during-xmlhttprequest
  //
  // As far as I can tell it's not the length of the timeout that
  // matters but moving the request into its own event callback, thus
  // the timeout of 0.  I could be wrong though.

  setTimeout(
    function() {
      $.ajax(
        {'async': true,
         'cache': false,
         'data': {'id': channel_id},
         'dataType': 'json',
         'error': function(jqXHR, textStatus, errorThrown) {
           log('poll failed', textStatus);
           connection_lost();
           setTimeout(poll, 10000);
         },
         'success': function (data) {
           have_connection();
           if (data) {
             message_received(data);
           }
           poll();
         },
         'type': 'POST',
         'url': evalto_url + 'longpoll-json'
        });
    },
    0);
}

$(function () {
  poll();
});

function send_message(data) {
  data.channel = channel_id;
  $.ajax(
      {'cache': false,
       'data': data,
       'dataType': 'json',
       'error': function (jqXHR, textStatus, errorThrown) {
         // console.log('post eval error', textStatus, errorThrown);
       },
       'success': function (data, textStatus, jqXHR) {
         //console.log('post eval success', data, textStatus);
       },
       'type': 'POST',
       'url': evalto_url + 'eval'
      });
}
