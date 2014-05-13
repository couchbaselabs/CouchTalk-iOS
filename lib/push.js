var couchapp, ddoc, path;

couchapp = require('couchapp');

path = require('path');

ddoc = {
  _id: '_design/app',
  filters: {}
};

ddoc.filters.roomItems = function (doc, req) {
  return (
    doc.type === 'com.couchbase.labs.couchtalk.message-item' &&
    doc.room === req.query.room
  );
};

couchapp.loadAttachments(ddoc, path.join(__dirname, '..', 'build'));

module.exports = ddoc;
