"use strict";

var arr = ""
var arr = arr.split(",")
var cont = 0;

for (var i = 0; i < arr.length; i++)
  {
    if (arr[i].indexOf("d")>-1) {

var d = parseInt(arr[i].substring(0,arr[i].indexOf("d")));

if (d > 30) {cont+=d} else {cont+=d*8};

if (arr[i].indexOf("h")>-1) {
    cont+=parseInt(arr[i].substring(arr[i].indexOf("d")+2,arr[i].indexOf("h")));
  }
}
else

  {
    if (arr[i].indexOf("h")>-1) {
      cont+=parseInt(arr[i].substring(0,arr[i].indexOf("h")));
      }
    }
  }

console.log(cont);

console.log(i);
