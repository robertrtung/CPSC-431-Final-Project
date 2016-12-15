(
// true or false, if you want to see the results of the analysis posted
~displayDataInPostWindow = false;

~trackNumber = 1;
~motifCount = 1;
~flagArray;
~motifDict;
~melodyNotesToPlay;
~melodyRhythmsToPlay;
// For testign purposes only
~testArray = [[1, 2], [3, 1], [4, 5], [1, 2], [3, 1], [0], [0, 1], [0, 2], [0, 3], [1, 5], [1, 2], [3, 1], [4, 5], [1, 5], [1, 10], [4]];
(
//  CHOOSE THE FILE TO READ \\
~fileNameArray = ["xml_mario_theme.xml", "xml_pokemon_theme.xml", "xml_pokemon_battle.xml"];
~fileName = ~fileNameArray[1];

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

};


~tempoArray = List[];
~tempoStringArray = List[];

i = 32;
while ({i <= 240},{
	~tempoArray.add(i);
	a = ""+ i.asString +" BPM";
	~tempoStringArray.add(a);
	i = i + 4;
});


~instrumentArray = [\steel, \bass, \pad, \sine];

~melodyInstrument = ~instrumentArray[0];
~harmonyInstrument = ~instrumentArray[1];


/*
* GUI code adapted from that of Group D Project 1.
*/
~makeGUI = {
	var menu_melSynth, menu_harmSynth, menu_track, menu_version, menu_tempo,
	button_print_preset, button_play, text_choose_synths, text_presets,
	button_preset1, button_preset2, button_preset3, button_preset4,
	param_1m, param_2m, param_3m, param_4m,
	param_1h, param_2h, param_3h, param_4h;

	w = Window.new("Group Mare Tranquillitatis GUI", Rect(200,200,600,400));
	w.view.background_(Color.black);


	// - - - - - - - - - - TEXT - - - - - - - - - - \\

	text_choose_synths = StaticText.new(w,Rect(10,10,380,50));
	text_choose_synths.string_("CHOOSE SYNTHS");
	text_choose_synths.align = \center;
	text_choose_synths.font = Font(size: 40);
	text_choose_synths.background = Color(1, 0, 0, 0.7);


	text_presets = StaticText.new(w,Rect(445,235,110,25));
	text_presets.string_("presets");
	text_presets.align = \center;
	text_presets.font = Font(size: 15);
	text_presets.background = Color(1, 0, 0, 0.7);

	text_presets = StaticText.new(w,Rect(445,260,110,25));
	text_presets.string_(" ");
	text_presets.align = \center;
	text_presets.font = Font(size: 10);
	text_presets.background = Color(1, 0, 0, 0.7);


	// - - - - - - - - - - POP UP MENUS - - - - - - - - - - \\

	menu_melSynth = PopUpMenu(w, Rect(25, 100, 150, 20));
	menu_melSynth.items = [
		"Pick a Melody Synth", "Steel Drum", "Phasor Bass", "Pretty Pad", "Pure Octaves"
	];
	menu_melSynth.background = Color.red;
	menu_melSynth.action = {
		~melodyInstrument = ~instrumentArray[menu_melSynth.value-1];
		~setSynths.value;
	};


	menu_harmSynth = PopUpMenu(w, Rect(225,100, 150, 20));
	menu_harmSynth.items = [
		"Pick a Harmony Synth", "Steel Drum", "Phasor Bass", "Pretty Pad", "Pure Octaves"
	];
	menu_harmSynth.background = Color.red;
	menu_harmSynth.action = {
		~harmonyInstrument = ~instrumentArray[menu_harmSynth.value-1];
		~setSynths.value;
	};

	menu_track = PopUpMenu(w, Rect(425, 100, 150, 20));
	menu_track.items = [
		"Choose which file", "Mario Theme", "Pokemon Theme", "Pokemon Battle"
	];
	menu_track.background = Color.red;
	menu_track.action = {
		~fileName = ~fileNameArray[menu_track.value-1];
		~fileName.postln;
		~analyze.value;
		~afterTrackSelected.value;
	};

    menu_version = PopUpMenu(w, Rect(425, 125, 150, 20));
	menu_version.items = [
		"Choose version", "Original version", "New version"
	];
	menu_version.background = Color.red;
	menu_version.action = {
	};

	menu_tempo = PopUpMenu(w, Rect(450, 200, 100, 20));
	menu_tempo.items = ~tempoStringArray.asArray;
	menu_tempo.background = Color.red;
	menu_tempo.action = {
		~bpm = ~tempoArray[menu_tempo.value];
		(~bpm+"BPM").postln;
		~setSynths.value;
	};


	// - - - - - - - - - - BUTTONS - - - - - - - - - - \\

	button_play = Button.new(w,Rect(425,300,150,70)).states_([["PLAY"]]);
	button_play.font = Font(size: 40);
	button_play.action = {
		if (menu_track.value == 0, {
			"PLEASE SELECT A TRACK".postln;
		},{
			if (menu_version.value == 0, {
				"PLEASE SELECT A VERSION".postln;
			},{
				// Play the new version if selected, else play the old
				if (menu_version.value == 2, {
					~playNewMelody.play;
				},{
					~playOldMelody.play;
					~playHarmony.play;
					~playDrums.play;
				});

			});
		});

	};

	button_print_preset = Button.new(w,Rect(425,375,150,20)).states_([["print preset"]]);
	button_print_preset.font = Font(size: 10);
	button_print_preset.action = {
		~settingsArray.value.postln;
	};

	// - - - PRESET BUTTONS - - - \\\
	button_preset1 = Button.new(w,Rect(450,260,20,20)).states_([["1"]]);
	button_preset1.font = Font(size: 15);
	button_preset1.action = {
		~setSliders.value(~presetsArray[0]);
	};

	button_preset2 = Button.new(w,Rect(475,260,20,20)).states_([["2"]]);
	button_preset2.font = Font(size: 15);
	button_preset2.action = {
		~setSliders.value(~presetsArray[1]);
	};
	button_preset3 = Button.new(w,Rect(500,260,20,20)).states_([["3"]]);
	button_preset3.font = Font(size: 15);
	button_preset3.action = {
		~setSliders.value(~presetsArray[2]);
	};
	button_preset4 = Button.new(w,Rect(525,260,20,20)).states_([["4"]]);
	button_preset4.font = Font(size: 15);
	button_preset4.action = {
		~setSliders.value(~presetsArray[3]);
	};

	// - - - - - - - - - - SLIDERS AND TEXT - - - - - - - - - - \\

	// - - - MELODY PARAMETER 1 - - - \\
	param_1m = Slider(w, Rect(10, 150, 180, 20))
	.action_({
		z = param_1m.value;
		z = z * z;
		~melodyAttack = z;
		~setSynths.value;
		q.string_(" Attack Time (s): "+ z.round(0.001) +" ");
	});
	q = StaticText.new(w,Rect(15,175,170,20));
	q.background = Color(1, 1, 1, 0.5);

	// - - - MELODY PARAMETER 2 - - - \\
	param_2m = Slider(w, Rect(10, 200, 180, 20))
	.action_({
		z = param_2m.value;
		z = z * z;
		~melodyDecay = z;
		~setSynths.value;
		r.string_(" Decay Time (s): "+ z.round(0.001) +" ");
	});
	r = StaticText.new(w,Rect(15,225,170,20));
	r.background = Color(1, 1, 1, 0.5);

	// - - - MELODY PARAMETER 3 - - - \\
	param_3m = Slider(w, Rect(10, 250, 180, 20))
	.action_({
		z = param_3m.value;
		~melodySusLvl = z;
		~setSynths.value;
		s.string_(" Sustain Level: "+ z.round(0.001) +" ");
	});
	s = StaticText.new(w,Rect(15,275,170,20));
	s.background = Color(1, 1, 1, 0.5);

	// - - - MELODY PARAMETER 4 - - - \\

	param_4m = Slider(w, Rect(10, 300, 180, 20))
	.action_({
		z = param_4m.value;
		z = z * z;
		~melodyRelease = z;
		~setSynths.value;
		t.string_(" Release Time (s): "+ z.round(0.001) +" ");
	});
	t = StaticText.new(w,Rect(15,325,170,20));
	t.background = Color(1, 1, 1, 0.5);


	// - - - HARMONY PARAMETER 1 - - - \\
	param_1h = Slider(w, Rect(210, 150, 180, 20))
	.action_({
		z = param_1h.value;
		z = z * z;
		~harmonyAttack = z;
		~setSynths.value;
		u.string_(" Attack Time (s): "+ z.round(0.001) +" ");
	});
	u = StaticText.new(w,Rect(215,175,170,20));
	u.background = Color(1, 1, 1, 0.5);

	// - - - HARMONY PARAMATER 2 - - - \\
	param_2h = Slider(w, Rect(210, 200, 180, 20))
	.action_({
		z = param_2h.value;
		z = z * z;
		~harmonyDecay = z;
		~setSynths.value;
		v.string_(" Decay Time (S): "+ z.round(0.001) +" ");
	});
	v = StaticText.new(w,Rect(215,225,170,20));
	v.background = Color(1, 1, 1, 0.5);

	// - - - HARMONY PARAMATER 3 - - - \\
	param_3h = Slider(w, Rect(210, 250, 180, 20))
	.action_({
		z = param_3h.value;
		~harmonySusLvl = z;
		~setSynths.value;
		x.string_(" Sustain Level: "+ z.round(0.001) +" ");
	});
	x = StaticText.new(w,Rect(215,275,170,20));
	x.background = Color(1, 1, 1, 0.5);

	// - - - HARMONY PARAMATER 4 - - - \\

	param_4h = Slider(w, Rect(210, 300, 180, 20))
	.action_({
		z = param_4h.value;
		z = z * z;
		~harmonyRelease = z;
		~setSynths.value;
		y.string_(" Release Time (s): "+ z.round(0.001) +" ");
	});
	y = StaticText.new(w,Rect(215,325,170,20));
	y.background = Color(1, 1, 1, 0.5);

	// - - - - - - - - - - INITIALIZE VALUES - - - - - - - - - - \\


	~settingsArray = {
		[
			param_1m.value, param_2m.value, param_3m.value, param_4m.value,
			param_1h.value, param_2h.value, param_3h.value, param_4h.value
		].round(0.0001);
	};

	~presetsArray = [
		[ 0.04, 0.3, 0.12, 0.5, 0.1, 0.3, 0.1, 0.5 ],
		[ 0.8797, 0.0696, 0.0886, 0.8165, 0.7975, 0.481, 0.1139, 0.8861 ],
		[ 0.8797, 0.0696, 0.0886, 0.8165, 0.0759, 0.1203, 0.1139, 0.1139 ],
		[ 0.3481, 0.3734, 0.3544, 0.3987, 0.4937, 0.4937, 0.481, 0.481 ]
	];

	~setSliders = {arg presetArray;
		param_1m.valueAction = presetArray[0];
		param_2m.valueAction = presetArray[1];
		param_3m.valueAction = presetArray[2];
		param_4m.valueAction = presetArray[3];
		param_1h.valueAction = presetArray[4];
		param_2h.valueAction = presetArray[5];
		param_3h.valueAction = presetArray[6];
		param_4h.valueAction = presetArray[7];
	};

	~setSliders.value(~presetsArray[0]);




	// - - - - - - - - - - DRAW LINES - - - - - - - - - - \\

	w.drawFunc = {
		// set the Color
		Pen.strokeColor = Color.red;

		Pen.moveTo(0@70);
		Pen.lineTo(400@70);
		Pen.moveTo(200@70);
		Pen.lineTo(200@400);
		Pen.moveTo(400@0);
		Pen.lineTo(400@400);

		Pen.stroke

	};
	w.refresh;

	w.front;

	//CmdPeriod.doOnce({w.close});

};
);
~makeGUI.value;

