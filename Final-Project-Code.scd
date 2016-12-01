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
	for(1, numNotes-1, {arg i; out = out.add(nextNote.(out[i-1]))});

	out;
};

~drumRule = Dictionary.new(8);

/*
* Generate the dictionary representing a cellular automata rule based on the number
*/
~generateDrumRule = { arg num;
	~drumRule = Dictionary.new(8);
	~drumRule.put('[1,1,1]', floor(num/(2**7)) % 2);
	~drumRule.put('[1,1,0]', floor(num/(2**6)) % 2);
	~drumRule.put('[1,0,1]', floor(num/(2**5)) % 2);
	~drumRule.put('[1,0,0]', floor(num/(2**4)) % 2);
	~drumRule.put('[0,1,1]', floor(num/(2**3)) % 2);
	~drumRule.put('[0,1,0]', floor(num/(2**2)) % 2);
	~drumRule.put('[0,0,1]', floor(num/(2**1)) % 2);
	~drumRule.put('[0,0,0]', floor(num/(2**0)) % 2);
	~drumRule;
};