"use strict";

var arr = "21d,1d,2d,2d,5d,1d,1h,1d,2h,1d,5d,2h,2d,2d,15d,10d,10d,2d,3d,2d,2d,2d,2h,4d,4h,4d,2d,1d,1d,3d,3h,3d,4d,4h,4d,1d,1d,5d,4h,1d,1h,2d,7d,3d,3d,4h,2d,2d,2h,2d,2d,15d,25d,1d,1d,1d,1d,4h)"

var arr = arr.split(",")
var cont = 0;
for (var i = 0; i < arr.length; i++)
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
