escapeHtml = (unsafe) ->
  unsafe.replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#039;")

if process.argv.length < 3 
  console.log "no file"
  return
fs = require "fs"
logData = fs.readFileSync(process.argv[2],"utf8")
lines = logData.split("\n")

errorReport = '<html><body>'
result={}
for line in lines
  if line.length<1 then continue
  tmpObj=JSON.parse(line)
  result[tmpObj.level]?={}
  result[tmpObj.level][tmpObj.kind]?=0
  result[tmpObj.level][tmpObj.kind]+=1

  if tmpObj.level is 'fail'
    
    #errorReport+=tmpObj.toString()
    errorReport+="\n<hr>\n"
    errorReport+= tmpObj.name + "<br>\n" + tmpObj.message.substring(tmpObj.message.indexOf("\u001b[39m: ")+7)
    if tmpObj.failMessage?
      errorReport+="<br><code>"+escapeHtml(tmpObj.failMessage).replace(/(?:\r\n|\r|\n)/g, '<br/>\n')+"</code>"

  
console.log "Passed :"
for testType,t of result.pass
  console.log "  #{testType} : #{t}"
  
console.log "Failed :"
for testType,t of result.fail
  console.log "  #{testType} : #{t}"

errorReport+="</body></html>"
fs.writeFileSync("errors.html", errorReport, 'utf8')