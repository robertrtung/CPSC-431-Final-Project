(

// ~globalOutputArray is the array you will use. it has MIDI note and duration

// the index in that array indicates the measure number

// ex. ~globalOutputArray[0] = measure 1, ~globalOutputArray[1] = measure 2, etc...

// each index contains [voice#, midi_note#, note_length]
//   in the correct order that they appear in that measure

// this is good for monophonic instruments, but you can have several of them.

// it works for sharps, flats, and dotted rhythms as well

var rest, pitch, dot, instrument_ID, measure_number, midiNote, duration;



//  CHOOSE THE FILE TO READ \\
~fileNameArray = ["mario_theme.xml", "traumerei.xml", "marry_you.xml"];
~fileName = ~fileNameArray[1];



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
	("~/Desktop/CS431_final_project/"++~fileName));
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

)