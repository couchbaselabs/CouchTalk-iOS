/* global $ */
var CouchTalk = require("../jsx/app.jsx");

$(function () {
  var match = /\/talk\/(.*)/.exec(location.pathname);
  var room = location.hash.replace("#",'')
  if (room) {
    React.renderComponent(
      CouchTalk.App({id : room}),
      document.getElementById('container')
    );
  } else {
    React.renderComponent(CouchTalk.Index({}),
      document.getElementById("container"))
  }
})
