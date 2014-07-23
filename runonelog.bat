@cd c:\qat
@SET name=%~dp1
@node . --globLoader.only.file.pattern="%~nx1" --globLoader.root="%name:~0,-1%" %2 %3