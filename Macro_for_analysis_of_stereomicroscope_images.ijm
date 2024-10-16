// Macro to measure lesion size from stereomicroscope color images. Images should be RGB Color tif files
// Macro Written by Fabrizio Orsenigo and modfied by Ross Smith (January 2022)

// User supplies stereomicroscope images of rodent brains on a dark background saved in tif format. 
// A parent folder is selected, this folder contains a child folder (i.e /Tif_images) which in turn contains the tifs.
// The script is initated by pressing the Run button below or by using the keyboard shortcut Ctrl + R.

function CT_lesion() {
a=getTitle();
run("HSB Stack");
run("Convert Stack to Images");
selectWindow("Hue");
rename("0");
selectWindow("Saturation");
rename("1");
//We duplicate the Saturation to get a nicer brain outline in a later step
run("Duplicate...", " ");
rename("1a");
selectWindow("Brightness");
rename("2");


for (m=0;m<3;m++){
  selectWindow(""+m);
  setThreshold(min[m], max[m]);
  run("Convert to Mask");
  if (filter[m]=="stop")  run("Invert");
}
//This gives a cleaner outline, if max range on brightness is not 255 some shiny spots on the brain would otherwise not be included in the brain outline
selectWindow("1a");
setAutoThreshold("Li dark");
//added to limit to brain area
run("Create Selection");
roiManager("Add");
//Depending on the number of pixels in an image, the minimum size of a particle can be changed by supplying a larger or smaller number in the line below for size =
//The desired result is to have only a single particle, representing the shape of the brain in the image
run("Analyze Particles...", "size=100000-Infinity pixel show=Masks display clear include");
selectWindow("Mask of 1a");
//several images are generated that can be viewed later to ensure that the analysis has worked for each image in the folder
saveAs("tif", dir1 + cond + File.separator + "Brain Masks"+ File.separator + substring(a, 0, indexOf(a, ".tif")) + "_Br-mask");
rename("ch4");

brA=getResult("Area", 0);
imageCalculator("AND create", "0","1");
imageCalculator("AND create", "Result of 0","2");
for (n=0;n<3;n++){
  selectWindow(""+n);
  close();
}
selectWindow("Result of 0");
close();
selectWindow("Result of Result of 0");
rename(a);
roiManager("Select", 0);
run("Clear Outside");
roiManager("Delete");
run("Analyze Particles...", "  show=Masks display clear");
selectWindow("Mask of " + a);
saveAs("tif", dir1 + cond + File.separator + "Lesion Masks" +File.separator + substring(a, 0, indexOf(a, ".tif")) + "_Les-masks");
rename("ch1");
run("Merge Channels...", "c1=[ch1] c4=[ch4] create");
Stack.setChannel(2);
run("Invert LUT");
run("Flatten");
saveAs("tif", dir1 + cond + File.separator + "Merge" +File.separator + substring(a, 0, indexOf(a, ".tif")) + "_merge");

close();
lesA = 0;
for (o = 0; o < nResults; o++) {
	lesA = lesA + getResult("Area", o);
}
selectWindow("Results");
run("Close");
// results are added to a txt file in the folder first- and then later saved as an excel file- note that ResultToExcel plugin is needed for that to work
exists1 = File.exists(dir1 + "Results.txt");
if (exists1 != 1) {
	print("ImageID,Folder,Brain Area,Total Lesion Area,% (Lesion/Brain)");
	selectWindow("Log");
	saveAs("txt", dir1 + "Results.txt");
	run("Close");
}
print(a + "," + cond + "," + brA + "," +lesA + "," + lesA/brA*100);
Res=getInfo("log");
File.append(Res, dir1 + "Results.txt");
selectWindow("Log");
run("Close");
run("Close All");
}

//end of function

// Get the time
MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
TimeString = DayNames[dayOfWeek]+" ";
if (dayOfMonth<10) {TimeString = TimeString+"0";}
TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year;

