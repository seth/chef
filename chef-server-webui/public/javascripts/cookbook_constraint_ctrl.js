$(document).ready(function() {
  if (document.getElementById('edit') != null) {
    var versions = cookbook_versions();
    for (var cookbook in versions){
      var operator = versions[cookbook]["op"];
      var version = versions[cookbook]["version"];
      addTableRow(cookbook, operator, version);
    }
  }
})

function jQuerySuggest(timestamp){
  $(".ac_results").remove(); // FIXME issue w/ jquery suggest
  var cb_name = retrieveCbName(timestamp);
  console.log("in jQuerySuggest " + cb_name);
  populateVersionBoxContent(timestamp, cb_name);
  $("#cookbook_version_" + timestamp).value = "0.0.0";
  $("#cookbook_version_" + timestamp).text("0.0.0");
}

function populateVersionBoxContent(timestamp, cb_name){
  // Ignore environments when editing the environments constraints
  $.getJSON('/cookbooks/'+cb_name+'?num_versions=all&ignore_environments=true',
            function(result){
              var versions = $.map(result[cb_name],
                                   function(item, i) {
                                     return item["version"];
                                   });
              jQuery('#cookbook_version_' + timestamp).suggest(versions);
            });
}

function clearVersionBox(box, timestamp){
  populateVersionBoxContent(timestamp, retrieveCbName(timestamp));
  $('#invalid_version_error_' + timestamp).remove();
}

function validateVersionBoxValue(box, timestamp) {
  // a short delay prevents validation from firing
  // when user clicks on one of the suggestions.
  setTimeout(function() {
    var msg_class = 'invalid_version_error';
    var msg_id = 'invalid_version_error_' + timestamp;
    var xyz_match = box.value.match(/^\d+\.\d+\.\d+$/);
    var xy_match = box.value.match(/^\d+\.\d+$/);
    if (!xyz_match && !xy_match) {
      if (box.value.length != 0 && $('.' + msg_class).length == 0) {
        var error_msg = $('<div/>')
          .addClass(msg_class)
          .attr('id', msg_id).text("Version must be x.y.z or x.y");
        $(box).parent().append(error_msg);
      }
      if (box.value.length == 0) {
        box.value = "0.0.0";
      }
    }
  }, 100);
}


function appendCookbookOptions(cookbook_names, default_cookbook, obj) {
  if (default_cookbook != null && $.inArray(default_cookbook, cookbook_names) < 0) {
    cookbook_names.push(default_cookbook);
  }
  obj.append($('<option/>').attr("value", "").text(""));
  for (i = 0; i < cookbook_names.length; i++) {
    var opt = $('<option/>')
    opt.attr("value", cookbook_names[i]).text(cookbook_names[i]);
    if (cookbook_names[i] == default_cookbook) {
      opt.attr("selected", "true");
    }
    obj.append(opt);
  }
}

function appendOperatorsOptions(default_operator, obj) {
  var ops = [">=", ">", "=", "<", "<=", "~>"];
  for (i in ops) {
    var op = ops[i]
    var option = $('<option/>').attr("value", op).text(op);
    if (default_operator == op) {
      option.attr("selected", "true");
    }
    obj.append(option);
  }
}

function retrieveCbName(timestamp) {
  var cb_name_item = $('#cookbook_name_' + timestamp)[0];
  if (cb_name_item && cb_name_item.value) {
    return cb_name_item.value;
  }
  return "";
}

function addTableRow0000() {
  var cookbook = $("#cookbook_name_0000")[0].value;
  var operator = $("#cookbook_operator_selector")[0].value;
  var version = $("#cookbook_version_0000")[0].value;
  addTableRow(cookbook, operator, version);
}

function constraint_exists(cookbook) {
  var cookbooks = $('.hidden_cookbook_name').map(
    function(i, x) { return x.value });
  return $.inArray(cookbook, cookbooks) > -1;
}

function validateUniqueConstraint(cookbook) {
  var msg_class = 'invalid_version_error';
  var msg_id = 'duplicate_cookbook_error';
  if (constraint_exists(cookbook)) {
    var error_msg = $('<div/>')
      .addClass(msg_class)
      .attr('id', msg_id).text("constraint already exists for " + cookbook);
    $('#cookbook_name_0000').parent().append(error_msg);
    return false;
  }
  return true;
}

function clearCookbookError() {
  $('#duplicate_cookbook_error').remove();
}

function addTableRow(default_cookbook, default_operator, default_version){
  if (default_cookbook == "") return;
  if (!validateUniqueConstraint(default_cookbook)) return;
  if ($('#invalid_version_error_0000').length > 0) {
    return;
  }
  var cookbook_names_string = document.getElementById('cbVerPickerTable').getAttribute('data-cookbook_names');
  var cookbook_names = cookbook_names_string.substring(2, cookbook_names_string.length-2).split('","');
  if (cookbook_names[0] == "[]") {
    cookbook_names = [];
  }
  var timestamp = new Date().getTime();
  var row = $('<tr/>');
  var td_name = $('<td/>').text(default_cookbook)
  var name_hidden = $('<input>')
    .addClass("hidden_cookbook_name")
    .attr("id", "cookbook_name_" + timestamp)
    .attr("type", "hidden")
    .attr("name", "cookbook_name_" + timestamp)
    .attr("value", default_cookbook);
  td_name.append(name_hidden);
  var td_op = $('<td/>');
  var select_op = $('<select/>').attr('name', "operator_" + timestamp);
  appendOperatorsOptions(default_operator, select_op);
  td_op.append(select_op);

  var td_version = $('<td/>');
  var version_box = $('<input>').addClass("text")
    .attr("name", "cookbook_version_" + timestamp)
    .attr("id", "cookbook_version_" + timestamp)
    .attr("type", "text")
    .attr("value", default_version)
    .focus(function() { clearVersionBox(this, timestamp) })
    .blur(function() { validateVersionBoxValue(this, timestamp) })
  td_version.append(version_box);

  var td_rm = $('<td/>');
  var rm_link = $('<a/>').text("remove")
    .attr("href", "javascript:void(0)")
    .click(function() { row.remove() });
  td_rm.append(rm_link);

  row.append(td_name).append(td_op).append(td_version).append(td_rm);
  $("#cbVerPickerTable tbody").append(row);
  validateVersionBoxValue(document.getElementById("cookbook_version_" + timestamp));
}

function removeTableRow(row){
    row.remove();
}
  
