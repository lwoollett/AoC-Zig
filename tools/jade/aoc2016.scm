jadeVersionNumber "25.0.01";
schemaDefinition
	AocSchema subschemaOf RootSchema completeDefinition;
localeDefinitions
	5129 "English (New Zealand)" schemaDefaultLocale;
typeHeaders
	AocSchema subclassOf RootSchemaApp transient, sharedTransientAllowed, transientAllowed, subclassSharedTransientAllowed, subclassTransientAllowed;
	Controllers subclassOf Object;
	AocController subclassOf Controllers;
	Items subclassOf Object;
	Year subclassOf Items;
	Day subclassOf Items;
	Part subclassOf Items;
	Tests subclassOf Object transient, sharedTransientAllowed, transientAllowed, subclassSharedTransientAllowed, subclassTransientAllowed;
	AocTestCase subclassOf Tests transient;
	AnswerTests subclassOf AocTestCase transient;
	JadeScript subclassOf Object;
	YearByNumber subclassOf MemberKeyDictionary loadFactor = 66;
	DayByNumber subclassOf MemberKeyDictionary loadFactor = 66;
	PartByNumber subclassOf MemberKeyDictionary loadFactor = 66;
membershipDefinitions
	YearByNumber of Year;
	DayByNumber of Day;
	PartByNumber of Part;
typeDefinitions
	AocSchema completeDefinition
	(
	)
	Object completeDefinition
	(
	)
	RootSchemaApp completeDefinition
	(
	)
	Controllers completeDefinition
	(
	)
	AocController completeDefinition
	(
	referenceDefinitions
		yearByNumber:                YearByNumber   explicitInverse;
	jadeMethodDefinitions
		ensureYear(
			n: Integer) updating;
	)
	Items completeDefinition
	(
	)
	Year completeDefinition
	(
	attributeDefinitions
		number:                       Integer;
	referenceDefinitions
		controller:                   AocController   explicitInverse;
		days:                         DayByNumber   explicitInverse;
	jadeMethodDefinitions
		ensureDay(
			n: Integer) updating;
	)
	Day completeDefinition
	(
	attributeDefinitions
		number:                       Integer;
	referenceDefinitions
		year:                         Year   explicitInverse;
		parts:                        PartByNumber   explicitInverse;
	jadeMethodDefinitions
		addPart(
			n: Integer;
			answer: StringUtf8) updating;
	)
	Part completeDefinition
	(
	attributeDefinitions
		number:                       Integer;
		answer:                       StringUtf8[32];
		correct:                      Boolean;
	referenceDefinitions
		day:                          Day   explicitInverse;
	)
	Tests completeDefinition
	(
	)
	AocTestCase completeDefinition
	(
	attributeDefinitions
		passed:                       Integer;
		failed:                       Integer;
		failLog:                      StringUtf8[512];
	jadeMethodDefinitions
		check(
			actual: StringUtf8;
			expected: StringUtf8;
			label: StringUtf8) updating;
		report(): StringUtf8;
	)
	AnswerTests completeDefinition
	(
	jadeMethodDefinitions
		checkPart(
			ctl: AocController;
			d: Integer;
			p: Integer;
			expected: StringUtf8) updating;
		run2016(): StringUtf8;
	)
	JadeScript completeDefinition
	(
	jadeMethodDefinitions
		populateData(): StringUtf8 updating;
		runTests(): StringUtf8;
	)
	YearByNumber completeDefinition
	(
	)
	DayByNumber completeDefinition
	(
	)
	PartByNumber completeDefinition
	(
	)
memberKeyDefinitions
	YearByNumber completeDefinition
	(
		number;
	)
	DayByNumber completeDefinition
	(
		number;
	)
	PartByNumber completeDefinition
	(
		number;
	)
inverseDefinitions
	yearByNumber of AocController automatic peerOf controller of Year manual;
	days of Year automatic peerOf year of Day manual;
	parts of Day automatic peerOf day of Part manual;
