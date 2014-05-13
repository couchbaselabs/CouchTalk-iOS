/* global $ */
var CouchTalk = require("../jsx/app.jsx"),
    coax = CouchTalk._coaxModule;

$(function () {
  var room = location.hash.slice(1),
      db_url = location.origin + '/' + location.pathname.split('/')[1];

  window.onhashchange = function(){
    location.reload()
  }

  if (room) {
    React.renderComponent(
      CouchTalk.App({
        db : (window.coaxDb = coax(db_url)),
        room : room,
        client :  "s:"+Math.random().toString(20)
      }),
      document.getElementById('container')
    );
  } else {
    React.renderComponent(CouchTalk.Index({}),
      document.getElementById('container'))
  }
})
