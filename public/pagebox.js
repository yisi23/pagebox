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
  console.log('Pagebox allows: ', pagebox(1).scope)
}


window.pageboxForms = function(){
  var nodes = document.getElementsByName('pagebox');
  var pb = pagebox();
  for(var i in nodes){
    nodes[i].value = pb;
  }
}

window.onload = pageboxForms

window.Pagebox = {};
Pagebox.pagebox = pagebox;

Pagebox.XHRProxy = function(){
  this.ready = 0;
}
Pagebox.XHRProxy.queue = 0;
Pagebox.XHRProxy.pending = []

Pagebox.XHRProxy.prototype.open = function(method, action, async){
  this.formproxy = document.createElement('form');
  this.formproxy.style = 'display:none;'
  this.formproxy.method = method;
  //this.formproxy.enctype = 'text/plain'; //no encoding
  this.formproxy.action = action;

  if(!this.body_input){
    this.body_input = document.createElement('input');
    this.body_input.name = 'body';
    this.formproxy.appendChild(this.body_input);      
  }
  if(!this.pagebox_input){
    this.pagebox_input = document.createElement('input');
    this.pagebox_input.name = 'pagebox';
    this.pagebox_input.value = pagebox();
    this.formproxy.appendChild(this.pagebox_input);      
  }
  if(!this.pageboxqueue_input){
    this.pageboxqueue_input = document.createElement('input');
    this.pageboxqueue_input.name = '_pageboxqueue';
    this.formproxy.appendChild(this.pageboxqueue_input);      
  }
  if(!this.contenttype_input){
    this.contenttype_input = document.createElement('input');
    this.contenttype_input.name = 'content_type';
    this.formproxy.appendChild(this.contenttype_input);      
  }

}
Pagebox.XHRProxy.prototype.setRequestHeader = function(header,value){
  if(header.toLowerCase()=='content-type'){
    this.contenttype_input.value = value;
  }
}

Pagebox.XHRProxy.prototype.getAllResponseHeaders = function(){}

Pagebox.XHRProxy.prototype.send = function(body){
  this.frame = createFrame(Pagebox.XHRProxy.queue++);
  this.pageboxqueue_input.value = Pagebox.XHRProxy.queue;
  this.body_input.value = body;
  
  this.formproxy.target = this.frame.name;
  this.formproxy.submit();
  Pagebox.XHRProxy.pending[Pagebox.XHRProxy.queue] = this;

}  
function createFrame(id) {
  var frame = document.createElement('iframe');
  frame.src = 'about:blank';
  frame.name = '_formproxy' + id;
  frame.setAttribute('style', 'position:absolute;width:1px;height:1px;left:-200px');
  document.body.appendChild(frame);
  return frame;
}

window.addEventListener('message', function(e) {
  window.e = e;
  var data = e.data; //JSON.parse(e.data);
  if(data.pagebox == Pagebox.pagebox()){
    var cur = Pagebox.XHRProxy.pending[parseInt(data.queue)];
    cur.readyState = 4;
    cur.status = data.status;
    cur.responseType = data.responseType;
    cur.response = cur.responseText = cur.responseXML = data.body;
    cur.frame.parentElement.removeChild(cur.frame);
    //document.body.removeChild(cur.formproxy);
    cur.onreadystatechange();
  }else{
    alert('No!');
    //message injection attack
  }

}, false);

XMLHttpRequest = Pagebox.XHRProxy;
//})();
