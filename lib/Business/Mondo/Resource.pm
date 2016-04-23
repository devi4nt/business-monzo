package Business::Mondo::Resource;

=head1 NAME

Business::Mondo::Resource

=head1 DESCRIPTION

This is a base class for Mondo resource classes, it implements common
behaviour. You shouldn't use this class directly, but extend it instead.

=cut

use Moo;
use Carp qw/ confess carp /;
use JSON ();
use Try::Tiny;
use Business::Mondo::Paginator;

=head1 ATTRIBUTES

    client
    url
    url_no_id

=cut

has client => (
    is       => 'ro',
    isa      => sub {
        confess( "$_[0] is not a Business::Mondo::Client" )
            if ref $_[0] ne 'Business::Mondo::Client';

        $Business::Mondo::Resource::client = $_[0];
    },
    required => 1,
);

has [ qw/ url / ] => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        join( '/',$self->url_no_id,$self->id )
    },
);

has [ qw/ url_no_id / ] => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        my ( $self ) = @_;
        return join(
            '/',
            $self->client->api_url,
            lc( ( split( ':',ref( $self ) ) )[-1] ),
        );
    },
);

=head1 METHODS

=head2 to_hash

Returns a hash representation of the object.

    my %data = $Issue->to_hash;

=head2 to_json

Returns a json string representation of the object.

    my $json = $Issue->to_json;

=head2 get

Populates the object with its attributes (calls the API)

    $Issue->get

As the data returned in the call to list objects does not contain the full data
of the objects (it only contains lightweight information, such as the URLs of
the objects you are interested in) you need to call the ->get method to
populate the attributes on an object. Really the Paginator just contains a list
of URLs and an easy way to navigate through them.

If the data returned from Mondo contains attributes not available on the object
then warnings will be raised for those attributes that couldn't be set - if you
see any of these please raise an issue against the dist as these are likely due
to updates to the Mondo API.

=cut

sub to_hash {
    my ( $self ) = @_;

    my %hash = %{ $self };
    delete( $hash{client} );
    return %hash;
}

sub to_json {
    my ( $self ) = @_;
    return JSON->new->canonical->encode( { $self->to_hash } );
}

# for JSON encoding modules
sub TO_JSON { shift->to_hash; }

sub get {
    my ( $self,$sub_key ) = @_;

    my $data = $self->client->api_get( $self->url );

    $data = $data->{$sub_key} if $sub_key;

    foreach my $attr ( keys( %{ $data } ) ) {
        try { $self->$attr( $data->{$attr} ); }
        catch {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $_" );
        };
    }

    return $self;
}

sub _parse_envelope_data {
    my ( $self,$data ) = @_;

    return $self if ! ref( $data );

    my $Envelope = Business::Mondo::Envelope->new(
        client => $self->client,
        %{ $data }
    );

    foreach my $attr ( keys( %{ $Envelope->Entity // {} } ) ) {
        try { $self->$attr( $Envelope->Entity->{$attr} ); }
        catch {
            carp( "Couldn't set $attr on @{[ ref( $self ) ]}: $_" );
        };
    }

    return $self;
}

sub _create {
    my ( $self,$update,$class,$cb ) = @_;

    if ( ! $update && $self->id ) {
        Business::Mondo::Exception->throw({
            message  => "Can't create $class when id is already set",
        });
    } elsif ( $update && ! $self->id ) {
        Business::Mondo::Exception->throw({
            message  => "Can't update $class if id is not set",
        });
    }

    my $post_data = $cb->( $self );

    return $self->_parse_envelope_data(
        $self->client->api_post( $class,$post_data )
    );
}

sub _paginated_items {
    my ( $self,$class,$item_class,$item_class_singular ) = @_;

    my $items = $self->client->api_get(
        "$class/@{[ $self->id ]}/$item_class",
    );

    my $b_mondo_class = "Business::Mondo::$item_class_singular";

    my $Paginator = Business::Mondo::Paginator->new(
        links  => {
            next     => $items->{NextURL},
            previous => $items->{PreviousURL},
        },
        client  => $self->client,
        class   => 'Business::Mondo::Issue',
        objects => [ map { $b_mondo_class->new(
            client => $self->client,
            %{ $_ },
        ) } @{ $items->{Items} } ],
    );

    return $Paginator;
}

sub update {
    my ( $self ) = @_;
    return $self->create( 'update' );
}

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
