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
		run2024(): StringUtf8;
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
	yr := ctl.yearByNumber[ 2024 ];
	if yr = null then
		self.failed += 1;
		self.failLog := self.failLog & "year 2024 missing; ";
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
run2024
{
run2024(): StringUtf8;

vars
	ctl: AocController;

begin
	ctl := AocController.firstInstance;
	if ctl = null then
		return "no data — run JadeScript.populateData first";
	endif;
					self.checkPart(ctl, 1, 1, "2031679");
	self.checkPart(ctl, 1, 2, "19678534");
	self.checkPart(ctl, 2, 1, "660");
	self.checkPart(ctl, 2, 2, "689");
	self.checkPart(ctl, 3, 1, "170068701");
	self.checkPart(ctl, 3, 2, "78683433");
	self.checkPart(ctl, 4, 1, "2530");
	self.checkPart(ctl, 4, 2, "1921");
	self.checkPart(ctl, 5, 1, "5732");
	self.checkPart(ctl, 5, 2, "4716");
	self.checkPart(ctl, 6, 1, "4696");
	self.checkPart(ctl, 6, 2, "1443");
	self.checkPart(ctl, 7, 1, "6083020304036");
	self.checkPart(ctl, 7, 2, "59002246504791");
	self.checkPart(ctl, 8, 1, "261");
	self.checkPart(ctl, 8, 2, "898");
	self.checkPart(ctl, 9, 1, "6463499258318");
	self.checkPart(ctl, 9, 2, "6493634986625");
	self.checkPart(ctl, 10, 1, "582");
	self.checkPart(ctl, 10, 2, "1302");
	self.checkPart(ctl, 11, 1, "183435");
	self.checkPart(ctl, 11, 2, "218279375708592");
	self.checkPart(ctl, 12, 1, "1573474");
	self.checkPart(ctl, 12, 2, "966476");
	self.checkPart(ctl, 13, 1, "37297");
	self.checkPart(ctl, 13, 2, "83197086729371");
	self.checkPart(ctl, 14, 1, "230900224");
	self.checkPart(ctl, 14, 2, "4512");
	self.checkPart(ctl, 15, 1, "1406392");
	self.checkPart(ctl, 15, 2, "973568");
	self.checkPart(ctl, 16, 1, "108504");
	self.checkPart(ctl, 16, 2, "538");
	self.checkPart(ctl, 17, 1, "2,1,4,0,7,4,0,2,3");
	self.checkPart(ctl, 17, 2, "258394985014171");
	self.checkPart(ctl, 18, 1, "338");
	self.checkPart(ctl, 18, 2, "20,44");
	self.checkPart(ctl, 19, 1, "290");
	self.checkPart(ctl, 19, 2, "712058625427487");
	self.checkPart(ctl, 20, 1, "1487");
	self.checkPart(ctl, 20, 2, "1115193");
	self.checkPart(ctl, 21, 1, "465490");
	self.checkPart(ctl, 21, 2, "303579478413311");
	self.checkPart(ctl, 22, 1, "17005483322");
	self.checkPart(ctl, 22, 2, "1910");
	self.checkPart(ctl, 23, 1, "1194");
	self.checkPart(ctl, 23, 2, "bd,bu,dv,gl,qc,rn,so,tm,wf,yl,ys,ze,zr");
	self.checkPart(ctl, 24, 1, "49520947122770");
	self.checkPart(ctl, 24, 2, "ffg,gjc,qjj,qsb,vfk,wmp,z26,z39");
	self.checkPart(ctl, 25, 1, "3451");
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
	yr := ctl.yearByNumber[ 2024 ];
	if yr = null then
		ctl.ensureYear( 2024 );
		yr := ctl.yearByNumber[ 2024 ];
	endif;
	yr.ensureDay( 1 );
	yr.days[ 1 ].addPart( 1, "2031679" );
	yr.days[ 1 ].addPart( 2, "19678534" );
	yr.ensureDay( 2 );
	yr.days[ 2 ].addPart( 1, "660" );
	yr.days[ 2 ].addPart( 2, "689" );
	yr.ensureDay( 3 );
	yr.days[ 3 ].addPart( 1, "170068701" );
	yr.days[ 3 ].addPart( 2, "78683433" );
	yr.ensureDay( 4 );
	yr.days[ 4 ].addPart( 1, "2530" );
	yr.days[ 4 ].addPart( 2, "1921" );
	yr.ensureDay( 5 );
	yr.days[ 5 ].addPart( 1, "5732" );
	yr.days[ 5 ].addPart( 2, "4716" );
	yr.ensureDay( 6 );
	yr.days[ 6 ].addPart( 1, "4696" );
	yr.days[ 6 ].addPart( 2, "1443" );
	yr.ensureDay( 7 );
	yr.days[ 7 ].addPart( 1, "6083020304036" );
	yr.days[ 7 ].addPart( 2, "59002246504791" );
	yr.ensureDay( 8 );
	yr.days[ 8 ].addPart( 1, "261" );
	yr.days[ 8 ].addPart( 2, "898" );
	yr.ensureDay( 9 );
	yr.days[ 9 ].addPart( 1, "6463499258318" );
	yr.days[ 9 ].addPart( 2, "6493634986625" );
	yr.ensureDay( 10 );
	yr.days[ 10 ].addPart( 1, "582" );
	yr.days[ 10 ].addPart( 2, "1302" );
	yr.ensureDay( 11 );
	yr.days[ 11 ].addPart( 1, "183435" );
	yr.days[ 11 ].addPart( 2, "218279375708592" );
	yr.ensureDay( 12 );
	yr.days[ 12 ].addPart( 1, "1573474" );
	yr.days[ 12 ].addPart( 2, "966476" );
	yr.ensureDay( 13 );
	yr.days[ 13 ].addPart( 1, "37297" );
	yr.days[ 13 ].addPart( 2, "83197086729371" );
	yr.ensureDay( 14 );
	yr.days[ 14 ].addPart( 1, "230900224" );
	yr.days[ 14 ].addPart( 2, "4512" );
	yr.ensureDay( 15 );
	yr.days[ 15 ].addPart( 1, "1406392" );
	yr.days[ 15 ].addPart( 2, "973568" );
	yr.ensureDay( 16 );
	yr.days[ 16 ].addPart( 1, "108504" );
	yr.days[ 16 ].addPart( 2, "538" );
	yr.ensureDay( 17 );
	yr.days[ 17 ].addPart( 1, "2,1,4,0,7,4,0,2,3" );
	yr.days[ 17 ].addPart( 2, "258394985014171" );
	yr.ensureDay( 18 );
	yr.days[ 18 ].addPart( 1, "338" );
	yr.days[ 18 ].addPart( 2, "20,44" );
	yr.ensureDay( 19 );
	yr.days[ 19 ].addPart( 1, "290" );
	yr.days[ 19 ].addPart( 2, "712058625427487" );
	yr.ensureDay( 20 );
	yr.days[ 20 ].addPart( 1, "1487" );
	yr.days[ 20 ].addPart( 2, "1115193" );
	yr.ensureDay( 21 );
	yr.days[ 21 ].addPart( 1, "465490" );
	yr.days[ 21 ].addPart( 2, "303579478413311" );
	yr.ensureDay( 22 );
	yr.days[ 22 ].addPart( 1, "17005483322" );
	yr.days[ 22 ].addPart( 2, "1910" );
	yr.ensureDay( 23 );
	yr.days[ 23 ].addPart( 1, "1194" );
	yr.days[ 23 ].addPart( 2, "bd,bu,dv,gl,qc,rn,so,tm,wf,yl,ys,ze,zr" );
	yr.ensureDay( 24 );
	yr.days[ 24 ].addPart( 1, "49520947122770" );
	yr.days[ 24 ].addPart( 2, "ffg,gjc,qjj,qsb,vfk,wmp,z26,z39" );
	yr.ensureDay( 25 );
	yr.days[ 25 ].addPart( 1, "3451" );
	return "populated 2024: 25 days, 49 parts";
end;
}
runTests
{
runTests(): StringUtf8;

vars
	tests: AnswerTests;

begin
	create tests transient;
	return tests.run2024();
end;
}
	)
