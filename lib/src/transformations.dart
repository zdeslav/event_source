part of event_source;


/*
 * Wraps the specified [stream] into DebouncingTransformer.
 *
 * All the raised events are ignored until [delay] milliseconds have elapsed since the last raised
 * event. [leading] must be set to true if event should be triggered on the leading edge of delay
 * period, i.e. when the first wrapped event is triggered. [trailing] must be set to true if event
 * should be triggered on the trailing edge, i.e. after the last wrapped event.
 *
 * The wrapped events are always raised with the value of the last wrapped event which was handled.
 *
 * Example:
 *
 *     // trigger printing 100 ms after last mouse move event
 *     debounce(window.onMouseMove, 100).listen((e) => print('$e'));
 */
Stream debounce(Stream stream, int delay, {bool leading: false, bool trailing: true}) {
    return stream.transform(new DebouncingTransformer(delay, leading: leading, trailing: trailing));
}

/*
 * Wraps the specified [stream] into ThrottlingTransformer.
 *
 * All the events raised on the original stream are filtered to ensure that they will be triggered
 * at most once every [delay] milliseconds. [leading] must be set to true if event should be
 * triggered on the leading edge of delay period, i.e. when the first wrapped event is triggered.
 * [trailing] must be set to true if event should be triggered on the trailing edge, i.e. after the
 * last wrapped event.
 *
 * The wrapped events are always raised with the value of the last wrapped event which was handled.
 *
 * Example:
 *
 *     // trigger printing at most every 100 ms
 *     throttle(window.onMouseMove, 100).listen((e) => print('$e'));
 */
Stream throttle(Stream stream, int delay, {bool leading: true, bool trailing: true}) {
    return stream.transform(new ThrottlingTransformer(delay, leading: leading, trailing: trailing));
}

/*
 * Stream transformer which wraps a stream and ensures that the events are raised at most once every
 * [delay] milliseconds, as specified in class constructor.
 *
 * E.g. to ensure that onMouseMove event is handled at most every 100 ms, you can wrap it like this:
 *
 *     // trigger printing at most every 100 ms
 *     window.onMouseMove.transform(new ThrottlingTransformer(100)).listen((e) => print('$e'));
 *
 * The helper method [throttle] provides a bit shorter way to do the same thing.
 *
 */
class ThrottlingTransformer<T> extends StreamEventTransformer<T, T> {
  final bool leading, trailing;
  final int delay;
  Timer timer = null;
  int _lastCalled = 0, _remaining = 0;
  T _args;

  /*
   * Creates a [ThrottlingTransformer] instance.
   *
   * It will filter the events from the transformed stream to ensure that they will be triggered
   * at most once every [delay] milliseconds. [leading] must be set to true if event should be
   * triggered on the leading edge of delay period, i.e. when the first wrapped event is triggered.
   * [trailing] must be set to true if event should be triggered on the trailing edge, i.e. after the
   * last wrapped event.
   */
  ThrottlingTransformer(this.delay, {bool this.leading: true, bool this.trailing: true}) : super() {}

  void handleData(T data, EventSink<T> sink) {
    var _currTime = new DateTime.now().millisecondsSinceEpoch;

    if(!leading && _lastCalled == 0) {
      _lastCalled = _currTime;
    }

    _remaining = delay - (_currTime - _lastCalled);
    _args = data;

    if(_remaining <= 0) {
      if(timer != null) timer.cancel();
      timer = null;
      sink.add(_args);
      _lastCalled = _currTime;
    }
    else if(trailing && timer == null) {
      timer = new Timer(new Duration(milliseconds: _remaining), () {
        sink.add(_args);
      });
    }
  }
}

/*
 * Stream transformer which wraps a stream and ensures that the events are raised only some time
 * after the last event in a time period has been triggered on the wrapped stream.
 *
 * To ensure that onMouseMove event is handled just once, 100 ms after the mouse has stopped moving,
 * you can wrap it like this:
 *
 *     // trigger printing at most every 100 ms
 *     window.onMouseMove.transform(new DebouncingTransformer(100)).listen((e) => print('$e'));
 *
 * The helper method [debounce] provides a bit shorter way to do the same thing.
 *
 */
class DebouncingTransformer<T> extends StreamEventTransformer<T, T> {
  final bool leading, trailing;
  final int delay;
  Timer timer = null;

/*
 * Creates a [DebouncingTransformer] instance.
 *
 * It will filter the events from the transformed stream to ensure that they will be triggered
 * only after [delay] milliseconds has passed since the last raised event on wrapped stream.
 * [leading] must be set to true if event should be triggered on the leading edge of delay period,
 * i.e. when the first wrapped event is triggered. [trailing] must be set to true if event should be
 * triggered on the trailing edge, i.e. after the  * last wrapped event.
 */
  DebouncingTransformer(this.delay, {bool this.leading: false, bool this.trailing: true}) : super() {}

  void handleData(T data, EventSink<T> sink) {
    if(timer == null && leading) {
      sink.add(data);
    }

    if(timer != null) timer.cancel();

    timer = new Timer(new Duration(milliseconds: delay), () {
      if(trailing) sink.add(data);
    });
  }
}

