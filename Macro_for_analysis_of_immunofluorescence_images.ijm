// Macro to measure immunofluorescent stainings of mouse sagittal brain sections. 
// Images should be supplied as a path to a .lif file (Leica project file)
// Macro Written by Ross Smith and Favour Onyeogaziri (January 2023)

// For most analysis, we want to limit analysis to the Cerebellum only. 
// This is acheived by generating ROI files that outline the cerebellum in each image.
// Images and any drawn ROIs are labeled with a 6-digit ID number, to facillitate the automation.
// The ID code is arbitrarily set as a 6-digit ID to match with how our lab identifies our research mice and samples, and can be adjusted if needed.


//set the format for your measurements
run("Set Measurements...", "area mean limit min display redirect=None decimal=2");

//new Mac OS does not have a title for the folders- you can uncomment and use the code in next line 
setOption("JFileChooser", true);
run("Bio-Formats Macro Extensions"); // needed for processing a lif file, not really needed for tifs.

//This script can be adapted for use with different file types. Shown here for a LIF file.
#@ File (label="Select a lif file to process", style="file") lifPath
//ROIs can be drawn in imageJ and saved with the proper ID number
#@ File (label="Select a folder of unzipped ROIs outlines of cerebellum_all the ROIs in one folder, not individual folders", style="directory") dirROI
#@ File (label="Select a folder in which to create an output", style="directory") OutFolder
#@ String (label="Choose a title for the results file") ResultTitle

// Our images have DAPI in the ch1 position, other channels will be used to label other features
// The signal intensity considered to be positive for each stain is determined by the User and supplied here 
#@ Integer (label = "DAPI Threshold", value = 600) Ch1Thresh
#@ Integer (label = "Ch2 threshold", value = 800) Ch2Thresh
#@ Integer (label = "Ch3 threshold", value = 200) Ch3Thresh
#@ Integer (label = "Ch4 threshold", value = 337) Ch4Thresh
// LIF files can contain many images, this option allows for analysis of only a subset of images
#@ boolean  (label="Only Process Some images?") selectSeries
// quality control (qc) images help to visually confirm that the analysis parameters selected worked as expected
// it is possible to skip the generation of qc images to save disk space and time
#@ boolean  (label="skip qc images?") skipQC


//this code will make an ROI manager appear in batchmode, which seems necessary for some code
roiManager("show none");
setBatchMode(true);

// create folder for the output -- this will be nested within the chosen directory of files
	dir2 = OutFolder+File.separator+"--output"+File.separator;
	if (File.exists(dir2)==false) {
				File.makeDirectory(dir2); // new directory for output you want to save
		}

//If using a Lif file as input, how many series in this lif file?
	Ext.setId(lifPath);//-- Initializes the given path (filename).
	Ext.getSeriesCount(seriesCount); //-- Gets the number of image series in the active dataset.
	selectArray=newArray();

