import "dart:async";

class EventController {
  // awkward, whole class could be implemented as:
  // StreamController _ctrl = new StreamController();
  // final Stream _stream = _ctrl.stream.asBroadcastStream(); // << no luck ATM, no this here!
  // void signal([var data]) => _ctrl.add(data);

  StreamController _ctrl;
  Stream _stream;

  EventController() {
    _ctrl = new StreamController();
    _stream = _ctrl.stream.asBroadcastStream();
  }

  Stream get stream => _stream;
  void signal([var data]) => _ctrl.add(data);
}

class EventSource {
  Map<Object, EventController> _ctrls = new Map<Object, EventController>();
  EventSource get events => this;

  dynamic operator[] (var id) {
    if(id is Function) id = id(); // in case that event id is given by runtime function call
    _ctrls.putIfAbsent(id, () => new EventController());
    return _ctrls[id];
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
