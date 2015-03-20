R = require 'ramda'
K = require 'kefir'
crud = require './crud'
Crud = crud.Crud

# :: Kefir.Emitter (Crud a) -> (a -> ())
#
# Emit a Crud.Create to the stream
emitCreate = (emitter) ->
  R.compose(emitter.emit, Crud.Create)

# :: Kefir.Emitter (Crud a) -> (a -> ())
#
# Emit a Crud.Update to the stream
emitUpdate = (emitter) ->
  R.compose(emitter.emit, Crud.Update)

# :: Kefir.Emitter (Crud a) -> (String -> ())
#
# Emit a Crud.Delete to the stream
emitDelete = (emitter) ->
  R.compose(emitter.emit, Crud.Delete)

# :: (b -> Crud a -> b) -> Kefir e b -> Kefir e (Crud a) -> Kefir e b
#
# Continuously fold the crud stream with the given function, using the the first
# `b` emitted from the stream of bs as the starting value. Both streams are
# consumed concurrently, buffering Crud events until the first `b` is emitted.
#
applyToFirst = R.curry((f, bs, cruds) ->
  firstB   = bs.take(1).map(R.map(Crud.Create))
  buffered = cruds.bufferBy(firstB).take(1)
  skipped  = cruds.skipUntilBy(firstB).map(R.of)

  K.merge([firstB, buffered, skipped]).scan(R.reduce(f), []))

# :: (b -> Crud a -> b) -> Kefir e b -> Kefir e (Crud a) -> Kefir e b
#
# Fold the crud stream using the latest `b` emitted as the starting value,
# restarting whenever a new `b` is emitted.
#
applyToLatest = R.curry((f, bs, cruds) ->
  bs.flatMapLatest((b) -> cruds.scan(f, b)))

module.exports = {crud, emitCreate, emitUpdate, emitDelete, applyToFirst, applyToLatest}

