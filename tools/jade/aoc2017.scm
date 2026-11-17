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
		run2017(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2017 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2017 missing; ";
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
run2017
{
run2017(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
	self.checkPart(ctl, 1, 1, "1119");
	self.checkPart(ctl, 1, 2, "1420");
	self.checkPart(ctl, 2, 1, "46402");
	self.checkPart(ctl, 2, 2, "265");
	self.checkPart(ctl, 3, 1, "552");
	self.checkPart(ctl, 3, 2, "341823");
	self.checkPart(ctl, 4, 1, "337");
	self.checkPart(ctl, 4, 2, "231");
	self.checkPart(ctl, 5, 1, "396086");
	self.checkPart(ctl, 5, 2, "28675390");
	self.checkPart(ctl, 6, 1, "14029");
	self.checkPart(ctl, 6, 2, "2765");
	self.checkPart(ctl, 7, 1, "cqmvs");
	self.checkPart(ctl, 7, 2, "2310");
	self.checkPart(ctl, 8, 1, "4832");
	self.checkPart(ctl, 8, 2, "5443");
	self.checkPart(ctl, 9, 1, "14212");
	self.checkPart(ctl, 9, 2, "6569");
	self.checkPart(ctl, 10, 1, "38628");
	self.checkPart(ctl, 10, 2, "e1462100a34221a7f0906da15c1c979a");
	self.checkPart(ctl, 11, 1, "759");
	self.checkPart(ctl, 11, 2, "1501");
	self.checkPart(ctl, 12, 1, "152");
	self.checkPart(ctl, 12, 2, "186");
	self.checkPart(ctl, 13, 1, "2264");
	self.checkPart(ctl, 13, 2, "3875838");
	self.checkPart(ctl, 14, 1, "8304");
	self.checkPart(ctl, 14, 2, "1018");
	self.checkPart(ctl, 15, 1, "597");
	self.checkPart(ctl, 15, 2, "303");
	self.checkPart(ctl, 16, 1, "giadhmkpcnbfjelo");
	self.checkPart(ctl, 16, 2, "njfgilbkcoemhpad");
	self.checkPart(ctl, 17, 1, "1306");
	self.checkPart(ctl, 17, 2, "20430489");
	self.checkPart(ctl, 18, 1, "4601");
	self.checkPart(ctl, 18, 2, "6858");
	self.checkPart(ctl, 19, 1, "LOHMDQATP");
	self.checkPart(ctl, 19, 2, "16492");
	self.checkPart(ctl, 20, 1, "125");
	self.checkPart(ctl, 20, 2, "461");
	self.checkPart(ctl, 21, 1, "158");
	self.checkPart(ctl, 21, 2, "2301762");
	self.checkPart(ctl, 22, 1, "5570");
	self.checkPart(ctl, 22, 2, "2512022");
	self.checkPart(ctl, 23, 1, "9409");
	self.checkPart(ctl, 23, 2, "913");
	self.checkPart(ctl, 24, 1, "1511");
	self.checkPart(ctl, 24, 2, "1471");
	self.checkPart(ctl, 25, 1, "4225");
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
	yr := ctl.yearByNumber[ 2017 ];
	if yr = null then
		ctl.ensureYear( 2017 );
		yr := ctl.yearByNumber[ 2017 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "1119" );
	yr.days[ 1 ].addPart( 2, "1420" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "46402" );
	yr.days[ 2 ].addPart( 2, "265" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "552" );
	yr.days[ 3 ].addPart( 2, "341823" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "337" );
	yr.days[ 4 ].addPart( 2, "231" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "396086" );
	yr.days[ 5 ].addPart( 2, "28675390" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "14029" );
	yr.days[ 6 ].addPart( 2, "2765" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "cqmvs" );
	yr.days[ 7 ].addPart( 2, "2310" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "4832" );
	yr.days[ 8 ].addPart( 2, "5443" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "14212" );
	yr.days[ 9 ].addPart( 2, "6569" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "38628" );
	yr.days[ 10 ].addPart( 2, "e1462100a34221a7f0906da15c1c979a" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "759" );
	yr.days[ 11 ].addPart( 2, "1501" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "152" );
	yr.days[ 12 ].addPart( 2, "186" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "2264" );
	yr.days[ 13 ].addPart( 2, "3875838" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "8304" );
	yr.days[ 14 ].addPart( 2, "1018" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "597" );
	yr.days[ 15 ].addPart( 2, "303" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "giadhmkpcnbfjelo" );
	yr.days[ 16 ].addPart( 2, "njfgilbkcoemhpad" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "1306" );
	yr.days[ 17 ].addPart( 2, "20430489" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "4601" );
	yr.days[ 18 ].addPart( 2, "6858" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "LOHMDQATP" );
	yr.days[ 19 ].addPart( 2, "16492" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "125" );
	yr.days[ 20 ].addPart( 2, "461" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "158" );
	yr.days[ 21 ].addPart( 2, "2301762" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "5570" );
	yr.days[ 22 ].addPart( 2, "2512022" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "9409" );
	yr.days[ 23 ].addPart( 2, "913" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "1511" );
	yr.days[ 24 ].addPart( 2, "1471" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "4225" );
	return "populated 2017: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2017();
end;
}
	)
