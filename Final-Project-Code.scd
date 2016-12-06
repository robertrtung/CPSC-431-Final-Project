~melodyDict = Dictionary.new();
~motifCount = 1;

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
* Function to initialize and return an array of zeros for each measure in existence, to be used as an array of flags
* Takes in an array size
*/
~getZeroFlagArray = { arg arrSize;
	var outArray = List.new(3);
	arrSize.do({outArray.add(0)});
	outArray;
};

// Test the function above
~getZeroFlagArray.value(6).postln;

/*
* Function to find the dividing measures for two repeat sections
* returns a list of new section dividers in the format:
* [measureIndex, ]
*/
~getRepeatedSectionDividers = { arg notesArr, measureIndex, repeatMeasureIndex;
	var currentIndex = measureIndex + 1;
	var currentRepeatIndex = repeatMeasureIndex + 1;
	var newDividers = List[];
	var breakFlag = 0;

	// Make sure we don't run into the repeat section and don't run off the end of the array
	while ({(currentIndex < repeatMeasureIndex) && (currentRepeatIndex < notesArr.size) &&
		(breakFlag == 0)},
		{if (notesArr[currentIndex] == notesArr[currentRepeatIndex],
			// Measures still match, so continue
			{currentIndex++; currentRepeatIndex++;}
			// Else, break because the measures don't match anymore
			{breakFlag = 1;});
		}
	);
	newDividers = [measureIndex, currentIndex, repeatMeasureIndex, currentRepeatIndex];
};


/*
* Function to find any sequence of repeats in the song to break up the song into sections
* takes in a list of lists of notes grouped by measure
* returns a list of [start1, end1, start2, end2, etc...] values to indicate repeated sections
* the bounds of the repeated section looks like: [start1, end1] <- inclusive on both sides
*/
~getRepeats = { arg notesArr;
	var out = List[];
	var dividers = List[0];
	var measureIndex = 0;
	var dividersToAdd;

	// Go through notes and find any sequences that are equal
	while ( {measureIndex < notesArr.size}, // for each measure
		// Go through all measures following the current one to see if any match
		{ for (measureIndex + 1, notesArr.size - 1, { |i|
			if (notesArr[measureIndex] == notesArr[i],
				// Found a match so get the dividers
				dividersToAdd = ~getRepeatedSectionDividers.value(notesArr, measureIndex, i);
				// Move to the end of the repeated section
				measureIndex = notesArr[1];
				dividersToAdd.do{ |elt| }

				{ if (!dividers.includes(measureIndex), {dividers.add(measureIndex)});
					if (!dividers.includes(i), {dividers.add(i)});
					measureCount

				}
				dividers.add(measureIndex)
		)
	out;
}




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
* Given a set of notes representing a motif, generate a new motif through Markhov models
*/
~markhovMotif = { arg notes;
	var dict = Dictionary.new(notes.size); // Markhov model dictionary
	var out = Array.new(notes.size); // New notes to be output

	// Only calculate nonempty output if notes is nonempty
	if(notes.size > 0, {
		// Build the dictionary
		for(0,notes.size-2, { arg i;
			if(dict.at(notes[i]) == Nil, {
				// Note not yet a key in dictionary
				dict.put(notes[i], [notes[i+1]]);
			}, {
				// Note already in dictionary
				dict.put(notes[i], dict.at(notes[i]) ++ [notes[i+1]]);
			});
		});

		// Initialize first note of output
		out.put(notes[0]);

		// Each note generated from the Markhov chain of the previous note
		for(1, numNotes-1, {arg i; out = out.add(dict.at(out[i-1]).choose)});
	});

	out;
};

///////////// The following is a possible simple way to generate harmony notes above the track
// It requires scale degrees instead of just notes

// Seed for chord randomizer which is also random.
var chordRandSeed = rrand(0,5) / 10;

/*
* Generates the string of notes at the scale degree 'above' above the base, with a random chance of not including each note and including a rest instead.
Will be used to write the lines with the other chordal notes in each melody.
* Source: Robert Tung Midterm Project
*/
var chordRandomizer = {arg degrees, above, randSeed;
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
