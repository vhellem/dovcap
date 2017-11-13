test: testParser
	cd ../../../ && java -cp .:junit-4.12.jar:com/dlizarra/starter/hamcrest-core-1.3.jar:../../../:com/dlizarra/starter/gson_2_8_3.jar org.junit.runner.JUnitCore com.dlizarra.starter.TestParser
	make clean

testParser:
	javac -cp .:junit-4.12.jar:hamcrest-core-1.3.jar:../../../:gson_2_8_3.jar ../../../com/dlizarra/starter/TestParser.java

clean:
	rm *.class

