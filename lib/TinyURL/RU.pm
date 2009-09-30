package TinyURL::RU;

use utf8;
use strict;
use warnings;
use base 'Exporter';

use URI::Escape;
use XML::LibXML;
use LWP::UserAgent;

our @EXPORT_OK = qw(shorten lengthen);
our $VERSION   = '0.04';

use constant URL => 'http://whoyougle.ru/net/api/tinyurl/?long=%s&prefix=%s&suffix=%s&option=%d&increment=%d';

sub shorten {
    my $long   = shift || return;
    my $prefix = shift || '';
    my $suffix = shift || '';
    my %args   = @_;

    my $option = 1;
    if($prefix and not $suffix)    { $option = 2 }
    elsif(not $prefix and $suffix) { $option = 3 }
    elsif($prefix and $suffix)     { $option = 4 }

    $args{increment} = 0 unless defined $args{increment};
    return if $args{increment} and not $suffix;

    my $ua = LWP::UserAgent->new(timeout => 3);
    my $resp = $ua->get(sprintf URL, uri_escape_utf8($long), $prefix, $suffix, $option, $args{increment});
    $resp->is_success or return;

    my $xml = eval { XML::LibXML->new->parse_string($resp->content) } or return;
    return if $xml->findvalue('/result/@error');

    my($short) = $xml->findnodes('/result/tiny')->shift;
    return defined $short ? $short->textContent : undef
}

sub lengthen {
    my $short = shift;

    unless($short =~ m{^http://}) {
        $short = ($short =~ m{(?:tinyurl\.ru|byst\.ro)/})
            ? "http://$short"
            : "http://byst.ro/$short"
    }

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

=head2 $short = shorten($long [, $prefix, $suffix, %options])

Takes long URL as first argument and returns its tiny version (or undef on error).

Optionaly you can pass $prefix and/or $suffix for tiny URL and some other options.

C<$prefix> will be used as subdomain in shortened URL.

C<$suffix> will be used as path in shortened URL.

Note: passing C<$prefix> and/or C<$suffix> may cause shortening fail if C<$prefix> or C<$suffix> is already taken by someone.

C<%options> are:

=over 8

=item increment

Lets you to re-use same (almost) C<$suffix> for different URLs.

Implemented by automatical appending of an incremental number (starts with 1) on repeated requests with the same C<$suffix>.

Note: this options works only with C<$suffix> passed.

=back

Simple example:

    $short = shorten($long1, 'hello');          # $short eq 'http://hello.byst.ro/'
    $short = shorten($long2, 'hello', 'world'); # $short eq 'http://hello.byst.ro/world'

Incremental example:

    $short = shorten($long1, undef, 'hello');                # $short eq 'http://byst.ro/hello'
    $short = shorten($long1, undef, 'hello');                # short is undefined because 'hello' suffix already exists for $long1
    $short = shorten($long2, undef, 'hello', increment => 1) # $short eq 'http://byst.ro/hello1'
    $short = shorten($long3, undef, 'hello', increment => 1) # $short eq 'http://byst.ro/hello2'

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
