Event_source
============

[![Build Status](https://drone.io/github.com/zdeslav/event_source/status.png)](https://drone.io/github.com/zdeslav/event_source/latest)

Event_source is a library for wrist friendly event implementation in Dart.

It provides helper classes to simplify creation and handling of streams and stream controllers required to fire events.

Additionally it provides helpers for event throttling and debouncing.

This is a very early version - expect bugs and breaking changes.

Overview
--------

At the moment, idiomatic implementation in Dart requires a bit of boilerplate code:

```dart
class Dog {
    StreamController _barkController = new StreamController();
    StreamController _wagController = new StreamController();
    Stream _bark, _wag;

    Dog() {
        _bark = _barkController.stream.asBroadcastStream();
        _wag = _wagController.stream.asBroadcastStream();
    }

    Stream<String> get onBark => _bark;
    Stream get onWag => _wag;

    void Bark(String sound) => _barkController.add(sound);
    void Wag() => _wagController.add();
}
```

Now the client can attach as this:

```dart
var dog = new Dog();
dog.onBark.listen((data) => print('$data'));
dog.Bark('woof');
```

Event_source library removes the boilerplate from the implementation.
It can be added to a class as mixin, removing the need for any extra fields:

```dart
class Dog extends Object with EventSource {
    Stream<String> get onBark => events.BARK.stream;
    Stream get onWag => events.WAG.stream;

    void Bark(String sound) => events.BARK.signal(sound);
    void Wag() => events.WAG.add();
}
```

If you don't like the idea of mixin poluting your class, just add an `EventSource` instance as a field, everything else is exactly the same:

```dart
class Dog  {
    EventSource events = new EventSource();

    Stream<String> get onBark => events.BARK.stream;
    Stream get onWag => events.WAG.stream;

    void Bark(String sound) => events.BARK.signal(sound);
    void Wag() => events.WAG.add();
}
```

Usage
-----

### Different ways to configure event identifiers

The library dynamically checks the name (it overrides `noSuchMethod`) to create the event identifier internally.
However, you don't have to rely on dynamic name dispatch if that's not your cup of tea.
Here are different ways to setup events:

```dart
class Dog extends Object with EventSource {
    const int EVENT_WAG = 1;

    Stream<String> get onBark => events.BARK.stream;  // event name deduced
    Stream get onWag => events[EVENT_WAG].stream;     // numeric constant used as ID
    Stream get onRun => events['RUN'].stream;         // a string used as ID
    Stream get onDrool => events[() => 1 + 2].stream; // runtime expression used as ID

    void Bark(String sound) => events.BARK.signal(sound);
    void Wag() => events[EVENT_WAG].add();
    void Run() => events['RUN'].add();
    void Drool() => events.[() => 1 + 2].add();
}
```

The difference between `events['RUN']` and `events.RUN` is that in latter case, a `Symbol` instance is used as identifier instead of a string.
This means that you can't mix these approaches for same event. `events['RUN']` is a different event than `events.RUN`.

### Differences between mixin and field approach + caveat

I lied, there _are_ differences between mixin and field approach.

Mixin approach allows following:

```dart
class Dog extends Object with EventSource {
    Stream<String> get onBark => BARK.stream;   // no need to prepend 'events.'
    Stream get onWag => this[EVENT_WAG].stream; // 'this' instead of 'events'. 'events' returns 'this' anyway
}
```

If you use an `EventSource` instance as a field, you don't have this choice, obviously.

**WARNING:**

However, there is a situation where mixin approach might bite you. The name of the getter must differ from event ID if you use dynamic names:

```dart
class Dog extends Object with EventSource {
    Stream get onBark => events.onBark.stream;  // <<< stack overflow
    Stream get onWag => events['onWag'].stream; // this is fine
}
```

The reason is that Dog indeed has `onBark` getter, and as `events` point to the same object, it will again call the getter and so on.
Field approach doesn't exhibit this problem. Following works just fine:

```dart
class Dog {
    EventSource events = new EventSource();
    Stream get onBark => events.onBark.stream; // no problem here, delegated to EventSource instance
}
```

So feel free to pick what seems the best option to you.

### Canceling subscription

Canceling is done the same way as with any stream:

```dart
var dog = new Dog();
var sub = dog.onBark.listen((data) => print('$data'));
dog.bark('wooof');
sub.cancel();
```

Throttling and debouncing
-------------------------

Sometimes you don't want to handle all the events raised from an object, but instead want to handle them once they are finished firing.

E.g. you might want to handle `onMouseMove` only once the mouse has stopped moving, or at most once each 100 Hz. Here's how to do that:

```dart
import 'event_source';
    
// handle onMouseMove 100 ms after the mouse has stopped moving
debounce(element.onMouseMove, 100).listen((e) => print('$e'));
    
// this is equivalent to 
element.onMouseMove.transform(new DebouncingTransformer(100)).listen((e) => print('$e'));
    
// you can also specify whether to trigger the event at the beginning or the end of event stream
// leading/trailing arguments are also available on DebouncingTransformer constructor
debounce(element.onMouseMove, 100, leading: true, trailing: false).listen((e) => print('$e'));
    
// handle onMouseMove once each 100 ms until mouse stops moving 
throttle(element.onMouseMove, 100).listen((e) => print('$e'));
    
// this is equivalent to 
element.onMouseMove.transform(new ThrottlingTransformer(100)).listen((e) => print('$e'));
    
// leading/trailing arguments are also available on ThrottlingTransformer constructor and
// throttle method, to control how the start and end of the stream should be handled
throttle(element.onMouseMove, 100, leading: true, trailing: false).listen((e) => print('$e'));
```

NOTE: If both `leading` and `trailing` arguments are set to `true`, the event will be triggered on the trailing edge only if the wrapped event is raised more than once during the delay period.

Contributions
-------------

Contributions are welcome, just send a pull request and if it fits into library I will gladly accept it.


Copyright and license
---------------------

Copyright 2013., Zdeslav Vojkovic.

Licensed under the MIT License, Version 2.0 (the "License");

You may not use this work except in compliance with the License. You may obtain a copy of the License in the LICENSE file, or at:

http://opensource.org/licenses/MIT

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.