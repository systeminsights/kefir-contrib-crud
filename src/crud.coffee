R = require 'ramda'
D = require 'daggy'

# data Crud a = Create a | Update a | Delete StringOrNumber
Crud = D.taggedSum(
  Create: ['value']
  Update: ['value']
  Delete: ['id']
)

# :: (a -> b) -> (a -> b) -> (StringOrNumber -> b) -> Crud a -> b
#
# Fold a Crud event to a value
#
fold = R.curry((create, update, remove, crud) ->
  crud.cata(
    Create: create
    Update: update
    Delete: remove))

# :: (b -> a -> b) -> (b -> a -> b) -> (b -> StringOrNumber -> b) -> b -> Crud a -> b
#
# Combine the Crud event with a starting value.
#
foldLeft = R.curry((create, update, remove, b0, crud) ->
  fold(create(b0), update(b0), remove(b0), crud))

# :: (a -> StringOrNumber) -> a -> a -> Boolean
eqById = (getId) -> R.curry((a, b) ->
  getId(a) == getId(b))

# :: (a -> StringOrNumber) -> [a] -> Crud a -> [a]
#
# Given a function to extract an identifier from a value, apply the Crud event
# to an array, adding, replacing or removing the value.
#
applyToArray = (getId) ->
  eq = eqById(getId)
  replace = (as) -> (a)  -> R.append(a, R.reject(eq(a), as))
  remove  = (as) -> (id) -> R.reject(R.compose(R.eq(id), getId), as)

  foldLeft(replace, replace, remove)

# :: (a -> StringOrNumber) -> IList a -> Crud a -> IList a
#
# Given a function to extract an identifier from a value, apply the Crud event
# to an Immutable.List, adding, replacing or removing the value.
#
applyToIList = (getId) ->
  eq = eqById(getId)
  replace = (as) -> (a)  -> as.filterNot(eq(a)).push(a)
  remove  = (as) -> (id) -> as.filterNot(R.compose(R.eq(id), getId))

  foldLeft(replace, replace, remove)

# :: (a -> StringOrNumber) -> IMap a -> Crud a -> IMap a
#
# Given a function to extract an identifier from a value, apply the Crud event
# to an Immutable.Map, adding replacing or removing the value.
#
applyToIMap = (getId) ->
  replace = (as) -> (a)  -> as.set(getId(a), a)
  remove  = (as) -> (id) -> as.remove(id)

  foldLeft(replace, replace, remove)

module.exports = {Crud, fold, foldLeft, applyToArray, applyToIList, applyToIMap}

