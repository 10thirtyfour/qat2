module.exports = ->
  ALLTRACE = false
  {_,opts} = @
  _.merge opts,
  
    common:
      options:
        databaseProfile: "oracle" 

    logger:
      disable:
        couchdb: true
          
    globLoader:
      disable:
        file: 
          pattern: ["**/*-wd-test.coffee"]
      
    browserList :
      chrome: (false)
      firefox: (false)
      ie: (false)

    scenario: "Oracle"
