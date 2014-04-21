package App::Exegete;

use warnings;
use strict;
use base qw(Term::Shell);
#use lib './_exeg-lib';
use Exegete;
#use POSIX qw(strftime);

=head1 NAME

App::Exegete - Command-line static text generator

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

This command-line interface is based on L<Term::Shell> for simplicity; that means you can either call it from the command line with a specific command,
or you can open up an "Exegete shell" that can then be used to run multiple commands in an interactive environment.

   exeg build
   
or

   exeg, then:
   
   exeg> publish [target]
   exeg> quit
   
Simple, right?

=head1 COMMANDS

=head2 build: run_build

The core functionality of Exegete is of course to publish text starting from mildly Markdown-ish definitions. Running "build" in a
context will build those pages.

=cut

sub run_build {
   my ($self, $target) = @_;
   my $publisher = Exegete->new();
   $publisher->build($target);
}

=head2 rebuild: run_rebuild

The build process normally tries to minimize work, only looking at files that have changed.
To build everything regardless, do a "rebuild".

=cut

sub run_rebuild {
   my ($self, $target) = @_;
   my $publisher = Exegete->new();
   $publisher->{rebuild} = 1;
   $publisher->build($target);
}

=head2 build: run_publish

If the local work is just a part of a larger work, the "publish" command is used to push the current text to that destination.
This may involve the results from the last build, or it may not.  If the target is itself an Exegete work,  the target can also
be built as part of publication.

This is actually just a build for the "publish" target.

=cut

sub run_publish {
   my ($self) = @_;
   my $publisher = Exegete->new();
   $publisher->build('publish');
}



=head1 USEFUL INFRASTRUCTURE

=head2 prompt_str

Returns a prompt.

=cut

sub prompt_str { 'exeg> ' }

=head2 do

After the shell is initialized in C<new>, it's called either with @ARGV or without.  If with, it simply executes that command and exits;
otherwise, it runs a shell for interaction.

=cut
sub do {
   my $self = shift;
   if (@_) {
      return $self->run(@_);
   }
   $self->cmdloop;
}



=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-Exegete at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Exegete>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc App::Exegete


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=App-Exegete>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/App-Exegete>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/App-Exegete>

=item * Search CPAN

L<http://search.cpan.org/dist/App-Exegete/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of App::Exegete
