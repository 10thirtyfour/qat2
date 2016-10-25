if process.argv.length < 3 
  console.log "no file"
  return
fs = require "fs"
logData = fs.readFileSync(process.argv[2],"utf8")
lines = logData.split("\n")

errorReport = ''
result={}
for line in lines
  if line.length<1 then continue
  tmpObj=JSON.parse(line)
  result[tmpObj.level]?={}
  result[tmpObj.level][tmpObj.kind]?=0
  result[tmpObj.level][tmpObj.kind]+=1

  if tmpObj.level is 'fail'
    console.log tmpObj.message+' --FAIL--'

  if tmpObj.level is 'pass'
    console.log tmpObj.message+' --PASS--'

pas=0
fal=0
for testType,t of result.pass
  pas=pas+t
for testType,t of result.fail
  fal=fal+t  
total=pas+fal 
console.log " "
console.log "Total : #{total}" 


temp=0
for testType,t of result.pass
  if testType in ['compile.4gl'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['compile.4gl'] 
    temp=temp+t
console.log "  compile.4gl : #{temp}" 

temp=0
for testType,t of result.pass
  if testType in ['compile.per'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['compile.per'] 
    temp=temp+t
console.log "  compile.per : #{temp}" 

temp=0
for testType,t of result.pass
  if testType in ['xpath'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['xpath'] 
    temp=temp+t
console.log "  xpath : #{temp}" 

temp=0
for testType,t of result.pass
  if testType in ['build'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['build'] 
    temp=temp+t
console.log "  build : #{temp}" 

temp=0
for testType,t of result.pass
  if testType in ['deploy-workaround'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['deploy-workaround'] 
    temp=temp+t
console.log "  deploy-workaround : #{temp}" 

temp=0
for testType,t of result.pass
  if testType in ['wd-chrome'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['wd-chrome'] 
    temp=temp+t
console.log "  wd-chrome : #{temp}" 

temp=0
for testType,t of result.pass
  if testType in ['common-tlog'] 
    temp=temp+t
for testType,t of result.fail
  if testType in ['common-tlog'] 
    temp=temp+t
console.log "  common-tlog : #{temp}" 


  
console.log " " 
console.log "Passed : #{pas}"
for testType,t of result.pass
  console.log "  #{testType} : #{t}" 
console.log " "
console.log "Failed : #{fal}"
for testType,t of result.fail
  console.log "  #{testType} : #{t}"

