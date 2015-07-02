R = require 'ramda'
K = require 'kefir'
{Tuple2} = require 'fantasy-tuples'
{last, runLogValues} = require 'kefir-contrib-run'
{applyToFirst, applyToLatest, emitCreate, crud} = require '../src/index'
{Create, Update, Delete} = crud.Crud

t1 = Tuple2(1, "A")
t2 = Tuple2(2, "B")
t3 = Tuple2(3, "C")
t4 = Tuple2(4, "D")
t5 = Tuple2(5, "E")

fold = crud.applyToArray((t) -> t._1)
bs = [[t1, t2, t3], [t3, t4, t5]]
cruds = [Create(t4), Delete(1), Create(Tuple2(1, "AA")), Update(Tuple2(4, "CC"))]
expectedFinal = [t2, t3, Tuple2(1, "AA"), Tuple2(4, "CC")]

# TODO: Add to contrib
getOrElse = (x) -> (o) -> o.getOrElse(x)
applyToFirstA = applyToFirst(R.identity, R.of, R.map, [], R.reduce(fold))

describe "applyToFirst", ->
  it "should buffer crud events, applying once `b` is emitted", ->
    crudStream = K.sequentially(50, cruds)
    bStream = K.sequentially(117, bs)
    applied = applyToFirstA(bStream, crudStream)

    expect(last(applied).then(getOrElse([]))).to.become(expectedFinal)

  it "should apply crud events when they occur after `b`", ->
    crudStream = K.sequentially(100, cruds)
    bStream = K.sequentially(10, bs)
    applied = applyToFirstA(bStream, crudStream)

    expect(last(applied).then(getOrElse([]))).to.become(expectedFinal)

  it "should be the result of applying crud events to an empty array when bs never emits", ->
    applied = applyToFirstA(K.never(), K.sequentially(50, cruds))

    expect(last(applied).then(getOrElse([]))).to.become(R.drop(2, expectedFinal))

  it "should be the first bs when crud stream never emits", ->
    applied = applyToFirstA(K.sequentially(50, bs), K.never())

    expect(last(applied).then(getOrElse([]))).to.become(bs[0])

describe "applyToLatest", ->
  it "should apply the crud stream to the latest `b`", ->
    crudStream = K.sequentially(50, cruds)
    bStream = K.sequentially(120, bs)
    applied = applyToLatest(fold, bStream, crudStream)

    expect(runLogValues(applied)).to.become([
      bs[0],
      [t1, t2, t3, t4],
      [t2, t3, t4],
      bs[1],
      [t3, t4, t5, Tuple2(1, "AA")],
      [t3, t5, Tuple2(1, "AA"), Tuple2(4, "CC")]
    ])

describe "emit*", ->
  it "should emit an event to the emitter", ->
    emitter = K.emitter()
    vals = runLogValues(emitter)
    emitCreate(emitter)("A")
    emitter.end()

    expect(vals).to.become([Create("A")])

