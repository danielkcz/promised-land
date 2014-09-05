/*
* The MIT License (MIT)
* 
* Copyright (c) 2014 FredyC (https://github.com/FredyC/promised-land/)
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in all
* copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
* 
* Version: 0.2.0
*/
"use strict";
var Bacon, EventEmitter, Promise, PromisedLand;

Promise = require('bluebird');

Bacon = require('baconjs');

EventEmitter = require('eventemitter2').EventEmitter2;

PromisedLand = function() {
  var $emit, land, promiseResolver, promises, streams;
  land = Object.create(EventEmitter.prototype);
  land.constructor = PromisedLand;
  EventEmitter.call(land, {
    wildcard: false
  });
  promises = Object.create(null);
  land.promise = function(ev, customEmitter) {
    if (!(arguments.length && ev !== null)) {
      return Promise.reject(new TypeError('missing event argument for promise call'));
    }
    if (typeof customEmitter === "object") {
      if (typeof customEmitter.once !== "function") {
        throw new TypeError('specified emitter is missing once method');
      }
      return new Promise(function(resolve, reject) {
        return customEmitter.once(ev, function(val) {
          return promiseResolver(val, resolve, reject);
        });
      });
    }
    if (promises[ev]) {
      return promises[ev];
    }
    return promises[ev] = new Promise(function(resolve, reject) {
      return land.once(ev, function(val) {
        return promiseResolver(val, resolve, reject);
      });
    });
  };
  land.promiseAll = function() {
    var list;
    Array.prototype.reduce.call(arguments, function(list, ev) {
      ev && list.push(land.promise(ev));
      return list;
    }, list = []);
    if (!list.length) {
      return Promise.reject(new TypeError('no arguments given for promiseAll call'));
    }
    return Promise.all(list);
  };
  promiseResolver = function(value, resolve, reject) {
    if (value instanceof Error) {
      return reject(value);
    } else {
      return resolve(value);
    }
  };
  streams = Object.create(null);
  land.stream = function(ev) {
    var stream;
    if (!(stream = streams[ev])) {
      streams[ev] = stream = Bacon.fromEventTarget(this, ev);
    }
    return stream;
  };
  $emit = land.emit;
  land.emit = function(ev) {
    var value;
    if (!promises[ev]) {
      value = arguments.length > 2 ? Array.prototype.slice.call(arguments, 1) : arguments[1];
      promises[ev] = new Promise(promiseResolver.bind(null, value));
    }
    return $emit.apply(land, arguments);
  };
  return land;
};

module.exports = PromisedLand();

module.exports.create = function() {
  return PromisedLand();
};

module.exports.Promise = Promise;

module.exports.Bacon = Bacon;
