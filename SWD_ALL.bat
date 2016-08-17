

start /MIN C:\qat\chromedriver.exe
start /MIN C:\qat\IEDriverServer.exe

java -jar C:\qat\selenium-server-standalone-3.0.0.jar

rem java -jar -Dwebdriver.gecko.driver=geckodriver.exe selenium-server-standalone-3.0.0.jar

pause