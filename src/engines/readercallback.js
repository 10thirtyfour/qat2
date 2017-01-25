"use strict";

// from http://bjouhier.wordpress.com/2012/07/04/node-js-stream-api-events-or-callbacks/
module.exports.CallbackReadWrapper = function(stream) {
  var _chunks = [];
  var _error;
  var _done = false;

  stream.on('error', function(err) {
    _onData(err);
  });
  stream.on('data', function(data) {
    if (!data) data=new(String);
    _onData(null, data);
  });
  stream.on('end', function() {
    _onData(null, null);
  });

  function memoize(err, chunk) {
    if (err) _error = err;
    else if (chunk) {
      _chunks.push(chunk);
      stream.pause();
    } else _done = true;
  };

  var _onData = memoize;

  this.read = function(cb) {
    if (_chunks.length > 0) {
      var chunk = _chunks.splice(0, 1)[0];
      if (_chunks.length === 0) {
        stream.resume();
      }
      return cb(null, chunk);
    } else if (_done) {
      return cb(null, null);
    } else if (_error) {
      return cb(_error);
    } else _onData = function(err, chunk) {
      if (!err && !chunk) _done = true;
      _onData = memoize;
      cb(err, chunk);
    };
  }
}
