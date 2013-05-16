Event_source
============

[![Build Status](https://drone.io/github.com/zdeslav/event_source/status.png)](https://drone.io/github.com/zdeslav/event_source/latest)

Event_source is a library for wrist friendly event implementation in Dart.
This is version 0.0.1 - expect bugs and breaking changes.

At the moment, idiomatic implementation in Dart requires a bit of boilerplate code:

```Dart
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

```Dart
var dog = new Dog();
dog.onBark => (data) => print('$data');
dog.Bark('woof');
```

Event_source library removes the boilerplate from the implementation.
It can be added to a class as mixin, removing the need for any extra fields:

```Dart
class Dog extends Object with EventSource {
    Stream<String> get onBark => events.BARK.stream;
    Stream get onWag => events.WAG.stream;

    void Bark(String sound) => events.BARK.signal(sound);
    void Wag() => events.WAG.add();
}
```

If you don't like the idea of mixin poluting your class, just add an `EventSource` instance as a field, everything else is exactly the same:

```Dart
class Dog  {
    EventSource events = new EventSource();

    Stream<String> get onBark => events.BARK.stream;
    Stream get onWag => events.WAG.stream;

    void Bark(String sound) => events.BARK.signal(sound);
    void Wag() => events.WAG.add();
}
```

Different ways to configure event identifiers
---------------------------------------------

The library dynamically checks the name (it overrides `noSuchMethod`) to create the event identifier internally.
However, you don't have to rely on dynamic name dispatch if that's not your cup of tea.
Here are different ways to setup events:

```Dart
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

Differences between mixin and field approach + caveat
-----------------------------------------------------

I lied, there _are_ differences between mixin and field approach.

Mixin approach allows following:

```Dart
class Dog extends Object with EventSource {
    Stream<String> get onBark => BARK.stream;   // no need to prepend 'events.'
    Stream get onWag => this[EVENT_WAG].stream; // 'this' instead of 'events'. 'events' returns 'this' anyway
}
```

If you use an `EventSource` instance as a field, you don't have this choice, obviously.

**WARNING:**

However, there is a situation where mixin approach might bite you. The name of the getter must differ from event ID if you use dynamic names:

```Dart
class Dog extends Object with EventSource {
    Stream get onBark => events.onBark.stream;  // <<< stack overflow
    Stream get onWag => events['onWag'].stream; // this is fine
}
```

The reason is that Dog indeed has `onBark` getter, and as `events` point to the same object, it will again call the getter and so on.
Field approach doesn't exhibit this problem. Following works just fine:

```Dart
class Dog {
    EventSource events = new EventSource();
    Stream get onBark => events.onBark.stream; // no problem here, delegated to EventSource instance
}
```

So feel free to pick what seems the best option to you.

Canceling subscription
----------------------

Canceling is done the same way as with any stream:

```Dart
    var dog = new Dog();
    var sub = dog.onBark.listen((data) => print('$data'));
    dog.bark('wooof');
    sub.cancel();
```

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