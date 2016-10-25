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
  
fal=0
for testType,t of result.fail
  fal=fal+t  
 
console.log " "
console.log "Failed : #{fal}"
for testType,t of result.fail
  console.log "  #{testType} : #{t}"

