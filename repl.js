the_editor = null;
currently_exiting_editor = false;

function plain_enter(event) {
  return event.keyCode == 13 && !event.ctrlKey && !event.shiftKey;
}


function editor_onLoad(editor) {
  the_editor = editor;

  the_editor.grabKeys(
    function (keydown) {
    },
    function (keycode, event) {
      if (plain_enter(event)) {
        if (! currently_exiting_editor) {
          currently_exiting_editor = true;
          setTimeout(exit_editor, 0);
        }
        return true;
      }
      return false;
  });
  currently_exiting_editor = false;

  the_editor.focus();
}

function create_editor(div, content) {
  new CodeMirror.fromTextArea(div[0], {
    height: 'dynamic',
    minHeight: $('#one-line-height').height(),
    content: content,
    path: '/static/codemirror-0.93/',
    parserfile: ['tokenizescheme.js',
                 'parsescheme.js'],
    stylesheet:  '/static/codemirror-0.93/schemecolors.css',
    autoMatchParens: true,
    disableSpellcheck: true,
    onLoad: editor_onLoad
  });
}

function make_process_status_indicator() {
    $('#connector_instructions').before($('<div/>').attr('id', 'process_status_indicator').css('margin-bottom', '1em'));
}

connected = false;
lost_connection = false;
last_process_status = null;

function have_connection() {
  connected = true;
  lost_connection = false;
  set_process_status_indicator();
}

function connection_lost() {
  connected = false;
  lost_connection = true;
  set_process_status_indicator();
}

function ball(happy) {
    return '<span style="font-size: large" class="' +
           (happy ? 'green' : 'red') +
           '">&#x25CF;</span>';
}

function process_status() {
  if (lost_connection) {
    return ball(false) + ' lost connection to eval.to';
  }
  else if (last_process_status) {
    return (ball(last_process_status.status == 'connected') +
            ' process "' +
            last_process_status.process_name + '": ' + last_process_status.status);
  }
  else {
    return '';
  }
}

function set_process_status_indicator() {
  $('#process_status_indicator').html(process_status());
}
  
function update_process_status_indicator(message) {
  last_process_status = message;
  set_process_status_indicator();
  if (message.status == 'connected') {
    $('#connector_instructions').hide();
    if (the_editor) the_editor.focus();
  }
}

$(function () {
  make_process_status_indicator();
  $('body').append($('<div/>').attr('id', 'repl_div'));
  make_repl_input_row(0);
  $('body').append($('<button/>').attr('id', 'save_example_button').css({'margin-top': '1em'}).text('save example'));
  $('#save_example_button').click(function () {
    window.location = evalto_url + 'save-example?process=' + process_id;
  });
});

function show_job_result(n, result) {
  var div = $('#result' + n).empty();
  if (result.stdout) {
    div.append($('<div/>').addClass('codefont').text(result.stdout));
  }
  if (result.error) {
    div.append($('<div/>').addClass('codefont').append($('<i/>').text(result.error)));
  }
  if (result.value) {
    div.append($('<div/>').addClass('codefont').text(result.value));
  }
}

var n_repl = 0;
repl = [];
repl[0] = {};

function job_result(message) {
  show_job_result(message.for, message.results[0]);
}

function message_received(message) {
  if (message.kind == 'job_result') {
    job_result(message);
  }
  else if (message.kind == 'process_status') {
    update_process_status_indicator(message);
  }
  else {
    console.log('unknown message', message);
  }
}

function make_repl_input_row(n) {
  if (the_editor) { throw 'old editor still present'; }

  var table = $('<table/>');
  var tr = $('<tr/>').appendTo(table);
  var td1 = $('<td/>').text('arc>').appendTo(tr);
  var td2 = $('<td/>').appendTo(tr);
  var div = $('<div/>').css({'border': '1px solid #ddd', 'padding': '2px'}).appendTo(td2);
  var textarea = $('<textarea/>').attr('id', 'code' + n).appendTo(div);
  $('#repl_div').append(table);

  create_editor($('#code' + n), $.browser.mozilla ? '\n' : '');
}

function exit_editor() {
  var n = n_repl;
  code = the_editor.getCode();
  the_editor = null;
  var div = $('<div/>').css({'border': '1px solid #fff', 'padding': '2px'});
  div.append($('<pre/>').addClass('codefont').css({'white-space': 'pre-wrap'}).text(code));
  $('#code' + n).parent().parent().empty().append(div);

  $('<div/>').attr('id', 'result' + n).addClass('codefont').css({'white-space': 'pre-wrap'}).text('.........').appendTo($('#repl_div'));

  send_message({
    'process': process_id,
    'for': n_repl,
    'code': code
  });

  n_repl = n_repl + 1;
  repl[n_repl] = {};
  make_repl_input_row(n_repl);
}
