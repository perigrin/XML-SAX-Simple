use strict;
use IO::File;
use Test::More tests => 189;
use Test::Deep;
$|++;

##############################################################################
# Read file and return contents as a scalar.
#

sub ReadFile {
  local($/) = undef;

  open(_READ_FILE_, $_[0]) || die "open($_[0]): $!";
  my $data = <_READ_FILE_>;
  close(_READ_FILE_);
  return($data);
}

use XML::SAX::Simple;

# Try encoding a scalar value

my $xml = XMLout("scalar");
ok(1);                             # XMLout did not crash 
ok(defined($xml));                 # and it returned an XML string
ok(XMLin($xml), 'scalar');         # which parses back OK


# Next try encoding a hash

my $hashref1 = { one => 1, two => 'II', three => '...' };
my $hashref2 = { one => 1, two => 'II', three => '...' };

# Expect:
# <opt one="1" two="II" three="..." />

$_ = XMLout($hashref1);               # Encode to $_ for convenience
                                      # Confirm it parses back OK
(is_deeply($hashref1, XMLin($_)));
ok(s/one="1"//);                   # first key encoded OK
ok(s/two="II"//);                  # second key encoded OK
ok(s/three="..."//);               # third key encoded OK
ok(/^<\w+\s+\/>/);                 # no other attributes encoded


# Now try encoding a hash with a nested array

my $ref = {array => [qw(one two three)]};
# Expect:
# <opt>
#   <array>one</array>
#   <array>two</array>
#   <array>three</array>
# </opt>

$_ = XMLout($ref);                    # Encode to $_ for convenience
(is_deeply($ref, XMLin($_)));
ok(s{<array>one</array>\s*
         <array>two</array>\s*
         <array>three</array>}{}sx);  # array elements encoded in correct order
ok(/^<(\w+)\s*>\s*<\/\1>\s*$/s);  # no other spurious encodings


# Now try encoding a nested hash

$ref = { value => '555 1234',
         hash1 => { one => 1 },
         hash2 => { two => 2 } };
# Expect:
# <opt value="555 1234">
#   <hash1 one="1" />
#   <hash2 two="2" />
# </opt>

$_ = XMLout($ref);
(is_deeply($ref, XMLin($_))); # Parses back OK

ok(s{<hash1 one="1" />\s*}{}s);
ok(s{<hash2 two="2" />\s*}{}s);
ok(m{^<(\w+)\s+value="555 1234"\s*>\s*</\1>\s*$}s);


# Now try encoding an anonymous array

$ref = [ qw(1 two III) ];
# Expect:
# <opt>
#   <anon>1</anon>
#   <anon>two</anon>
#   <anon>III</anon>
# </opt>

$_ = XMLout($ref);
(is_deeply($ref, XMLin($_))); # Parses back OK

ok(s{<anon>1</anon>\s*}{}s);
ok(s{<anon>two</anon>\s*}{}s);
ok(s{<anon>III</anon>\s*}{}s);
ok(m{^<(\w+)\s*>\s*</\1>\s*$}s);


# Now try encoding a nested anonymous array

$ref = [ [ qw(1.1 1.2) ], [ qw(2.1 2.2) ] ];
# Expect:
# <opt>
#   <anon>
#     <anon>1.1</anon>
#     <anon>1.2</anon>
#   </anon>
#   <anon>
#     <anon>2.1</anon>
#     <anon>2.2</anon>
#   </anon>
# </opt>

$_ = XMLout($ref);
(is_deeply($ref, XMLin($_))); # Parses back OK

ok(s{<anon>1\.1</anon>\s*}{row}s);
ok(s{<anon>1\.2</anon>\s*}{ one}s);
ok(s{<anon>2\.1</anon>\s*}{row}s);
ok(s{<anon>2\.2</anon>\s*}{ two}s);
ok(s{<anon>\s*row one\s*</anon>\s*}{}s);
ok(s{<anon>\s*row two\s*</anon>\s*}{}s);
ok(m{^<(\w+)\s*>\s*</\1>\s*$}s);


# Now try encoding a hash of hashes with key folding disabled

$ref = { country => {
		      England => { capital => 'London' },
		      France  => { capital => 'Paris' },
		      Turkey  => { capital => 'Istanbul' },
                    }
       };
# Expect:
# <opt>
#   <country>
#     <England capital="London" />
#     <France capital="Paris" />
#     <Turkey capital="Istanbul" />
#   </country>
# </opt>

$_ = XMLout($ref, keyattr => []);
(is_deeply($ref, XMLin($_))); # Parses back OK
ok(s{<England\s+capital="London"\s*/>\s*}{}s);
ok(s{<France\s+capital="Paris"\s*/>\s*}{}s);
ok(s{<Turkey\s+capital="Istanbul"\s*/>\s*}{}s);
ok(s{<country\s*>\s*</country>}{}s);
ok(s{^<(\w+)\s*>\s*</\1>$}{}s);


# Try encoding same again with key folding set to non-standard value

# Expect:
# <opt>
#   <country fullname="England" capital="London" />
#   <country fullname="France" capital="Paris" />
#   <country fullname="Turkey" capital="Istanbul" />
# </opt>

$_ = XMLout($ref, keyattr => ['fullname']);
$xml = $_;
(is_deeply($ref,
                   XMLin($_, keyattr => ['fullname']))); # Parses back OK
ok(s{\s*fullname="England"}{uk}s);
ok(s{\s*capital="London"}{uk}s);
ok(s{\s*fullname="France"}{fr}s);
ok(s{\s*capital="Paris"}{fr}s);
ok(s{\s*fullname="Turkey"}{tk}s);
ok(s{\s*capital="Istanbul"}{tk}s);
ok(s{<countryukuk\s*/>\s*}{}s);
ok(s{<countryfrfr\s*/>\s*}{}s);
ok(s{<countrytktk\s*/>\s*}{}s);
ok(s{^<(\w+)\s*>\s*</\1>$}{}s);

# Same again but specify name as scalar rather than array

$_ = XMLout($ref, keyattr => 'fullname');
ok($_ eq $xml);                            # Same result as last time


# Same again but specify keyattr as hash rather than array

$_ = XMLout($ref, keyattr => { country => 'fullname' });
ok($_ eq $xml);                            # Same result as last time


# Same again but add leading '+'

$_ = XMLout($ref, keyattr => { country => '+fullname' });
ok($_ eq $xml);                            # Same result as last time


# and leading '-'

$_ = XMLout($ref, keyattr => { country => '-fullname' });
ok($_ eq $xml);                            # Same result as last time


# One more time but with default key folding values

# Expect:
# <opt>
#   <country name="England" capital="London" />
#   <country name="France" capital="Paris" />
#   <country name="Turkey" capital="Istanbul" />
# </opt>

$_ = XMLout($ref);
(is_deeply($ref, XMLin($_))); # Parses back OK
ok(s{\s*name="England"}{uk}s);
ok(s{\s*capital="London"}{uk}s);
ok(s{\s*name="France"}{fr}s);
ok(s{\s*capital="Paris"}{fr}s);
ok(s{\s*name="Turkey"}{tk}s);
ok(s{\s*capital="Istanbul"}{tk}s);
ok(s{<countryukuk\s*/>\s*}{}s);
ok(s{<countryfrfr\s*/>\s*}{}s);
ok(s{<countrytktk\s*/>\s*}{}s);
ok(s{^<(\w+)\s*>\s*</\1>$}{}s);


# Finally, confirm folding still works with only one nested hash

# Expect:
# <opt>
#   <country name="England" capital="London" />
# </opt>

$ref = { country => { England => { capital => 'London' } } };
$_ = XMLout($ref);
(is_deeply($ref, XMLin($_, forcearray => 1))); # Parses back OK
ok(s{\s*name="England"}{uk}s);
ok(s{\s*capital="London"}{uk}s);
ok(s{<countryukuk\s*/>\s*}{}s);
#print STDERR "\n$_\n";
ok(s{^<(\w+)\s*>\s*</\1>$}{}s);


# Check that default XML declaration works
#
# Expect:
# <?xml version='1' standalone='yes'?>
# <opt one="1" />

$ref = { one => 1 };

$_ = XMLout($ref, xmldecl => 1);
(is_deeply($ref, XMLin($_))); # Parses back OK
ok(s{^\Q<?xml version='1.0' standalone='yes'?>\E}{}s);
ok(s{<opt one="1" />}{}s);
ok(m{^\s*$}s);


# Check that custom XML declaration works
#
# Expect:
# <?xml version='1' encoding='ISO-8859-1'?>
# <opt one="1" />

$_ = XMLout($ref, xmldecl => "<?xml version='1.0' encoding='US-ASCII'?>");
(is_deeply($ref, XMLin($_))); # Parses back OK
ok(s{^\Q<?xml version='1.0' encoding='US-ASCII'?>\E}{}s);
ok(s{<opt one="1" />}{}s);
ok(m{^\s*$}s);


# Check that special characters do get escaped

$ref = { a => '<A>', b => '"B"', c => '&C&' };
$_ = XMLout($ref);
(is_deeply($ref, XMLin($_))); # Parses back OK
ok(s{a="&lt;A&gt;"}{}s);
ok(s{b="&quot;B&quot;"}{}s);
ok(s{c="&amp;C&amp;"}{}s);
ok(s{^<(\w+)\s*/>$}{}s);


# unless we turn escaping off

$_ = XMLout($ref, noescape => 1);
ok(s{a="<A>"}{}s);
ok(s{b=""B""}{}s);
ok(s{c="&C&"}{}s);
ok(s{^<(\w+)\s*/>$}{}s);


# Try encoding a recursive data structure and confirm that it fails

$_ = eval {
  my $ref = { a => '1' };
  $ref->{b} = $ref;
  XMLout($ref);
};
ok(!defined($_));
like($@, qr/circular data structures not supported/);


# Try encoding a blessed reference and confirm that it fails

$_ = eval { my $ref = new IO::File; XMLout($ref) };
ok(!defined($_));
ok($@ =~ /Can't encode a value of type: /);


# Repeat some of the above tests with named root element

# Try encoding a scalar value

$xml = XMLout("scalar", rootname => 'TOM');
ok(defined($xml));                 # and it returned an XML string
ok(XMLin($xml), 'scalar');         # which parses back OK
                                       # and contains the expected data
ok($xml =~ /^\s*<TOM>scalar<\/TOM>\s*$/si);


# Next try encoding a hash

# Expect:
# <DICK one="1" two="II" three="..." />

$_ = XMLout($hashref1, rootname => 'DICK');
                                      # Confirm it parses back OK
(is_deeply($hashref1, XMLin($_)));
ok(s/one="1"//);                  # first key encoded OK
ok(s/two="II"//);                 # second key encoded OK
ok(s/three="..."//);              # third key encoded OK
ok(/^<DICK\s+\/>/);               # only expected root element left


# Now try encoding a hash with a nested array

$ref = {array => [qw(one two three)]};
# Expect:
# <LARRY>
#   <array>one</array>
#   <array>two</array>
#   <array>three</array>
# </LARRY>

$_ = XMLout($ref, rootname => 'LARRY'); # Encode to $_ for convenience
(is_deeply($ref, XMLin($_)));
ok(s{<array>one</array>\s*
         <array>two</array>\s*
         <array>three</array>}{}sx);    # array encoded in correct order
ok(/^<(LARRY)\s*>\s*<\/\1>\s*$/s);  # only expected root element left


# Now try encoding a nested hash

$ref = { value => '555 1234',
         hash1 => { one => 1 },
         hash2 => { two => 2 } };
# Expect:
# <CURLY value="555 1234">
#   <hash1 one="1" />
#   <hash2 two="2" />
# </CURLY>

$_ = XMLout($ref, rootname => 'CURLY');
(is_deeply($ref, XMLin($_))); # Parses back OK

ok(s{<hash1 one="1" />\s*}{}s);
ok(s{<hash2 two="2" />\s*}{}s);
ok(m{^<(CURLY)\s+value="555 1234"\s*>\s*</\1>\s*$}s);


# Now try encoding an anonymous array

$ref = [ qw(1 two III) ];
# Expect:
# <MOE>
#   <anon>1</anon>
#   <anon>two</anon>
#   <anon>III</anon>
# </MOE>

$_ = XMLout($ref, rootname => 'MOE');
(is_deeply($ref, XMLin($_))); # Parses back OK

ok(s{<anon>1</anon>\s*}{}s);
ok(s{<anon>two</anon>\s*}{}s);
ok(s{<anon>III</anon>\s*}{}s);
ok(m{^<(MOE)\s*>\s*</\1>\s*$}s);


# Test again, this time with no root element

# Try encoding a scalar value

ok(XMLout("scalar", rootname => '')    =~ /scalar\s+/s);
ok(XMLout("scalar", rootname => undef) =~ /scalar\s+/s);


# Next try encoding a hash

# Expect:
#   <one>1</one>
#   <two>II</two>
#   <three>...</three>

$_ = XMLout($hashref1, rootname => '');
                                      # Confirm it parses back OK
(is_deeply($hashref1, XMLin("<opt>$_</opt>")));
ok(s/<one>1<\/one>//);            # first key encoded OK
ok(s/<two>II<\/two>//);           # second key encoded OK
ok(s/<three>...<\/three>//);      # third key encoded OK
ok(/^\s*$/);                      # nothing else left


# Now try encoding a nested hash

$ref = { value => '555 1234',
         hash1 => { one => 1 },
         hash2 => { two => 2 } };
# Expect:
#   <value>555 1234</value>
#   <hash1 one="1" />
#   <hash2 two="2" />

$_ = XMLout($ref, rootname => '');
(is_deeply($ref, XMLin("<opt>$_</opt>"))); # Parses back OK
ok(s{<value>555 1234<\/value>\s*}{}s);
ok(s{<hash1 one="1" />\s*}{}s);
ok(s{<hash2 two="2" />\s*}{}s);
ok(m{^\s*$}s);


# Now try encoding an anonymous array

$ref = [ qw(1 two III) ];
# Expect:
#   <anon>1</anon>
#   <anon>two</anon>
#   <anon>III</anon>

$_ = XMLout($ref, rootname => '');
(is_deeply($ref, XMLin("<opt>$_</opt>"))); # Parses back OK

ok(s{<anon>1</anon>\s*}{}s);
ok(s{<anon>two</anon>\s*}{}s);
ok(s{<anon>III</anon>\s*}{}s);
ok(m{^\s*$}s);


# Test option error handling

$_ = eval { XMLout($hashref1, searchpath => []) }; # only valid for XMLin()
ok(!defined($_));
ok($@ =~ /Unrecognised option:/);

$_ = eval { XMLout($hashref1, 'bogus') };
ok(!defined($_));
ok($@ =~ /Options must be name=>value pairs .odd number supplied./);


# Test output to file

my $TestFile = 'testoutput.xml';
unlink($TestFile);
ok(!-e $TestFile);

$xml = XMLout($hashref1);
XMLout($hashref1, outputfile => $TestFile);
ok(-e $TestFile);
ok(ReadFile($TestFile) eq $xml);
unlink($TestFile);


# Test output to an IO handle

ok(!-e $TestFile);
my $fh = new IO::File;
$fh->open(">$TestFile") || die "$!";
XMLout($hashref1, outputfile => $TestFile);
$fh->close();
ok(-e $TestFile);
ok(ReadFile($TestFile) eq $xml);
unlink($TestFile);

# After all that, confirm that the original hashref we supplied has not
# been corrupted.

(is_deeply($hashref1, $hashref2));


# Confirm that hash keys with leading '-' are skipped

$ref = {
  'a'  => 'one',
  '-b' => 'two',
  '-c' => {
	    'one' => 1,
	    'two' => 2
          }
};

$_ = XMLout($ref, rootname => 'opt');
ok(m{^\s*<opt\s+a="one"\s*/>\s*$}s);


# Try a more complex unfolding with key attributes named in a hash

$ref = {
  'car' => {
    'LW1804' => {
      'option' => {
        '9926543-1167' => { 'key' => 1, 'desc' => 'Steering Wheel' }
      },
      'id' => 2,
      'make' => 'GM'
    },
    'SH6673' => {
      'option' => {
        '6389733317-12' => { 'key' => 2, 'desc' => 'Electric Windows' },
        '3735498158-01' => { 'key' => 3, 'desc' => 'Leather Seats' },
        '5776155953-25' => { 'key' => 4, 'desc' => 'Sun Roof' },
      },
      'id' => 1,
      'make' => 'Ford'
    }
  }
};

# Expect:
# <opt>
#   <car license="LW1804" id="2" make="GM">
#     <option key="1" pn="9926543-1167" desc="Steering Wheel" />
#   </car>
#   <car license="SH6673" id="1" make="Ford">
#     <option key="2" pn="6389733317-12" desc="Electric Windows" />
#     <option key="3" pn="3735498158-01" desc="Leather Seats" />
#     <option key="4" pn="5776155953-25" desc="Sun Roof" />
#   </car>
# </opt>

$_ = XMLout($ref, keyattr => { 'car' => 'license', 'option' => 'pn' });
(is_deeply($ref,                                      # Parses back OK 
      XMLin($_, forcearray => 1,
	    keyattr => { 'car' => 'license', 'option' => 'pn' })));
ok(s{\s*make="GM"}{gm}s);
ok(s{\s*id="2"}{gm}s);
ok(s{\s*license="LW1804"}{gm}s);
ok(s{\s*desc="Steering Wheel"}{opt}s);
ok(s{\s*pn="9926543-1167"}{opt}s);
ok(s{\s*key="1"}{opt}s);
ok(s{\s*<cargmgmgm>\s*<optionoptoptopt\s*/>\s*</car>}{CAR}s);
ok(s{\s*make="Ford"}{ford}s);
ok(s{\s*id="1"}{ford}s);
ok(s{\s*license="SH6673"}{ford}s);
ok(s{\s*desc="Electric Windows"}{1}s);
ok(s{\s*pn="6389733317-12"}{1}s);
ok(s{\s*key="2"}{1}s);
ok(s{\s*<option111}{<option}s);
ok(s{\s*desc="Leather Seats"}{2}s);
ok(s{\s*pn="3735498158-01"}{2}s);
ok(s{\s*key="3"}{2}s);
ok(s{\s*<option222}{<option}s);
ok(s{\s*desc="Sun Roof"}{3}s);
ok(s{\s*pn="5776155953-25"}{3}s);
ok(s{\s*key="4"}{3}s);
ok(s{\s*<option333}{<option}s);
ok(s{\s*<carfordfordford>\s*(<option\s*/>\s*){3}</car>}{CAR}s);
ok(s{^<(\w+)\s*>\s*CAR\s*CAR\s*</\1>$}{}s);


# Check that empty hashes translate to empty tags

$ref = {
  'one' => {
    'attr1' => 'avalue1',
    'nest1' => [ 'nvalue1' ],
    'nest2' => {}
  },
  two => {}
};

$_ = XMLout($ref);

ok(s{<nest2\s*></nest2\s*>\s*}{<NNN>});
ok(s{<nest1\s*>nvalue1</nest1\s*>\s*}{<NNN>});
ok(s{<one\s*attr1\s*=\s*"avalue1">\s*}{<one>});
ok(s{<one\s*>\s*<NNN>\s*<NNN>\s*</one>}{<nnn>});
ok(s{<two\s*></two\s*>\s*}{<nnn>});
ok(m{^\s*<(\w+)\s*>\s*<nnn>\s*<nnn>\s*</\1\s*>\s*$});


# Check undefined values generate warnings 

{
my $warn = '';
local $SIG{__WARN__} = sub { $warn = $_[0] };
$_ = eval {
  $ref = { 'tag' => undef };
  XMLout($ref);
};
ok($warn =~ /Use of uninitialized value/);
}


# Unless undef is mapped to empty tags

$ref = { 'tag' => undef };
$_ = XMLout($ref, suppressempty => undef);
ok(m{^\s*<(\w*)\s*>\s*<tag\s*></tag\s*>\s*</\1\s*>\s*$}s);


# Test the keeproot option

$ref = {
  'seq' => {
    'name' => 'alpha',
    'alpha' => [ 1, 2, 3 ]
  }
};

my $xml1 = XMLout($ref, rootname => 'sequence');
my $xml2 = XMLout({ 'sequence' => $ref }, keeproot => 1);

(is_deeply($xml1, $xml2));


# Test that items with text content are output correctly
# Expect: <opt one="1">text</opt>

$ref = { 'one' => 1, 'content' => 'text' };

$_ = XMLout($ref);

ok(m{^\s*<opt\s+one="1">text</opt>\s*$}s);


# Even if we change the default value for the 'contentkey' option

$ref = { 'one' => 1, 'text_content' => 'text' };

$_ = XMLout($ref, contentkey => 'text_content');

ok(m{^\s*<opt\s+one="1">text</opt>\s*$}s);


# Check 'noattr' option

$ref = {
  attr1  => 'value1',
  attr2  => 'value2',
  nest   => [ qw(one two three) ]
};

# Expect:
#
# <opt>
#   <attr1>value1</attr1>
#   <attr2>value2</attr2>
#   <nest>one</nest>
#   <nest>two</nest>
#   <nest>three</nest>
# </opt>
#

$_ = XMLout($ref, noattr => 1);

ok(!m{=}s);                               # No '=' signs anywhere
(is_deeply($ref, XMLin($_)));         # Parses back ok
ok(s{\s*<(attr1)>value1</\1>\s*}{NEST}s); # Output meets expectations
ok(s{\s*<(attr2)>value2</\1>\s*}{NEST}s);
ok(s{\s*<(nest)>one</\1>\s*<\1>two</\1>\s*<\1>three</\1>}{NEST}s);
ok(s{^<(\w+)\s*>(NEST\s*){3}</\1>$}{}s);


# Check noattr doesn't screw up keyattr

$ref = { number => {
  'twenty one' => { dec => 21, hex => '0x15' },
  'thirty two' => { dec => 32, hex => '0x20' }
  }
};

# Expect:
#
# <opt>
#   <number>
#     <dec>21</dec>
#     <word>twenty one</word>
#     <hex>0x15</hex>
#   </number>
#   <number>
#     <dec>32</dec>
#     <word>thirty two</word>
#     <hex>0x20</hex>
#   </number>
# </opt>
#

$_ = XMLout($ref, noattr => 1, keyattr => [ 'word' ]);

ok(!m{=}s);                               # No '=' signs anywhere
                                               # Parses back ok
(is_deeply($ref, XMLin($_, keyattr => [ 'word' ])));
ok(s{\s*<(dec)>21</\1>\s*}{21}s);
ok(s{\s*<(hex)>0x15</\1>\s*}{21}s);
ok(s{\s*<(word)>twenty one</\1>\s*}{21}s);
ok(s{\s*<(number)>212121</\1>\s*}{NUM}s);
ok(s{\s*<(dec)>32</\1>\s*}{32}s);
ok(s{\s*<(hex)>0x20</\1>\s*}{32}s);
ok(s{\s*<(word)>thirty two</\1>\s*}{32}s);
ok(s{\s*<(number)>323232</\1>\s*}{NUM}s);
ok(s{^<(\w+)\s*>NUMNUM</\1>$}{}s);


# 'Stress test' with a data structure that maps to several thousand elements.
# Unfold elements with XMLout() and fold them up again with XMLin()

my $opt1 =  {};
foreach my $i (1..40) {
  foreach my $j (1..$i) {
    $opt1->{TypeA}->{$i}->{Record}->{$j} = { Hex => sprintf("0x%04X", $j) };
    $opt1->{TypeB}->{$i}->{Record}->{$j} = { Oct => sprintf("%04o", $j) };
  }
}

$xml = XMLout($opt1, keyattr => { TypeA => 'alpha', TypeB => 'beta', Record => 'id' });

my $opt2 = XMLin($xml, keyattr => { TypeA => 'alpha', TypeB => 'beta', Record => 'id' }, forcearray => 1);

(is_deeply($opt1, $opt2));

done_testing






