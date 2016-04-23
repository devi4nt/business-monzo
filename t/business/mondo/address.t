#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use JSON;

use Business::Mondo::Client;

$Business::Mondo::Resource::client = Business::Mondo::Client->new(
    token      => 'foo',
);

use_ok( 'Business::Mondo::Address' );
isa_ok(
    my $Address = Business::Mondo::Address->new(
        "address"   => "98 Southgate Road",
        "city"      => "London",
        "country"   => "GB",
        "latitude"  => 51.54151,
        "longitude" => -0.08482400000002599,
        "postcode"  => "N1 3JD",
        "region"    => "Greater London",
        'client'   => Business::Mondo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Mondo::Address'
);

can_ok(
    $Address,
    qw/
        url
        get
        to_hash
        to_json
        TO_JSON

        address
        city
        country
        latitude
        longitude
        postcode
        region
    /,
);

throws_ok(
    sub { $Address->get },
    'Business::Mondo::Exception'
);

is(
    $@->message,
    'Mondo API does not currently support getting address data',
    ' ... with expected message'
);

throws_ok(
    sub { $Address->url },
    'Business::Mondo::Exception'
);

is(
    $@->message,
    'Mondo API does not currently support getting address data',
    ' ... with expected message'
);

done_testing();

# vim: ts=4:sw=4:et
