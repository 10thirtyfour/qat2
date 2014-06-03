cd D:\src\qat
SET name=%~dp1
node . --globLoader.only.file.pattern="%~n1.tlog" --globLoader.root="%name:~0,-1%"