//if we only want to process a subset of the images, we select them here.
if(selectSeries){
	seriesArray=newArray();
	
	for (s=0; s<seriesCount; s++) {
		Ext.setSeries(s);
		Ext.getSeriesName(seriesName);
		seriesArray[s]=seriesName;
	}
	
	Dialog.create("Choose which images to process");
		for (d=0; d<seriesArray.length; d++) {
		Dialog.addCheckbox(seriesArray[d], false);
		}
		Dialog.show();
		n=0;
		for (c=0; c<seriesArray.length; c++) {
			if(Dialog.getCheckbox()){
			selectArray[n]=c;
			n++;
			}
		}
}		
else{ // this is what happens if we want to process all the images.
	for (s=0; s<seriesCount; s++){
		selectArray[s]=s;
	}
}
	
 //Loop through the lif file - use the first line with a selection to run only a single image. i.e. you can run image 16 with (j=16; j<=16; j++)
 // for (j=16; j<=16; j++) {
 print(String.join(selectArray));
 
	for (sa=0; sa<selectArray.length; sa++) {
		j=selectArray[sa]+1;
		print(j);
			run("Bio-Formats", "open=lifPath autoscale color_mode=Default view=Hyperstack stack_order=XYCZT series_"+j);

//naming conventions for files can vary- when there is a slash or comma in the file name, it can cause a problem for saving
name=getTitle();
slash = "/";
comma = ",";
dash = "-";
hash = "#";
name = name.replace(slash, dash);
name = name.replace(comma, dash);
name = name.replace(hash, dash);
rename(name);

//This code chunk determines the six digit sample id. It would need to be shifted for different naming conventions
	if (matches(name, ".*[0-9].*")) {   
		//if the filename has any digit, 0-9, contained within the string, we process it to find a sampleID
		indexArray=newArray(10);
		for (m=0; m<10; m++) {
		indexArray[m]= indexOf(name, m); // finds the index of each digit, returns -1 if the digit isn't found
		}
		numArray = Array.deleteValue(indexArray, -1);//throw away -1 values
		Array.getStatistics(numArray,min,max);//find out which range to look for a string of 6 digits
		len =name.length();
		len= len-5;
		for (n=min; n<len; n++){ 
			// min is the index of the first digit in the name, 
			// len is the last index where a sampleID could start 
			f2=n +6; // calculates the index at the end of the name
		trimStr = substring(name, n,f2);
		if (matches(trimStr, ".*[^0-9].*")) { //the caret symbol indicates NOT- so if there is a non-digit, try the next
			}else{
				// but if only digits, this stretch of 6 digits will be used as sampleID
		sampleID = trimStr;
		
		}
	}
	}

//To make this automatic, I have added code that requires the cerebellum ROIs to be named with the same 6 digit sampleID included

//within the unzipped ROI folder are many ROI files 
//this code selects the file that matches sample ID/ full ID
dirList = getFileList(dirROI);
fIndex = -1;
for (o=0; o<dirList.length; o++) {	
	file = dirList[o];
	if(indexOf(file,sampleID)>-1){
		fIndex = o;
	}
}

//this experiment has 4 channels, 
//the User can mark the channels with the correct label using comments and save the macro with their output folder for documentation 
run("Split Channels");
C1="C1-"+name;//DAPI
C2="C2-"+name;//CD13
C3="C3-"+name;//Thbd
C4="C4-"+name;//ILB4

	
	print(sampleID + "_" +fIndex);
// now import Cb outline
RoiPath = dirROI +File.separator+dirList[fIndex];
open(RoiPath);
roiManager("add");//add the Cerebellum outline roi index 0. note that non-zipped ROIs need to be added to manager
roiManager("select", 0);
	roiManager("Rename","1-cb outline");


//Identify Vessel area
//decide threshold for ILB4 positive stain this is user defined.
selectImage(C4); // select the correct channel for the vessel marker, in this case C4
setThreshold(Ch4Thresh, 65535); // match with the correct channel threshold
run("Create Selection");
roiManager("add");//roi index 1  is vessel area
	roiManager("select", 1);
	roiManager("Rename","1-vessel");//rename to suit the experiment


//Identify Thbd area
//decide threshold for Thbd positive stain this is user defined. Change to suit the experiment.
selectImage(C3); // select the correct channel for the stain
setThreshold(Ch3Thresh, 65535); // match with the correct channel threshold
run("Create Selection");
roiManager("add");// which area is considered Thbd positive, Roi index 2
roiManager("select",2);
roiManager("Rename","Thbd_positive"); // rename to suit


CbVArray = newArray(0,1);
roiManager("select",CbVArray); // identifies the vessel area within the cerebellum 
roiManager("and");
roiManager("add"); // vessel area within cb, roi index 3
roiManager("select",3);
roiManager("Rename","vessel_cb"); // can be renamed if adjusted


CbEArray = newArray(0,2);
roiManager("select",CbEArray); // identifies a region of ch3 positive signal within the cerebellum
roiManager("and");
roiManager("add"); // Thbd area within cb, roi index 4
roiManager("select",4);
roiManager("Rename","Thbd_cb"); // can be renamed to suit


ThbdILB4Array = newArray(0,1,2); // Thbd, ILB4 within cb
roiManager("select",ThbdILB4Array); // area that is positive for Ch3 and the vessel marker within the cerebellum 
roiManager("and");
roiManager("add"); //  roi index 5
roiManager("select",5);
roiManager("Rename","Thbd_ILB4_cb"); // can be renamed to suit


//collect measurements
selectImage(C3); // select a channel to perform the area measurements
resetThreshold();
// select a series of the ROIs generated that you want to measure in order to determine the area 
roiManager("select", 0); 
run("Measure");
roiManager("select", 3);
run("Measure");
roiManager("select", 4);
run("Measure");
roiManager("select", 5);
run("Measure");

// label with a description of each measurement 
	A1 = Table.get("Area",0);// Cerebellum Area
	A2 = Table.get("Area",1);// ILB4 in Cb Area
	A3 = Table.get("Area",2);// Thbd in Cb Area
	A4 = Table.get("Area",3);// Thbd_ILB4 in Cb Area

	IJ.renameResults("Results","Results_"+sampleID);

	
//create a quality control image to quickly look through
selectImage(C4); // select a channel to use as the background image
resetThreshold();
//setMinAndMax(0, 150);
run("8-bit");

// use different colors or hexcode colors to fill desired ROIs with overlay color. 
// The colors are not blended, so whichever color is added last will be shown on top
roiManager("select", 1);
Roi.setStrokeWidth(10);
run("Add Selection...", "fill=#00FF00");//green shows ILB4 outline
run("Flatten");

roiManager("select", 5);
run("Add Selection...", "fill=#FF0000");//red shows Thbd_ILB4 within Cb
run("Flatten");

roiManager("select", 0);
run("Add Selection...", "stroke=#FFFFFF");//white shows cb outline
run("Flatten");

shrink = getWidth()/3; // make it smaller to speed up the saving
run("Size...", "width="+shrink+" constrain average interpolation=Bilinear");
saveAs("tif", dir2 + name + "_qc"); // saves an image
SaveArray = newArray(0,3,4,5); // saves the rois
	roiManager("select",SaveArray);
	roiManager("save",  dir2 + name + "_output_rois.zip")
	selectWindow("Log");
	run("Close");
exists = File.exists(dir2 + "results.txt"); // start a results text file
				if (exists != 1) {
				print("name, Cb Area, ILB4 in Cb Area, Thbd in Cb Area, Thbd_ILB4 in Cb area "); // rename the column headers of the results to match
				selectWindow("Log");
				saveAs("txt", dir2 + "results.txt");
				run("Close");
				}
				print (name+","+A1+","+A2+","+A3+","+A4);
				results=getInfo("log");
				File.append(results, dir2 + "results.txt");
				selectWindow("Log");
				run("Close");

//clean up
roiManager("Deselect");
roiManager("Delete");
run("Close All");
}
} //now ready to loop back to test the next image in the folder

