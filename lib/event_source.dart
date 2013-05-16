import "dart:async";

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

  // as _stream is not final, we need a getter here
  Stream get stream => _stream;
  void signal([var data]) => _ctrl.add(data);
}

class EventSource {
  Map<Object, EventController> _controllers = new Map<Object, EventController>();
  EventSource get events => this; // for more readable access in derived class

  dynamic operator[] (var id) {
    if(id is Function) id = id(); // in case that event id is given by runtime expression
    _controllers.putIfAbsent(id, () => new EventController());
    return _controllers[id];
  }

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