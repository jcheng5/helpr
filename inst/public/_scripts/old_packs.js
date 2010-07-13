var showing_all = 0;
function show_all_packages() {
  $("#packages").toggleClass("loaded");

  showing_all = (showing_all + 1) %2;
  if(showing_all == 0){    
    $("#show_all_packs_button").attr("value", "Show All Packages");
  }else{
    $("#show_all_packs_button").attr("value", "Show Loaded Packages");    
  }
  
  set_update_button();
}

// highlight all old, out-of-date packages
var has_highlighted = 0;
function highlight_old_packages() {
  has_highlighted = 1;
  button = $("#out_of_date_button");
  button.attr("value", "Thinking...");
  button.attr("disabled", true);
  document.getElementById("thinking_wheel").style.display = "inline";

  jQuery.ajax({
    url: "/package/old.json",
    dataType: "json",
    success: function(packages) {
      for(i = 0; i < packages.length; i++) {
        pkg = packages[i];
        $("#" + pkg).addClass("old");
      }
      
      set_update_button();
    }
  })
  
}

// update all out-of-date packages
function update_packs() {
  var out_of_date_butto = $("#out_of_date_button");
  out_of_date_butto.value = "Updating...";
  out_of_date_butto.disabled = true;
  
  var all = "FALSE";
  if(showing_all == 1)
    all = "TRUE";
    
  $.blockUI({ message: "<h1><img src=\"/_images/busy.gif\" />Updating Packages</h1>" });   

  jQuery.ajax({
    url: "/package/update.json/"+all,
    dataType: "json",
    success: function(packages) {
      for(i = 0; i < packages.length; i++) {
        pkg = packages[i];
        $("#" + pkg).removeClass("old").addClass("update");
      }
      set_update_button();
      
      $.unblockUI();
      
      if(packages.length < 2)
        notify(packages[1] + " has been updated");
      else
        notify(packages.length + " packages have been updated");

    }
  })
}

function pluralize(count, word)
{
  if(count > 1)
    return word + "s";
  else
    return word;
}

function set_update_button(){

  // if highlight_old_packages has not been run, return 
  if(has_highlighted == 0)
    return;

  var i;
  var count = 0;
  
  // count all visible rows that are out_of_date
  var packs = document.getElementById("packages").tBodies[0];
  
  // count all visible packages that are 'old'
  for(i = 0; i < packs.childNodes.length; i++){
    var pkg = packs.childNodes[i];

    if(pkg.nodeType==1 && $(pkg).hasClass("old")  && ($(pkg).hasClass("loaded") || showing_all == 1)){
      window.console.log( pkg + ": " + $(pkg).hasClass("old")  + "    :  "+ !$(pkg).hasClass("hide"));
      count++;
    }
  }
  
  // set state of update button
  var out_of_date_butto = document.getElementById("out_of_date_button");
  if(count > 0){
    out_of_date_butto.value = "Update " + count + " "+pluralize(count, "Package");
    out_of_date_butto.onclick = update_packs;
    out_of_date_butto.disabled = false;
  }
  else{
    out_of_date_butto.value = "All up to date";
    out_of_date_butto.onClick = "";
    out_of_date_butto.disabled = true;
  }
  
  document.getElementById("thinking_wheel").style.display = "none";

}

