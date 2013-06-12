import 'dart:async';
import 'package:unittest/unittest.dart';
import '../lib/event_source.dart';

class DogMixin extends Object with EventSource
{
  static const int EVENT_WAG = 1;

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
  static const int EVENT_WAG = 1;

  Stream<String> get onBark => events.EVENT_BARK.stream;
  Stream get onWag => events[EVENT_WAG].stream;
  Stream get onRun => events['onRun'].stream;
  Stream get onDrool => events[() => 2 + 1].stream;

  void bark(String sound) => events.EVENT_BARK.signal(sound);
  void wag() => events[EVENT_WAG].signal();
  void run() => events['onRun'].signal();
  void drool() => events[() => 6 / 2].signal();
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

  test('Events can be debounced', () {
    var dog = new DogMixin();
    int count = 0;
    String sound = "";

    var debouncedBark = debounce(dog.onBark, 200, leading: true, trailing: true);

    debouncedBark.listen((data) {
      count++;
      sound = data;});

    dog.bark('wooof_1');
    expect(count, equals(1));
    expect(sound, equals('wooof_1'));
    dog.bark('wooof_2');
    dog.bark('wooof_3');
    dog.bark('wooof_4');
    expect(count, equals(1));
    expect(sound, equals('wooof_1'));
    dog.bark('wooof_5');
    expect(count, equals(1));
    expect(sound, equals('wooof_1'));

    // we need to wait at least 200 ms to check the reply
    var timer = new Timer(new Duration(milliseconds: 400), expectAsync0(() {
      expect(count, equals(2));
      expect(sound, equals('wooof_5'));
    }));
});

  test('Debounced event leading edge only', () {
    var dog = new DogMixin();
    int count = 0;
    String sound = "";

    var debouncedBark = debounce(dog.onBark, 200, leading: true, trailing: false);

    debouncedBark.listen((data) {
      count++;
      sound = data;});

    dog.bark('wooof_1');
    expect(count, equals(1));
    expect(sound, equals('wooof_1'));
    dog.bark('wooof_2');
    dog.bark('wooof_3');

    // we need to wait at least 200 ms to check the reply
    var timer = new Timer(new Duration(milliseconds: 400), expectAsync0(() {
      expect(count, equals(1));
      expect(sound, equals('wooof_1'));
    }));
});

