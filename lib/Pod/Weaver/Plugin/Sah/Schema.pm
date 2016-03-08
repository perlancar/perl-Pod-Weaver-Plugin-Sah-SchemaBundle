package Pod::Weaver::Plugin::Sah::Schema;

# DATE
# VERSION

use 5.010001;
use Moose;
with 'Pod::Weaver::Role::AddTextToSection';
with 'Pod::Weaver::Role::Section';

sub _process_module {
    no strict 'refs';

    my ($self, $document, $input, $package) = @_;

    my $filename = $input->{filename};

    # XXX handle dynamically generated module (if there is such thing in the
    # future)
    local @INC = ("lib", @INC);

    {
        my $package_pm = $package;
        $package_pm =~ s!::!/!g;
        $package_pm .= ".pm";
        require $package_pm;
    }

    my $schemas = \%{"$package\::SCHEMAS"};

    return unless keys %$schemas;

    # add POD section: SAH SCHEMAS
    {
        require Data::Sah::Normalize;
        require Markdown::To::POD;
        my @pod;
        push @pod, "=over\n\n";
        for my $name (sort keys %$schemas) {
            $self->log_debug(["Normalizing schema '%s'", $name]);
            my $sch = Data::Sah::Normalize::normalize_schema($schemas->{$name});
            push @pod, "=item * $name\n\n";
            push @pod, "$sch->[1]{summary}.\n\n" if $sch->[1]{summary};
            if ($sch->[1]{description}) {
                my $pod = Markdown::To::POD::markdown_to_pod(
                    $sch->[1]{description});
                push @pod, $pod, "\n\n";
            }
        }
        push @pod, "=back\n\n";
        $self->add_text_to_section(
            $document, join("", @pod), 'SAH SCHEMAS',
            {after_section => ['DESCRIPTION']},
        );
    }

    # add POD section: SEE ALSO
    {
        # XXX don't add if current See Also already mentions it
        my @pod = (
            "L<Sah> - specification\n\n",
            "L<Data::Sah>\n\n",
        );
        $self->add_text_to_section(
            $document, join('', @pod), 'SEE ALSO',
            {after_section => ['DESCRIPTION']},
        );
    }
    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        if ($package =~ /^Sah::Schema::/) {
            $self->_process_module($document, $input, $package);
        }
    }
}

1;
# ABSTRACT: Plugin to use when building Sah::Schema::* distribution

=for Pod::Coverage weave_section

=head1 SYNOPSIS

In your F<weaver.ini>:

 [-Sah::Schema]


=head1 DESCRIPTION

This plugin is used when building Sah::Schema::* distributions. It currently
does the following:

=over

=item * Create "SAH SCHEMAS" POD section from C<%SCHEMAS>

=item * Mention some modules in See Also section

e.g. L<Sah> and L<Data::Sah>.

=back


=head1 SEE ALSO

L<Sah> and L<Data::Sah>

L<Dist::Zilla::Plugin::Sah::Schema>
