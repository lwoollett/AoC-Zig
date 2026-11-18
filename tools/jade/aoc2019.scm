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
		run2019(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2019 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2019 missing; ";
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
run2019
{
run2019(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
		self.checkPart(ctl, 1, 1, "3429947");
	self.checkPart(ctl, 1, 2, "5142043");
	self.checkPart(ctl, 2, 1, "5290681");
	self.checkPart(ctl, 2, 2, "5741");
	self.checkPart(ctl, 3, 1, "5357");
	self.checkPart(ctl, 3, 2, "101956");
	self.checkPart(ctl, 4, 1, "1890");
	self.checkPart(ctl, 4, 2, "1277");
	self.checkPart(ctl, 5, 1, "7988899");
	self.checkPart(ctl, 5, 2, "13758663");
	self.checkPart(ctl, 6, 1, "151345");
	self.checkPart(ctl, 6, 2, "391");
	self.checkPart(ctl, 7, 1, "298586");
	self.checkPart(ctl, 7, 2, "9246095");
	self.checkPart(ctl, 8, 1, "1742");
	self.checkPart(ctl, 8, 2, "GJYEA");
	self.checkPart(ctl, 9, 1, "3989758265");
	self.checkPart(ctl, 9, 2, "76791");
	self.checkPart(ctl, 10, 1, "284");
	self.checkPart(ctl, 10, 2, "404");
	self.checkPart(ctl, 11, 1, "2172");
	self.checkPart(ctl, 11, 2, "CELEFGHP");
	self.checkPart(ctl, 12, 1, "8310");
	self.checkPart(ctl, 12, 2, "319290382980408");
	self.checkPart(ctl, 13, 1, "298");
	self.checkPart(ctl, 13, 2, "13956");
	self.checkPart(ctl, 14, 1, "870051");
	self.checkPart(ctl, 14, 2, "1863741");
	self.checkPart(ctl, 15, 1, "300");
	self.checkPart(ctl, 15, 2, "312");
	self.checkPart(ctl, 16, 1, "84487724");
	self.checkPart(ctl, 16, 2, "84692524");
	self.checkPart(ctl, 17, 1, "14332");
	self.checkPart(ctl, 17, 2, "1034009");
	self.checkPart(ctl, 18, 1, "4042");
	self.checkPart(ctl, 18, 2, "2014");
	self.checkPart(ctl, 19, 1, "138");
	self.checkPart(ctl, 19, 2, "13530764");
	self.checkPart(ctl, 20, 1, "580");
	self.checkPart(ctl, 20, 2, "6362");
	self.checkPart(ctl, 21, 1, "19353074");
	self.checkPart(ctl, 21, 2, "1147582556");
	self.checkPart(ctl, 22, 1, "6129");
	self.checkPart(ctl, 22, 2, "71345377301237");
	self.checkPart(ctl, 23, 1, "15416");
	self.checkPart(ctl, 23, 2, "10946");
	self.checkPart(ctl, 24, 1, "17321586");
	self.checkPart(ctl, 24, 2, "1957");
	self.checkPart(ctl, 25, 1, "25165890");
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
	yr := ctl.yearByNumber[ 2019 ];
	if yr = null then
		ctl.ensureYear( 2019 );
		yr := ctl.yearByNumber[ 2019 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "3429947" );
	yr.days[ 1 ].addPart( 2, "5142043" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "5290681" );
	yr.days[ 2 ].addPart( 2, "5741" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "5357" );
	yr.days[ 3 ].addPart( 2, "101956" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "1890" );
	yr.days[ 4 ].addPart( 2, "1277" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "7988899" );
	yr.days[ 5 ].addPart( 2, "13758663" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "151345" );
	yr.days[ 6 ].addPart( 2, "391" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "298586" );
	yr.days[ 7 ].addPart( 2, "9246095" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "1742" );
	yr.days[ 8 ].addPart( 2, "GJYEA" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "3989758265" );
	yr.days[ 9 ].addPart( 2, "76791" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "284" );
	yr.days[ 10 ].addPart( 2, "404" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "2172" );
	yr.days[ 11 ].addPart( 2, "CELEFGHP" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "8310" );
	yr.days[ 12 ].addPart( 2, "319290382980408" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "298" );
	yr.days[ 13 ].addPart( 2, "13956" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "870051" );
	yr.days[ 14 ].addPart( 2, "1863741" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "300" );
	yr.days[ 15 ].addPart( 2, "312" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "84487724" );
	yr.days[ 16 ].addPart( 2, "84692524" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "14332" );
	yr.days[ 17 ].addPart( 2, "1034009" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "4042" );
	yr.days[ 18 ].addPart( 2, "2014" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "138" );
	yr.days[ 19 ].addPart( 2, "13530764" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "580" );
	yr.days[ 20 ].addPart( 2, "6362" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "19353074" );
	yr.days[ 21 ].addPart( 2, "1147582556" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "6129" );
	yr.days[ 22 ].addPart( 2, "71345377301237" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "15416" );
	yr.days[ 23 ].addPart( 2, "10946" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "17321586" );
	yr.days[ 24 ].addPart( 2, "1957" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "25165890" );
	return "populated 2019: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2019();
end;
}
	)