///////////////////////////////////////

(

/*Get the melody line's notes and durations with measure organization
* Returns a two lists (for notes and durations respectively) of arrays, each of which represents a measure
*/
~extractLineMeasureNoteDurs = {arg input, voice;
	var output = List[];
	var notesToAdd = List[];
	var dursToAdd = List[];
	output.add(List[]);
	output.add(List[]);
	// Go through each measure
	for(0, input.size - 2, {arg i;
		// Go through each note in each measure
		for(0, input[i].size - 1, {arg j;
			if(input[i][j][0] == voice, {
				notesToAdd.add(input[i][j][1]);
				dursToAdd.add(input[i][j][2]);
			});
		});

		output[0].add(notesToAdd.asArray);
		output[1].add(dursToAdd.asArray);
		notesToAdd = List[];
	});
	output;
};

// Test the method above
/*~extractLineMeasureNoteDurs.value([[[1, 2, 3], [1, 2, 3]], [[1, 2, 3]], []], 1).postln;*/

/*
* Grab the harmony from the output of the MIDI, which is in an array of measures, each in an array of arrays, each containing [voice, pitch, duration]
*/


~extractLine = {arg input, voice;
	var notes = [];
	var durations = [];
	for(0, input.size - 2, {arg i;
		for(0,input[i].size - 1, {arg j;
			if(input[i][j][0] == voice, {
				notes = notes ++ input[i][j][1];
				durations = durations ++ input[i][j][2];
			});
		});
	});
	[notes, durations];
};

/*
* Function to initialize and return an array of zeros for each measure in existence, to be used as an array of flags
* Takes in an array size
*/
~getZeroFlagArray = { arg arrSize;
	var outArray = List.new(arrSize);
	~motifCount = 1;
	arrSize.do({outArray.add(0)});
	outArray;
};

// Test the function above
/*~getZeroFlagArray.value(6);*/

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

~incrementMatches.value([1, 2, 3]).postln;

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

// Testing code--make sure to keep commented if testing the real thing
// ~flagArray = ~getZeroFlagArray.value(~testArray.size);
// ~getRepeatSectionDividers.value(~testArray, 0, List[3]);
// ~flagArray;


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
	~motifDict = Dictionary.new();
	~flagArray = ~getZeroFlagArray.value(measuresArr.size);

	// Go through notes and find any sequences that are equal
	while ( {measureIndex < (measuresArr.size - 1)}, // for each measure
		// Check that the measure has not been assigned to a motif yet
		{ if (~flagArray[measureIndex] == 0,
			// Go through all measures following the current one to see if any match
			{
				for (measureIndex + 1, measuresArr.size - 1, { |i|
					if ((measuresArr[measureIndex] == measuresArr[i]) &&
						(~flagArray[measureIndex] == 0) && (~flagArray[i] == 0 ),
						// Found a match so add to the matches list
						{matches.add(i)}
					);
				});

				// Make sure we even have matches
				if (matches.size != 0, {
					// Get the dividers for the sections
					dividersToAdd = ~getRepeatSectionDividers.value(measuresArr,
						measureIndex, matches);
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
					matches = List[];
				},
				// Else there were no matches
				{measureIndex = measureIndex + 1;});
			// Else we already marked this measure as a part of a motif
			},
			{measureIndex = measureIndex + 1;}
		);

	});

	dividers.sort;
};

