/* BOOBS */
HttpRequest = XMLHttpRequest;

window.getOmap = function(decode){
  var meta = document.getElementsByName('omap')[0];
  if(meta){
    var meta = meta.content;
    if(decode){
      return JSON.parse(atob(meta.split('--')[0]));

    }else{
      return meta;
    }
  }else{
    // not found
    console.log('omap meta tag not found');
    return false;
  }
}


window.onload = function(){

}