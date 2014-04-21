/**
 * @jsx React.DOM
 */
 /* global $ */
 /* global io */
 
// TODO: [things that were in old code] snapshot when joining, proper "load older", autoplay/scroll-into-view
// postpone: conversation view (start/end)
// forget: message destruction


var
  connectAudio = require("../js/recorder").connectAudio,
  getUserMedia = require("getusermedia");

exports._coaxModule = require("coax");      // HACK: for whatever reason build process doesn't let main.js require 'coax' directly…

var ITEM_TYPE = 'com.couchbase.labs.couchtalk.message-item';

exports.Index = React.createClass({
  getInitialState : function(){
    return {goRoom : Math.random().toString(26).substr(2)}
  },
  onSubmit : function(e){
    e.preventDefault();
    document.location += "#" + this.state.goRoom;
    location.reload();
  },
  handleChange : function(e){
    this.setState({goRoom: e.target.value});
  },
  render : function(){
    return (<div id="splash">
          <h2>Welcome to CouchTalk</h2>
          <p>Enter the name of a room to join:</p>
          <form onSubmit={this.onSubmit}>
            <input type="text" size={40}
            value={this.state.goRoom}
            onChange={this.handleChange}/>
            <button type="submit">Join</button>
          </form>
          <img src="splash.jpg"/>
          <RecentRooms/>
        </div>)
  }
});