typeSources
	AocController (
	jadeMethodSources
ensureYear
{
ensureYear(n: Integer) updating;

vars
	yr: Year;

begin
	yr := self.yearByNumber[ n ];
	if yr = null then
		create yr persistent;
		yr.number := n;
		yr.controller := self;
	endif;
end;
}
	)
	Year (
	jadeMethodSources
ensureDay
{
ensureDay(n: Integer) updating;

vars
	day: Day;

begin
	day := self.days[ n ];
	if day = null then
		create day persistent;
		day.number := n;
		day.year := self;
	endif;
end;
}
	)
	Day (
	jadeMethodSources
addPart
{
addPart(n: Integer; answer: StringUtf8) updating;

vars
	part: Part;

begin
	part := self.parts[ n ];
	if part = null then
		create part persistent;
		part.number := n;
		part.day := self;
	endif;
	part.answer := answer;
	part.correct := true;
end;
}
	)
	AocTestCase (
	jadeMethodSources
check
{
check(actual: StringUtf8; expected: StringUtf8; label: StringUtf8) updating;

begin
	if actual = expected then
		self.passed += 1;
	else
		self.failed += 1;
		self.failLog := self.failLog & label & ": got '" & actual & "' want '" & expected & "'; ";
	endif;
end;
}
report
{
report(): StringUtf8;

begin
	if self.failed = 0 then
		return "all " & self.passed.String & " assertions passed";
	endif;
	return self.failed.String & " of " & (self.passed + self.failed).String & " assertions FAILED: " & self.failLog;
end;
}
	)
	AnswerTests (
	jadeMethodSources
checkPart
{
checkPart(ctl: AocController; d: Integer; p: Integer; expected: StringUtf8) updating;

vars
	yr: Year;
	day: Day;
	part: Part;

begin
	yr := ctl.yearByNumber[ 2016 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2016 missing; ";
		return;
	endif;
	day := yr.days[ d ];
	if day = null then
		self.failed += 1;
		self.failLog := self.failLog & "day " & d.String & " missing; ";
		return;
	endif;
	part := day.parts[ p ];
	if part = null then
		self.failed += 1;
		self.failLog := self.failLog & "part " & d.String & "/" & p.String & " missing; ";
		return;
	endif;
	self.check(part.answer, expected, d.String & "/" & p.String);
end;
}
run2016
{
run2016(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
	self.checkPart(ctl, 1, 1, "239");
	self.checkPart(ctl, 1, 2, "141");
	self.checkPart(ctl, 2, 1, "53255");
	self.checkPart(ctl, 2, 2, "7423A");
	self.checkPart(ctl, 3, 1, "982");
	self.checkPart(ctl, 3, 2, "1826");
	self.checkPart(ctl, 4, 1, "185371");
	self.checkPart(ctl, 4, 2, "984");
	self.checkPart(ctl, 5, 1, "d4cd2ee1");
	self.checkPart(ctl, 5, 2, "f2c730e5");
	self.checkPart(ctl, 6, 1, "ygjzvzib");
	self.checkPart(ctl, 6, 2, "pdesmnoz");
	self.checkPart(ctl, 7, 1, "118");
	self.checkPart(ctl, 7, 2, "260");
	self.checkPart(ctl, 8, 1, "123");
	self.checkPart(ctl, 8, 2, "RFBUPZBJPS");
	self.checkPart(ctl, 9, 1, "112830");
	self.checkPart(ctl, 9, 2, "10931789799");
	self.checkPart(ctl, 10, 1, "157");
	self.checkPart(ctl, 10, 2, "1085");
	self.checkPart(ctl, 11, 1, "37");
	self.checkPart(ctl, 11, 2, "61");
	self.checkPart(ctl, 12, 1, "318083");
	self.checkPart(ctl, 12, 2, "9227737");
	self.checkPart(ctl, 13, 1, "96");
	self.checkPart(ctl, 13, 2, "141");
	self.checkPart(ctl, 14, 1, "23769");
	self.checkPart(ctl, 14, 2, "20606");
	self.checkPart(ctl, 15, 1, "376777");
	self.checkPart(ctl, 15, 2, "3903937");
	self.checkPart(ctl, 16, 1, "10101001010100001");
	self.checkPart(ctl, 16, 2, "10100001110101001");
	self.checkPart(ctl, 17, 1, "RDULRDDRRD");
	self.checkPart(ctl, 17, 2, "752");
	self.checkPart(ctl, 18, 1, "1989");
	self.checkPart(ctl, 18, 2, "19999894");
	self.checkPart(ctl, 19, 1, "1808357");
	self.checkPart(ctl, 19, 2, "1407007");
	self.checkPart(ctl, 20, 1, "23923783");
	self.checkPart(ctl, 20, 2, "125");
	self.checkPart(ctl, 21, 1, "bdfhgeca");
	self.checkPart(ctl, 21, 2, "gdfcabeh");
	self.checkPart(ctl, 22, 1, "872");
	self.checkPart(ctl, 22, 2, "211");
	self.checkPart(ctl, 23, 1, "11478");
	self.checkPart(ctl, 23, 2, "479008038");
	self.checkPart(ctl, 24, 1, "464");
	self.checkPart(ctl, 24, 2, "652");
	self.checkPart(ctl, 25, 1, "189");
	return self.report();
end;
}
	)
	JadeScript (
	jadeMethodSources
populateData
{
populateData(): StringUtf8 updating;

vars
	ctl: AocController;
	yr: Year;
	day: Day;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		create ctl persistent;
	endif;
	yr := ctl.yearByNumber[ 2016 ];
	if yr = null then
		ctl.ensureYear( 2016 );
		yr := ctl.yearByNumber[ 2016 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "239" );
	yr.days[ 1 ].addPart( 2, "141" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "53255" );
	yr.days[ 2 ].addPart( 2, "7423A" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "982" );
	yr.days[ 3 ].addPart( 2, "1826" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "185371" );
	yr.days[ 4 ].addPart( 2, "984" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "d4cd2ee1" );
	yr.days[ 5 ].addPart( 2, "f2c730e5" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "ygjzvzib" );
	yr.days[ 6 ].addPart( 2, "pdesmnoz" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "118" );
	yr.days[ 7 ].addPart( 2, "260" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "123" );
	yr.days[ 8 ].addPart( 2, "RFBUPZBJPS" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "112830" );
	yr.days[ 9 ].addPart( 2, "10931789799" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "157" );
	yr.days[ 10 ].addPart( 2, "1085" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "37" );
	yr.days[ 11 ].addPart( 2, "61" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "318083" );
	yr.days[ 12 ].addPart( 2, "9227737" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "96" );
	yr.days[ 13 ].addPart( 2, "141" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "23769" );
	yr.days[ 14 ].addPart( 2, "20606" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "376777" );
	yr.days[ 15 ].addPart( 2, "3903937" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "10101001010100001" );
	yr.days[ 16 ].addPart( 2, "10100001110101001" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "RDULRDDRRD" );
	yr.days[ 17 ].addPart( 2, "752" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "1989" );
	yr.days[ 18 ].addPart( 2, "19999894" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "1808357" );
	yr.days[ 19 ].addPart( 2, "1407007" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "23923783" );
	yr.days[ 20 ].addPart( 2, "125" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "bdfhgeca" );
	yr.days[ 21 ].addPart( 2, "gdfcabeh" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "872" );
	yr.days[ 22 ].addPart( 2, "211" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "11478" );
	yr.days[ 23 ].addPart( 2, "479008038" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "464" );
	yr.days[ 24 ].addPart( 2, "652" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "189" );
	return "populated 2016: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2016();
end;
}
	)
