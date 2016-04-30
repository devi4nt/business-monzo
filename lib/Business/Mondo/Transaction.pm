package Business::Mondo::Transaction;

=head1 NAME

Business::Mondo::Transaction

=head1 DESCRIPTION

A class for a Mondo transaction, extends L<Business::Mondo::Resource>

=cut

use Moo;
extends 'Business::Mondo::Resource';
with 'Business::Mondo::Utils';
with 'Business::Mondo::Currency';

use Types::Standard qw/ :all /;
use Business::Mondo::Merchant;
use Business::Mondo::Attachment;
use DateTime::Format::DateParse;

=head1 ATTRIBUTES

The Transaction class has the following attributes (with their type).

    id (Str)
    description (Str)
    notes (Str)
    account_balance (Int)
    amount (Int)
    metadata (HashRef)
    is_load (Bool)
    merchant (Business::Mondo::Merchant)
    currency (Data::Currency)
    created (DateTime)
    settled (DateTime)
    attachments (ArrayRef[Business::Mondo::Attachment])

Note that if a HashRef or Str is passed to ->merchant it will be coerced
into a Business::Mondo::Merchant object. When a Str is passed to ->currency
this will be coerced to a Data::Currency object, and when a Str is passed
to ->created / ->settled this will be coerced to a DateTime object.

=cut

has [ qw/ id description notes / ] => (
    is  => 'ro',
    isa => Str,
);

has [ qw/ account_balance amount / ] => (
    is  => 'ro',
    isa => Int,
);

has [ qw/ metadata / ] => (
    is  => 'ro',
    isa => HashRef,
);

has [ qw/ is_load / ] => (
    is  => 'ro',
    isa => Bool,
);

has merchant => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['Business::Mondo::Merchant']],
    coerce  => sub {
        my ( $args ) = @_;

        return undef if ! defined $args;

        if ( ref( $args ) eq 'HASH' ) {
            return undef if ! keys %{ $args };
            $args = Business::Mondo::Merchant->new(
                client => $Business::Mondo::Resource::client,
                %{ $args },
            );
        } elsif ( ! ref( $args ) ) {
            $args = Business::Mondo::Merchant->new(
                client => $Business::Mondo::Resource::client,
                id     => $args,
            );
        }

        return $args;
    },
);

has attachments => (
    is      => 'ro',
    isa     => Maybe[ArrayRef[InstanceOf['Business::Mondo::Attachment']]],
    coerce  => sub {
        my ( $args ) = @_;

        return undef if ! defined $args;

        my @attachments;

        foreach my $attachment ( @{ $args } ) {
            push( @attachments,Business::Mondo::Attachment->new(
                client => $Business::Mondo::Resource::client,
                %{ $attachment },
            ) );
        }

        return [ @attachments ];
    },
);

has [ qw/ created settled / ] => (
    is      => 'ro',
    isa     => Maybe[InstanceOf['DateTime']],
    coerce  => sub {
        my ( $args ) = @_;

        if ( ! ref( $args ) ) {
            $args = DateTime::Format::DateParse->parse_datetime( $args );
        }

        return $args;
    },
);

=head1 Operations on an transaction

=head2 get

Returns a new instance of the object populated with the attributes having called
the API

    my $populated_transaction = $transaction->get;

This is for when you have instantiated an object with the id, so calling the API
will retrieve the full details for the entity.

=cut

sub get {
    shift->SUPER::get( 'transaction' );
}

=head2 annotate

Returns a new instance of the object with annotated data having called the API

    my $annotated_transaction = $transaction->annotate(
        foo => "bar",
        baz => "boz,
    );

=cut

sub annotate {
    my ( $self,%annotations ) = @_;

    %annotations = $self->_params_as_array_string( 'metadata',\%annotations );

    my $data = $self->client->api_patch( $self->url,\%annotations );
    $data = $data->{transaction};

    return $self->new(
        client => $self->client,
        %{ $data },
    );
}

sub annotations {
    return shift->metadata;
}

=head1 SEE ALSO

L<Business::Mondo>

L<Business::Mondo::Resource>

=head1 AUTHOR

Lee Johnson - C<leejo@cpan.org>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/leejo/business-mondo

=cut

1;

# vim: ts=4:sw=4:et