//options and folders
setOption("ExpandableArrays", true);
//choose which folder to be the parent folder- a user dialog is created to find the folder with tifs
dir0 =getDirectory("Choose folder that is the parent of the one with RGB tif files");
//output folder will be created inside a chosen location
dirOut =File.getParent(dir0)+ File.separator;
M_NAME = "CCM_stereo_macro";	
dir2Name = M_NAME +  "_" + TimeString;
dir2 = dirOut + "OUTPUT_from_" + dir2Name + File.separator;
File.makeDirectory(dir2);
dir1 = dir2;
//main routine
list = getFileList(dir0);
for (i = 0; i < list.length; i++) {
	result=endsWith(list[i], "/");

	if(result==1) {
		cond =substring(list[i], 0, (lengthOf(list[i])-1));
		File.makeDirectory(dir1 + cond + File.separator);
		File.makeDirectory(dir1 + cond + File.separator+ "Lesion Masks" + File.separator);
		File.makeDirectory(dir1 + cond + File.separator+ "Brain Masks" + File.separator);
		File.makeDirectory(dir1 + cond + File.separator+ "Merge" + File.separator);
		dir2=dir0 + list[i];
		list2=getFileList(dir2);
		Dialog.create("First row images selection");
		Dialog.addMessage("Select which images from the folder '" + cond + "' should go on the top row of the montage (e.g. the controls):");
			for (l = 0; l < list2.length; l++) {
			Dialog.addCheckbox(list2[l], false);
			}
		Dialog.show();
		Col=0;
			for (m = 0; m < list2.length; m++) {
			Sel=Dialog.getCheckbox();
				if (Sel == true) {
					Col = Col + 1;
				}
			}
		run("Image Sequence...", "open=[" + dir2 + "]");
		run("Make Montage...", "columns=" + Col + " rows=" + -floor(-list2.length/Col) +" scale=1");
		selectWindow("Montage");
		rename(cond);
		waitForUser("Find thresholds", "Use the window 'Threshold Color', that will appear next, to test the threshold parameters. Annotate the best parameter");
		run("Color Threshold...");
		waitForUser("Click OK when you are done");
		run("Close All");
		
		setBatchMode(true);
		list1=getFileList(dir2);
		for (l = 0; l < list1.length; l++) {
			open(dir2 + list1[l]);
			if (l==0) {

				Dialog.create("Select thresholds");
				Dialog.addMessage("Insert here the parameters that you have just annotated");
				Dialog.addMessage("The same paramenter will be applied to all the images within the folder called '" + cond + "'");
				Dialog.addMessage("");
				Dialog.addSlider("Hue Min", 0, 255, 0);
				Dialog.addSlider("Hue Max", 0, 255, 36);
				Dialog.addSlider("Sat Min", 0, 255, 84);
				Dialog.addSlider("Sat Max", 0, 255, 255);
				Dialog.addSlider("Brightness Min", 0, 255, 51);
				Dialog.addSlider("Brightness Max", 0, 255, 255);
				Dialog.addCheckbox("Hue filter is Pass", true);
				Dialog.addCheckbox("Saturation filter is Pass", true);
				Dialog.addCheckbox("Brightness filter is Pass", true);
				
				Dialog.show();
				min=newArray(3);
				max=newArray(3);
				filter=newArray(3);
				min[0]=Dialog.getNumber();
				max[0]=Dialog.getNumber();
				if (Dialog.getCheckbox() == true){
				filter[0]="pass";}
				else {
				filter[0]="stop";}
				
				min[1]=Dialog.getNumber();
				max[1]=Dialog.getNumber();
				if (Dialog.getCheckbox() == true){
				filter[1]="pass";}
				else {
				filter[1]="stop";}
			
				min[2]=Dialog.getNumber();
				max[2]=Dialog.getNumber();
				if (Dialog.getCheckbox() == true){
				filter[2]="pass";}
				else {
				filter[2]="stop";}
				
				//the user selected values will be saved as a parameter file- So that values can be reused in future experiments and to help with reporting and documentation
				exists2 = File.exists(dir1 + "Parameters.txt");
				if (exists2 != 1) {
				print("Folder,Hue Min,Hue Max, Sat Min, Sat Max, Bri Min, Bri Max, Hue Filter, Sat Filter, Bri Filter");
				selectWindow("Log");
				saveAs("txt", dir1 + "Parameters.txt");
				run("Close");
				}
				print (cond+","+min[0]+","+max[0]+","+min[1]+","+max[1]+","+min[2] +","+max[2]+","+ filter[0] + "," + filter[1] +"," + filter[2]);
				param=getInfo("log");
				File.append(param, dir1 + "Parameters.txt");
				selectWindow("Log");
				run("Close");
				
			}
			
			CT_lesion();
			
		}
		setBatchMode(false);
		}

}
call("java.lang.System.gc");
// code to export the results directly into excel, requires "read and write excel" plugin - can be commented out if the plugin is not available
File.copy(dir1 + "Results.txt", dir1 + "Results.csv")
open(dir1 + "Results.csv");
run("Read and Write Excel", "file=[" + dir1 +"Results.xlsx]");
File.copy(dir1 + "Parameters.txt", dir1 + "Parameters.csv")
waitForUser("Done!");
exit();