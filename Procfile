dev_phone: ios-sim launch `xcodebuild -workspace CouchTalk.xcworkspace -scheme CouchTalk -sdk iphonesimulator7.1 | awk '/com.apple.actool.compilation-results/{getline;print}' | sed s/\\\\/Assets.car//`
dev_watcher: sleep $APP_WAIT; grunt dev
dev_open: sleep $APP_WAIT; open http://localhost:59840/couchtalk/_design/app/index.html; tail -f /dev/null