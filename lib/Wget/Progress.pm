package Wget::Progress;

use strict;
use warnings;
use 5.00801;
use Encode ();
use Encode::Guess qw/euc-jp sjis 7bit-jis/;
use LWP::UserAgent ();
use File::Basename ();
use File::Spec ();
use URI::Escape ();
use Carp ();
use Exporter 'import';

our @EXPORT = qw/wget/;

our $VERSION = '0.02';
our $OVERWRITE = 0;
our $VERBOSE = 0;
our $SKIP = 1;

my $LWP = LWP::UserAgent->new(keep_alive => 1);
my $ENC = Encode::find_encoding('utf8');

sub wget {
	my $uri = shift || Carp::croak "Usage: wget('http://example.com/big.iso', {filename => save_filename, dir => save_directory, encode => 'cp932'})";
	local $VERBOSE = 1;
	__PACKAGE__->get($uri, @_);
}

sub new {
	my $class = shift;
	my $arg = ref $_[0] eq 'HASH' ? $_[0] : { @_ };
	bless $arg, $class;
}

sub get {
	my $self = shift;
	my $uri = shift || Carp::croak "Usage: \$self->get('http://example.com/big.iso')";
	my $arg = shift || {};
	
	if (ref $self) {
		%$arg = (
			%$self,
			%$arg,
		);
	}
	
	my $file;
	unless ($arg->{filename}) {
		$file = File::Basename::basename($uri);
	}
	
	else {
		$file = $arg->{filename};
	}
	
	do {
		use bytes ();
		$file = URI::Escape::uri_unescape($file);
	};
	
	my $guess = Encode::Guess->guess($file);
	unless (ref $guess) {
		&_set_or_die($self, "$file $guess");
		return 0;
	}
	
	$file = &_encode($guess->decode($file), $arg->{enc});
	
	if ($arg->{dir}) {
		unless (-d $arg->{dir}) {
			&_set_or_die($self, "$arg->{dir} $!");
			return 0;
		}
		$file = File::Spec->catfile($arg->{dir}, $file);
	}
	
	if (-f $file) {
		unless ($arg->{OVER} or $OVERWRITE) {
			if ($arg->{SKIP} or $SKIP) {
				Carp::carp "SKIP: $file";
				return 1;
			}
			else {
				&_set_or_die($self, "$file exists");
				return 0;
			}
		}
	}
	
	print $file, "\n" if $arg->{VERBOSE} or $VERBOSE;
	
	open my $wfh, '>', $file or die "$file $!";
	binmode $wfh;
	my $res = $LWP->get(
		$uri,
		':content_cb' => sub {
			my ( $chunk, $res, $proto ) = @_;
			print $wfh $chunk;
			my $size = tell $wfh;
			
			if (my $total = $res->header('Content-Length')) {
				printf "%d/%d (%f%%)\r", $size, $total, $size/$total * 100 if $arg->{VERBOSE} or $VERBOSE;
			}
			
			else {
				printf "%d/Unknown bytes\r", $size if $arg->{VERBOSE} or $VERBOSE;
			}
		},
	);
	close $wfh;
	
	print "\n", $res->status_line, "\n" if $arg->{VERBOSE} or $VERBOSE;
	
	unless ($res->is_success) {
		unlink $file or die "$file $!";
		&_set_or_die($self, sprintf("%s wget failed (status: %s)", $uri, $res->status_line));
		return 0;
	}
	
	return $file;
}

sub agent {
	my $self = shift;
	$LWP->agent(shift);
}

sub _encode {
	my $file = shift;
	my $enc = shift || $ENC;
	$enc = Encode::find_encoding($enc) unless ref $enc eq 'Encode::XS';
	return $enc->encode($file, sub { sprintf "U+%04X", shift });
}

sub error {
	my $self = shift;
	return $self->{_error};
}

sub _set_or_die {
	my $self = shift;
	my $msg = shift;
	unless (ref $self) {
		Carp::croak $msg;
	}
	
	$self->{_error} = $msg;
}

1;
__END__

=head1 NAME

Wget::Progress is a file download module.

=head1 SYNOPSIS

  use Wget::Progress;
  
  my $uri = 'http://example.com/big.iso';
  
  wget($uri);
  
  my $wget = Wget::Progress->new({VERBOSE => 1});
  $wget->get($uri);

=head1 DESCRIPTION

Wget::Progress is a file download module.
But, use wget if (Unix|Linux) OS :-)

=head1 METHODS

=over

=item wget

download the file

  wget($uri);
  wget($uri, %$params);
  
error handling

  eval { wget($uri) };
  die "Oops! $@" if $@;

=item new

  my $wget = Wget::Progress->new();
  my $wget = Wget::Progress->new(%$params);
  
=item get

download the file

  $wget->get($uri);
  $wget->get($uri, %$params);
  
error handling

  $wget->get($uri) or die $wget->error;

=item agent

set/get L<LWP::UserAgent>-E<gt>agent;

=item error

get error message

  $wget->get($uri) or die $wget->error;

=back

=head2 PARAMS

=over

=item filename

save filename (default File::Basename::basename $uri)

=item dir

save directory (default current)

=item encode

save filename encoding.

=item VREBOSE

print progress mssage (default 0)

=item ORVE

Exists file overwrite (default 0)

=item SKIP

Exists file skip (default 1)
If the file exists, OVER SKIP If there is also designated as the function exits immediately.

=back

=head1 AUTHOR

Yuji Shimada E<lt>xaicron {at} gmail.comE<gt>

=head1 SEE ALSO

L<LWP::UserAgent>
L<Encode>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