module.exports.App = React.createClass({
  propTypes : {
    db: React.PropTypes.func.isRequired,
    room : React.PropTypes.string.isRequired,
    client : React.PropTypes.string.isRequired,
    snapshotInterval: React.PropTypes.number
  },
  getDefaultProps : function() {
    return {
      snapshotInterval : 250    // init as `Infinity` to disable
    };
  },
  getInitialState : function () {
    return {
      recording : false,
      messages : $.extend([], {_byKey:Object.create(null)}),
      currentlyPlayingChild : null,
      lastPlayedChild : null
    };
  },
  componentWillMount : function () {
    this.props.db.changes({since:'now', include_docs:true}, function (e,d) {
      if (e) throw e;   // TODO: what?
      else if (d.doc.type !== ITEM_TYPE || d.doc.room !== this.props.room) return;
      else if (d.doc.client === this.props.client) return;      // already directly integrated
      else this.integrateItemIntoMessages(d.doc);
    }.bind(this));
  },
  componentDidMount : function (rootNode) {
    connectAudio(function(e, webcam) {
      if (e) return reloadError(e);
      this.setupSpacebarRecording();
      this.setState({webcam : webcam, webcamStreamURL : window.URL.createObjectURL(webcam.stream)});
    }.bind(this))
  },
  
  integrateItemIntoMessages : function (doc) {
    var messages = this.state.messages,
        message = messages._byKey[doc.message];
    if (!message) {
      message = {
        key: doc.message,
        snaps: [],
        audio: null
      };
      messages.push(messages._byKey[message.key] = message);
    }
    
    if ('snapshotNumber' in doc) {
      message.snaps[doc.snapshotNumber] = [this.props.db.url, doc._id, 'snapshot'].join('/');
    } else {    // assume it's the recording instead
      message.audio = [this.props.db.url, doc._id, 'audio'].join('/');
    }
    
window.dbgMessages = messages;
    this.setState({messages : messages});
  },
  
  setupSpacebarRecording : function () {
    var spacebar = ' '.charCodeAt(0),
        session = null;
    window.onkeydown = function (evt) {
      if (evt.repeat) return;
      var key = evt.keyCode || evt.which;
      if (key === spacebar) {
        evt.preventDefault();
        session = this.startRecording();
      }
    }.bind(this);
    window.onkeyup = function (evt) {
      var key = evt.keyCode || evt.which;
      if (key === spacebar) {
        this.stopRecording(session);
      }
    }.bind(this);
  },
  
  startRecording : function () {
    if (this.state.recording) throw Error("Recording started while already in progress!");
    
    var session = {},
        msgId = "msg:"+Math.random().toString(20),
        picNo = 0;
    session.messageId = msgId;
    session.snapshotTimer = setInterval(function () {
      this.saveSnapshot(msgId, picNo++)
    }.bind(this), this.props.snapshotInterval);
    this.saveSnapshot(msgId, picNo++);
    this.state.webcam.record();
    this.setState({recording : true});
    return session;
  },
  stopRecording : function (session) {
    if (!this.state.recording) throw Error("Recording stopped while not in progress!");
    
    clearInterval(session.snapshotTimer);
    var recorder = this.state.webcam;
    recorder.stop();
    recorder.exportMonoWAV(this.saveAudio.bind(this, session.messageId));
    recorder.clear();
    this.setState({recording : false});
  },
  
  saveItemToRoom : function (fields, atts) {    // atts [optional] uses keys for name, expects data url in values
    var item = $.extend({
      _id : "msg:"+Math.random().toString(20),    // if we don't assign, short circuited local display gets into trouble
      type : ITEM_TYPE,
      room : this.props.room,
      client : this.props.client,
      timestamp : new Date().toISOString()
    }, fields);
    if (atts) item._attachments = Object.keys(atts).reduce(function (obj, name) {
      var urlParts = atts[name].split(/[,;:]/);
      obj[name] = {
        content_type : urlParts[1],
        data : urlParts[3]
      };
      return obj;
    }, item._attachments || {});
    this.props.db.post(item, function (e) {
      if (e) throw e;
    });
    // also display locally right away
    this.integrateItemIntoMessages(item);
  },
  
  saveSnapshot : function (msgId, picNo) {
    var $node = $(this.getDOMNode()),
        video = $node.find('video')[0],
        ctx = $node.find('canvas')[0].getContext('2d');
    ctx.drawImage(video, 0,0, ctx.canvas.width,ctx.canvas.height);
    
    var snapshot = ctx.canvas.toDataURL("image/jpeg");
    this.saveItemToRoom({
      message : msgId,
      snapshotNumber : picNo
    }, {snapshot : snapshot});
  },
  
  saveAudio : function (msgId, wav) {
    var reader = new FileReader();
    reader.readAsDataURL(wav);
    reader.onerror = function () {
      throw reader.error;
    };
    reader.onloadend = function () {
      this.saveItemToRoom({
        message : msgId
      }, {audio : reader.result});
    }.bind(this);
  },
  
  manualPlayback : function (child) {
    if (this.state.currentlyPlayingChild) this.state.currentlyPlayingChild.stop();
    child.play();
    this.setState({currentlyPlayingChild : child});
  },
  
  playbackFinished : function (child) {
    this.setState({lastPlayedChild : child, currentlyPlayingChild : null});
  },
  
  updateAutoPlayback : function (msgObj) {
    // messages in desired order
    // state: [pic, ]old, own, new
    
  },
  
  render : function() {
    //var messageToPlay;
    //this.state.messages
    
  
    var url = window.location;
    var recording = (this.state.recording) ?
      <span className="recording">Recording.</span> :
      <span/>;
    var oldestKnownMessage = this.state.messages[0];
    document.title = this.props.id + " - CouchTalk"
    var beg = (this.state.webcam) ? "" : <h2>Smile! &uArr;</h2>;
    return (
      <div className="room">
      <header>
        {beg}
        <h4>Push to Talk <a href="http://www.couchbase.com/">Couchbase Demo</a></h4>
        <p><strong>Hold down the space bar</strong> while you are talking to record.
          <em>All messages are public. </em>
        </p>
        <video autoPlay muted width={160} height={120} className={(this.state.recording) ? 'recording' : ''} src={this.state.webcamStreamURL}/>
        <canvas style={{display : "none"}} width={320} height={240}/>
        <label className="autoplay"><input type="checkbox" onChange={this.autoPlayChanged} checked={this.state.autoplay}/> Auto-play</label> {recording}
        <br/>
        
        // TODO: this still needs to be updated (alongside workaround for missing `_changes?since=now`)
        {(0 && oldestKnownMessage && oldestKnownMessage.snap.split('-')[2] !== '0') && <p><a onClick={this.loadEarlierMessages}>Load earlier messages.</a></p>}
        
        <aside>Invite people to join the conversation: <input className="shareLink" value={url} readOnly/> or <a href="/">Go to a new room.</a>
        </aside>
        
        <RecentRooms id={this.props.id}/>
        
        <aside><strong>1997 called: </strong> it wants you to know CouchTalk <a href="http://caniuse.com/#feat=stream">requires </a>
          <a href="http://www.mozilla.org/en-US/firefox/new/">Firefox</a> or <a href="https://www.google.com/intl/en/chrome/browser/">Chrome</a>.</aside>
      </header>
      <ul className="messages">
        {this.state.messages.map(function (m) {
          return <Message message={m} key={m.key} onPlaybackRequested={this.manualPlayback} onPlaybackDone={this.playbackFinished} ref="testing"/>
        }, this)}
      </ul>
      </div>
      );
  }
});

