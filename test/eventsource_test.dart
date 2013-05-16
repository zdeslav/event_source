import 'dart:async';
import 'package:unittest/unittest.dart';
import '../lib/event_source.dart';

class DogMixin extends Object with EventSource
{
  const int EVENT_WAG = 1;

  Stream<String> get onBark => events.EVENT_BARK.stream; // => EVENT_BARK.stream; also works
  Stream get onWag => events[EVENT_WAG].stream;          // => this[EVENT_WAG].stream; also works
  Stream get onRun => events['onRun'].stream;
  Stream get onDrool => events[() => 2 + 1].stream;

  void bark(String sound) => events.EVENT_BARK.signal(sound);
  void wag() => events[EVENT_WAG].signal();
  void run() => events['onRun'].signal();
  void drool() => events[() => 2 + 1].signal();
}

class DogComposed
{
  EventSource events = new EventSource();
  const int EVENT_WAG = 1;

  Stream<String> get onBark => events.EVENT_BARK.stream;
  Stream get onWag => events[EVENT_WAG].stream;
  Stream get onRun => events['onRun'].stream;
  Stream get onDrool => events[() => 2 + 1].stream;

  void bark(String sound) => events.EVENT_BARK.signal(sound);
  void wag() => events[EVENT_WAG].signal();
  void run() => events['onRun'].signal();
  void drool() => events[() => 2 + 1].signal();
}

main() {

  test('EventSource can be added as mixin', () {
    var dog = new DogMixin();
    bool triggeredDynamically = false;
    bool triggeredByStringId = false;
    bool triggeredByIntegerId = false;
    bool triggeredByClosure = false;

    dog.onBark.listen((data) => triggeredDynamically = true);
    dog.onWag.listen((data) => triggeredByIntegerId = true);
    dog.onRun.listen((data) => triggeredByStringId = true);
    dog.onDrool.listen((data) => triggeredByClosure = true);

    dog.bark('woof');
    expect(triggeredDynamically, equals(true));

    dog.wag();
    expect(triggeredByIntegerId, equals(true));

    dog.run();
    expect(triggeredByStringId, equals(true));

    dog.drool();
    expect(triggeredByClosure, equals(true));
});

  test('EventSource can be added as field', () {
    var dog = new DogComposed();
    bool triggeredDynamically = false;
    bool triggeredByStringId = false;
    bool triggeredByIntegerId = false;
    bool triggeredByClosure = false;

    dog.onBark.listen((data) => triggeredDynamically = true);
    dog.onWag.listen((data) => triggeredByIntegerId = true);
    dog.onRun.listen((data) => triggeredByStringId = true);
    dog.onDrool.listen((data) => triggeredByClosure = true);

    dog.bark('woof');
    expect(triggeredDynamically, equals(true));

    dog.wag();
    expect(triggeredByIntegerId, equals(true));

    dog.run();
    expect(triggeredByStringId, equals(true));

    dog.drool();
    expect(triggeredByClosure, equals(true));
});

  test('Event arguments are propagated', () {
    var dog = new DogMixin();
    String sound = '';

    dog.onBark.listen((data) => sound = data);

    dog.bark('wooof');
    expect(sound, equals('wooof'));
});

  test('Subscription can be canceled', () {
    var dog = new DogMixin();
    bool triggered = false;

    var sub = dog.onBark.listen((data) => triggered = true);

    dog.bark('wooof');
    expect(triggered, equals(true));

    triggered = false;
    sub.cancel();
    dog.bark('wooof');
    expect(triggered, equals(false));
});

  test('Dynamic names treat same name as same symbol', () {
    var dog = new DogMixin();
    int count = 0;

    // as Symbol(name) is used as an id, this more or less checks whether
    // Symbol('x') == Symbol('x'). Documentation is not clear on this (no equality operator) but
    // implementation shows that it is so. Otherwise, these would be 2 different events:
    dog.onBark.listen((data) => count++);
    dog.onBark.listen((data) => count++);

    dog.bark('wooof'); // and this would create the third
    expect(count, equals(2));
});
}