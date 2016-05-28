
module.exports = ->
  {Q,utils} = @

  for i in [0..10]
    if i==10
      @reg
        name: "xdep$"+i
    else
      @reg
        name: "xdep$"+i
        after: ["xdep$#{i+1}"]
