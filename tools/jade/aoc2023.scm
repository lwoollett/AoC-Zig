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
		run2023(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2023 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2023 missing; ";
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
run2023
{
run2023(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
				self.checkPart(ctl, 1, 1, "56506");
	self.checkPart(ctl, 1, 2, "56017");
	self.checkPart(ctl, 2, 1, "2505");
	self.checkPart(ctl, 2, 2, "70265");
	self.checkPart(ctl, 3, 1, "536202");
	self.checkPart(ctl, 3, 2, "78272573");
	self.checkPart(ctl, 4, 1, "23678");
	self.checkPart(ctl, 4, 2, "15455663");
	self.checkPart(ctl, 5, 1, "313045984");
	self.checkPart(ctl, 5, 2, "20283860");
	self.checkPart(ctl, 6, 1, "170000");
	self.checkPart(ctl, 6, 2, "20537782");
	self.checkPart(ctl, 7, 1, "251121738");
	self.checkPart(ctl, 7, 2, "251421071");
	self.checkPart(ctl, 8, 1, "19637");
	self.checkPart(ctl, 8, 2, "8811050362409");
	self.checkPart(ctl, 9, 1, "1708206096");
	self.checkPart(ctl, 9, 2, "1050");
	self.checkPart(ctl, 10, 1, "6867");
	self.checkPart(ctl, 10, 2, "595");
	self.checkPart(ctl, 11, 1, "10276166");
	self.checkPart(ctl, 11, 2, "598693078798");
	self.checkPart(ctl, 12, 1, "8270");
	self.checkPart(ctl, 12, 2, "204640299929836");
	self.checkPart(ctl, 13, 1, "30158");
	self.checkPart(ctl, 13, 2, "36474");
	self.checkPart(ctl, 14, 1, "112046");
	self.checkPart(ctl, 14, 2, "104639");
	self.checkPart(ctl, 15, 1, "513643");
	self.checkPart(ctl, 15, 2, "265345");
	self.checkPart(ctl, 16, 1, "7939");
	self.checkPart(ctl, 16, 2, "8318");
	self.checkPart(ctl, 17, 1, "742");
	self.checkPart(ctl, 17, 2, "918");
	self.checkPart(ctl, 18, 1, "76387");
	self.checkPart(ctl, 18, 2, "250022188522074");
	self.checkPart(ctl, 19, 1, "332145");
	self.checkPart(ctl, 19, 2, "136661579897555");
	self.checkPart(ctl, 20, 1, "800830848");
	self.checkPart(ctl, 20, 2, "8441522854317");
	self.checkPart(ctl, 21, 1, "264");
	self.checkPart(ctl, 21, 2, "108028463");
	self.checkPart(ctl, 22, 1, "411");
	self.checkPart(ctl, 22, 2, "47671");
	self.checkPart(ctl, 23, 1, "2094");
	self.checkPart(ctl, 23, 2, "6442");
	self.checkPart(ctl, 24, 1, "16172");
	self.checkPart(ctl, 24, 2, "9885155970716517");
	self.checkPart(ctl, 25, 1, "556467");
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
	yr := ctl.yearByNumber[ 2023 ];
	if yr = null then
		ctl.ensureYear( 2023 );
		yr := ctl.yearByNumber[ 2023 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "56506" );
	yr.days[ 1 ].addPart( 2, "56017" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "2505" );
	yr.days[ 2 ].addPart( 2, "70265" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "536202" );
	yr.days[ 3 ].addPart( 2, "78272573" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "23678" );
	yr.days[ 4 ].addPart( 2, "15455663" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "313045984" );
	yr.days[ 5 ].addPart( 2, "20283860" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "170000" );
	yr.days[ 6 ].addPart( 2, "20537782" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "251121738" );
	yr.days[ 7 ].addPart( 2, "251421071" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "19637" );
	yr.days[ 8 ].addPart( 2, "8811050362409" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "1708206096" );
	yr.days[ 9 ].addPart( 2, "1050" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "6867" );
	yr.days[ 10 ].addPart( 2, "595" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "10276166" );
	yr.days[ 11 ].addPart( 2, "598693078798" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "8270" );
	yr.days[ 12 ].addPart( 2, "204640299929836" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "30158" );
	yr.days[ 13 ].addPart( 2, "36474" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "112046" );
	yr.days[ 14 ].addPart( 2, "104639" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "513643" );
	yr.days[ 15 ].addPart( 2, "265345" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "7939" );
	yr.days[ 16 ].addPart( 2, "8318" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "742" );
	yr.days[ 17 ].addPart( 2, "918" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "76387" );
	yr.days[ 18 ].addPart( 2, "250022188522074" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "332145" );
	yr.days[ 19 ].addPart( 2, "136661579897555" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "800830848" );
	yr.days[ 20 ].addPart( 2, "8441522854317" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "264" );
	yr.days[ 21 ].addPart( 2, "108028463" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "411" );
	yr.days[ 22 ].addPart( 2, "47671" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "2094" );
	yr.days[ 23 ].addPart( 2, "6442" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "16172" );
	yr.days[ 24 ].addPart( 2, "9885155970716517" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "556467" );
	return "populated 2023: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2023();
end;
}
	)
