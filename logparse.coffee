fs = require "fs"
logfname = process.argv[2]
lines = fs.readFileSync(logfname).toString().split("\n");
objs =[]
for line in lines
  if line.length>1
    objs.push JSON.parse(line)


for obj in objs
  if obj.level == "fail"
    console.log "====="+obj.kind+"====="
    console.log obj
#    console.log obj.message
#    console.log obj.failReason

  