// Test the ~getRepeatsDividers function on a test array--make sure to keep commented or
// delete if running the real thing!
/*~motifCount = 1;
~getRepeatsDividers.value(~testArray).postln;
~flagArray.postln;
~motifDict.postln;*/

/*Function to go through the flag array and update all consecutive 0s to reflect a new motif; also updates the ~motifDict as it goes*/
~handleZeroFlags = {
	var currentIndex = 0;
	var currentMotifStart = 0;
	~flagArray;
	~motifDict;
	~motifCount;
	while ({ currentIndex < ~flagArray.size},
		// Find the first instance of a zero and
		{if ( ~flagArray[currentIndex] == 0,
			// Set the starting point and go reassign all 0 flags immediately following until we hit a non-zero or the end of the array
			{currentMotifStart = currentIndex;
				while({ currentIndex < ~flagArray.size && ~flagArray[currentIndex] == 0},
					{~flagArray[currentIndex] = ~motifCount;
						currentIndex = currentIndex + 1;
					}
				);
				// We've finished setting the flag array, so we need to set the dictionary
				~motifDict.put(~motifCount, [currentMotifStart, currentIndex]);
				~motifCount = ~motifCount + 1;
			}
		);
		// Update the current Index
		currentIndex = currentIndex + 1;
	});
};

