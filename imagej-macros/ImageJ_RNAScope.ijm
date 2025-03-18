/*
 *    This file is part of acosta-organoid-scRNAseq.
 *    Copyright (C) 2022-2025  Emir Turkes, Diana Acosta, Gi Guo, Yuzhou Chang,
 *    Hongjun Fu, Ohio State University Wexner Medical Center
 *
 *    This program is free software: you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation, either version 3 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 *    Emir Turkes can be contacted at emir.turkes@eturkes.com
 */

/*
 * Select Run once all files, file names, and file locations are correctly organized. Processed images work in .tiff file format. Analysis is done with ROIs that have been dilated.
 */

#@ File (label = "Input directory", style = "directory") input
#@ File (label = "Output directory", style = "directory") output
#@ String (label = "File suffix", value = ".tif") suffix

// See also Process_Folder.py for a version of this code
// in the Python scripting language.

processFolder(input);
// function to scan folders/subfolders/files to find files with correct suffix
function processFolder(input) {
	list = getFileList(input);
	list = Array.sort(list);
	for (i = 0; i < list.length; i++) {
    print(list[i]);
    }
	for (i = 0; i < list.length; i++) {
		if(File.isDirectory(input + File.separator + list[i]))
			processFolder(input + File.separator+ list[i]);
		if(endsWith(list[i], suffix)){
	

			print(input);
			processFile(input, output, list[i]);
		}
	}
}

function processFile(input, output, file) {
	open(input + file);
	print("Processing: " + input + File.separator + file);
	print("Saving to: " + input);
	run("8-bit");
	//title = getTitle();
	title = File.getNameWithoutExtension(file);
	// Set scale according to your image scale bar
	run("Set Scale...", "distance=60 known=6.434 unit=micron global");
	// Counting dots in image using Find Maxima function (Prominence set to 15) This value can be changed if the number of dots being counted is not accurate. 
	// each dot becomes a pixel
	run("Find Maxima...", "prominence=15 output=[Single Points]");
	close("\\Others");
	//Open ROI DAPI set onto image and count number of ROIs ***location of ROI file and name of file needs to accurate***
	filename_roi = "RoiSet_DAPI.zip";
	roiManager("Open", input + filename_roi);
	roiManager("Measure");
	saveAs("Results", input + "Nuclei_size.xls");
	close("Results");
	numberofroi = roiManager("count");
	print(numberofroi);
	roiManager("Show All");

for (i = 0; i < numberofroi; i++){
		roiManager("Select", i);
		run("Analyze Particles...", "size=1-1 pixel exclude summarize");
	}
	saveAs("Results", input + title + ".xls");
	roiManager("select all");
	roiManager("delete");
	close("*");
	close("Results");
	print(numberofroi);
	
}
