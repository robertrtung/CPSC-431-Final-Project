(
(
//  CHOOSE THE FILE TO READ \\
~fileNameArray = ["mario_theme.xml", "traumerei.xml", "marry_you.xml"];
~fileName = ~fileNameArray[0];

// ~globalOutputArray is the array you will use. it has MIDI note and duration

// the index in that array indicates the measure number

// ex. ~globalOutputArray[0] = measure 1, ~globalOutputArray[1] = measure 2, etc...

// each index contains [voice#, midi_note#, note_length]
//   in the correct order that they appear in that measure

// this is good for monophonic instruments, but you can have several of them.

// it works for sharps, flats, and dotted rhythms as well
~analyze = {
	var rest, pitch, dot, instrument_ID, measure_number, midiNote, duration;

	~globalOutputArray = List[];

	// - - - - - - - - - SORTING FUNCTION - - - - - - - - - \\
	~findMinMax = {arg list, pos;
		var max;
		var min;
		i = 0;

		while ({i < list.size},{
			a = list[i][pos];
			if (max == nil, {
				max = a;
				min = a;
			},{
				if (a > max, { max = a });
				if (a < min, { min = a });
			});
			i = i + 1;
		});
		[min, max];
	};

	~sortFunc = {arg list;
		var numVoices, found, measureNumber, tempList, tempListSort, sortedByMeasure;
		sortedByMeasure = List[];
		numVoices = ~findMinMax.value(list, 1)[1];
		found = true;
		measureNumber = 1;

		while ({found},{
			found = false;
			i = 0;
			tempList = List[];
			tempListSort = List[];

			while ({i < list.size},{
				if (measureNumber == list[i][0], {
					tempList.add(list[i]);
					found = true;
				},{});
				i = i + 1;
			});

			i = 1;
			while ({i <= numVoices},{
				j = 0;
				while ({j < tempList.size},{
					if (i == tempList[j][1], {
						a = [tempList[j][1], tempList[j][2], tempList[j][3]];
						tempListSort.add(a);
					},{});
					j = j + 1;
				});
				i = i + 1;
			});
			sortedByMeasure.add(tempListSort.asArray);
			measureNumber = measureNumber + 1;
		});
		sortedByMeasure = sortedByMeasure.asArray;
	};


	// - - - - - - - - - - GET PITCH FUNCTION - - - - - - - - - - \\
	~getPitchFunction = {arg i;
		var betweenPitchTags, accidental, step, octave;
		betweenPitchTags = ~betweenTags.value(~pitchTags, ~noteTagsArray[i], 0)[1].asString;

		step = ~betweenTags.value(~stepTags, betweenPitchTags, 0)[1].asString;
		octave = ~betweenTags.value(~octaveTags, betweenPitchTags, 0)[1].asString;

		// accidental
		if (betweenPitchTags.find(~alterTags[0]) != nil, {
			accidental = ~betweenTags.value(~alterTags, betweenPitchTags, 0)[1].asInteger;
		},{
			accidental = 0;
		});
		~getMIDI.value(step++octave) + accidental;
	};


	~noteValue = {arg string;
		var length;
		case
		{string == "whole"}{length = 4}
		{string == "half"}{length = 2}
		{string == "quarter"}{length = 1}
		{"NEED TO ADD A NEW VARIABLE"};
	};

	~getMIDI = { arg noteStr; // Input letter and octave number from 0-9
		var len = noteStr.size; // Number of characters in the string
		var octave = noteStr.separate[(len - 1)].asInt;
		var midiNote = 12 + (12 * octave);
		var noteName = noteStr.separate[0].toUpper;


		if (len != 2,
			{},
			{
				case
				{noteName == "C"} {}
				{noteName == "D"} {midiNote = midiNote + 2}
				{noteName == "E"} {midiNote = midiNote + 4}
				{noteName == "F"} {midiNote = midiNote + 5}
				{noteName == "G"} {midiNote = midiNote + 7}
				{noteName == "A"} {midiNote = midiNote + 9}
				{noteName == "B"} {midiNote = midiNote + 11}
				{false};
			};
		);

		midiNote; // Return the MIDI value
	};

	~makeLongStringFromXML = { arg xml_fileName; //string, "~/path/filename"
		var bigList, bigString, littleString;

		// "true" arguments gets rid of excess spaces before tags
		bigList = FileReader.read( xml_fileName.standardizePath, true, true);

		// go from original format to long string with no brackets.
		bigString = "";
		n = 0;

		while ({n < bigList.size }, {
			a = bigList[n].asString;
			b = 2;
			littleString = "";

			while ({b < (a.size - 2)}, {
				littleString = littleString ++ a.at(b);
				b =  b + 1;
			});

			bigString = bigString + littleString;
			n = n + 1;
		});
		bigString; // number of total characters in the string
	};

	// > > > > > INSERT .XML FILE HERE < < < < < \\
	//                     "~/path/fileName"                       \\
	~longString = ~makeLongStringFromXML.value(
		("~/Desktop/CPSC-431-Final-Project/"++~fileName));
	//    > > > > > > > > ><  < < < < < < < < <   \\


	// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \\
	//   - - - - Find Everything Between Open and Close Tags - - - -   \\
	// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \\

	~betweenTags = {arg tagArray, stringToSearch, offset; // [str, str], str, int

		var
		o_Tag, o_Tag_start, o_Tag_size, o_Tag_end,
		c_Tag, c_Tag_start, tagType,
		string, char, arguments, arg_size;

		o_Tag = tagArray[0];
		c_Tag = tagArray[1];

		// tagType = 0 if there is an opening and closing tag
		// tagType = 1 if there is just one tag with an argument
		if (c_Tag != "/>", {tagType = 0},{tagType = 1});

		// check to see if an opening tag can be found
		o_Tag_start = stringToSearch.find(o_Tag, offset: offset);

		if (o_Tag_start != nil, {
			c_Tag_start = stringToSearch.find(c_Tag, offset: o_Tag_start);
			o_Tag_size = o_Tag.size + o_Tag_start;
			if (tagType == 0, {
				o_Tag_end = stringToSearch.find(">", offset: o_Tag_start);
				arg_size = o_Tag_end - o_Tag_size;
			},{
				o_Tag_end = o_Tag_size;
				arg_size = o_Tag_end - c_Tag_start;
			});

			// get the arguments within the opening tag
			if (arg_size > 0, {
				o_Tag_size = o_Tag_size + 1;
				while ({ o_Tag_size <  o_Tag_end},{
					char = stringToSearch.at(o_Tag_size);
					if (char.asString != ",", {arguments = arguments ++ char;},{});

					o_Tag_size = o_Tag_size + 1;
				});
			},{
				arguments = nil;
			});

			string = "";
			// get the data contained between the tags
			o_Tag_end = o_Tag_end + 1;
			while ({o_Tag_end < c_Tag_start},{
				// get the next character
				char = stringToSearch.at(o_Tag_end);
				// if its not a comma, add it to the string
				if (char.asString != ",", {string = string ++ char;},{});

				o_Tag_end = o_Tag_end + 1;
			});

			o_Tag = o_Tag ++ ">";
		},{o_Tag = nil});

		[c_Tag_start, string, arguments];
	};


	// * * * * * TAGS TO SEARCH FOR * * * * * \\
	~pitchTags = ["<pitch", "</pitch"];
	~restTags = ["<rest", "<instrument"];
	~noteTags = ["<note", "</note"];
	~stepTags = ["<step", "</step"];
	~octaveTags = ["<octave", "</octave"];
	~durationTags = ["<duration", "</duration"];
	~alterTags = ["<alter", "</alter"];
	~measureTags = ["<measure", "</measure"];
	~measureNumberTags = ["<measureNumber", "/>"];
	~instrument_idTags = ["<instrument id", "/>"];

	// - - - - - - - - - - - - - - - - - - - - - - \\

	~measureTagsArray = List[]; // array of all strings contained within each measure tag
	~noteTagsArray = List[]; // array of all strings contained within each note tag


	// function to get the argument "number=" from the measure tag
	~getMeasureArgs = {arg string;
		j =  string.find("number=") + 7;
		c = ("\"0123456789 ".contains(string.at(j)));
		d = ""; // d = temporary string

		while ({c},{
			c = ("\"0123456789 ".contains(string.at(j)));
			if (c, {d = d ++ string.at(j)});
			j = j + 1;
		});

		e = ""; // e = temporary string
		j = 0;
		while ({j < d.size},{
			c = ("0123456789".contains(d.at(j)));
			if (c, {e = e ++ d.at(j)});
			j = j + 1;
		});
		e;
	};

	// make an array of each measure tag
	// [ [measure_#, data_between_tags], etc... ]
	i = 0;
	while ({i != nil},{
		a = ~betweenTags.value(~measureTags, ~longString, i);
		if (a[1] != nil, {
			b = ~getMeasureArgs.value(a[2].asString);
			~measureTagsArray.add([b, a[1]])},{});
		i = a[0];
	});
	//("size of ~measureTagsArray: " + ~measureTagsArray.size + "\n").postln;


	// input the measureNumberTags and measure number in each group of noteTags
	// - - - - - - - - - - - - - - - - - - - - - - - - \\
	j = 0;
	while ({j < ~measureTagsArray.size},{
		d = ( ~measureNumberTags[0] +
			~measureTagsArray[j][0] +
			~measureNumberTags[1] );
		e = ~measureTagsArray[j][1];
		i = 0;
		while ({i != nil},{
			a = ~betweenTags.value(~noteTags, e, i);
			if (a[1] != nil, {
				~noteTagsArray.add((d ++ a[1]));
			},{});
			i = a[0];
		});
		j = j + 1;
	});
	//("size of ~noteTagsArray:" + ~noteTagsArray.size + "\n").postln;


	// - - - - - - - - - - - - evaluate each string noteTagsArray - - - - - - - - - - - - \\
	~dataList = List[];
	i = 0;
	while ( { i < ~noteTagsArray.size }, {
		// rest
		if (~noteTagsArray[i].find("<rest />") != nil, {rest = 1},{rest = 0});

		// pitch
		if (~noteTagsArray[i].find("<pitch") != nil, {pitch = 1},{pitch = 0});

		// dot
		if (~noteTagsArray[i].find("<dot, />") != nil, {dot = 1.5},{dot = 1});

		if ((pitch == 0 && rest == 0), {},{ // for the few times the both came up nil
			// midiNote
			if (rest == 1, {
				midiNote = 0;
			},{});
			if (pitch == 1, {
				midiNote = ~getPitchFunction.value(i);
			},{});

			duration = ~betweenTags.value(~durationTags, ~noteTagsArray[i], 0)[1].asSymbol.asInteger;
			duration = (duration / 256)*dot;

			instrument_ID = ~betweenTags.value(~instrument_idTags, ~noteTagsArray[i], 0)[1];
			instrument_ID = instrument_ID.at(2).asSymbol.asInteger;

			measure_number = ~betweenTags.value(~measureNumberTags, ~noteTagsArray[i], 0)[1].asInteger;

			~dataList.add([measure_number, instrument_ID, midiNote, duration]);

		});

		i = i + 1;

	});

	// - - - - - send the data to the sort function - - - - - \\
	// this function will group the data by measure number \\
	~globalOutputArray= ~sortFunc.value(~dataList.asArray);


	// - - - - - DISPLAY DATA IN POST WINDOW - - - - - \\
	i = 0;
	while ({i < (~globalOutputArray.size - 1)}, {
		("Measure:" + i).postln;
		~globalOutputArray[i].postcs;
		"".postln;
		i = i + 1;
	});
};

/*
* GUI code adapted from that of Group D Project 1.
*/
w = Window.new("Group Mare Tranquillitatis GUI", Rect(200,200,400,150));
b = Button.new(w,Rect(150,80,150,30)).states_([["Analyze and Play"]]);

p = PopUpMenu(w, Rect(150, 30, 200, 20));
p.items = [
	"Choose which file", "Mario Theme", "Traumerei", "Marry You"
];

b.action = {
	~fileName = ~fileNameArray[p.value-1];
	~fileName.postln;
	~analyze.value;
};

StaticText.new(w,Rect(50,30,60,20)).string_("File:  ");

w.front;
)

///////////////////////////////////////

(
~melodyDict = Dictionary.new();

/*
* Generate the dictionary used for Markhov models on a set of notes
*/
~generateMelodyDict = { arg notes;
	var temp;
	~melodyDict = Dictionary.new(notes.size);
	for(0, notes.size-2, {arg i;
		if(~melodyDict.at(notes[i]) == Nil, {
			~melodyDist.put(notes[i], [notes[i+1]]);
		}, {
			temp = ~melodyDist.at(notes[i]);
			temp = temp ++ [notes[i+1]];
			~melodyDist.put(notes[i], temp);
		});
	});
};

/*
* Function nextNote takes in the last note and chooses the next note based on Markov probabilities based on
* the given Frere Jacques segment
*/
~nextNote = { arg note;
	~melodyDict.at(note).choose;
};

/*
* Function generateNotes takes in the starting note for the measure and the number of notes in the measure;
* returns a measure of notes in an array
*  Source: Group B (our own group) project 1 source code
*/
~generateNotes = { arg startingNote, numNotes;
	// Output
	var out = Array.new(numNotes);
	out.add(startingNote);

	// Each note generated from the Markhov chain of the previous note
	for(1, numNotes-1, {arg i; out = out.add(~nextNote.(out[i-1]))});

	out;
};

/*
* Generate the dictionary representing a cellular automata rule based on the number
*/
~generateDrumRule = { arg num;
	var drumRule;
	drumRule = ('[ 1, 1, 1 ]': floor(num/(2**7)) % 2, '[ 1, 1, 0 ]': floor(num/(2**6)) % 2, '[ 1, 0, 1 ]': floor(num/(2**5)) % 2, '[ 1, 0, 0 ]': floor(num/(2**4)) % 2, '[ 0, 1, 1 ]': floor(num/(2**3)) % 2, '[ 0, 1, 0 ]': floor(num/(2**2)) % 2, '[ 0, 0, 1 ]': floor(num/(2**1)) % 2, '[ 0, 0, 0 ]': floor(num/(2**0)) % 2);
	drumRule;
};

/*
* Generate the array that represents the visual representation of a cellular automaton.
* Source: Our own group's second group project. (but modified slightly)
*/
~cellularAutomataArray = {arg size, rules;
	var arr = Array.fill(size, {Array.fill(size, {0})}); // create an array full of 0s
	arr[0].put(size / 2, 1);
	rules.postln;
	rules.at('[,1,1]'.asSymbol).postln;

	// Code in the loop below taken from Professor Petersen's notes
	arr.do {|row, index|
		// stop before last row
		if ( index <= (size - 2) ) // index = system index
		{ row.size.do {|rIndex| // for each row
			rIndex = rIndex + 1;  // row index
			if (rIndex <= (row.size -2)) // stop before the last member of the row
			{
				var array = [row[rIndex - 1], row[rIndex], row[rIndex + 1]]; // create an array of nearest neighbor
				rules.at(array.asSymbol);

				// add a 0 or 1 to the cell index of the next row by looking the array up in the rules
				arr.at(index + 1).put(rIndex, rules.at(array.asSymbol))

			}
		}
		}
	};
	arr;
};

/*
* Get a column of the cellular automaton array that is used for drums.
* Source: Our own group's second group project.
*/
~getDrumColumn = { arg col, drumSize, drumRules;
	var drumArray, outArr;

	// Get the Cellular Automaton array itself
	drumArray = ~cellularAutomataArray.(drumSize, drumRules);

	outArr = Array.new(drumArray.size);

	// Build up the output column
	for(1,drumArray.size, {arg i;
		outArr = outArr.add(drumArray[i-1][col]);
	});

	// Return
	outArr;
};

/*
* Find the cellular automata rule whose middle column, interpreted as drum beats, most closely resembles the input
*/
~findClosestDrumRule = { arg drums;
	var minDiff = drums.size + 1; // minimum difference between drums and rule found so far
	var minRule = 1; // closest rule to output

	// loop through rules and find the closest rule
	for(1,255, {arg i;
		if((drums-~getDrumColumn.(drums.size / 2, drums.size, ~generateDrumRule.(i))).sum < minDiff, {
			minRule = i;
		});
	});
	minRule;
};

///////////// The following is to be used after Kat's code to isolate motifs

/*
* Generate random durations to fit a certain number of beats, given an input set of durations
*/
~durationGenerate = { arg durs;
	var dict = Dictionary.new(durs.size); // Markhov model dictionary

	var totalCounts = durs.sum;
	var out = Array.new(totalCounts); // New durations to be output
	var next;
	var break = 0;
	var count = 0;

	// Only calculate nonempty output if durs is nonempty
	if(durs.size > 0, {
		// Build the dictionary
		for(0,durs.size-2, { arg i;
			if(dict.at(durs[i]) == nil, {
				// Duration not yet a key in dictionary
				dict.put(durs[i], [durs[i+1]]);
			}, {
				// Duration already in dictionary
				dict.put(durs[i], dict.at(durs[i]) ++ [durs[i+1]]);
			});
		});

		// Initialize first duration of output
		out = out.add(durs[0]);

		// Each duration generated from the Markhov chain of the previous note
		while({totalCounts > 0 && break == 0 && count < 40}, {
			count = count +1;
			if(dict.at(out[out.size-1]) == nil, {
				if(totalCounts < durs.sort[0], {
					break = 1;
				});
			});
			if(dict.at(out[out.size-1]) != nil, {
				if(totalCounts < dict.at(out[out.size-1]).sort[0], {
					break = 1;
				});
			});
			if(break == 0, {
				// If the last duration was unique, it will not be in the dictionary, so we need to randomly give a note
				if(dict.at(out[out.size-1]) == nil, {
					next = durs.choose;
				}, {
					next = dict.at(out[out.size-1]).choose;
				});

				// Add values as long as we do not surpass the total number of counts
				if(next < totalCounts, {
					out = out.add(next);
					totalCounts = totalCounts - next;
				});
			});
		});

		if(totalCounts > 0, {
			out = out.add(totalCounts);
		});
	});

	out;
};

/*
* Takes an array of durations and just gives the beat numbers.
*/
~durToBeat = {arg durs, bpm;
	var soFar = 0;
	var out = Array.new(durs.size);
	for(0,durs.size-1, {arg i;
		soFar = soFar + durs[i];
		soFar = soFar % bpm;
		out = out.add(soFar);
	});
	out;
};

/*
* Given a set of notes representing a motif, generate a new motif through Markhov models
*/
~markhovMotif = { arg notes, numNotes;
	var dict = Dictionary.new(notes.size); // Markhov model dictionary
	var out = Array.new(numNotes); // New notes to be output

	// Only calculate nonempty output if notes is nonempty
	if(notes.size > 0, {
		// Build the dictionary
		for(0,notes.size-2, { arg i;
			if(dict.at(notes[i]) == nil, {
				// Note not yet a key in dictionary
				dict.put(notes[i], [notes[i+1]]);
			}, {
				// Note already in dictionary
				dict.put(notes[i], dict.at(notes[i]) ++ [notes[i+1]]);
			});
		});

		// Initialize first note of output
		out = out.add(notes[0]);

		// Each note generated from the Markhov chain of the previous note
		for(1, numNotes-1, {arg i;
			// If the last duration was unique, it will not be in the dictionary, so we need to randomly give a note
			if(dict.at(out[i-1]) == nil, {
				out = out.add(notes.choose)
			}, {
				out = out.add(dict.at(out[i-1]).choose);
			});
		});
	});

	out;
};

// ~markhovMotif.([1,2,1,1,3,1,2,5,1,4], 10).postln;

///////////// The following is a possible simple way to generate harmony notes above the track
// It requires scale degrees instead of just notes

// Seed for chord randomizer which is also random.
~chordRandSeed = rrand(0,5) / 10;

/*
* Generates the string of notes at the scale degree 'above' above the base, with a random chance of not including each note and including a rest instead.
Will be used to write the lines with the other chordal notes in each melody.
* Source: Robert Tung Midterm Project
*/
~chordRandomizer = {arg degrees, above, randSeed;
	var chordNotes = Array.new(degrees.size);
	var randomVal = 0;

	for(0, degrees.size - 1, {arg i;
		randomVal = [0,1].wchoose([randSeed,1 - randSeed]); // Random chance of including note.
		if(randomVal == 0, {
			// Include chord note.
			chordNotes.add((degrees[i] + above));
		}, {
			// Include rest instead.
			chordNotes.add(\rest);
		});
	});
	chordNotes;
};

/*
* Given a melody line and a harmony line, determine what harmony note was playing when this melody note played.
*/
~pullHarmonyNote = {arg melNotes, melDurs, harmNotes, harmDurs, note;
	var dursUntil = 0;
	var found = 0;
	var out;
	var outIndex;
	var currDurs = 0;
	var harmFound = 0;
	for(0, melNotes.size-1, {arg i;
		if(found == 0, {
			if(melNotes[i] == note, {
				found = 1;
			}, {
				dursUntil = dursUntil + melDurs[i];
			});
		});
	});

	dursUntil.postln;

	if(found == 0, {
		out = note - 12;
	}, {
		for(0, harmNotes.size-1, {arg i;
			if(harmFound == 0, {
				currDurs = currDurs + harmDurs[i];
				if(currDurs >= dursUntil, {
					out = harmNotes[i];
					harmFound = 1;
				});
			});
		});
	});

	if(harmFound == 0, {
		out = note - 12;
	});

	out;
};

~pullHarmonyNote.([5,4,3,1,2], [1,2,3,4,5], [1,2,3,4,5], [5,4,3,2,1], 1);

/*
* As a continuation to the above function, pull an entire harmony line from a melody line
*/
~writeHarmonyLine = {arg melNotes, melDurs, harmNotes, harmDurs, newMel;
	out = Array.new(newMel.size);
	for(0,newMel.size-1, {arg i;
		out = out.add(~pullHarmonyNote.(melNodes,melDurs,harmNotes,harmDurs,newMel[i]));
	});
};

/*
* Converts a dictionary of motif notes, a dictionary of motif durations, and an array of motif numbers into an array of notes and durations
Returns as [notes, durations]
*/
~convertToLine = { arg durDict, noteDict, motifs;
	var out = Array.new(2);
	out[0] = [];
	out[1] = [];
	for(0, motifs.size - 1, {
		out[0] = out[0] ++ noteDict.at(motifs[i]);
		out[1] = out[1] ++ durDict.at(motifs[i]);
	});
	out;
};

)
)