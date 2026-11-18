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
		run2018(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2018 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2018 missing; ";
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
run2018
{
run2018(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
	self.checkPart(ctl, 1, 1, "497");
	self.checkPart(ctl, 1, 2, "558");
	self.checkPart(ctl, 2, 1, "6944");
	self.checkPart(ctl, 2, 2, "srijafjzloguvlntqmphenbkd");
	self.checkPart(ctl, 3, 1, "112418");
	self.checkPart(ctl, 3, 2, "560");
	self.checkPart(ctl, 4, 1, "94040");
	self.checkPart(ctl, 4, 2, "39940");
	self.checkPart(ctl, 5, 1, "10638");
	self.checkPart(ctl, 5, 2, "4944");
	self.checkPart(ctl, 6, 1, "4143");
	self.checkPart(ctl, 6, 2, "35039");
	self.checkPart(ctl, 7, 1, "GKCNPTVHIRYDUJMSXFBQLOAEWZ");
	self.checkPart(ctl, 7, 2, "1265");
	self.checkPart(ctl, 8, 1, "41849");
	self.checkPart(ctl, 8, 2, "32487");
	self.checkPart(ctl, 9, 1, "394486");
	self.checkPart(ctl, 9, 2, "3276488008");
	self.checkPart(ctl, 10, 1, "FNRGPBHR");
	self.checkPart(ctl, 10, 2, "10511");
	self.checkPart(ctl, 11, 1, "33,45");
	self.checkPart(ctl, 11, 2, "233,116,15");
	self.checkPart(ctl, 12, 1, "2542");
	self.checkPart(ctl, 12, 2, "2550000000883");
	self.checkPart(ctl, 13, 1, "5,102");
	self.checkPart(ctl, 13, 2, "46,45");
	self.checkPart(ctl, 14, 1, "5992684592");
	self.checkPart(ctl, 14, 2, "20181148");
	self.checkPart(ctl, 15, 1, "193476");
	self.checkPart(ctl, 15, 2, "36768");
	self.checkPart(ctl, 16, 1, "531");
	self.checkPart(ctl, 16, 2, "649");
	self.checkPart(ctl, 17, 1, "34541");
	self.checkPart(ctl, 17, 2, "28000");
	self.checkPart(ctl, 18, 1, "466125");
	self.checkPart(ctl, 18, 2, "207998");
	self.checkPart(ctl, 19, 1, "930");
	self.checkPart(ctl, 19, 2, "10628484");
	self.checkPart(ctl, 20, 1, "3810");
	self.checkPart(ctl, 20, 2, "8615");
	self.checkPart(ctl, 21, 1, "9258470");
	self.checkPart(ctl, 22, 1, "9659");
	self.checkPart(ctl, 22, 2, "1043");
	self.checkPart(ctl, 23, 1, "933");
	self.checkPart(ctl, 23, 2, "74738656");
	self.checkPart(ctl, 24, 1, "22862");
	self.checkPart(ctl, 24, 2, "3014");
	self.checkPart(ctl, 25, 1, "425");
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
	yr := ctl.yearByNumber[ 2018 ];
	if yr = null then
		ctl.ensureYear( 2018 );
		yr := ctl.yearByNumber[ 2018 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "497" );
	yr.days[ 1 ].addPart( 2, "558" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "6944" );
	yr.days[ 2 ].addPart( 2, "srijafjzloguvlntqmphenbkd" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "112418" );
	yr.days[ 3 ].addPart( 2, "560" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "94040" );
	yr.days[ 4 ].addPart( 2, "39940" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "10638" );
	yr.days[ 5 ].addPart( 2, "4944" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "4143" );
	yr.days[ 6 ].addPart( 2, "35039" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "GKCNPTVHIRYDUJMSXFBQLOAEWZ" );
	yr.days[ 7 ].addPart( 2, "1265" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "41849" );
	yr.days[ 8 ].addPart( 2, "32487" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "394486" );
	yr.days[ 9 ].addPart( 2, "3276488008" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "FNRGPBHR" );
	yr.days[ 10 ].addPart( 2, "10511" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "33,45" );
	yr.days[ 11 ].addPart( 2, "233,116,15" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "2542" );
	yr.days[ 12 ].addPart( 2, "2550000000883" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "5,102" );
	yr.days[ 13 ].addPart( 2, "46,45" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "5992684592" );
	yr.days[ 14 ].addPart( 2, "20181148" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "193476" );
	yr.days[ 15 ].addPart( 2, "36768" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "531" );
	yr.days[ 16 ].addPart( 2, "649" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "34541" );
	yr.days[ 17 ].addPart( 2, "28000" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "466125" );
	yr.days[ 18 ].addPart( 2, "207998" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "930" );
	yr.days[ 19 ].addPart( 2, "10628484" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "3810" );
	yr.days[ 20 ].addPart( 2, "8615" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "9258470" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "9659" );
	yr.days[ 22 ].addPart( 2, "1043" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "933" );
	yr.days[ 23 ].addPart( 2, "74738656" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "22862" );
	yr.days[ 24 ].addPart( 2, "3014" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "425" );
	return "populated 2018: 25 days, 48 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2018();
end;
}
	)
