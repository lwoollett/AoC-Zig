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
		run2025(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2025 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2025 missing; ";
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
run2025
{
run2025(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
						self.checkPart(ctl, 1, 1, "995");
	self.checkPart(ctl, 1, 2, "4804");
	self.checkPart(ctl, 2, 1, "28846518423");
	self.checkPart(ctl, 2, 2, "31578210022");
	self.checkPart(ctl, 3, 1, "17359");
	self.checkPart(ctl, 3, 2, "172787336861064");
	self.checkPart(ctl, 4, 1, "1445");
	self.checkPart(ctl, 4, 2, "8317");
	self.checkPart(ctl, 5, 1, "638");
	self.checkPart(ctl, 5, 2, "352946349407338");
	self.checkPart(ctl, 6, 1, "5595593539811");
	self.checkPart(ctl, 6, 2, "10153315705125");
	self.checkPart(ctl, 7, 1, "1619");
	self.checkPart(ctl, 8, 1, "32103");
	self.checkPart(ctl, 9, 1, "4495856007");
	self.checkPart(ctl, 10, 1, "466");
	self.checkPart(ctl, 11, 1, "772");
	self.checkPart(ctl, 12, 1, "454");
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
	yr := ctl.yearByNumber[ 2025 ];
	if yr = null then
		ctl.ensureYear( 2025 );
		yr := ctl.yearByNumber[ 2025 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "995" );
	yr.days[ 1 ].addPart( 2, "4804" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "28846518423" );
	yr.days[ 2 ].addPart( 2, "31578210022" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "17359" );
	yr.days[ 3 ].addPart( 2, "172787336861064" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "1445" );
	yr.days[ 4 ].addPart( 2, "8317" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "638" );
	yr.days[ 5 ].addPart( 2, "352946349407338" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "5595593539811" );
	yr.days[ 6 ].addPart( 2, "10153315705125" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "1619" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "32103" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "4495856007" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "466" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "772" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "454" );
	return "populated 2025: 12 days, 18 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2025();
end;
}
	)