  test('Debounced event trailing edge only', () {
    var dog = new DogMixin();
    int count = 0;
    String sound = "";

    // same as var debouncedBark = debounce(dog.onBark, 200, leading: false, trailing: true);
    dog.onBark.transform(new DebouncingTransformer(200, leading: false, trailing: true)).listen((data) {
      count++;
      sound = data;
    });

    dog.bark('wooof_1');
    expect(count, equals(0));
    expect(sound, equals(''));
    dog.bark('wooof_2');
    dog.bark('wooof_3');
    expect(count, equals(0));
    expect(sound, equals(''));

    // we need to wait at least 200 ms to check the reply
    var timer = new Timer(new Duration(milliseconds: 400), expectAsync0(() {
      expect(count, equals(1));
      expect(sound, equals('wooof_3'));
    }));

  test('Events can be throttled', () {
    var dog = new DogMixin();
    var throttledBark = throttle(dog.onBark, 200, leading: true, trailing: true);

    // run synchronously for half a second
    ThrottlingResult result = run_loop(dog, throttledBark, 500);

    var timer = new Timer(new Duration(milliseconds: 300), expectAsync0(() {
      expect(result.time_received.length, equals(4));
      expect(result.time_triggered.length, equals(4));
      expect(result.sounds.length, equals(4));

      expect(result.time_received[0], inInclusiveRange(0, 10));
      expect(result.time_received[1], inInclusiveRange(190, 210));
      expect(result.time_received[2], inInclusiveRange(390, 410));
      expect(result.time_received[3], inInclusiveRange(590, 610));

      expect(result.time_triggered[0], equals(0));
      expect(result.time_triggered[1], inInclusiveRange(190, 210));
      expect(result.time_triggered[2], inInclusiveRange(390, 410));
      expect(result.time_triggered[3], inInclusiveRange(490, 510));

      expect(result.sounds[3], equals('last_woof'));

      for(int i = 0; i < 3; i++ )  // all but last
      {
        expect(result.sounds[i], equals('woof_${result.time_triggered[i]}'));
      }
    }));
  });

  test('Throttled event leading edge only', () {
    var dog = new DogMixin();
    var throttledBark = throttle(dog.onBark, 200, leading: true, trailing: false);

    // run synchronously for half a second
    ThrottlingResult result = run_loop(dog, throttledBark, 500);

    var timer = new Timer(new Duration(milliseconds: 300), expectAsync0(() {
      expect(result.time_received.length, equals(3));
      expect(result.time_triggered.length, equals(3));
      expect(result.sounds.length, equals(3));

      expect(result.time_received[0], inInclusiveRange(0, 10));
      expect(result.time_received[1], inInclusiveRange(190, 210));
      expect(result.time_received[2], inInclusiveRange(390, 410));

      expect(result.time_triggered[0], equals(0));
      expect(result.time_triggered[1], inInclusiveRange(190, 210));
      expect(result.time_triggered[2], inInclusiveRange(390, 410));

      expect(result.sounds[2], isNot(equals('last_woof')));

      for(int i = 0; i < 3; i++ )
      {
        expect(result.sounds[i], equals('woof_${result.time_triggered[i]}'));
      }
    }));
  });

  test('Throttled event trailing edge only', () {
    var dog = new DogMixin();

    // run synchronously for half a second
    ThrottlingResult result = run_loop(
        dog,
        dog.onBark.transform(new ThrottlingTransformer(200, leading: false, trailing: true)),
        500);

    var timer = new Timer(new Duration(milliseconds: 300), expectAsync0(() {
      expect(result.time_received.length, equals(3));
      expect(result.time_triggered.length, equals(3));
      expect(result.sounds.length, equals(3));

      expect(result.time_received[0], inInclusiveRange(190, 210));
      expect(result.time_received[1], inInclusiveRange(390, 410));
      expect(result.time_received[2], inInclusiveRange(590, 610));

      expect(result.time_triggered[0], inInclusiveRange(190, 210));
      expect(result.time_triggered[1], inInclusiveRange(390, 410));
      expect(result.time_triggered[2], inInclusiveRange(490, 510));

      expect(result.sounds[2], equals('last_woof'));

      for(int i = 0; i < 2; i++ ) // all but last
      {
        expect(result.sounds[i], equals('woof_${result.time_triggered[i]}'));
      }
    }));
  });

  test('Debounced event with leading and trailing - trailing not fired if just 1 event', () {
    var dog = new DogMixin();
    int count = 0;

    var debouncedBark = debounce(dog.onBark, 200, leading: true, trailing: true);

    debouncedBark.listen((data) {
      count++;
      sound = data;});

    dog.bark('wooof_1');
    expect(count, equals(1));
    expect(sound, equals('wooof_1'));

    var timer = new Timer(new Duration(milliseconds: 300), expectAsync0(() {
      // trailing was not fired, as there was only one bark
      expect(count, equals(1));
      expect(sound, equals('wooof_1'));
    }));
  });

  test('Throttled event with leading and trailing - trailing not fired if just 1 event', () {
    var dog = new DogMixin();
    int count = 0;

    var throttledBark = throttle(dog.onBark, 200, leading: true, trailing: true);

    throttledBark.listen((data) {
      count++;
      sound = data;});

    dog.bark('wooof_1');
    expect(count, equals(1));
    expect(sound, equals('wooof_1'));

    var timer = new Timer(new Duration(milliseconds: 300), expectAsync0(() {
      // trailing was not fired, as there was only one bark
      expect(count, equals(1));
      expect(sound, equals('wooof_1'));
    }));
  });

});
}

ThrottlingResult run_loop(var dog, Stream throttledStream, int durationMs) {

  ThrottlingResult result = new ThrottlingResult();
  var start = 0;
  int offset = 0;

  throttledStream.listen((data) {
    result.sounds.add(data);
    result.time_received.add(new DateTime.now().millisecondsSinceEpoch - start);
    result.time_triggered.add(offset);
  });

  start = new DateTime.now().millisecondsSinceEpoch;

  for(int i = 1; i > 0; i++ ) { // i > 0 -> deliberate infinite loop
    offset = new DateTime.now().millisecondsSinceEpoch - start;
    if(i == 0) offset = 0; // special case, so offset for 1st iteration is always 0
    dog.bark('woof_$offset');
    if(offset > durationMs) break;
  }

  dog.bark('last_woof');
  return result;
}

class ThrottlingResult {
  final time_triggered = new List<int>();
  final time_received = new List<int>();
  final sounds = new List<String>();
}