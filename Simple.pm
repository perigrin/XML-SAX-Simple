# $Id: Simple.pm,v 1.2 2001/11/21 10:16:16 matt Exp $

package XML::SAX::Simple;

use strict;
use vars qw($VERSION @ISA @EXPORT);
use XML::Simple ();
use XML::SAX;
use XML::Handler::Trees;
@ISA = ('XML::Simple');

$VERSION = '0.02';

@EXPORT = qw(XMLin XMLout);

sub XMLin {
    my $self;
    if($_[0]  and  UNIVERSAL::isa($_[0], 'XML::Simple')) {
        $self = shift;
    }
    else {
        $self = new XML::SAX::Simple();
    }
    $self->SUPER::XMLin(@_);
}

sub XMLout {
    my $self;
    if($_[0]  and  UNIVERSAL::isa($_[0], 'XML::Simple')) {
        $self = shift;
    }
    else {
        $self = new XML::SAX::Simple();
    }
    $self->SUPER::XMLout(@_);
}

sub build_tree {
    my $self = shift;
    my ($filename, $string) = @_;
    
    if($filename  and  $filename eq '-') {
        local($/);
        $string = <STDIN>;
        $filename = undef;
    }
    
    my $handler = XML::Handler::Tree->new();
    my $parser = XML::SAX::ParserFactory->parser(Handler => $handler);
    my $tree;
    if($filename) {
        $tree = $parser->parse_uri($filename);
    }
    else {
        if (ref($string)) {
            $tree = $parser->parse_file($string);
        }
        else {
            $tree = $parser->parse_string($string);
        }
    }

    # use Data::Dumper;
    # warn("returning ", Dumper($tree), "\n");
    return($tree);
}

1;
__END__

=head1 NAME

XML::SAX::Simple - SAX version of XML::Simple

=head1 SYNOPSIS

  use XML::SAX::Simple qw(XMLin XMLout);
  my $hash = XMLin("foo.xml");

=head1 DESCRIPTION

XML::SAX::Simple is a very simple version of XML::Simple but for
SAX. It can be used as a complete drop-in replacement for XML::Simple.

See the documentation for XML::Simple (which is required for this module
to work) for details.

=head1 AUTHOR

Matt Sergeant, matt@sergeant.org

=head1 SEE ALSO

L<XML::Simple>, L<XML::SAX>.

=cut
