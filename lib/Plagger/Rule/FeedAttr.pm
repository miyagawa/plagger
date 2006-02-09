package Plagger::Rule::FeedAttr;
use strict;
use base qw( Plagger::Rule );

use Plagger::Operator;
use Plagger::Feed;

sub init {
    my $self = shift;

    if (my $attrs = $self->{attrs}) {
	$attrs = [ $attrs ] if ref($attrs) ne 'ARRAY';
	$self->{attrs} = $attrs;
    } else {
	Plagger->context->error("Can't parse attr");
    }
    
    my $feed = Plagger::Feed->new;
    for my $attr (@{$self->{attrs}}) {
	unless ($feed->can($attr->{name})) {
	    Plagger->context->error("Unsupported attr name '$attr->{name}'");
	}
	
	if (my $value = $attr->{value}) {
	    $value = [ $value ] if ref($value) ne 'ARRAY';
	    $self->{value} = $value;
	} else {
	    Plagger->context->error("Can't parse value in '$attr->{name}'");
	}
	    
	$attr->{op} ||= 'OR';
	unless (Plagger::Operator->is_valid_op($attr->{op})) {
	    Plagger->context->error("Unsupported operator $self->{op} in '$attr->{name}'");
	}
    }

    $self->{op} ||= 'OR';
    unless (Plagger::Operator->is_valid_op($self->{op})) {
	Plagger->context->error("Unsupported operator $self->{op}");
    }
}

sub hooks { [ 'publish.add_feed' ] }

sub dispatch {
    my($self, $args) = @_;

    my $feed = $args->{feed}
        or Plagger->context->error("No feed object in this plugin phase");

    my @bool;
    for my $attr (@{$self->{attrs}}) {
	my @value;
	my $name = $attr->{name};
	for my $want (@{$attr->{value}}) {
	    if ($want =~ m{^/(.+?)/(i?)$}) {
		my ($pattern, $icase) = ($1, $2);
		if ($icase) {
		    push @value, ($feed->$name() =~ m{$pattern}i);
		} else {
		    push @value, ($feed->$name() =~ m{$pattern});
		}
	    } else {
		push @value, ($feed->$name() eq $want);
	    }
	}
	push @bool, Plagger::Operator->call($attr->{op}, @value);
    }

    Plagger::Operator->call($self->{op}, @bool);
}

1;
__END__
example config.
    rule:
      - module: FeedAttr
        op: AND
        attrs: 
          - 
            name: type
            op: NOR
            value:
              - mixi
              - frepa
          -
            name: link
            op: OR
            value:
              - /Yappo/i
              - /bulknews/
