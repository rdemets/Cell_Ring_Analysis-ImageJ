/*
Plugin to install : 
MorpholibJ (via IJPB-plugins)


The aim of the macro is to analyse the density of smooth cells in channel 3, and to analyse the profile of the inner ring in channel 2 using channel 1 
All function used are available from the stable version of Fiji and MorpholibJ




Macro author R. De Mets
Version : 0.1.1 , 27/01/2026
Added Continuity % based on Otsu
*/


Dialog.create("GUI");
Dialog.addDirectory("Source image path","");
Dialog.show();
run("Clear Results");
run("Close All");
dirS = Dialog.getString;
filenames = getFileList(dirS);

title_progress = "[Progress]";
run("Text Window...", "name="+ title_progress +" width=50 height=5 monospaced");

setBatchMode(true);

// Open each file
for (i = 0; i < filenames.length; i++) {
//for (i = 0; i < 1; i++) {
// Open file if CZI
	currFile = dirS+filenames[i];
	print(title_progress, "\\Update:"+i+1+"/"+filenames.length+" ("+(i*100)/filenames.length+"%)\n"+getBar(i, filenames.length));
	if(endsWith(currFile, ".czi")) { // process czi files matching regex
		run("Close All");
		//run("Bio-Formats Importer", "open=[" + currFile+"]");
		open(currFile);
		print("\n\n"+currFile);


		scenes = nImages;
		titleList = getList("image.titles");
		roiManager("reset");
		
		print(nImages+ " scenes to analyse");
		
		for (scene = 0; scene < scenes; scene++) {
		
			
			// Analysis smooth muscle channel
			
			title = titleList[scene];
			print(title + " Scene "+ scene+1);
		
			selectWindow(title);
			// Preprocessing
			run("Duplicate...", "title=raw duplicate channels=3");
			run("Duplicate...", "title=blurred");
			run("Median...", "radius=3");
			
			
			//run("Threshold...");
			/*
			setAutoThreshold("Huang dark");
			setAutoThreshold("Intermodes dark");
			setAutoThreshold("IsoData dark");
			setAutoThreshold("IJ_IsoData dark");
			setAutoThreshold("Li dark");
			setAutoThreshold("MaxEntropy dark");
			setAutoThreshold("Mean dark");
			setAutoThreshold("MinError dark");
			setAutoThreshold("Minimum dark");
			setAutoThreshold("Moments dark");
			setAutoThreshold("Otsu dark");
			setAutoThreshold("Percentile dark");
			setAutoThreshold("RenyiEntropy dark");
			setAutoThreshold("Shanbhag dark");
			*/
			setAutoThreshold("Triangle dark");
			//setAutoThreshold("Yen dark");
			
			// Create mask for muscle cells
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Keep Largest Region");
			run("Create Selection");
			roiManager("Add");
			
			
			run("Select None");
			getHistogram(values, counts, 256);
			pixels_muscles = counts[255];
			//print(pixels_muscles);
			close("blurred");
			
			// Create mask for the whole muscle band
			run("Duplicate...", "title=band");
			run("Fill Holes");
			
			
			// Remove the central part
			imageCalculator("XOR create", "band","blurred-largest");
			run("Keep Largest Region");
			run("Create Selection");
			roiManager("Add");
			selectImage("band");
			roiManager("Select", 1);
			run("Invert");
			run("Create Selection");
			roiManager("Add");
			
			run("Select None");
			getHistogram(values, counts, 256);
			
			
			close("Result-largest");
			close("Result of band");
			
			pixels_band = counts[255];
			//print(pixels_band);
			print("Cell density: "+pixels_muscles/pixels_band*100);
			
			
			// run Average thickness and save zip
			Image.removeScale;
			run("Average Thickness");
			print("Average Thickness (px): "+getResult("AverageThickness_[pixel]", 0));
			
			
			close("blurred-largest");
			close("band");
			close("raw");
			
			
			
			// Analysis endotelium
			
			title = titleList[scene];
			selectWindow(title);
			// Preprocessing
			run("Duplicate...", "title=raw duplicate channels=1");
			run("Duplicate...", "title=blurred");
			run("Median...", "radius=2");
			setAutoThreshold("Triangle dark");
			//setAutoThreshold("Yen dark");
			
			// Create mask for tissue
			setOption("BlackBackground", true);
			run("Convert to Mask");
			run("Keep Largest Region");
			run("Create Selection");
			close("blurred");
			
			// Create mask for the whole muscle band
			run("Select None");
			run("Duplicate...", "title=band");
			run("Fill Holes");
			
			
			// Remove the central part
			imageCalculator("XOR create", "band","blurred-largest");
			run("Keep Largest Region");
			run("Dilate");
			run("Dilate");
			run("Dilate");
			run("Fill Holes");
			
			run("Create Selection");
			roiManager("Add");
			roiManager("save", dirS+ title+".zip");
			

			close("Result-largest");
			close("Result of band");
			close("band");
			close("blurred-largest");
			
			selectWindow("raw");
			close("raw");
			
			run("Duplicate...", "title=raw duplicate channels=2");
			roiManager("Select", 3);
			run("Area to Line");
			run("Straighten...", "title=[line] line=4");
			saveAs("Tiff", dirS+ title+"_PlotProfile.tif");
			
			run("Select All");
			profile = getProfile();
			bright = 0;
			for (j=0; j<profile.length; j++){
			  setResult("Value", j, profile[j]);
			  if(profile[j]>1183) // Determined by Percentile method on 19 sections
			  	bright = bright + 1;
			}
			updateResults();
			print("Endothelium Continuity:"+bright/profile.length*100+"%");
			saveAs("Measurements", dirS+ title+".csv");


			roiManager("reset");
			close(title);
			close("raw");
			close("line");
			close("Plot of line");
			run("Clear Results");


		}
	}
}

setBatchMode(false);
Dialog.create("DONE");
Dialog.addMessage("Done");
Dialog.show();


  function getBar(p1, p2) {
        n = 20;
        bar1 = "--------------------";
        bar2 = "********************";
        index = round(n*(p1/p2));
        if (index<1) index = 1;
        if (index>n-1) index = n-1;
        return substring(bar2, 0, index) + substring(bar1, index+1, n);
  }
