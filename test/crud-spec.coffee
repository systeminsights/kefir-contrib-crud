R = require 'ramda'
{Tuple2} = require 'fantasy-tuples'
{Map, List} = require 'immutable'
crud = require '../src/crud'
{Create, Update, Delete} = crud.Crud

t1 = Tuple2(1, "A")
t2 = Tuple2(2, "B")
t3 = Tuple2(3, "C")
t4 = Tuple2(4, "D")

arrayToMap = R.compose(Map, R.map((t) -> [t._1, t]))

applyTests = (name, fromArray, toArray) ->
  f = crud[name]((t) -> t._1)
  toMap = R.compose(arrayToMap, toArray)

  describe name, ->
    it "should add value when applying Create", ->
      ts = fromArray([t1, t2])
      expect(toMap(f(ts, Create(t4)))).to.deep.equal(arrayToMap([t1, t2, t4]))

    it "should replace value when applying Update and previous exists", ->
      ts  = fromArray([t1, t2, t3])
      t2x = Tuple2(2, "X")
      expect(toMap(f(ts, Update(t2x)))).to.deep.equal(arrayToMap([t1, t2x, t3]))

    it "should behave the same as Create when applying Update and previous does not exist", ->
      ts = fromArray([t1, t2])
      expect(toMap(f(ts, Update(t3)))).to.deep.equal(toMap(f(ts, Create(t3))))

    it "should remove value when applying Delete and previous exists", ->
      ts = fromArray([t2, t3, t4])
      expect(toMap(f(ts, Delete(3)))).to.deep.equal(arrayToMap([t2, t4]))

    it "should be the identity function when applying Delete and previous does not exist", ->
      ts = fromArray([t2, t3, t4])
      expect(toMap(f(ts, Delete(7)))).to.deep.equal(toMap(ts))

applyTests('applyToArray', R.identity, R.identity)

applyTests('applyToIList', List, (xs) -> xs.toArray())

applyTests('applyToIMap', arrayToMap, (xs) -> xs.toArray())

