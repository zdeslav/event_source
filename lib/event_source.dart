import "dart:async";

/*
 * Pairs a StreamController to its broadcast stream for easier handling.
 * Users should not use this class directly but instead access the instance through [EventSource]
 * and call [signal] on retrieved object.
 */
class EventController {
  // initialization is a bit awkward. if language allowed, whole class could be implemented as:
  //    StreamController _ctl = new StreamController();
  //    final Stream _stream = _ctl.stream.asBroadcastStream(); // << no luck, this not allowed here
  //    void signal([var data]) => _ctl.add(data);

  StreamController _ctrl;
  Stream _stream; // can't be final as we can't initialize it yet due to dependency on controller

  EventController() {
    _ctrl = new StreamController();
    _stream = _ctrl.stream.asBroadcastStream();
  }

  /*
   * retrieves the broadcast stream related to this event
   */
  Stream get stream => _stream; // as _stream is not final, we need a getter here

  /*
   * triggers the event - sends the data to the corresponding stream
   */
  void signal([var data]) => _ctrl.add(data);
}

/*
 * Simplifies the event implementation by replacing multiple instances of [StreamController] and
 * [Stream] with a single instance of [EventSource].
 * Can be used as a mixin or as a class field.
 *
 * Example:
 *
 *     class Dog extends Object with EventSource {
 *       Stream<String> get onBark => events.BARK.stream;
 *       Stream get onWag => events.WAG.stream;
 *       void Bark(String sound) => events.BARK.signal(sound);
 *       void Wag() => events.WAG.add();
 *     }
 *
 * Check the docs for more details
 */
class EventSource {
  Map<Object, EventController> _controllers = new Map<Object, EventController>();

  /*
   * for more readable access in derived class when used as mixin:
   *     Stream get onBark => events['BARK'].stream; // instead of this['BARK']
   */
  EventSource get events => this;

  /* lookup events by id (can be anything: string, number, expression...)
   *     Stream get onBark => events['BARK'].stream;
   *     void bark() => events['BARK'].signal();
   */
  dynamic operator[] (var id) {
    if(id is Function) id = id(); // in case that event id is given by runtime expression
    _controllers.putIfAbsent(id, () => new EventController());
    return _controllers[id];
  }

  /*
   * overridden. provides dynamic access to events:
   *     Stream get onBark => events.BARK.stream;
   *     void bark() => eventsBARK.signal();
   */
  dynamic noSuchMethod(Invocation invocation) {
    // can't call super from mixin according to specs and compiler
    // however, this should be removed eventually, according to
    // https://groups.google.com/a/dartlang.org/d/msg/misc/3heNFVbeJ0E/amUhOK8Nr7gJ
    // if(!invocation.isGetter) return super.noSuchMethod(invocation);

    // therefore, we need to do this, but there is no way to get the clean memberName as string,
    // without MirrorSystem.getName(Symbol); which affects minification (and I am not sure on
    // current state of mirrors). We can live with this temporarily - it's good enough
    if(!invocation.isGetter)
      throw new NoSuchMethodError(this,
          invocation.memberName.toString(),
          invocation.positionalArguments,
          invocation.namedArguments);

    return this[invocation.memberName];
  }
}