// After all the images in the folder are processed, move onto saving parameters and improving the output. Get the time
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
TimeString = DayNames[dayOfWeek]+" ";
if (dayOfMonth<10) {TimeString = TimeString+"0";}
TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year;

exists = File.exists(dir2 + "parameters.txt");
				if (exists != 1) {
				print("Folder,Date,Thbd Threshold,ILB4 Threshold"); // rename the column titles of the parameters to match
				selectWindow("Log");
				saveAs("txt", dir2 + "parameters.txt");
				run("Close");
				}
print (dir2+","+TimeString+","+Ch3Thresh+","+Ch4Thresh);
				param=getInfo("Log");
				File.append(param, dir2 + "parameters.txt");
				selectWindow("Log");
				run("Close");			

//appending data in this way results in extra line breaks forming. This method removes them
double ="(\n\n)"; //the paranthesis make this a full expression
single ="\n";
filter = File.openAsString(dir2 + "results.txt");
filter = filter.replace(double,single);
lastnew = filter.lastIndexOf("\n");
filter = filter.substring(0,lastnew);
print(filter);
selectWindow("Log");
saveAs("txt", dir2 + "results.txt");
run("Close");


File.copy(dir2 + "results.txt", dir2 + "results.csv")
File.copy(dir2 + "parameters.txt", dir2 + "parameters.csv")
open(dir2 + "results.csv");
IJ.renameResults("results.csv","Results");
//can print results directly to Excel if plugin and excel are on the computer
run("Read and Write Excel", "no_count_column sheet=[Full Results] file=["+dir2 +ResultTitle +".xlsx]");
IJ.renameResults("AllResults"); 
open(dir2 + "parameters.csv");
IJ.renameResults("parameters.csv","Results");
run("Read and Write Excel", "no_count_column sheet=[Parameters] file=["+dir2 +ResultTitle +".xlsx]");
showMessage(" -- finished --");
run("Close All");
setBatchMode(false);

waitForUser("clear results windows?");
 list = getList("window.titles");
  if (list.length==0){
     print("No non-image windows are open");
  }else {
     print("Non-image windows:");
     for (i=0; i<list.length; i++){
        print("   "+list[i]);
        selectWindow(list[i]);
     	run("Close");
  }
  print("");