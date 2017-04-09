# Running code from source

There are two main ways to run this code from source:

a) Copy all of the .pde files and the data folder to a project folder in the <a href="www.processing.org">Processing</a> sketchbook, then run the project like a normal Processing sketch.

b) Copy the .java file, the data folder and the lib folder (libraries from <a href="www.processing.org">Processing</a>) (the appropiate lib folders are in source/[OS name (Windows/Linux)][(32/64)]) to a directory (make sure the lib folder is where the data folder and .java file are), then run the .java file from the command-line using the following command (or something similar) to start the file:

<b>java -Djna.nosys=true -Djava.library.path="lib" -cp "lib/*" GDE</b>

<br></br>

If any errors occur or the methods don't work, please submit an issue if nobody has done so yet.