var Message = React.createClass({
  propTypes : {
    message: React.PropTypes.object.isRequired,
    onPlaybackRequested: React.PropTypes.func,
    onPlaybackDone: React.PropTypes.func
  },
  getInitialState : function () {
    return {
      percentProgress : 0
    };
  },
  
  componentDidMount : function () {
    var audio = this.refs.audio.getDOMNode();
    audio.ontimeupdate = function () {
      this.setState({percentProgress: audio.currentTime / audio.duration});
    }.bind(this);
    audio.onended = function () {
      this.stop();
      if (this.props.onPlaybackDone) this.props.onPlaybackDone(this);
    }.bind(this);
    audio.onerror = function () {
      console.warn("AUDIO ERROR!", audio.error, audio);
      if (audio.error.code === window.MediaError.MEDIA_ERR_SRC_NOT_SUPPORTED && audio.src.indexOf('?') === -1) {
        // WORKAROUND: https://github.com/couchbase/couchbase-lite-ios/issues/317
        audio.src += "?nocache="+Math.random();
      }
    }
  },
  play : function () {
    var audio = this.refs.audio.getDOMNode();
    if (audio.currentTime) audio.currentTime = 0;
    audio.play();
  },
  stop : function () {
    var audio = this.refs.audio.getDOMNode();
    audio.pause();
    audio.currentTime = 0;      // go back to first thumbail
  },
  
  handleClick : function () {
    if (this.props.onPlaybackRequested) this.props.onPlaybackRequested(this);
  },
  
  render : function () {
    var message = this.props.message,
        snapIdx = Math.round(this.state.percentProgress * (message.snaps.length - 1));
    return (<li key={message.key}>
        <img src={message.snaps[snapIdx]} onClick={this.handleClick}/>
        <audio preload="auto" src={message.audio} ref="audio"/>
      </li>);
  }
});


