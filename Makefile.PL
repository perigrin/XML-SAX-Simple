use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'XML::SAX::Simple',
    'VERSION_FROM'	=> 'Simple.pm', # finds $VERSION
    'PREREQ_PM'		=> { 'XML::Simple' => 1.06, 
			     'XML::SAX' => 0.02,
                             'XML::Handler::Trees' => 0.02,
                           },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Simple.pm', # retrieve abstract from module
      AUTHOR     => 'Matt Sergeant, <matt@sergeant.org>') : ()),
);

