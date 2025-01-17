/* Inspired by the BAR ROI_Color_Coder.ijm
	This macro adds a statistical summary of the analysis to the image in the selection box or at one of the corners of the image.
	This version defaults to choosing units automatically.
	v170411 removes spaces in new image names to fix issue with naming new image combinations.
	v180612 set to work on only one slice.
	v190108 fixed median for single object.
	v190506 removed redundant function.
	v200706 Just changed imageDepth variable name to match other macros.
	v210630 Replaced unnecessary getAngle function
	v211022 Updated color function choices
	v211102 Added option to edit the label
	v211103 Expanded expansion function  f1-5: updated functions
 */
macro "Add Summary Table to Copy of Image"{
	macroL = "Fancy_Summary_Table_v211103-f5";
	requires("1.47r");
	saveSettings;
	/* Set options for black objects on white background as this works better for publications */
	run("Options...", "iterations=1 white count=1"); /* Set the background to white */
	run("Colors...", "foreground=black background=white selection=yellow"); /* Set the preferred colors for these macros */
	setOption("BlackBackground", false);
	run("Appearance...", " "); if(is("Inverting LUT")) run("Invert LUT"); /* do not use Inverting LUT */
	/*	The above should be the defaults but this makes sure (black particles on a white background)
		http://imagejdocu.tudor.lu/doku.php?id=faq:technical:how_do_i_set_up_imagej_to_deal_with_white_particles_on_a_black_background_by_default */
	getPixelSize(unit, pixWidth, pixHeight, pixDepth);
	selEType = selectionType; 
	if (selEType>=0) {
		if ((selEType>=5) && (selEType<=7)) {
			line==true;
			if (selEType>5) {
				/*  for 6=segmented line or 7=freehand line do a linear fit */
				getSelectionCoordinates(xPoints, yPoints);
				Array.getStatistics(xPoints, selEX1, selEX2, null, null);
				Fit.doFit("Linear", xPoints, yPoints);
				selEY1 = Fit.f(selEX1);
				selEY2 = Fit.f(selEX2);
			}
			else = getLine(selEX1, selEY1, selEX2, selEY2, selLineWidth);
			x1=selEX1*pixWidth; y1=selEY1*pixHeight; x2=selEX2*pixWidth; y2=selEY2*pixHeight; 
			scaledLineAngle = (180/PI) * Math.atan2((y1-y2), (x1-x2));
			scaledLineLength = sqrt(pow(x2-x1,2)+pow(y2-y1,2));
			selLineLength = sqrt(pow(selEX2-x1,2)+pow(selEY2-selEY1,2));
		}
		else {
			line = false;
			getSelectionBounds(selEX, selEY, selEWidth, selEHeight);
		}
	}
	t=getTitle();
	/* Now checks to see if a Ramp legend has been selected by accident */
	if (matches(t, ".*Ramp.*")==1) showMessageWithCancel("Title contains \"Ramp\"", "Do you really want to label " + t + " ?"); 
	setBatchMode(true);
	checkForResults();
	items= nResults;
	imageWidth = getWidth();
	imageHeight = getHeight();
	id = getImageID();
	fontSize = 22; /* default font size */
	lineSpacing = 1.1;
	outlineStroke = 8; /* default outline stroke: % of font size */
	shadowDrop = 12;  /* default outer shadow drop: % of font size */
	dIShO = 5; /* default inner shadow drop: % of font size */
	offsetX = round(1 + imageWidth/150); /* default offset of label from edge */
	offsetY = round(1 + imageHeight/150); /* default offset of label from edge */
	outlineColor = "black"; 	
	imageDepth = bitDepth();
	paraLabFontSize = round((imageHeight+imageWidth)/60);
	decPlacesSummary = -1;	/* defaults to scientific notation */
	Dialog.create("Label Formatting Options: " + macroL);
		headings = split(String.getResultsHeadings);
		Dialog.addChoice("Measurement:", headings, "Area");
		if (imageDepth==24)
			colorChoice = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray", "red", "cyan", "pink", "green", "blue", "yellow", "orange", "garnet", "gold", "aqua_modern", "blue_accent_modern", "blue_dark_modern", "blue_modern", "blue_honolulu", "gray_modern", "green_dark_modern", "green_modern", "orange_modern", "pink_modern", "purple_modern", "jazzberry_jam", "red_n_modern", "red_modern", "tan_modern", "violet_modern", "yellow_modern", "radical_red", "wild_watermelon", "outrageous_orange", "atomic_tangerine", "neon_carrot", "sunglow", "laser_lemon", "electric_lime", "screamin'_green", "magic_mint", "blizzard_blue", "shocking_pink", "razzle_dazzle_rose", "hot_magenta");
		else colorChoice = newArray("white", "black", "off-white", "off-black", "light_gray", "gray", "dark_gray");
		Dialog.addChoice("Text color:", colorChoice, colorChoice[0]);
		fontStyleChoice = newArray("bold", "bold antialiased", "italic", "italic antialiased", "bold italic", "bold italic antialiased", "unstyled");
		Dialog.addChoice("Font style:", fontStyleChoice, fontStyleChoice[1]);
		fontNameChoice = newArray("SansSerif", "Serif", "Monospaced");
		fontNameChoice = getFontChoiceList();
		iFN = indexOfArray(fontNameChoice, call("ij.Prefs.get", "fancy.scale.font",fontNameChoice[0]),0);
		Dialog.addChoice("Font name:", fontNameChoice, fontNameChoice[iFN]);
		Dialog.addNumber("Line Spacing", lineSpacing,0,3,"");
		unitChoice = newArray("Auto", "Manual", unit, unit+"^2", "None", "pixels", "pixels^2", fromCharCode(0x00B0), "degrees", "radians", "%", "arb.");
		Dialog.addChoice("Unit Label \(if needed\):", unitChoice, unitChoice[0]);
		Dialog.addNumber("Outline stroke:", outlineStroke,0,3,"% of font size");
		Dialog.addChoice("Outline (background) color:", colorChoice, colorChoice[1]);
		Dialog.addNumber("Shadow drop: �", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow displacement right: �", shadowDrop,0,3,"% of font size");
		Dialog.addNumber("Shadow Gaussian blur:", floor(0.75 * shadowDrop),0,3,"% of font size");
		Dialog.addNumber("Shadow Darkness:", 75,0,3,"%\(darkest = 100%\)");
		Dialog.addMessage("The following \"Inner Shadow\" options do not change the Overlay scale bar");
		Dialog.addNumber("Inner shadow drop: �", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner displacement right: �", dIShO,0,3,"% of font size");
		Dialog.addNumber("Inner shadow mean blur:",floor(dIShO/2),1,3,"% of font size");
		Dialog.addNumber("Inner Shadow Darkness:", 20,0,3,"% \(darkest = 100%\)");
		Dialog.show();
		parameter = Dialog.getChoice();
		labelColor = Dialog.getChoice();
		fontStyle = Dialog.getChoice();
		fontName = Dialog.getChoice();
		lineSpacing = Dialog.getNumber();
		unitLabel = Dialog.getChoice();
		outlineStroke = Dialog.getNumber();
		outlineColor = Dialog.getChoice();
		shadowDrop = Dialog.getNumber();
		shadowDisp = Dialog.getNumber();
		shadowBlur = Dialog.getNumber();
		shadowDarkness = Dialog.getNumber();
		innerShadowDrop = Dialog.getNumber();
		innerShadowDisp = Dialog.getNumber();
		innerShadowBlur = Dialog.getNumber();
		innerShadowDarkness = Dialog.getNumber();
	// Determine parameter label
	parameterLabel = parameter;
	if (unitLabel=="Auto") unitLabel = unitLabelFromString(parameter, unit);
	if (unitLabel=="Manual") {
		unitLabel = unitLabelFromString(parameter, unit);
			Dialog.create("Manual unit input");
			Dialog.addString("Label:", unitLabel, 8);
			Dialog.addMessage("^2 & um etc. replaced by " + fromCharCode(178) + " & " + fromCharCode(181) + "m...");
			Dialog.show();
			unitLabel = Dialog.getString();
	}
	if (unitLabel=="None") unitLabel = ""; 
	parameterLabel = stripUnitFromString(parameter);
	unitLabel= cleanLabel(unitLabel);	
	parameterLabel= cleanLabel(parameterLabel);
	parameterLabel = replace(parameterLabel, "px", "pixels"); // expand "px" used to keep Results columns narrower
	//recombine units and labels
	if (unitLabel!="") paraLabel = parameterLabel + ", " + unitLabel;
	else paraLabel = parameterLabel;
	// parameterLabel = replace(parameterLabel, "_", fromCharCode(0x2009)); // replace underlines with thin spaces
	parameterLabel = expandLabel(parameterLabel);
	negAdj = 0.5;  /* negative offsets appear exaggerated at full displacement */
	if (shadowDrop<0) shadowDrop *= negAdj;
	if (shadowDisp<0) shadowDisp *= negAdj;
	if (shadowBlur<0) shadowBlur *= negAdj;
	if (innerShadowDrop<0) innerShadowDrop *= negAdj;
	if (innerShadowDisp<0) innerShadowDisp *= negAdj;
	if (innerShadowBlur<0) innerShadowBlur *= negAdj;
		fontPC = fontSize/100; /* convert percent to pixels */
	outlineStroke = floor(fontPC * outlineStroke);
	shadowDrop = floor(fontPC * shadowDrop);
	shadowDisp = floor(fontPC * shadowDisp);
	shadowBlur = floor(fontPC * shadowBlur);
	innerShadowDrop = floor(fontPC * innerShadowDrop);
	innerShadowDisp = floor(fontPC * innerShadowDisp);
	innerShadowBlur = floor(fontPC * innerShadowBlur);
		shadowDarkness = (255/100) * (abs(shadowDarkness));
	innerShadowDarkness = (255/100) * (100 - (abs(innerShadowDarkness)));
	unitLabelCheck = matches(unitLabel, ".*[A-Za-z].*");
		if (fontStyle=="unstyled") fontStyle="";
	paraLabFontSize = round((imageHeight+imageWidth)/45);
	statsLabFontSize= round((imageHeight+imageWidth)/60);
	/*
	Get values for chosen parameter */
	values= newArray(items);
	for (i=0; i<items; i++)
		values[i]= getResult(parameter,i);
	Array.getStatistics(values, arrayMin, arrayMax, arrayMean, arraySD);
	decPlacesSummary = autoCalculateDecPlacesFromValueOnly(arrayMean);
	coeffVar = (100/arrayMean)*arraySD;
	dpLab = decPlacesSummary+2; /* Increase dp over ramp label autosetting */
	coeffVar = d2s(coeffVar,dpLab);
	arrayMeanLab = d2s(arrayMean,dpLab);
	coeffVarLab = d2s((100/arrayMean)*arraySD,dpLab);
	arraySDLab = d2s(arraySD,dpLab);
	arrayMinLab = d2s(arrayMin,dpLab);
	arrayMaxLab = d2s(arrayMax,dpLab);
	sortedValues = Array.copy(values);
	sortedValues = Array.sort(sortedValues);
	arrayMedian = sortedValues[floor(items/2)];
	arrayMedianLab = d2s(arrayMedian,dpLab);
				
	if (selEType>=0) loc = 6; /* default choice selector for dialog */
	else loc = 2; /* default choice selector for dialog - center */
	paraLabel = expandLabel(paraLabel);
	Dialog.create("Feature Label Formatting Options");
		if (selEType>=0) paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection", "At Selection"); 
		else paraLocChoice = newArray("Top Left", "Top Right", "Center", "Bottom Left", "Bottom Right", "Center of New Selection"); 
		Dialog.addChoice("Location of Summary:", paraLocChoice, paraLocChoice[loc]);
		Dialog.addString("Parameter label:",cleanLabel(paraLabel),lengthOf(paraLabel) + 10);
		Dialog.addChoice("Parameter Label: " + paraLabel, newArray("Yes", "No"), "Yes");
		Dialog.addNumber("Image Label Font size:", paraLabFontSize);			
		statsChoice = newArray("None", "No more labels", "Dashed line:  ---", "Number of objects:  "+items,  "Mean:  "+arrayMeanLab, "Median:  "+arrayMedianLab, "StdDev:  "+arraySDLab, "CoeffVar:  "+coeffVarLab, "Min-Max:  "+arrayMinLab+"-"+arrayMaxLab, "Minimum:  "+arrayMinLab, "Maximum:  "+arrayMaxLab, "6 Underlines:  ___", "12 Underlines:  ___", "18 Underlines:  ___", "24 Underlines:  ___");
		statsChoiceLines = 8;
		for (i=0; i<statsChoiceLines; i++)
			Dialog.addChoice("Statistics Label Line "+(i+2)+":", statsChoice, statsChoice[i+2]);
		dpChoice = newArray(dpLab, -1, 0, 1, 2, 3, 4, 5, 6, 7, 8);
		Dialog.addChoice("Change Decimal Places from "+dpLab, dpChoice, dpLab);
		Dialog.addNumber("Statistics Label Font size:", statsLabFontSize);
		Dialog.show();
		
		paraLabPos = Dialog.getChoice();
		paraLabel = Dialog.getString();
		paraLabChoice = Dialog.getChoice();
		paraLabFontSize =  Dialog.getNumber();
		statsLabLine = newArray(statsChoiceLines);
		for (i=0; i<statsChoiceLines; i++)
			statsLabLine[i] = Dialog.getChoice();
		decPlacesSummary = Dialog.getChoice();
		statsLabFontSize = Dialog.getNumber();
			
	if (paraLabChoice=="Yes") labLines = 1;
	else labLines = 0;
	statsLines = 0;
	statsLabLineText = newArray(8);
	setFont(fontName, statsLabFontSize, fontStyle);
	longestStringWidth = 0;
	for (i=0; i<statsChoiceLines; i++) {
		// if (statsLabLine[i]!="None") statsLines = statsLines + 1;
		if (statsLabLine[i]=="No more labels") i = statsChoiceLines;
		else if (statsLabLine[i]!="None") {
			statsLines = i + 1;
			statsLabLine[i] = substring(statsLabLine[i], 0, indexOf(statsLabLine[i], ":  "));
			if (statsLabLine[i]=="Dashed line") statsLabLineText[i] = "----------";
			else if (statsLabLine[i]=="Number of objects") statsLabLineText[i] = "Objects = " + items;
			else if (statsLabLine[i]=="Mean") statsLabLineText[i] = "Mean = " + d2s(arrayMean,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Median") statsLabLineText[i] = "Median = " + d2s(arrayMedian,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="StdDev") statsLabLineText[i] = "Std.Dev. = " + d2s(arraySD,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="CoeffVar") statsLabLineText[i] = "Coeff.Var. = " + d2s(coeffVar,decPlacesSummary) + "%";
			else if (statsLabLine[i]=="Min-Max") statsLabLineText[i] = "Range = " + d2s(arrayMin,decPlacesSummary) + " - " + d2s(arrayMax,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Minimum") statsLabLineText[i] = "Minimum = " + d2s(arrayMin,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="Maximum") statsLabLineText[i] = "Maximum = " + d2s(arrayMax,decPlacesSummary) + " " + unitLabel;
			else if (statsLabLine[i]=="6 Underlines") statsLabLineText[i] = "______";
			else if (statsLabLine[i]=="12 Underlines") statsLabLineText[i] = "____________";
			else if (statsLabLine[i]=="18 Underlines") statsLabLineText[i] = "__________________";
			else if (statsLabLine[i]=="24 Underlines") statsLabLineText[i] = "________________________";
			if (unitLabel==fromCharCode(0x00B0)) statsLabLineText[i] = replace(statsLabLineText[i], " "+ fromCharCode(0x00B0), fromCharCode(0x00B0)); // tweak to remove space before degree symbol
			if (getStringWidth(statsLabLineText[i])>longestStringWidth) longestStringWidth = getStringWidth(statsLabLineText[i]);
		}
	}
	linesSpace = lineSpacing * ((labLines*paraLabFontSize)+(statsLines*statsLabFontSize)); // Calculate vertical space taken up by text
	if (paraLabChoice=="Yes") {
		setFont(fontName, paraLabFontSize, fontStyle);
		if (getStringWidth(paraLabel)>longestStringWidth) longestStringWidth = getStringWidth(paraLabel);
	}
	if (paraLabPos == "Top Left") {
		selEX = offsetX;
		selEY = offsetY;
	} else if (paraLabPos == "Top Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = offsetY;
	} else if (paraLabPos == "Center") {
		selEX = round((imageWidth/2) - longestStringWidth/2);
		selEY = round((imageHeight/2) - (linesSpace/2));
	} else if (paraLabPos == "Bottom Left") {
		selEX = offsetX;
		selEY = imageHeight - (offsetY + linesSpace); 
	} else if (paraLabPos == "Bottom Right") {
		selEX = imageWidth - longestStringWidth - offsetX;
		selEY = imageHeight - (offsetY + linesSpace);
	} else if (paraLabPos == "Center of New Selection"){
		if (is("Batch Mode")==true) setBatchMode(false); /* Does not accept interaction while batch mode is on */
		setTool("rectangle");
		msgtitle="Location for the summary labels...";
		msg = "Draw a box in the image where you want to center the summary labels...";
		waitForUser(msgtitle, msg);
		getSelectionBounds(newSelEX, newSelEY, newSelEWidth, newSelEHeight);
		selEX = newSelEX + round((newSelEWidth/2) - longestStringWidth/1.5);
		selEY = newSelEY + round((newSelEHeight/2) - (linesSpace/2));
		if (is("Batch Mode")==false) setBatchMode(true);	// toggle batch mode back on
	} else if (selEType>=0) {
		selEX = selEX + round((selEWidth/2) - longestStringWidth/1.5);
		selEY = selEY + round((selEHeight/2) - (linesSpace/2));
	}
	run("Select None");
	if (selEY<=1.5*paraLabFontSize)
		selEY += paraLabFontSize;
	if (selEX<offsetX) selEX = offsetX;
	endX = selEX + longestStringWidth;
	if ((endX+offsetX)>imageWidth) selEX = imageWidth - longestStringWidth - offsetX;
	paraLabelX = selEX;
	paraLabelY = selEY;
	roiManager("show none");
	// roiManager("Show All without labels");
	run("Flatten");
	if (imageDepth==8) run("8-bit"); /* restores to 8-bit after flatten */
	flatImage = getTitle();
	if (is("Batch Mode")==false) setBatchMode(true);
	newImage("label_mask", "8-bit black", imageWidth, imageHeight, 1);
	roiManager("show none");
	roiManager("deselect");
	run("Select None");
	setColor(255,255,255);
	/* Draw summary over top of image */
	if (paraLabChoice=="Yes") {
		setFont(fontName, paraLabFontSize, fontStyle);
		drawString(paraLabel, paraLabelX, paraLabelY);
		paraLabelY += lineSpacing * paraLabFontSize;
	}
	setFont(fontName,statsLabFontSize, fontStyle);
	for (i=0; i<statsLines; i++) {
		// if (statsLabLine[i]!="None") statsLines = statsLines + 1;
		if (statsLabLine[i]!="None") {
			drawString(statsLabLineText[i], paraLabelX, paraLabelY);
			paraLabelY += lineSpacing * statsLabFontSize;
		}
	}
	setThreshold(0, 128);
	setOption("BlackBackground", false);
	run("Convert to Mask");
	/*
	Create drop shadow if desired */
	if (shadowDrop!=0 || shadowDisp!=0 || shadowBlur!=0) {
		showStatus("Creating drop shadow for labels . . . ");
		newImage("shadow", "8-bit black", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX+shadowDisp, selMaskY+shadowDrop);
		setBackgroundColor(shadowDarkness, shadowDarkness, shadowDarkness);
		run("Clear", "slice");
		getSelectionFromMask("label_mask");
		expansion = abs(shadowDisp) + abs(shadowDrop) + abs(shadowBlur);
		if (expansion>0) run("Enlarge...", "enlarge=&expansion pixel");
		if (shadowBlur>0) run("Gaussian Blur...", "sigma=&shadowBlur");
		run("Select None");
	}
	/*	Create inner shadow if desired */
	if (innerShadowDrop!=0 || innerShadowDisp!=0 || innerShadowBlur!=0) {
		showStatus("Creating inner shadow for labels . . . ");
		newImage("inner_shadow", "8-bit white", imageWidth, imageHeight, 1);
		getSelectionFromMask("label_mask");
		setBackgroundColor(innerShadowDarkness, innerShadowDarkness, innerShadowDarkness);
		run("Clear Outside");
		getSelectionBounds(selMaskX, selMaskY, selMaskWidth, selMaskHeight);
		setSelectionLocation(selMaskX-innerShadowDisp, selMaskY-innerShadowDrop);
		setBackgroundColor(innerShadowDarkness, innerShadowDarkness, innerShadowDarkness);
		run("Clear Outside");
		getSelectionFromMask("label_mask");
		expansion = abs(innerShadowDisp) + abs(innerShadowDrop) + abs(innerShadowBlur);
		if (expansion>0) run("Enlarge...", "enlarge=&expansion pixel");
		if (innerShadowBlur>0) run("Mean...", "radius=&innerShadowBlur"); /* Gaussian is too large */
		if (statsLabFontSize<12) run("Unsharp Mask...", "radius=0.5 mask=0.2"); /* A tweak to sharpen effect for small font sizes */
		imageCalculator("Max", "inner_shadow","label_mask");
		run("Select None");
		run("Invert");  /* Create an image that can be subtracted - this works better for color than Min */
	}
	if (isOpen("shadow"))
		imageCalculator("Subtract", flatImage,"shadow");
	run("Select None");
	getSelectionFromMask("label_mask");
	run("Enlarge...", "enlarge=&outlineStroke pixel");
	setBackgroundFromColorName(outlineColor); // functionoutlineColor]")
	run("Clear", "slice");
	run("Select None");
	getSelectionFromMask("label_mask");
	setBackgroundFromColorName(labelColor);
	run("Clear", "slice");
	run("Select None");
	if (isOpen("inner_shadow"))
		imageCalculator("Subtract", flatImage,"inner_shadow");
	closeImageByTitle("shadow");
	closeImageByTitle("inner_shadow");
	closeImageByTitle("label_mask");
	selectWindow(flatImage);
	if ((lastIndexOf(t,"."))>0)  labeledImageNameWOExt = unCleanLabel(substring(flatImage, 0, lastIndexOf(flatImage,".")));
	else labeledImageNameWOExt = unCleanLabel(flatImage);
	rename(labeledImageNameWOExt + "_" + parameter);
	restoreSettings();
	setBatchMode("exit & display");
	beep();beep();beep();
	call("java.lang.System.gc");
	showStatus("Fancy Summary Table Macro Finished");
}	

  /* ********* ASC modified BAR Color Functions Color Functions ********* */
  
	function getColorArrayFromColorName(colorName) {
		/* v180828 added Fluorescent Colors
		   v181017-8 added off-white and off-black for use in gif transparency and also added safe exit if no color match found
		   v191211 added Cyan
		   v211022 all names lower-case, all spaces to underscores v220225 Added more hash value comments as a reference
		*/
		if (colorName == "white") cA = newArray(255,255,255);
		else if (colorName == "black") cA = newArray(0,0,0);
		else if (colorName == "off-white") cA = newArray(245,245,245);
		else if (colorName == "off-black") cA = newArray(10,10,10);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "off-black") cA = newArray(10,10,10);
		else if (colorName == "light_gray") cA = newArray(200,200,200);
		else if (colorName == "gray") cA = newArray(127,127,127);
		else if (colorName == "dark_gray") cA = newArray(51,51,51);
		else if (colorName == "red") cA = newArray(255,0,0);
		else if (colorName == "pink") cA = newArray(255, 192, 203);
		else if (colorName == "green") cA = newArray(0,255,0); /* #00FF00 AKA Lime green */
		else if (colorName == "blue") cA = newArray(0,0,255);
		else if (colorName == "yellow") cA = newArray(255,255,0);
		else if (colorName == "orange") cA = newArray(255, 165, 0);
		else if (colorName == "cyan") cA = newArray(0, 255, 255);
		else if (colorName == "garnet") cA = newArray(120,47,64);
		else if (colorName == "gold") cA = newArray(206,184,136);
		else if (colorName == "aqua_modern") cA = newArray(75,172,198); /* #4bacc6 AKA "Viking" aqua */
		else if (colorName == "blue_accent_modern") cA = newArray(79,129,189); /* #4f81bd */
		else if (colorName == "blue_dark_modern") cA = newArray(31,73,125); /* #1F497D */
		else if (colorName == "blue_modern") cA = newArray(58,93,174); /* #3a5dae */
		else if (colorName == "blue_honolulu") cA = newArray(0,118,182); /* Honolulu Blue #30076B6 */
		else if (colorName == "gray_modern") cA = newArray(83,86,90); /* bright gray #53565A */
		else if (colorName == "green_dark_modern") cA = newArray(121,133,65); /* Wasabi #798541 */
		else if (colorName == "green_modern") cA = newArray(155,187,89); /* #9bbb59 AKA "Chelsea Cucumber" */
		else if (colorName == "green_modern_accent") cA = newArray(214,228,187); /* #D6E4BB AKA "Gin" */
		else if (colorName == "green_spring_accent") cA = newArray(0,255,102); /* #00FF66 AKA "Spring Green" */
		else if (colorName == "orange_modern") cA = newArray(247,150,70); /* #f79646 tan hide, light orange */
		else if (colorName == "pink_modern") cA = newArray(255,105,180); /* hot pink #ff69b4 */
		else if (colorName == "purple_modern") cA = newArray(128,100,162); /* blue-magenta, purple paradise #8064A2 */
		else if (colorName == "jazzberry_jam") cA = newArray(165,11,94);
		else if (colorName == "red_n_modern") cA = newArray(227,24,55);
		else if (colorName == "red_modern") cA = newArray(192,80,77);
		else if (colorName == "tan_modern") cA = newArray(238,236,225);
		else if (colorName == "violet_modern") cA = newArray(76,65,132);
		else if (colorName == "yellow_modern") cA = newArray(247,238,69);
		/* Fluorescent Colors https://www.w3schools.com/colors/colors_crayola.asp */
		else if (colorName == "radical_red") cA = newArray(255,53,94);			/* #FF355E */
		else if (colorName == "wild_watermelon") cA = newArray(253,91,120);		/* #FD5B78 */
		else if (colorName == "outrageous_orange") cA = newArray(255,96,55);	/* #FF6037 */
		else if (colorName == "supernova_orange") cA = newArray(255,191,63);	/* FFBF3F Supernova Neon Orange*/
		else if (colorName == "atomic_tangerine") cA = newArray(255,153,102);	/* #FF9966 */
		else if (colorName == "neon_carrot") cA = newArray(255,153,51);			/* #FF9933 */
		else if (colorName == "sunglow") cA = newArray(255,204,51); 			/* #FFCC33 */
		else if (colorName == "laser_lemon") cA = newArray(255,255,102); 		/* #FFFF66 "Unmellow Yellow" */
		else if (colorName == "electric_lime") cA = newArray(204,255,0); 		/* #CCFF00 */
		else if (colorName == "screamin'_green") cA = newArray(102,255,102); 	/* #66FF66 */
		else if (colorName == "magic_mint") cA = newArray(170,240,209); 		/* #AAF0D1 */
		else if (colorName == "blizzard_blue") cA = newArray(80,191,230); 		/* #50BFE6 Malibu */
		else if (colorName == "dodger_blue") cA = newArray(9,159,255);			/* #099FFF Dodger Neon Blue */
		else if (colorName == "shocking_pink") cA = newArray(255,110,255);		/* #FF6EFF Ultra Pink */
		else if (colorName == "razzle_dazzle_rose") cA = newArray(238,52,210); 	/* #EE34D2 */
		else if (colorName == "hot_magenta") cA = newArray(255,0,204);			/* #FF00CC AKA Purple Pizzazz */
		else restoreExit("No color match to " + colorName);
		return cA;
	}
	function setBackgroundFromColorName(colorName) {
		colorArray = getColorArrayFromColorName(colorName);
		setBackgroundColor(colorArray[0], colorArray[1], colorArray[2]);
	}
	/* Hex conversion below adapted from T.Ferreira, 20010.01 http://imagejdocu.tudor.lu/doku.php?id=macro:rgbtohex */
	function pad(n) {
	  /* This version by Tiago Ferreira 6/6/2022 eliminates the toString macro function */
	  if (lengthOf(n)==1) n= "0"+n; return n;
	  if (lengthOf(""+n)==1) n= "0"+n; return n;
	}
	
	/* End ASC modified BAR Color Functions */
	
		/* ( 8(|)   ( 8(|)  ASC Functions  ( 8(|)  ( 8(|)   */
	
	function autoCalculateDecPlacesFromValueOnly(value){ /* Note this version is different from the one used for ramp legends */
		valueSci = d2s(value, -1);
		iExp = indexOf(valueSci, "E");
		valueExp = parseInt(substring(valueSci, iExp+1));
		if (valueExp>=2) dP = 0;
		if (valueExp<2) dP = 2-valueExp;
		if (valueExp<-5) dP = -1; /* Scientific Notation */
		if (valueExp>=4) dP = -1; /* Scientific Notation */
		return dP;
	}
	function binaryCheck(windowTitle) { /* For black objects on a white background */
		/* v180601 added choice to invert or not 
		v180907 added choice to revert to the true LUT, changed border pixel check to array stats
		v190725 Changed to make binary
		Requires function: restoreExit
		*/
		selectWindow(windowTitle);
		if (!is("binary")) run("8-bit");
		/* Quick-n-dirty threshold if not previously thresholded */
		getThreshold(t1,t2); 
		if (t1==-1)  {
			run("8-bit");
			run("Auto Threshold", "method=Default");
			setOption("BlackBackground", false);
			run("Make Binary");
		}
		if (is("Inverting LUT"))  {
			trueLUT = getBoolean("The LUT appears to be inverted, do you want the true LUT?", "Yes Please", "No Thanks");
			if (trueLUT) run("Invert LUT");
		}
		/* Make sure black objects on white background for consistency */
		cornerPixels = newArray(getPixel(0, 0), getPixel(0, 1), getPixel(1, 0), getPixel(1, 1));
		Array.getStatistics(cornerPixels, cornerMin, cornerMax, cornerMean, cornerStdDev);
		if (cornerMax!=cornerMin) restoreExit("Problem with image border: Different pixel intensities at corners");
		/*	Sometimes the outline procedure will leave a pixel border around the outside - this next step checks for this.
			i.e. the corner 4 pixels should now be all black, if not, we have a "border issue". */
		if (cornerMean==0) {
			inversion = getBoolean("The background appears to have intensity zero, do you want the intensities inverted?", "Yes Please", "No Thanks");
			if (inversion) run("Invert"); 
		}
	}
	function checkForResults() {
		nROIs = roiManager("count");
		nRES = nResults;
		if (nRES==0)	{
			Dialog.create("No Results to Work With");
			Dialog.addCheckbox("Run Analyze-particles to generate table?", true);
			Dialog.addMessage("This macro requires a Results table to analyze.\n \nThere are   " + nRES +"   results.\nThere are    " + nROIs +"   ROIs.");
			Dialog.show();
			analyzeNow = Dialog.getCheckbox(); /* If (analyzeNow==true), ImageJ Analyze Particles will be performed, otherwise exit */
			if (analyzeNow==true) {
				if (roiManager("count")!=0) {
					roiManager("deselect")
					roiManager("delete"); 
				}
				setOption("BlackBackground", false);
				run("Analyze Particles..."); /* Let user select settings */
			}
			else restoreExit("Goodbye, your previous setting will be restored.");
		}
	}
	function cleanLabel(string) {
		/*  ImageJ macro default file encoding (ANSI or UTF-8) varies with platform so non-ASCII characters may vary: hence the need to always use fromCharCode instead of special characters.
		v180611 added "degreeC"
		v200604	fromCharCode(0x207B) removed as superscript hyphen not working reliably	*/
		string= replace(string, "\\^2", fromCharCode(178)); /* superscript 2 */
		string= replace(string, "\\^3", fromCharCode(179)); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, "\\^-"+fromCharCode(185), "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-"+fromCharCode(178), "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-^2", "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-1", "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-2", "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "\\^-^1", "-" + fromCharCode(185)); /* superscript -1 */
		string= replace(string, "\\^-^2", "-" + fromCharCode(178)); /* superscript -2 */
		string= replace(string, "(?<![A-Za-z0-9])u(?=m)", fromCharCode(181)); /* micron units */
		string= replace(string, "\\b[aA]ngstrom\\b", fromCharCode(197)); /* �ngstr�m unit symbol */
		string= replace(string, "  ", " "); /* Replace double spaces with single spaces */
		string= replace(string, "_", " "); /* Replace underlines with space as thin spaces (fromCharCode(0x2009)) not working reliably  */
		string= replace(string, "px", "pixels"); /* Expand pixel abbreviation */
		string= replace(string, "degreeC", fromCharCode(0x00B0) + "C"); /* Degree symbol for dialog boxes */
		string = replace(string, " " + fromCharCode(0x00B0), fromCharCode(0x2009) + fromCharCode(0x00B0)); /* Replace normal space before degree symbol with thin space */
		string= replace(string, " �", fromCharCode(0x2009) + fromCharCode(0x00B0)); /* Replace normal space before degree symbol with thin space */
		string= replace(string, "sigma", fromCharCode(0x03C3)); /* sigma for tight spaces */
		string= replace(string, "�", fromCharCode(0x00B1)); /* plus or minus */
		return string;
	}
	function closeImageByTitle(windowTitle) {  /* Cannot be used with tables */
		/* v181002 reselects original image at end if open
		   v200925 uses "while" instead of if so it can also remove duplicates
		*/
		oIID = getImageID();
        while (isOpen(windowTitle)) {
			selectWindow(windowTitle);
			close();
		}
		if (isOpen(oIID)) selectImage(oIID);
	}
	function expandLabel(string) {  /* Expands abbreviations typically used for compact column titles
		v200604	fromCharCode(0x207B) removed as superscript hyphen not working reliably
		v211102-v211103  Some more fixes and updated to match latest extended geometries  */
		string = replace(string, "Raw Int Den", "Raw Int. Density");
		string = replace(string, "FeretAngle", "Feret Angle");
		string = replace(string, "FiberThAnn", "Fiber Thckn. from Annulus");
		string = replace(string, "FiberLAnn", "Fiber Length from Annulus");
		string = replace(string, "FiberLR", "Fiber Length R");
		string = replace(string, " Th ", " Thickness ");
		string = replace(string, " Crl ", " Curl ");
		string = replace(string, "Snk", "\(Snake\)");
		string = replace(string, "Fbr", "Fiber");
		string = replace(string, "Cir_to_El_Tilt", "Circle Tilt based on Ellipse");
		string = replace(string, "AR_", "Aspect Ratio: ");
		string = replace(string, "Rnd_", "Roundness: ");
		string = replace(string, "Sqr_", "Square: ");
		string = replace(string, "Squarity_AP","Squarity: from Area and Perimeter");
		string = replace(string, "Squarity_AF","Squarity: from Area and Feret");
		string = replace(string, "Squarity_Ff","Squarity: from Feret");
		string = replace(string, "Rss1", "/(Russ Formula 1/)");
		string = replace(string, "Rss1", "/(Russ Formula 2/)");
		string = replace(string, "Rndnss", "Roundness");
		string = replace(string, "_cAR", "\(Corrected by Aspect Ratio\)");
		string = replace(string, "Da_Equiv","Diameter from Area \(Circular\)");
		string = replace(string, "Dp_Equiv","Diameter from Perimeter \(Circular\)");	
		string = replace(string, "Dsph_Equiv","Diameter from Feret \(Spherical\)");
		string = replace(string, "Hxgn_", "Hexagon: ");
		string = replace(string, "Perim", "Perimeter");
		string = replace(string, "Perimetereter", "Perimeter"); /* just in case we already have a perimeter */
		string = replace(string, "HSFR", "Hexagon Shape Factor Ratio");
		string = replace(string, "HSF", "Hexagon Shape Factor");
		string = replace(string, "Vol_", "Volume: ");
		string = replace(string, "Da", "Diam:area");
		string = replace(string, "Dp", "Diam:perim.");
		string = replace(string, "equiv", "equiv.");
		string = replace(string, "_", " ");
		string = replace(string, "�", "degrees");
		string = replace(string, "0-90", "0-90�"); /* An exception to the above */
		string = replace(string, "�, degrees", "�"); /* That would be otherwise be too many degrees */
		string = replace(string, fromCharCode(0x00C2), ""); /* Remove mystery � */
		// string = replace(string, "^-", fromCharCode(0x207B)); /* Replace ^- with superscript - Not reliable though */
		// string = replace(string, " ", fromCharCode(0x2009)); /* Use this last so all spaces converted */
		return string;
	}
  	function getFontChoiceList() {
		/*	v180723 first version
			v180828 Changed order of favorites
			v190108 Longer list of favorites
		*/
		systemFonts = getFontList();
		IJFonts = newArray("SansSerif", "Serif", "Monospaced");
		fontNameChoice = Array.concat(IJFonts,systemFonts);
		faveFontList = newArray("Your favorite fonts here", "Open Sans ExtraBold", "Fira Sans ExtraBold", "Noto Sans Black", "Arial Black", "Montserrat Black", "Lato Black", "Roboto Black", "Merriweather Black", "Alegreya Black", "Tahoma Bold", "Calibri Bold", "Helvetica", "SansSerif", "Calibri", "Roboto", "Tahoma", "Times New Roman Bold", "Times Bold", "Serif");
		faveFontListCheck = newArray(faveFontList.length);
		counter = 0;
		for (i=0; i<faveFontList.length; i++) {
			for (j=0; j<fontNameChoice.length; j++) {
				if (faveFontList[i] == fontNameChoice[j]) {
					faveFontListCheck[counter] = faveFontList[i];
					counter +=1;
					j = fontNameChoice.length;
				}
			}
		}
		faveFontListCheck = Array.trim(faveFontListCheck, counter);
		fontNameChoice = Array.concat(faveFontListCheck,fontNameChoice);
		return fontNameChoice;
	}
	function getSelectionFromMask(selection_Mask){
		batchMode = is("Batch Mode"); /* Store batch status mode before toggling */
		if (!batchMode) setBatchMode(true); /* Toggle batch mode off */
		tempTitle = getTitle();
		selectWindow(selection_Mask);
		run("Create Selection"); /* Selection inverted perhaps because the mask has an inverted LUT? */
		run("Make Inverse");
		selectWindow(tempTitle);
		run("Restore Selection");
		if (!batchMode) setBatchMode(false); /* Return to original batch mode setting */
	}
	function indexOfArray(array,string, default) {
		/* v190423 Adds "default" parameter (use -1 for backwards compatibility). Returns only first instance of string */
		index = default;
		for (i=0; i<lengthOf(array); i++){
			if (array[i]==string) {
				index = i;
				i = lengthOf(array);
			}
		}
		return index;
	}
	function removeTrailingZerosAndPeriod(string) {
	/* Removes any trailing zeros after a period
	v210430 totally new version: Note: Requires remTZeroP function
	Nested string functions require "" prefix
	*/
		lIP = lastIndexOf(string, ".");
		if (lIP>=0) {
			lIP = lengthOf(string) - lIP;
			string = "" + remTZeroP(string,lIP);
		}
		return string;
	}
	function remTZeroP(string,iterations){
		for (i=0; i<iterations; i++){
			if (endsWith(string,"0"))
				string = substring(string,0,lengthOf(string)-1);
			else if (endsWith(string,"."))
				string = substring(string,0,lengthOf(string)-1);
			/* Must be "else if" because we only want one removal per iteration */
		}
		return string;
	}
	function restoreExit(message){ /* Make a clean exit from a macro, restoring previous settings */
		/* 9/9/2017 added Garbage clean up suggested by Luc LaLonde - LBNL */
		restoreSettings(); /* Restore previous settings before exiting */
		setBatchMode("exit & display"); /* Probably not necessary if exiting gracefully but otherwise harmless */
		call("java.lang.System.gc");
		exit(message);
	}
	function stripUnitFromString(string) {
		if (endsWith(string,"\)")) { /* Label with units from string if enclosed by parentheses */
			unitIndexStart = lastIndexOf(string, "\(");
			unitIndexEnd = lastIndexOf(string, "\)");
			stringUnit = substring(string, unitIndexStart+1, unitIndexEnd);
			unitCheck = matches(stringUnit, ".*[0-9].*");
			if (unitCheck==0) {  /* If the "unit" contains a number it probably isn't a unit */
				stringLabel = substring(string, 0, unitIndexStart);
			}
			else stringLabel = string;
		}
		else stringLabel = string;
		return stringLabel;
	}
	function unCleanLabel(string) {
	/* v161104 This function replaces special characters with standard characters for file system compatible filenames.
	+ 041117b to remove spaces as well.
	+ v220126 added getInfo("micrometer.abbreviation").
	+ v220128 add loops that allow removal of multiple duplication.
	+ v220131 fixed so that suffix cleanup works even if extensions are included.
	*/
		/* Remove bad characters */
		string= replace(string, fromCharCode(178), "\\^2"); /* superscript 2 */
		string= replace(string, fromCharCode(179), "\\^3"); /* superscript 3 UTF-16 (decimal) */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(185), "\\^-1"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(0xFE63) + fromCharCode(178), "\\^-2"); /* Small hyphen substituted for superscript minus as 0x207B does not display in table */
		string= replace(string, fromCharCode(181), "u"); /* micron units */
		string= replace(string, getInfo("micrometer.abbreviation"), "um"); /* micron units */
		string= replace(string, fromCharCode(197), "Angstrom"); /* �ngstr�m unit symbol */
		string= replace(string, fromCharCode(0x2009) + fromCharCode(0x00B0), "deg"); /* replace thin spaces degrees combination */
		string= replace(string, fromCharCode(0x2009), "_"); /* Replace thin spaces  */
		string= replace(string, "%", "pc"); /* % causes issues with html listing */
		string= replace(string, " ", "_"); /* Replace spaces - these can be a problem with image combination */
		/* Remove duplicate strings */
		unwantedDupes = newArray("8bit","lzw");
		for (i=0; i<lengthOf(unwantedDupes); i++){
			iLast = lastIndexOf(string,unwantedDupes[i]);
			iFirst = indexOf(string,unwantedDupes[i]);
			if (iFirst!=iLast) {
				string = substring(string,0,iFirst) + substring(string,iFirst + lengthOf(unwantedDupes[i]));
				i=-1; /* check again */
			}
		}
		unwantedDbls = newArray("_-","-_","__","--","\\+\\+");
		for (i=0; i<lengthOf(unwantedDbls); i++){
			iFirst = indexOf(string,unwantedDbls[i]);
			if (iFirst>=0) {
				string = substring(string,0,iFirst) + substring(string,iFirst + lengthOf(unwantedDbls[i])/2);
				i=-1; /* check again */
			}
		}
		string= replace(string, "_\\+", "\\+"); /* Clean up autofilenames */
		/* cleanup suffixes */
		unwantedSuffixes = newArray(" ","_","-","\\+"); /* things you don't wasn't to end a filename with */
		extStart = lastIndexOf(string,".");
		sL = lengthOf(string);
		if (sL-extStart<=4) extIncl = true;
		else extIncl = false;
		if (extIncl){
			preString = substring(string,0,extStart);
			extString = substring(string,extStart);
		}
		else {
			preString = string;
			extString = "";
		}
		for (i=0; i<lengthOf(unwantedSuffixes); i++){
			sL = lengthOf(preString);
			if (endsWith(preString,unwantedSuffixes[i])) { 
				preString = substring(preString,0,sL-lengthOf(unwantedSuffixes[i])); /* cleanup previous suffix */
				i=-1; /* check one more time */
			}
		}
		if (!endsWith(preString,"_lzw") && !endsWith(preString,"_lzw.")) preString = replace(preString, "_lzw", ""); /* Only want to keep this if it is at the end */
		string = preString + extString;
		/* End of suffix cleanup */
		return string;
	}
	function unitLabelFromString(string, imageUnit) {
	/* v180404 added Feret_MinDAngle_Offset
		v210823 REQUIRES ASC function indexOfArray(array,string,default) for expanded "unitless" array
		*/
		if (endsWith(string,"\)")) { /* Label with units from string if enclosed by parentheses */
			unitIndexStart = lastIndexOf(string, "\(");
			unitIndexEnd = lastIndexOf(string, "\)");
			stringUnit = substring(string, unitIndexStart+1, unitIndexEnd);
			unitCheck = matches(stringUnit, ".*[0-9].*");
			if (unitCheck==0) {  /* If the "unit" contains a number it probably isn't a unit */
				unitLabel = stringUnit;
			}
			else {
				unitLabel = "";
			}
		}
		else {
			unitLess = newArray("Circ.","Slice","AR","Round","Solidity","Image_Name","PixelAR","ROI_name","ObjectN","AR_Box","AR_Feret","Rnd_Feret","Compact_Feret","Elongation","Thinnes_Ratio","Squarity_AP","Squarity_AF","Squarity_Ff","Convexity","Rndnss_cAR","Fbr_Snk_Crl","Fbr_Rss2_Crl","AR_Fbr_Snk","Extent","HSF","HSFR","Hexagonality");
			angleUnits = newArray("Angle","FeretAngle","Cir_to_El_Tilt","Angle_0-90�","Angle_0-90","FeretAngle0to90","Feret_MinDAngle_Offset","MinDistAngle");
			chooseUnits = newArray("Mean" ,"StdDev" ,"Mode" ,"Min" ,"Max" ,"IntDen" ,"Median" ,"RawIntDen" ,"Slice");
			if (string=="Area") unitLabel = imageUnit + fromCharCode(178);
			else if (indexOfArray(unitLess,string,-1)>=0) unitLabel = "None";
			else if (indexOfArray(chooseUnits,string,-1)>=0) unitLabel = "";
			else if (indexOfArray(angleUnits,string,-1)>=0) unitLabel = fromCharCode(0x00B0);
			else if (string=="%Area") unitLabel = "%";
			else unitLabel = imageUnit;
		}
		return unitLabel;
	}