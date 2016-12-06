(
~melodyDict = Dictionary.new();
~motifCount = 1;
~flagArray;
~motifDict = Dictionary.new();
~testArray = [[1, 2], [3, 1], [4, 5], [0], [1, 2], [3, 1], [4, 5]];

/*
* Generate the dictionary used for Markhov models on a set of notes
*/
~generateMelodyDict = { arg notes;
	var temp;
	~melodyDict = Dictionary.new(notes.size);
	for(0, notes.size-2, {arg i;
		if(~melodyDict.at(notes[i]) == Nil, {
			~melodyDict.put(notes[i], [notes[i+1]]);
		}, {
			temp = ~melodyDict.at(notes[i]);
			temp = temp ++ [notes[i+1]];
			~melodyDict.put(notes[i], temp);
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
~getZeroFlagArray.value(6);

// Check that the measures following the matched ones are not yet marked
// Also check that they all match the measure following currentIndex
~checkNextMeasures = { arg currentIndex, measuresArr, matches;
	var bool = true;
	matches.do({|measureIndex|
		if ((measureIndex + 1) >= measuresArr.size,
			// We can't continue because we've run off of the end of the array
			{bool = false},
			{measuresArr[measureIndex + 1];
				measuresArr[currentIndex + 1];

				if ((~flagArray[measureIndex + 1] != 0) ||
				(measuresArr[measureIndex + 1] != measuresArr[currentIndex + 1]),
				// We can't continue because the next measure is marked as non-zero
				// or the next measure doesn't match the one at currentIndex + 1
				{measuresArr[measureIndex + 1];
				measuresArr[currentIndex + 1];
						bool = false;}
			);}
		);
	});
	bool;
};

// Increase every element of the matches array
~incrementMatches = { arg matches;
	matches.size.do({ arg index;
		matches[index] = matches[index] + 1;
	});
	matches;
};

/*
* Function to find the dividing measures for many repeat sections
* takes in the array of measures, the index of the first repeated measure, and an array of matches to that measure
* returns a list of new section dividers
*/
~getRepeatSectionDividers = { arg measuresArr, measureIndex, rawMatches;
	var currentIndex = measureIndex;
	var matches = List.copyInstance(rawMatches);
	var newDividers = List[];

	// Set the flags for the motif
	~flagArray[measureIndex] = ~motifCount;
	matches.do({|measIndex| ~flagArray[measIndex] = ~motifCount;});

	// Make sure we don't run into a marked section and don't run off the end of the array
	while ({(~flagArray[currentIndex + 1] == 0) &&
		(~checkNextMeasures.value(currentIndex, measuresArr, matches) == true)},
		// Increment the currentIndex as well as the matches indicies because
		// we know they're safe
		{currentIndex = (currentIndex + 1);
		matches = ~incrementMatches.value(matches);

		// Set the flags for the motif
		~flagArray[currentIndex] = ~motifCount;
		matches.do({|currIndex| ~flagArray[currIndex] = ~motifCount;});
	});

	newDividers = (rawMatches ++ (matches + 1)).add(measureIndex).add(currentIndex + 1);
	newDividers;
};

// Testing code
/*~flagArray = ~getZeroFlagArray.value(~testArray.size);
~getRepeatSectionDividers.value(~testArray, 0, List[3]);
~flagArray;*/


/*
* Function to find any sequence of repeats in the song to break up the song into sections
* takes in a list of lists of notes grouped by measure
* returns a list of section dividers
*/
~getRepeatsDividers = { arg measuresArr;
	var dividers = List[0];
	var measureIndex = 0;
	var matches = List[];
	var dividersToAdd;
	var motifStart;
	var motifEnd;
	~flagArray = ~getZeroFlagArray.value(measuresArr.size);

	// Go through notes and find any sequences that are equal
	while ( {measureIndex < measuresArr.size}, // for each measure

		// Go through all measures following the current one to see if any match
		{ for (measureIndex + 1, measuresArr.size - 1, { |i|
			if ((measuresArr[measureIndex] == measuresArr[i]) &&
				(~flagArray[measureIndex] == 0) && (~flagArray[i] == 0 ),
				// Found a match so add to the matches list
				{matches.add(i)}
			);
		});

		// Get the dividers for the sections
		dividersToAdd = ~getRepeatSectionDividers.value(measuresArr, measureIndex,
			matches);
		motifStart = dividersToAdd[dividersToAdd.size - 2];
		motifEnd = dividersToAdd[dividersToAdd.size - 1]; // equivalent to the start of the next section

		// Add the motif to the motif dictionary and increment the motif count
		// The bounds of the motif are [motifStart, motifEnd)
		~motifDict.put(~motifCount, [motifStart, motifEnd]);
		~motifCount = ~motifCount + 1;

		// Add any dividers that have not yet been added
		dividersToAdd.do({ arg divider;
			if ((dividers.includes(divider) == false) && (divider < measuresArr.size),
				{dividers.add(divider)});
		});

		// Move to the end of the repeated section
		measureIndex = motifEnd.postln;
		}
	);

	dividers.sort;
};

~getRepeatsDividers.value(~testArray).postln;
~flagArray;
)

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
