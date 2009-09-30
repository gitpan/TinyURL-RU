use Test::More qw(no_plan);

use utf8;
use TinyURL::RU qw(shorten lengthen);

binmode STDOUT, ':utf8';
no warnings 'utf8';

my @links = (
    [ 'http://whoyougle.com/time/converter/#gregorian_24.8.1990_saka', undef,    undef,    ],
    [ 'http://whoyougle.com/base/science-pop-magazines/',              'prefix', 'suffix', ],
    [ 'http://whoyougle.com/money/currency/#100-USD-RUB',              'prefix', undef,    ],
    [ 'http://whoyougle.com/search/?text=сегодня по еврейскому',       undef,    'suffix', ],
);
my @links_autoincr = (
    'http://whoyougle.com/base/provider-choice/',
    'http://whoyougle.com/base/ten-best-undergrounds/',
    'http://whoyougle.com/base/car-rent-sites/',
    'http://whoyougle.com/base/online-education/',
);

is shorten('http://byst.ro'), undef, 'should not shorten itself';

for(@links) {
    my($url, $prefix, $suffix) = @$_;

    my $tiny = shorten($url, $prefix, $suffix);
    ok defined $tiny, 'shorten ok';

    my $re = qr{^http://byst\.ro/.+$};
    if(not defined $prefix and defined $suffix)    { $re = qr{^http://byst\.ro/$suffix$}          }
    elsif(defined $prefix and not defined $suffix) { $re = qr{^http://$prefix\.byst\.ro/?$}       }
    elsif(defined $prefix and defined $suffix)     { $re = qr{^http://$prefix\.byst\.ro/$suffix$} }
    like $tiny || '', $re, 'looks like shorten url';

    my $long = lengthen($tiny);
    ok defined $long, 'lengthen ok';
    is $long, $url, 'lengthen url is equal to orginal';
    
    $tiny =~ s{http://}{};
    $long = lengthen($tiny);
    ok defined $long, 'lengthen ok (w/o scheme)';
    is $long, $url, 'lengthen url is equal to orginal (w/o scheme)';

    $tiny =~ s{byst\.ro}{tinyurl\.ru};
    $long = lengthen($tiny);
    ok defined $long, 'lengthen ok (w/ tinyurl host)';
    is $long, $url, 'lengthen url is equal to orginal (w/ tinyurl host)'
}

my $start = 0;
for(@links_autoincr) {
    my $tiny = shorten($_, undef, 'autoincr', increment => 1);
    ok defined $tiny, 'shorten ok (w/ increment)';
    like $tiny || '', qr{autoincr\d*$}, 'looks like shorten url (w/ increment)';
    if($start) {
        my($current) = $tiny =~ /autoincr(\d+)/;
        ok int $current, 'increment is integer and > 0';
        is $current - 1, $start, 'increment is ok';
        $start = $current
    }
    else {
        $start = '' unless defined $start;
        ($start) = $tiny =~ /autoincr(\d*)$/
    }
}
