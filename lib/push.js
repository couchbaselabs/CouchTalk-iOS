var couchapp, ddoc, path;

couchapp = require('couchapp');

path = require('path');

ddoc = {
  _id: '_design/app'
};

couchapp.loadAttachments(ddoc, path.join(__dirname, '..', 'build'));

module.exports = ddoc;
