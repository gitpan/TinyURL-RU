package TinyURL::RU;

use utf8;
use strict;
use warnings;
use base 'Exporter';

use URI::Escape;
use XML::LibXML;
use LWP::UserAgent;

our @EXPORT_OK = qw(shorten lengthen);
our $VERSION   = '0.01';

use constant URL => 'http://whoyougle.ru/net/api/tinyurl/?long=%s&prefix=%s&suffix=%s&option=%d';

sub shorten {
    my $long   = shift || return;
    my $prefix = shift || '';
    my $suffix = shift || '';

    my $option = 1;
    if($prefix and not $suffix)    { $option = 2 }
    elsif(not $prefix and $suffix) { $option = 3 }
    elsif($prefix and $suffix)     { $option = 4 }

    my $ua = LWP::UserAgent->new(timeout => 3);
    my $resp = $ua->get(sprintf URL, uri_escape_utf8($long), $prefix, $suffix, $option);
    $resp->is_success or return;

    my $xml = eval { XML::LibXML->new->parse_string($resp->content) } or return;
    return if $xml->findvalue('/result/@error');

    my($short) = $xml->findnodes('/result/tiny')->shift;
    return defined $short ? $short->textContent : undef
}

sub lengthen {
    my $short = shift;

    $short = "http://byst.ro/$short" unless $short =~ m{^http://};

    my $ua = LWP::UserAgent->new(timeout => 3);
    $ua->parse_head(0);
    $ua->max_redirect(0);
    my $resp = $ua->get($short);
    $resp->{_rc} == 302 or return;

    my $loc = $resp->header('Location');
    utf8::decode($loc);
    $loc
}

1

__END__

=encoding utf8

=head1 NAME

TinyURL::RU - shorten URLs with byst.ro (aka tinyurl.ru)

=head1 SYNOPSIS

    use TinyURL::RU qw(shorten lengthen);
    my $long  = 'http://www.whitehouse.gov/';
    my $short = shorten($long);
    $long     = lengthen($short);

=head1 DESCRIPTION

This module provides you a very simple interface to URL shortening site http://byst.ro (aka http://tinyurl.ru).

=head1 FUNCTIONS

=head2 $short = shorten($long [, $prefix, $suffix])

Takes long URL as first argument and returns its tiny version (or undef on error).

Optionaly you can pass $prefix and/or $suffix for tiny URL.

C<$prefix> will be used as subdomain in shortened URL.

C<$suffix> will be used as path in shortened URL.

Example:

    $short = shorten($long, 'hello');          # $short eq 'http://hello.byst.ro/'
    $short = shorten($long, undef, 'hello');   # $short eq 'http://byst.ro/hello'
    $short = shorten($long, 'hello', 'world'); # $short eq 'http://hello.byst.ro/world'

Note: passing C<$prefix> and/or C<$suffix> may cause shortening fail if C<$prefix> or C<$suffix> is already taken by someone.

=head2 $long = lengthen($short)

Takes shortened URL (or its path part) as argument and returns its original version (or undef on error).

=head1 AUTHOR

Алексей Суриков E<lt>ksuri@cpan.orgE<gt>

=head1 NOTE

There is a small convenience for you: a plugin for L<WWW::Shorten> comes with this distribution.

See L<WWW::Shorten::TinyURL::RU>.

=head1 SEE ALSO

L<WWW::Shorten::TinyURL::RU>

L<http://byst.ro/>

L<http://tinyurl.ru/>

=head1 LICENSE

This program is free software, you can redistribute it under the same terms as Perl itself.
