R = require 'ramda'
K = require 'kefir'
crud = require './crud'
Crud = crud.Crud

# :: Kefir.Emitter (Crud a) -> (a -> ())
#
# Emit a Crud.Create to the stream
emitCreate = (emitter) ->
  R.compose(emitter.emit.bind(emitter), Crud.Create)

# :: Kefir.Emitter (Crud a) -> (a -> ())
#
# Emit a Crud.Update to the stream
emitUpdate = (emitter) ->
  R.compose(emitter.emit.bind(emitter), Crud.Update)

# :: Kefir.Emitter (Crud a) -> (String -> ())
#
# Emit a Crud.Delete to the stream
emitDelete = (emitter) ->
  R.compose(emitter.emit.bind(emitter), Crud.Delete)

# :: ([Crud a] -> f (Crud a)) ->
#    (Crud a -> f (Crud a)) ->
#    ((x -> y) -> f x -> f y) ->
#    f a ->
#    (f a -> f (Crud a) -> f a) ->
#    Kefir e (f a) ->
#    Kefir e (Crud a) ->
#    Kefir e (f a)
#
# Continuously fold the crud stream with the given function, using the the first
# `fa` emitted from the stream of fas as the starting value. Both streams are
# consumed concurrently, buffering Crud events until the first `fa` is emitted.
#
applyToFirst = R.curry (fromArray, point, map, empty, f, fas, cruds) ->
  firstFa  = fas.take(1).map(map(Crud.Create))
  buffered = cruds.bufferBy(firstFa, flushOnEnd: false).take(1).map(fromArray)
  skipped  = cruds.skipUntilBy(firstFa).map(point)

  K.merge([firstFa, buffered, skipped]).scan(f, empty).changes()

# :: ([a] -> Crud a -> [a]) -> Kefir e [a] -> Kefir e (Crud a) -> Kefir e [a]
arrayApplyToFirst = R.curry (f, as, cruds) ->
  applyToFirst(R.identity, R.of, R.map, [], R.reduce(f), as, cruds)

# :: (b -> Crud a -> b) -> Kefir e b -> Kefir e (Crud a) -> Kefir e b
#
# Fold the crud stream using the latest `b` emitted as the starting value,
# restarting whenever a new `b` is emitted.
#
applyToLatest = R.curry (f, bs, cruds) ->
  bs.flatMapLatest((b) -> cruds.scan(f, b))

module.exports = {crud, emitCreate, emitUpdate, emitDelete, arrayApplyToFirst, applyToFirst, applyToLatest}

