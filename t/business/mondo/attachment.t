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

use_ok( 'Business::Mondo::Attachment' );
isa_ok(
    my $Attachment = Business::Mondo::Attachment->new(
        "id"          => "attach_00009237aqC8c5umZmrRdh",
        "created"     => "2015-08-22T12:20:18Z",
        "user_id"     => "user_00009238aMBIIrS5Rdncq9",
        "external_id" => "tx_00008zIcpb1TB4yeIFXMzx",
        "file_url"    => "https://foo/bar/user_00009237hliZellUicKuG1/LcCu4ogv1xW28OCcvOTL-foo.png",
        "file_type"   => "image/png",
        'client'      => Business::Mondo::Client->new(
            token      => 'foo',
        ),
    ),
    'Business::Mondo::Attachment'
);

can_ok(
    $Attachment,
    qw/
        url
        get
        to_hash
        to_json
        TO_JSON

        id
        created
        user_id
        external_id
        file_url
        file_type
        client
    /,
);

throws_ok(
    sub { $Attachment->upload },
    'Business::Mondo::Exception'
);

is(
    $@->message,
    'upload requires params: file_name, file_type',
    ' ... with expected message'
);

no warnings 'redefine';
*Business::Mondo::Client::api_post = sub { {
    file_url => 'http://baz',
    upload_url => 'http://boz',
} };

cmp_deeply(
    $Attachment->upload( file_name => 'foo',file_type => 'bar' ),
    { file_url => 'http://baz','upload_url' => 'http://boz' },
    '->upload'
);

throws_ok(
    sub { $Attachment->register },
    'Business::Mondo::Exception'
);

is(
    $@->message,
    'register requires params: external_id, file_name, file_type',
    ' ... with expected message'
);

*Business::Mondo::Client::api_post = sub { {
    "attachment" => {
        "id" => "attach_00009238aOAIvVqfb9LrZh",
        "user_id" => "user_00009238aMBIIrS5Rdncq9",
        "external_id" => "tx_00008zIcpb1TB4yeIFXMzx",
        "file_url" => "https://foo/bar/user_00009237hliZellUicKuG1/LcCu4ogv1xW28OCcvOTL-foo.png",
        "file_type" => "image/png",
        "created" => "2015-11-12T18:37:02Z"
    }
} };

isa_ok( $Attachment = $Attachment->register(
    external_id => 1,
    file_url    => 'http://bar',
    file_type   => 'http://boz',
),'Business::Mondo::Attachment','->register' );

*Business::Mondo::Client::api_post = sub { {} };
ok( $Attachment->deregister,'->deregister' );

ok( $Attachment->to_hash,'to_hash' );
ok( $Attachment->as_json,'to_json' );
ok( $Attachment->TO_JSON,'TO_JSON' );

done_testing();

# vim: ts=4:sw=4:et