var OldMessage = React.createClass({
  getInitialState : function () {
    return {showing : 0}
  },
  componentDidMount : function () {
    var audio = $(this.getDOMNode()).find("audio")[0];
    audio.addEventListener('ended', function(){
      this.stopAnimation()
      this.props.playFinished(this.props.message)
    }.bind(this))
    audio.addEventListener('playing', function(){
      this.animateImages()
    }.bind(this))
    var deck = $(this.getDOMNode()).find("img.ondeck")[0];
    deck.addEventListener("load", function(e) {
      // console.log("deck load", this, e)
      $(this).parent().find("img.messImg")[0].src = this.src;
    })
  },
//   shouldComponentUpdate : function(nextProps) {
//     // console.log(nextProps.message)
// warning
//     return ["snap","audio","played","playing","image"].filter(function(k){
//       console.log(k, nextProps.message[k], this.props.message[k])
//       return nextProps.message[k] !== this.props.message[k]
//     }.bind(this)).length !== 0
// // return true;
//   },
  getMax : function(){
    var split = this.props.message.snap.split(":");
    if (split[1]) {
      return parseInt(split[1], 10) || 0;
    } else { return 0}
  },
  getSnapURL : function(){
    var url = "/snapshot/" + this.props.message.snap.split(":")[0];
    var number =  this.props.message.audio ? this.state.showing : this.getMax();
    if (number) {
      url += ":" + number
    }
    return url;
  },
  animateImages : function() {
    var animateHandle = setInterval(function(){
      this.setState({showing : this.state.showing+1})
    }.bind(this), 250)
    this.setState({animateHandle : animateHandle})
  },
  stopAnimation: function(){
    clearInterval(this.state.animateHandle)
    this.setState({showing : 0})
  },
  render : function() {
    // console.log("Render", this.props.message)
    var snapURL, backupURL;
    if (this.props.message.image) {
      snapURL = this.getSnapURL();
      backupURL = "/snapshot/" + this.props.message.snap.split(":")[0];
    }
    if (this.props.message.snapdata) {
      snapURL = this.props.message.snapdata;
    }
    var audioURL = "/audio/" + this.props.message.audio;
    var className = "messImg";

    if (!this.props.message.audio) {
      if (!this.props.message.join) {
        className += " noAudio"
      }
    } else {
      if (this.props.playing) {
        className += " playing"
      } else {
        if (this.props.message.played) {
          className += " played"
        } else {
          className += " unplayed"
        }
      }
    }
    return (<li key={this.props.message.key}>
        <img className={className} src={backupURL} onClick={this.props.playMe}/>
        <img className="ondeck" src={snapURL}/>
        <audio src={audioURL}/>
      </li>)
  }
});


var RecentRooms = React.createClass({
  getInitialState : function(){
    return {
      sortedRooms : this.sortedRooms()
    }
  },
  parseRooms : function(){
    var rooms = $.fn.cookie("rooms");
    if (rooms) {
      return JSON.parse(rooms)
    } else {
      return {}
    }
  },
  sortedRooms : function() {
    var rooms = this.parseRooms()
    var sortedRooms = [];
    for (var room in rooms) {
      if (room !== this.props.id)
        sortedRooms.push([room, new Date(rooms[room])])
    }
    if (sortedRooms.length > 0) {
      sortedRooms.sort(function(a, b) {return b[1] - a[1]})
      console.log("sortedRooms", sortedRooms)
      return sortedRooms;
    }
  },
  clearHistory : function(){
    $.fn.cookie("rooms", '{}', {path : "/"})
    this.setState({sortedRooms : this.sortedRooms()})
  },
  componentDidMount : function(){
    if (this.props.id) {
      var rooms = this.parseRooms()
      console.log("parseRooms", rooms)
      rooms[this.props.id] = new Date();
      $.fn.cookie("rooms", JSON.stringify(rooms), {path : "/"})
    }
  },
  render : function(){
    if (this.state.sortedRooms) {
      return <aside>
        <h4>Recent Rooms <a onClick={this.clearHistory}>(Clear)</a></h4>
        <ul>{
          this.state.sortedRooms.map(function(room){
            var href = "/talk/"+room[0]
            return <li key={room[0]}><a href={href}>{room[0]}</a></li>
          }, this)
        }</ul>
      </aside>
    } else {
      return <aside/>
    }
  },
})

function reloadError(error) {
  if (navigator.getUserMedia) {
    console.error("reload",error);
    setTimeout(function(){
      document.location = location
    },200)
  } else {
    $("h2").html('CouchTalk requires Firefox or Chrome!')
  }
}

function getQueryVariable(variable) {
  var query = window.location.search.substring(1);
  var vars = query.split("&");
  for (var i=0; i < vars.length; i++) {
    var pair = vars[i].split("=");
    if (pair[0] == variable) {
      return pair[1];
    }
  }
}