// Test the function above--make sure to keep commented if running the real thing!
/*~handleZeroFlags.value();
~flagArray.postln;
~motifDict.postln;
~motifCount.postln;*/

/*
* From a list of dividers and a flagarray, determine the motif array.
*/
~determineMotifs = { arg divs, flags;
	var curr = 0;
	var out = Array.new(divs.size + 1);
	if(flags.size > 0, {
		for(0,divs.size - 1, {arg i;
			out = out.add(flags[divs[i]]);
		});
	});
	out;
};

/*
* From the dictionary of (ID -> [start, end)) and the parsed MIDI, build the dictionary of durations and of motifs
*/
~noteDurDictionaries = {arg melIndex, map;

	var noteDur = ~extractLineMeasureNoteDurs.(~globalOutputArray, melIndex);
	var id = 1;
	var currRanges;
	var notes = Dictionary.new(map.size);
	var durs = Dictionary.new(map.size);

	// Go through all ids in the dictionary
	while({map.at(id) != nil}, {
		currRanges = map.at(id);
		notes.put(id, []);
		durs.put(id, []);

		// Go through the range of the given id and add the note or duration from
		// noteDur to the respective dictionaries for the id
		for(currRanges[0], currRanges[1] - 1, {arg i;
			notes.put(id, notes.at(id) ++ noteDur[0][i]);
			durs.put(id, durs.at(id) ++ noteDur[1][i]);
		});
		// Increment id for the while loop
		id = id + 1;
	});
	[notes,durs];
};

// ~determineMotifs.([0,3,6,8,11,14],[1,1,1,1,1,1,2,2,1,1,1,3,3,3,2,2]);


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

// ~getDrumColumn.(10, 20, ~generateDrumRule.(25));

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

