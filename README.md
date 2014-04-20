# Promised Land

Follow the road to the Promised Land with [Bluebird] while eating some [Bacon] on the way.

[Bluebird]:https://github.com/petkaantonov/bluebird
[BaconJS]:https://github.com/baconjs/bacon.js
[Bacon]:https://github.com/baconjs/bacon.js
[EventEmitter2]:https://github.com/asyncly/EventEmitter2
[Promise]:https://www.promisejs.org/
[modular code]:http://singlepageappbook.com/maintainability1.html
[pub/sub pattern]:http://msdn.microsoft.com/en-us/magazine/hh201955.aspx
[event emitters]:http://javascriptplayground.com/blog/2014/03/event-emitter/
[design patterns]:http://addyosmani.com/resources/essentialjsdesignpatterns/book/

*Please note, that this is very basic implementation (but fully functional) of the idea and it definitely needs some polishing and bug fixing. Feel free to issue ticket or create pull request with your improvements.*

## Features

 - Inherited from [EventEmitter2].
 - Follow one-time events with [Promise].
 - Handle multiple events with [Bacon] streams.
 - Browser environment compatibility.

## Introduction

When writing [modular code] there is usually need to indirectly communicate with other modules. Having them to know about each other would basically eliminate any attempt to keep them decoupled. You are probably used to apply some kind of [pub/sub pattern] or [event emitters] for such situation. That works just fine (when handled properly).

Generally these published events can be divided into two categories:

 * events published only once per application run
 * events repeated multiple times with some data

### Do it just once

Category of one-time events is mainly useful in situation when you want to publish information about something being ready to use without really worrying about possible consumers of such information. For example you can have database module taking care of connecting to database server. When the connection is ready, it should publish such information in case something is listening.

### The old story

However there is one rather *big pitfall*. Some of your modules may subscribe to the event too late and miss out that event happening. That means you have to make sure that database module is initialized only after all other dependent modules have subscribed to the event. That can be especially tricky if you are adding some modules to the mix later.

### It looks promising

Most viable solution to the issue of being late for the event is called [Promise]. Basically it means you get container object that gives you the value whenever it's ready. You might ask where to actually obtain such object? Most direct way is to ask the module that is providing it. In that case you are creating some kind of coupling again, although less serious and it can be overcome with good use of [design patterns].

### Let's roll !

It's time to move this idea little bit further. You want to keep your code modular, but still able to utilize advantages of Promise? It would be great to have some single shared object (similar to emitter) that serves as connection point between modules but doesn't really know about any modules on it's own.And here comes **Promised Land**, check this out:

```js
// in your database module nothing new happens...
var Land = require('promised-land');
Land.emit('databaseConnected', db);

// ...however in some consumer module...
var Land = require('promised-land');
Land.promise('databaseConnected').then(function(db) {
	doSomethingWithDatabase();
});

```

That's right. It's simple as that! You might wonder what is it good for. Well, just emit the event as you are used to and the *promised-land* will take care of the rest. You can ask for the Promise before event is published or after. That means you don't need to think about any initialization order anymore.

Promise resolution is made when the event is emitted for the first time. Any subsequent emits doesn't change state of the promise nor the value. It's nature of the Promise, but keep this in mind as only one part of your code should emit that particular event.

For the actual Promise implementation I have picked [Bluebird] library. It's not very well know just yet, but I am actively using it and I love it! Whole library is  at your service at `require('promised-land').Promise` in case you want to create your own promises with ease.

### Repeated events

Now this is much more straightforward and as you may know, promises are not helpful for this at all since repeated resolution of promise is not causing anything. Promised land is inherited from [EventEmitter2]. You can use any of the methods provided by that library like `on` or `many` directly.

**Please note**, current version of *promised-land* doesn't support `wildcard` option of *EventEmitter*, but it's definitely planned in future versions.

#### Some Bacon for the breakfast ?

To have a complete package for event handling, I decided to include library [BaconJS] that is used for FRP (Functional Reactive Programming). I don't have any credits here, I just felt it should be there for the convenience. Just call `stream` method with event name and you have got yourself full [Bacon stream](https://github.com/baconjs/bacon.js#eventstream). FRP is just whole new *land* to explore!

```js
Land.stream('repeatedEvent').onValue(function(val) {
	doSomethingRepeatedly();
});
```
## Usage tips

Just collection of tips you can achieve using *promised-land*.

### Private land

Having the *promised-land* accessible globally is surely neat, but you may have some privacy concerns here. Anybody can access your land and emit events or steal your promises. But worry not, there is very simple solution!

```js
var Land = require('promised-land');
var myPrivateLand = Land.create();
myPrivateLand.promise('secretEvent');
```

You can pass `myPrivateLand` variable around in your code however you like and nobody else can access it. This is basically same approach you might have chosen with your current EventEmitter. You can easily exchange your currently used shared emitter object with private *promised-land* and everything works like magic!

### Reject the promise

In some cases you might want to publish one-time event with some faulty state. Database connection may fail which you might want to handle with application shut down. In that case simply emit event with  value being instance of object inherited from the `Error`.

```js
Land.emit('queryFailed', new QueryFailError());
Land.promise('queryFailed').catch(QueryFailError, (function(err) {
	handleError();
}));
```

### Multiple promised events

Some of your modules can depend on multiple one-time events being emitted. With promise it's pretty easy, but for the convenience I have included method `promiseAll` where you can pass any number of event names to obtain one Promise object to watch for all of them.

```js
Land.promiseAll('event1', 'event2', 'event3').then(function(values) {
	doSomethingWhenEverythingIsReady();
});

// that is equivalent to...

Promise.all([
	Land.promise('event1'),
	Land.promise('event2'),
	Land.promise('event3')
]).then(function(values) {...})
```

## Testing

To run the tests, start the `npm test` in command line.