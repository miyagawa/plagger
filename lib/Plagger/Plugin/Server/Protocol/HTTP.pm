package Plagger::Plugin::Server::Protocol::HTTP;
use strict;

use CGI;
use HTTP::Date;
use URI;

use base qw( Plagger::Plugin::Server::Protocol );
__PACKAGE__->mk_accessors( qw(uri cgi headders_in headders_out content_type) );

sub proto { 'tcp' }
sub service { 'http' }

sub session_init {
    my $self = shift;

    $self->status(0);
    $self->body('');
    $self->uri('');
    $self->cgi('');
    $self->headders_in({});
    $self->headders_out({});
    $self->content_type('');
}

sub add_headders_out {
    my($self, @headder) = @_;

    while (my($name, $value) = splice @headder, 0, 2) {
	$self->{headders_out}->{$name} = $value;
    }
}

sub input {
    my $self = shift;
    my $req = shift;

    my $req;
    $req = <STDIN>;
    unless ($req =~ m!^(GET|POST) ([^ ]+) HTTP/\d\.\d\r\n!) {
	$self->status(400);
	return 0;
    };
    my $method = $1;
    my $query = $2;

    while (<STDIN> =~ /^([^:]+): (.+)\r\n/) {
	$self->{headders_in}->{$1} = $2;
    }
    if ($method eq 'POST') {
	read(STDIN, my $data, $self->headders_in->{'Content-Length'} || 0);
	$query .= "?$data";
    }

    my $host = $self->headders_in->{Host} ||= sprintf("%s:%s", $self->conf->{host}, $self->conf->{port});
    $self->uri(URI->new("http://$host$query"));
    $self->cgi(CGI->new($self->uri->query));

    Plagger->context->log(debug => "request: " . $self->uri->as_string);
    return 1;
}

sub output {
    my $self = shift;

    my $other_headders;
    foreach my $name (%{ $self->headders_out }) {
	$other_headders .= sprintf("%s: %s\r\n", $name, $self->headders_out->{$name});
	$self->status(302) if $name eq 'Location';
    }

    my $body;
    if ($self->status eq 302) {
	$body = "HTTP/1.0 302 Plagger Redirect\r\n";
	print $body;
    } elsif ($self->status) {
	$body = "HTTP/1.0 500 Plagger Error\r\n";
	print $body;
    } else {
	print "HTTP/1.0 200 OK\r\n";
	$body = $self->body;
   }
    utf8::encode($body) if utf8::is_utf8($body);

    printf("Server: Plagger/%s\r\n", $Plagger::VERSION);
    printf("Date: %s\r\n", HTTP::Date::time2str); 
    print "Connection: close\r\n";
    printf("Content-Type: %s\r\n", $self->content_type || 'text/html'); 
    printf("Content-Length: %d\r\n", length($body));
    print $other_headders;
    print "\r\n";
    print $body;
}
1;
