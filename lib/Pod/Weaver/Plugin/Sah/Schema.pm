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

    my $res = gen_pod_from_acme_cpanlists(
        module => $package,
        _raw=>1,
    );

    $self->add_text_to_section(
        $document, $res->{author_lists}, 'AUTHOR LISTS',
        {after_section => ['DESCRIPTION']},
    ) if $res->{author_lists};

    $self->add_text_to_section(
        $document, $res->{module_lists}, 'MODULE LISTS',
        {after_section => ['AUTHOR LISTS', 'DESCRIPTION']},
    ) if $res->{module_lists};

    # XXX don't add if current See Also already mentions it
    my @pod = (
        "L<Acme::CPANLists> - about the Acme::CPANLists namespace\n\n",
        "L<acme-cpanlists> - CLI tool to let you browse/view the lists\n\n",
    );
    $self->add_text_to_section(
        $document, join('', @pod), 'SEE ALSO',
        {after_section => ['DESCRIPTION']
     },
    );

    $self->log(["Generated POD for '%s'", $filename]);
}

sub weave_section {
    my ($self, $document, $input) = @_;

    my $filename = $input->{filename};

    my $package;
    if ($filename =~ m!^lib/(.+)\.pm$!) {
        $package = $1;
        $package =~ s!/!::!g;
        $self->_process_module($document, $input, $package);
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
