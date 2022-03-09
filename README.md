⚠️ This repo is obsolete.  It was developed using a version of Couchbase Lite that reached end of life years ago.

# CouchTalk-iOS

This is a port of <https://github.com/couchbaselabs/couchtalk-node> to work with [Couchbase Lite](http://www.couchbase.com/mobile).

## Instructions

Start with the usual `git clone`, etc. of this repo. (You'll also need node installed, with npm.)

Then build the CouchApp which the iOS app will host:

    npm install
    # TODO: at least some of these should be in package.json
    npm install grunt-cli grunt-couchapp coax couchapp
    node_modules/.bin/grunt build       # TBD: not needed with `grunt dev` below?

Next get the iOS app stuff ready:

    brew install ios-sim
    sudo gem install cocoapods
    pod install


## Manual launch

To run the app
    open CouchTalk.xcworkspace      # now Build+Go

(Note the need to open the .xcworkspace file, if you use the .xcodeproj directly your builds will fail with `ld: library not found for -lPods`.)

Now you should be able to start the "automatic install" helper, and open the simulator-served app:

    node_modules/.bin/grunt dev
    open http://localhost:59840/couchtalk/_design/app/index.html


## Automatic launch

Or just `npm start` which will launch everything (iOS app, CouchApp pusher, browser tab) automatically.
