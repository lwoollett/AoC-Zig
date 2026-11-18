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
		run2021(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2021 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2021 missing; ";
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
run2021
{
run2021(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
			self.checkPart(ctl, 1, 1, "1559");
	self.checkPart(ctl, 1, 2, "1600");
	self.checkPart(ctl, 2, 1, "2117664");
	self.checkPart(ctl, 2, 2, "2073416724");
	self.checkPart(ctl, 3, 1, "1997414");
	self.checkPart(ctl, 3, 2, "1032597");
	self.checkPart(ctl, 4, 1, "63424");
	self.checkPart(ctl, 4, 2, "23541");
	self.checkPart(ctl, 5, 1, "7436");
	self.checkPart(ctl, 5, 2, "21104");
	self.checkPart(ctl, 6, 1, "377263");
	self.checkPart(ctl, 6, 2, "1695929023803");
	self.checkPart(ctl, 7, 1, "335330");
	self.checkPart(ctl, 7, 2, "92439766");
	self.checkPart(ctl, 8, 1, "342");
	self.checkPart(ctl, 8, 2, "1068933");
	self.checkPart(ctl, 9, 1, "631");
	self.checkPart(ctl, 9, 2, "821560");
	self.checkPart(ctl, 10, 1, "319233");
	self.checkPart(ctl, 10, 2, "1118976874");
	self.checkPart(ctl, 11, 1, "1599");
	self.checkPart(ctl, 11, 2, "418");
	self.checkPart(ctl, 12, 1, "3298");
	self.checkPart(ctl, 12, 2, "93572");
	self.checkPart(ctl, 13, 1, "743");
	self.checkPart(ctl, 13, 2, "RCPLAKHL");
	self.checkPart(ctl, 14, 1, "2975");
	self.checkPart(ctl, 14, 2, "3015383850689");
	self.checkPart(ctl, 15, 1, "824");
	self.checkPart(ctl, 15, 2, "3063");
	self.checkPart(ctl, 16, 1, "993");
	self.checkPart(ctl, 16, 2, "144595909277");
	self.checkPart(ctl, 17, 1, "9730");
	self.checkPart(ctl, 17, 2, "4110");
	self.checkPart(ctl, 18, 1, "16155");
	self.checkPart(ctl, 18, 2, "14365");
	self.checkPart(ctl, 19, 1, "445");
	self.checkPart(ctl, 19, 2, "13225");
	self.checkPart(ctl, 20, 1, "5291");
	self.checkPart(ctl, 20, 2, "16665");
	self.checkPart(ctl, 21, 1, "597600");
	self.checkPart(ctl, 21, 2, "634769613696613");
	self.checkPart(ctl, 22, 1, "580012");
	self.checkPart(ctl, 22, 2, "1334238660555542");
	self.checkPart(ctl, 23, 1, "18051");
	self.checkPart(ctl, 23, 2, "50245");
	self.checkPart(ctl, 24, 1, "39494195799979");
	self.checkPart(ctl, 24, 2, "13161151139617");
	self.checkPart(ctl, 25, 1, "486");
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
	yr := ctl.yearByNumber[ 2021 ];
	if yr = null then
		ctl.ensureYear( 2021 );
		yr := ctl.yearByNumber[ 2021 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "1559" );
	yr.days[ 1 ].addPart( 2, "1600" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "2117664" );
	yr.days[ 2 ].addPart( 2, "2073416724" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "1997414" );
	yr.days[ 3 ].addPart( 2, "1032597" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "63424" );
	yr.days[ 4 ].addPart( 2, "23541" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "7436" );
	yr.days[ 5 ].addPart( 2, "21104" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "377263" );
	yr.days[ 6 ].addPart( 2, "1695929023803" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "335330" );
	yr.days[ 7 ].addPart( 2, "92439766" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "342" );
	yr.days[ 8 ].addPart( 2, "1068933" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "631" );
	yr.days[ 9 ].addPart( 2, "821560" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "319233" );
	yr.days[ 10 ].addPart( 2, "1118976874" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "1599" );
	yr.days[ 11 ].addPart( 2, "418" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "3298" );
	yr.days[ 12 ].addPart( 2, "93572" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "743" );
	yr.days[ 13 ].addPart( 2, "RCPLAKHL" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "2975" );
	yr.days[ 14 ].addPart( 2, "3015383850689" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "824" );
	yr.days[ 15 ].addPart( 2, "3063" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "993" );
	yr.days[ 16 ].addPart( 2, "144595909277" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "9730" );
	yr.days[ 17 ].addPart( 2, "4110" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "16155" );
	yr.days[ 18 ].addPart( 2, "14365" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "445" );
	yr.days[ 19 ].addPart( 2, "13225" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "5291" );
	yr.days[ 20 ].addPart( 2, "16665" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "597600" );
	yr.days[ 21 ].addPart( 2, "634769613696613" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "580012" );
	yr.days[ 22 ].addPart( 2, "1334238660555542" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "18051" );
	yr.days[ 23 ].addPart( 2, "50245" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "39494195799979" );
	yr.days[ 24 ].addPart( 2, "13161151139617" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "486" );
	return "populated 2021: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2021();
end;
}
	)
