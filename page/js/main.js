/* global $ */
var CouchTalk = require("../jsx/app.jsx");

$(function () {
  var room = location.hash.slice(1);
  if (room) {
    React.renderComponent(
      CouchTalk.App({id : room}),
      document.getElementById('container')
    );
  } else {
    React.renderComponent(CouchTalk.Index({}),
      document.getElementById('container'))
  }
})
