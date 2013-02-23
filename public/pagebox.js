/* BOOBS */
HttpRequest = XMLHttpRequest;

window.pagebox = function(decode){
  var meta = document.getElementsByName('pagebox')[0];
  if(meta){
    var meta = meta.content;
    if(decode){
      return JSON.parse(atob(meta.split('--')[0]));
    }else{
      return meta;
    }
  }else{
    // not found
    console.log('pagebox meta tag not found');
    return false;
  }
}

window.pb_log = function(){
  console.log('Pagebox allows: ', pagebox(1).scopes)
}


window.onload = function(){

}