/*
* Generate random durations to fit a certain number of beats, given an input set of durations
*/
~durationGenerate = { arg durs;
	var dict = Dictionary.new(durs.size); // Markov model dictionary

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

		// Each duration generated from the Markov chain of the previous note
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

// ~durationGenerate.([1,1,2,3,1,2,3,1,2,2,1,4,1,2,3,1,4,1,1]);

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

// ~test = ~durationGenerate.([1,1,2,3,1,2,3,1,2,2,1,4,1,2,3,1,4,1,1]);
// ~test.postln;
// ~durToBeat.(~test,4);

/*
* Given a set of notes representing a motif, generate a new motif through Markov models
*/
~markovMotif = { arg notes, numNotes;
	var dict = Dictionary.new(notes.size); // Markov model dictionary
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

		// Each note generated from the Markov chain of the previous note
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

// Test the function above
// ~markovMotif.([1,2,1,1,3,1,2,5,1,4], 10).postln;

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

// ~pullHarmonyNote.([5,4,3,1,2], [1,2,3,4,5], [1,2,3,4,5], [5,4,3,2,1], 1);

/*
* As a continuation to the above function, pull an entire harmony line from a melody line
*/
~writeHarmonyLine = {arg melNotes, melDurs, harmNotes, harmDurs, newMel;
	var out = Array.new(newMel.size);
	for(0,newMel.size-1, {arg i;
		out = out.add(~pullHarmonyNote.(melNotes,melDurs,harmNotes,harmDurs,newMel[i]));
	});
	out;
};

// ~writeHarmonyLine.([5,4,3,1,2], [1,2,3,4,5], [1,2,3,4,5], [5,4,3,2,1], [1,1,2,2,3,3,4,4,5,5]);

/*
* Converts a dictionary of motif notes, a dictionary of motif durations, and an array of motif numbers into an array of notes and durations
Returns as [notes, durations]
*/
~convertToLine = { arg durDict, noteDict, motifs;
	var out;
	var newDurDict;
	var newNoteDict;
	var newDurs;
	var count;

	out = Array.new(2);
	out.add([]);
	out.add([]);
	newDurDict = Dictionary.new(durDict.size);
	newNoteDict = Dictionary.new(noteDict.size);
	count = 1;

	// Construct a dictionary with the new durations using durationGenerate
	// and new notes using markovMotif on each "section"
	while({durDict.at(count) != nil}, {
		newDurDict.put(count, ~durationGenerate.value(durDict.at(count)));
		newNoteDict.put(count, ~markovMotif.value(noteDict.at(count), newDurDict.at(count).size));
		count = count + 1;

		// Go through all the elements of the motifs array and add the new notes and durations to
		// the respective arrays of the output
		for(0, motifs.size - 1, {|i|
			out[0] = out[0] ++ newNoteDict.at(motifs[i]);
			out[1] = out[1] ++ newDurDict.at(motifs[i]);
		});
	});
	out;
};

/*
* Function that randomizes durations.
* For making harmony not monophonic.
*/
~randomizeDurations = {arg seed, durs;
	var next;
	var diff;
	for(0, durs.size - 2, {arg i;
		next = durs[i+1];
		if(seed.coin, {
			diff = next.rand;
			durs[i] = durs[i] + diff;
			durs[i+1] = durs[i+1] - diff;
		});
	});
	durs;
};

// ~randomizeDurations.(0.5, [1,2,3,1,3,2,5,4,1,2,3]).postln;

/*
* Add intermediate notes randomly.
*/
~addRandomNotes = {arg seed, durs, notes;
	var newDurs = [];
	var newNotes = [];
	for(0, durs.size - 1, {arg i;
		if(seed.coin, {
			newDurs = newDurs ++ [floor(durs[i]/2)];
			newDurs = newDurs ++ [durs[i] - floor(durs[i]/2)];
			newNotes = newNotes ++ [notes[i]];
			newNotes = newNotes ++ [notes[i]];
		}, {
			newDurs = newDurs ++ [durs[i]];
			newNotes = newNotes ++ [notes[i]];
		});
	});
	[newDurs, newNotes];
};

// ~addRandomNotes.(0.5,[1,2,3,1,4,1,5,2,6,3,2], [1,2,3,1,4,1,5,2,6,3,2]);

/*
* Function that gets the notes and durations for the new melody, returns as array of
* [notes, durations]
*/
~getNewMelody = {
	var formattedNotes;
	var dividers;
	var motifArray;
	var noteDurDict;

	// Get the melody notes properly formatted and grouped by measure
	formattedNotes = ~extractLineMeasureNoteDurs.value(~globalOutputArray, 1)[0].postln;

	// Get the dividers and the properly set ~flagArray
	dividers = ~getRepeatsDividers.value(formattedNotes);
	~handleZeroFlags.value;
	// Array that has information about order of motifs
	motifArray = ~determineMotifs.value(dividers, ~flagArray);
	// Get the note and duration dictionaries
	noteDurDict = ~noteDurDictionaries.value(1, ~motifDict);
	"Flag array".postln;
	~flagArray.postln;
	"Motif array".postln;
	motifArray.postln;
	~motifDict.postln;

	// Finally, convert a dictionary of motif durations (at noteDurDict[1]),
	// a dictionary of motif notes (at noteDurDict[0]), and
	// an array of motif numbers into a new array of note and duration arrays
	// Format is [notes, durations]
	~convertToLine.value(noteDurDict[1], noteDurDict[0], motifArray);

};

// Test the function above
 //~getNewMelody.value();


~afterTrackSelected = {
	var newMelody;

	a =  ~extractLine.(~globalOutputArray, 1);
	b =  ~extractLine.(~globalOutputArray, 2);

	~oldMelodyNotes = a[0];
	~oldMelodyRhythms = a[1];
	~oldHarmonyNotes = b[0];
	~oldHarmonyRhythms = b[1];

	if(~displayDataInPostWindow, {~post.value});

	newMelody = ~getNewMelody.value();
	~newMelodyNotes = newMelody.at(0);
	~newMelodyRhythms = newMelody.at(1);

	~setSynths.value;
	~setDrums.value;

};

// - - - - - DISPLAY DATA IN POST WINDOW - - - - - \\
~post = {
	"\n".postln;
	i = 0;
	while ({i < (~globalOutputArray.size - 1)}, {
		("Measure:" + i + "\n").postln;
		~globalOutputArray[i].round(0.01).postcs;
		"\n- - - - - - - - - - - - - - - - - - - -\n".postln;
		i = i + 1;
	});

	"\n\t OLD MELODY NOTES \n".postln;
	~oldMelodyNotes.round(0.01).postcs;
	"\n\t OLD MELODY RHYTHMS \n".postln;
	~oldMelodyRhythms.round(0.01).postcs;
	"\n\t OLD HARMONY NOTES \n".postln;
	~oldHarmonyNotes.round(0.01).postcs;
	"\n\t OLD HARMONY RHYTHMS \n".postln;
	~oldHarmonyRhythms.round(0.01).postcs;
};

~bpm = 104;

~setSynths = {
	var tempo = 60/~bpm;
	var rolloffList = List[];
	var attackList = List[];
	var ranReleases = List[];
	var notes = List[];
	var rhythms = List[];
	var ampsList = List[];
	var thisMany;
	var  speed = tempo/4;

	var nextBass = { arg set;
		// Hard-coded in probabilities based on what set followed what set in the source material.
		var probabilities = Dictionary.newFrom([
			[1,0,0,0], [[1,0,0,0]]
		]);

		probabilities.at(set).choose;
	};

	var nextSnare = { arg set;
		// Hard-coded in probabilities based on what set followed what set in the source material.
		var probabilities = Dictionary.newFrom([
			[0,0,0,0], [[1,0,0,0]],
			[1,0,0,0], [[0,0,1,0]],
			[0,0,1,0], [[0,0,1,0],[0,0,0,0]]
		]);

		probabilities.at(set).choose;
	};
	var nextHat = { arg set;
		// Hard-coded in probabilities based on what set followed what set in the source material.
		var probabilities = Dictionary.newFrom([
			[0,0,0,0], [[0,0,1,0]],
			[1,0,0,0], [[0,0,1,0]],
			[0,0,1,0], [[1,0,0,0],[0,0,0,0]]
		]);

		probabilities.at(set).choose;
	};
	var nextTom = { arg set;
		// Hard-coded in probabilities based on what set followed what set in the source material.
		var probabilities = Dictionary.newFrom([
			[0,0,0,1], [[0,0,1,0],[0,0,0,1]],
			[1,0,0,1], [[0,0,0,1]],
			[0,0,1,0], [[1,0,0,1]]
		]);

		probabilities.at(set).choose;
	};
	/*
	* Generate drums.
	* Drum generation uses Markov chains on sets of four beats.
	*/
	var generateDrums = {arg numBeats;
		var bass = Array.new(numBeats);
		var snare = Array.new(numBeats);
		var hat = Array.new(numBeats);
		var tom = Array.new(numBeats);
		var currBass = [1, 0, 0, 0]; // current bass value, initialized at beginning of given motif
		var currSnare = [0, 0, 0, 0]; // current snare value, initialized at beginning of given motif
		var currHat = [0, 0, 0, 0]; // current hat value, initialized at beginning of given motif
		var currTom = [0, 0, 0, 1]; // current tom value, initialized at beginning of given motif

		// Initialize all the markov chains with the first value
		bass = bass ++ currBass;
		snare = snare ++ currSnare;
		hat = hat ++ currHat;
		tom = tom ++ currTom;

		// Determine the rest of the drum sequence through Markov chains
		for(2,round(numBeats/4), {
			currBass = nextBass.(currBass);
			bass = bass ++ currBass;

			currSnare = nextSnare.(currSnare);
			snare = snare ++ currSnare;

			currHat = nextHat.(currHat);
			hat = hat ++ currHat;

			currTom = nextTom.(currTom);
			tom = tom ++ currTom;
		});

		[bass,snare,hat,tom];
	};

	// Generate the drums for this melody
	//var drumNotes = generateDrums.(~mel.sum);
	var drumNotes = generateDrums.(~oldMelodyRhythms.sum*2);


	// These drums are taken from http://superdupercollider.blogspot.com/2009/02/simple-drum-machine.html
	SynthDef(\drums, {|out = 0, bassLevel = 0 , snareLevel = 0, hatLevel = 0, tomLevel = 0, pan1 = 0, pan2 = 0, pan3 = 0, pan4 = 0|
		var env1, env2, env3, env4, bass, snare, hat, tom, bassOut, snareOut, hatOut, tomOut, mixer;
		env1 = EnvGen.kr(Env.perc(0.001, 0.2, 1, -4), 1, doneAction:2);
		env2 = EnvGen.kr(Env.perc(0.001, 0.5, 1, -1), 1, doneAction:2);
		env3 = EnvGen.kr(Env.perc(0.002, 0.3, 1, -2), 1, doneAction:2);
		env4 = EnvGen.kr(Env.perc(0.001, 0.1, 1, -5), 1, doneAction:2);
		bass = SinOsc.ar(80) + Crackle.ar(1, 0.5);
		bassOut = Pan2.ar(bass*env1, pan1, bassLevel);
		snare = SinOsc.ar(120) - WhiteNoise.ar(0.5, 0.5);
		snareOut = Pan2.ar(snare*env4, pan2, snareLevel);
		hat = Klank.ar(`[ [ 6563, 9875 ],
			[ 0.6, 0.5 ],
			[ 0.002, 0.003] ], PinkNoise.ar(1));
		hatOut = Pan2.ar(hat*env3, pan2, hatLevel);
		tom = SinOsc.ar(440);
		tomOut = Pan2.ar(tom*env4, pan4, tomLevel);
		mixer = Mix.new([bassOut, snareOut, hatOut, tomOut]);
		Out.ar(out, mixer);
	}).store;


	~speed = tempo/4;
	a = Pseq (drumNotes[0],1);
	b = Pseq (drumNotes[1],1);
	c = Pseq (drumNotes[2],1);
	d = Pseq (drumNotes[3],1);

	// DRUM LEVELS
	// [bass, snare, hat, tom]
	e = [0.9, 0.9, 0.6, 0.15];

	// Play the drums

	~playDrums = Pbind(
		\instrument, \drums,
		\dur, ~speed,
		\bassLevel, Pseq ([a]*e[0], 1),
		\snareLevel, Pseq ([b]*e[1], 1),
		\hatLevel, Pseq ([c]*e[2], 1),
		\tomLevel, Pseq ([d]*e[3], 1)
	);


	//------------------------ \sine ------------------------------\\
	SynthDef(\sine, { |
		freq = 440, amp = 0.1, attack = 1,
		decay = 1, sustain = 1, susLvl = 0.1, release = 1 |
		var freqMultiples = [1, 2, 4, 8];
		var sig = Array.fill(4, {arg i;
			SinOsc.ar( (freq*freqMultiples[i]), 0, amp*(1/pow(i+1, 3)) ) *
			EnvGen.ar(Env(
				levels: [ 0, 1, susLvl, susLvl, 0 ],
				times: [ attack, decay, sustain, release ] ),
			doneAction: 2);
		});
		Out.ar(0, sig ! 2)
	}).add;


	//------------------------ \steel ------------------------------\\

	SynthDef(\steel, { |
		freq = 440, amp = 0.1, delay = 0, attack = 1, rolloff = 1,
		decay = 1, sustain = 1, susLvl = 0.1, release = 1 |

		var sig = Array.fill(12, {arg i;
			j = i + 1;
			SinOsc.ar( (freq*j), 0, (amp*(1/pow(j, rolloff))) ) *
			EnvGen.ar(Env(
				levels: [ 0, 0, 1, susLvl, susLvl, 0 ],
				times: [ delay*(i), (attack*j), decay, (sustain), (release/pow(j, 0.666)) ] ),
			doneAction: if (i == 0, {2}, {0} ));
		});
		Out.ar(0, sig ! 2)
	}).add;


	//------------------------ \bass ------------------------------\\

	SynthDef(\bass, { |
		freq = 440, amp = 0.5, undertone1 = 1, undertone2 = 1,
		deTune = 0.001, attack = 0.002, decay = 1, release = 0.5 |

		var sig, env, osc, tuning1, tuning2, tuning3, tuning4;
		tuning1 = (freq * deTune) + freq;
		tuning2 = (freq * (deTune * -1)) + freq;
		tuning3 = (freq * deTune * 2) + freq;
		tuning4 = (freq * (deTune * -1) * 2) + freq;

		osc = Saw.ar(freq) + (Saw.ar(freq/2) * undertone1) + (Saw.ar(freq/4) * undertone2) +
		Saw.ar(tuning1) + (Saw.ar(tuning1/2) * undertone1) + (Saw.ar(tuning1/4) * undertone2) +
		Saw.ar(tuning2) + (Saw.ar(tuning2/2) * undertone1) + (Saw.ar(tuning2/4) * undertone2) +
		Saw.ar(tuning3) + (Saw.ar(tuning3/2) * undertone1) + (Saw.ar(tuning3/4) * undertone2) +
		Saw.ar(tuning4) + (Saw.ar(tuning4/2) * undertone1) + (Saw.ar(tuning4/4) * undertone2);
		// change these numbers! its awesome!
		sig = LPF.ar(osc, XLine.ar(20000, 200, 0.1));
		//sig = LPF.ar(osc, XLine.ar(1000, 100, 0.1));
		//sig = LPF.ar(osc, XLine.ar(20000, 5000, 0.1));
		env = EnvGen.ar(Env( [0, amp, (amp / 15), 0], [attack, decay, release], [1, -5, 0] ), doneAction: 2);
		sig = sig * env;
		Out.ar(0, sig !2);
	}).add;

	//------------------------ \pad ------------------------------\\

	SynthDef(\pad, { |freq = 500, amp = 0.2, sustain = 1, attack = 0.02, release = 0.5,
		start = 0.5, end = 5.0, time = 1.5, tremSpeed = 8, tremDepth = 0.25|

		var deTune = 0.005;
		var numHarmonics = 5;
		var sig;

		sig = Array.fill((numHarmonics*3), {arg i;
			j = (i % numHarmonics)+1;
			k = (((i / numHarmonics)+0.5).round-2)*deTune;
			SinOsc.ar( ((freq*j)+((freq*j)*k)), 0, (amp/pow(j, 1.75)) ) *
			EnvGen.ar(Env(
				levels: [ 0, 1, amp, 0 ],
				times: [ attack, sustain, release ] ),
			doneAction: if (i == 0, {2}, {0} ))
			* SinOsc.ar(tremSpeed*(0.333+((2/j)*k*(1/deTune))), 0, tremDepth, 1 - tremDepth) *SinOsc.ar((tremSpeed*(0.5+((1.5/j)))), 0, tremDepth, 1 - tremDepth)
		});

		Out.ar(0, sig ! 2);
	}).add;

	(

		//~melodySize = ~mel.size;
		~melodySize = ~oldMelodyNotes.size;

		~melodySize.do{arg i;

			a= exprand(1.0, 5.0).round(0.001);
			rolloffList.add(a);



		};
		rolloffList = rolloffList.sort.reverse;
	);

	//rhythms = ~durs* tempo;

	rhythms = ~oldMelodyRhythms * tempo;

	~playOldMelody = Pbind(
		\instrument, ~melodyInstrument,
		//\midinote, Pseq(~mel, 1),
		\midinote, Pseq(~oldMelodyNotes, 1),
		\dur, Pseq(rhythms, 1),
		\sustain, Pseq(rhythms, 1),
		\amp, 0.2,
		\delay, 0.001,
		\attack, ~melodyAttack,
		\decay, ~melodyDecay,
		\susLvl, ~melodySusLvl,
		\release, ~melodyRelease,
		//\rolloff, Pseq(rolloffList, 1)
		\rolloff, 1.5
	);

	~playHarmony = Pbind(
		\instrument, ~harmonyInstrument,
		//\midinote, Pseq(~harm, 1),
		\midinote, Pseq(~oldHarmonyNotes, 1),
		\dur, Pseq(rhythms, 1),
		\sustain, Pseq(rhythms, 1),
		\amp, 0.2,
		\attack, ~harmonyAttack,
		\decay, ~harmonyDecay,
		\susLvl, ~harmonySusLvl,
		\release, ~harmonyRelease,
	);

	//rhythms = ~newMelodyRhythms * tempo;

	~playNewMelody = Pbind(
		\instrument, ~melodyInstrument,
		//\midinote, Pseq(~mel, 1),
		\midinote, Pseq(~newMelodyNotes, 1),
		\dur, Pseq(~newMelodyRhythms * tempo, 1),
		\sustain, Pseq(~newMelodyRhythms * tempo, 1),
		\amp, 0.2,
		\delay, 0.001,
		\attack, ~melodyAttack,
		\decay, ~melodyDecay,
		\susLvl, ~melodySusLvl,
		\release, ~melodyRelease,
		//\rolloff, Pseq(rolloffList, 1)
		\rolloff, 1.5
	);

	/*Pbind(
	\instrument, \bass,
	//\midinote, Pseq(~harm, 1),
	\midinote, Pseq(~oldHarmonyNotes, 1),
	\dur, Pseq(rhythms, 1),
	\sustain, Pseq(rhythms, 1),
	\amp, 0.2,
	\attack, 0.003,
	\decay, 0.75,
	\susLvl, 0.15,
	\release, 0.5,
	).play;*/




	/*Pbind(
	\instrument, \steel,
	//\midinote, Pseq(~mel, 1),
	\midinote, Pseq(~oldMelodyNotes, 1),
	\dur, Pseq(rhythms, 1),
	\sustain, Pseq(rhythms, 1),
	\amp, 0.2,
	\delay, 0.0001,
	\attack, 0.0001,
	\decay, 0.25,
	\susLvl, 0.15,
	\release, 0.25,
	//\rolloff, Pseq(rolloffList, 1)
	\rolloff, 2
	).play;

	Pbind(
	\instrument, \sine,
	//\midinote, Pseq(~harm, 1),
	\midinote, Pseq(~oldHarmonyNotes, 1),
	\dur, Pseq(rhythms, 1),
	\sustain, Pseq(rhythms, 1),
	\amp, 0.2,
	\attack, 0.00,
	\decay, 0.05,
	\susLvl, 0.1,
	\release, 0.5
	).play;*/

	/*	Pbind(
	\instrument, \pad,
	\midinote, Pseq(~oldMelodyNotes-12, 1),
	\dur, Pseq(rhythms, 1),
	\sustain, Pseq(rhythms, 1),
	\amp, 0.3,
	\attack, 0.01,
	\decay, 0.15,
	\susLvl, 0.55,
	\release, 1.5,
	).play;*/

};



/*
INSTRUCTIONS: How everything works together:

After running xml_read portion of code, ~globalOutputArray has the song

Assuming the harmony voice is number 2, to get the harmony, call ~oldHarm = ~extractLine.(~globalOutputArray, 2);

Kat's code turns the ~globalOutputArray into a duration dictionary (ID -> array of durations for each motif), a note dictionary (ID -> array of notes for each motif), and an array of motifs (call ~determineMotifs on divs and flags). The dictionaries are found by calling ~noteDurDictionaries on the melody index (if the melody is voice 1 in ~globalOutputArray then this is 1), and ~globalOutputArray. (Use ~getRepeatsDividers to get the list of dividers. This function also creates a dictionary of ID-> array mappings as well as an array indicating what motifs each measure is associated with. From here, we may need to create dummy motifs out of the 0 flags in ~flagarray. The last element of the array may or may not be included in the dividers.)

Get the melody using ~extractLineMeasureNotes and then get the dividers from ~getRepeatsDividers.
~getRepeatsDividers(~extractLineMeasureNotes.value(~globalOutputArray))

Call ~convertToLine on this output, lets say stored into ~oldMel

After this, use the following lines to get the output melody notes and durations:
~durs = ~durationGenerate.(oldMel[1}); // durations for melody and harmony
~mel = ~markovMotif.(~oldMel[0], ~durs.size); // notes for melody
~harm = ~writeHarmonyLine.(~oldMel[0], ~oldMel[1], ~oldHarm[0], ~oldHarm[1], ~mel); // notes for harmony

~harmDurs = ~durs;

// **NEW: to write a varied harmony, have the UI take a number between 0 and 1 (set it to ~seed) and then do ~harmDurs = ~randomizeDurations.(~seed, ~harmDurs);
~harmBoth = ~addRandomNotes.(~seed, ~harmDurs, ~harm);
~harmDurs = ~harmBoth[0];
~harm = ~harmBoth[1];

Given that we currently don't take drums as input, drums can be generated just with: (where size is the length of the output you want)

~getDrumColumn.(size / 2, size, ~generateDrumRule.(255.rand)); // drum beats (an array of 0's and 1's where 0's are silences and 1's are drum hits)
*/

)
)