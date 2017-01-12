var arr =  "1d,1d,1d,4d,1d,1d,1d,1d,1d,1d,15d,1d,10d,4d,10d,2d,2d,2d,1d,1d,1d,34d,9d,1d,1d,1d,5d,10d,15d)"


var arr = arr.split(",")
cont = 0;
for (i = 0; i < arr.length; i++)
{
if (arr[i].indexOf("d")>-1)
{
var d = parseInt(arr[i].substring(0,arr[i].indexOf("d")));
if (d > 30) {cont+=d}else{cont+=d*8};
if (arr[i].indexOf("h")>-1)
{
cont+=parseInt(arr[i].substring(arr[i].indexOf("d")+2,arr[i].indexOf("h")));
}
}
else 
{
if (arr[i].indexOf("h")>-1)
{
cont+=parseInt(arr[i].substring(0,arr[i].indexOf("h")));
}
}
}
console.log(cont);
console.log(i);
