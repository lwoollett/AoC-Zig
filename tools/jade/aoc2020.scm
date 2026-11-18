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
		run2020(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2020 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2020 missing; ";
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
run2020
{
run2020(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
			self.checkPart(ctl, 1, 1, "842016");
	self.checkPart(ctl, 1, 2, "9199664");
	self.checkPart(ctl, 2, 1, "638");
	self.checkPart(ctl, 2, 2, "699");
	self.checkPart(ctl, 3, 1, "148");
	self.checkPart(ctl, 3, 2, "727923200");
	self.checkPart(ctl, 4, 1, "196");
	self.checkPart(ctl, 4, 2, "114");
	self.checkPart(ctl, 5, 1, "874");
	self.checkPart(ctl, 5, 2, "594");
	self.checkPart(ctl, 6, 1, "6662");
	self.checkPart(ctl, 6, 2, "3382");
	self.checkPart(ctl, 7, 1, "274");
	self.checkPart(ctl, 7, 2, "158730");
	self.checkPart(ctl, 8, 1, "1451");
	self.checkPart(ctl, 8, 2, "1160");
	self.checkPart(ctl, 9, 1, "32321523");
	self.checkPart(ctl, 9, 2, "4794981");
	self.checkPart(ctl, 10, 1, "2272");
	self.checkPart(ctl, 10, 2, "84627647627264");
	self.checkPart(ctl, 11, 1, "2108");
	self.checkPart(ctl, 11, 2, "1897");
	self.checkPart(ctl, 12, 1, "45");
	self.checkPart(ctl, 12, 2, "73521");
	self.checkPart(ctl, 13, 1, "207");
	self.checkPart(ctl, 13, 2, "530015546283687");
	self.checkPart(ctl, 14, 1, "14553106347726");
	self.checkPart(ctl, 14, 2, "2737766154126");
	self.checkPart(ctl, 15, 1, "755");
	self.checkPart(ctl, 15, 2, "11962");
	self.checkPart(ctl, 16, 1, "24021");
	self.checkPart(ctl, 16, 2, "1289178686687");
	self.checkPart(ctl, 17, 1, "336");
	self.checkPart(ctl, 17, 2, "2620");
	self.checkPart(ctl, 18, 1, "30753705453324");
	self.checkPart(ctl, 18, 2, "244817530095503");
	self.checkPart(ctl, 19, 1, "104");
	self.checkPart(ctl, 19, 2, "314");
	self.checkPart(ctl, 20, 1, "29293767579581");
	self.checkPart(ctl, 20, 2, "1989");
	self.checkPart(ctl, 21, 1, "2826");
	self.checkPart(ctl, 21, 2, "pbhthx,sqdsxhb,dgvqv,csnfnl,dnlsjr,xzb,lkdg,rsvlb");
	self.checkPart(ctl, 22, 1, "31781");
	self.checkPart(ctl, 22, 2, "35154");
	self.checkPart(ctl, 23, 1, "47382659");
	self.checkPart(ctl, 23, 2, "42271866720");
	self.checkPart(ctl, 24, 1, "254");
	self.checkPart(ctl, 24, 2, "3697");
	self.checkPart(ctl, 25, 1, "8740494");
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
	yr := ctl.yearByNumber[ 2020 ];
	if yr = null then
		ctl.ensureYear( 2020 );
		yr := ctl.yearByNumber[ 2020 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "842016" );
	yr.days[ 1 ].addPart( 2, "9199664" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "638" );
	yr.days[ 2 ].addPart( 2, "699" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "148" );
	yr.days[ 3 ].addPart( 2, "727923200" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "196" );
	yr.days[ 4 ].addPart( 2, "114" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "874" );
	yr.days[ 5 ].addPart( 2, "594" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "6662" );
	yr.days[ 6 ].addPart( 2, "3382" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "274" );
	yr.days[ 7 ].addPart( 2, "158730" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "1451" );
	yr.days[ 8 ].addPart( 2, "1160" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "32321523" );
	yr.days[ 9 ].addPart( 2, "4794981" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "2272" );
	yr.days[ 10 ].addPart( 2, "84627647627264" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "2108" );
	yr.days[ 11 ].addPart( 2, "1897" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "45" );
	yr.days[ 12 ].addPart( 2, "73521" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "207" );
	yr.days[ 13 ].addPart( 2, "530015546283687" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "14553106347726" );
	yr.days[ 14 ].addPart( 2, "2737766154126" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "755" );
	yr.days[ 15 ].addPart( 2, "11962" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "24021" );
	yr.days[ 16 ].addPart( 2, "1289178686687" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "336" );
	yr.days[ 17 ].addPart( 2, "2620" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "30753705453324" );
	yr.days[ 18 ].addPart( 2, "244817530095503" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "104" );
	yr.days[ 19 ].addPart( 2, "314" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "29293767579581" );
	yr.days[ 20 ].addPart( 2, "1989" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "2826" );
	yr.days[ 21 ].addPart( 2, "pbhthx,sqdsxhb,dgvqv,csnfnl,dnlsjr,xzb,lkdg,rsvlb" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "31781" );
	yr.days[ 22 ].addPart( 2, "35154" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "47382659" );
	yr.days[ 23 ].addPart( 2, "42271866720" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "254" );
	yr.days[ 24 ].addPart( 2, "3697" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "8740494" );
	return "populated 2020: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2020();
end;
}
	)
