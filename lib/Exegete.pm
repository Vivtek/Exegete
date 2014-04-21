package Exegete;

use warnings;
use strict;
use YAML::Any;
#use POSIX qw(strftime
use Tree::Tracker;
use Template;
use File::Spec;
use File::Copy;
use File::Path qw(make_path);
use Data::Dumper;
use utf8;


=head1 NAME

Exegete - Text generation framework

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Exegete is a system for writing text about code. As such it includes the tools necessary for publishing text (static sites and blogs, articles,
even books) as well as tools for analyzing and generating code (literate programming tools, macro language, make-style build system, etc.).


=head1 STEPS OF THE BUILD PROCESS

Exegete's general sequence of events is simple:  (1) create the context, (2) load the configuration and item structure, (3) build a dependency graph,
including any defined index nodes, (4) check what source files have changed since the last build, and build a list of nodes to be regenerated, 
(5) load and parse all content, also marking index nodes that have changed due to content changes, (6) build or rebuild all index nodes, 
(7) generate target chunks of output from the Markdown structures, (8) apply templates to express all changed results, and finally (9) run whatever
post-build scripts have been specified (these might publish to Github, run LaTeX, or run make if you're using all this as a literate programming environment).

=head2 new

Exegete's 'new' does almost nothing, just establishes the context within which all other action will take place.  This gives you the chance to set
some things up before the load step.

=cut

sub new { bless ({
                    rebuild => 0,
                 }, shift ) }

=head2 build (definition, additional_content)

This build process is simply a wrapper for all the numbered steps implemented below.  Since this is the usual way of doing things,
it may well be that you will never need the individual pieces anyway.

The "definition" is either a directory or a YAML file.  If it's just a directory, the file will be exeg.conf;
the default is the current directory.
If the definition doesn't exist, the build process will return with an error list saying so.

The "additional_content" is a hashref with named text blocks to be included into the project.  This permits you to use Exegete as a reporting
tool and pass it whatever content you like.  If the text block in question is a coderef, it will be run, passing the current state of the publisher
and its own name as parameters.

=cut

sub build {
    my $publisher = shift;
    my $target = shift;
    my $definition = shift;
    my $additional_content = shift;
    
    if ($target eq "vivtek") {
       return $publisher->vivtek_builder;
    }
    
    my @errors = ();
    push @errors, $publisher->load($definition);
    push @errors, $publisher->mull_over();
    push @errors, $publisher->load_content();
    push @errors, $publisher->load_content($additional_content) if defined $additional_content;
    push @errors, $publisher->index();
    push @errors, $publisher->generate();
    push @errors, $publisher->express();
    push @errors, $publisher->post_build();
}


=head2 load

By default, load reads 'exeg.conf' in the current directory, and asks Exegete::Storage to load the Item defined by the current directory.  That Item is generally
going to be a site.  Each item has a type, content, and (optionally) children, so after loading each item, that item loads its own subitems in any way it
sees fit (by default, using a combination of the root.yaml and the subdirectories of the current directory).

=cut

sub load {
    my $self = shift;
    my $location = shift || '.';
    if (-e $location and -d $location) {
        $location .= "/exeg.conf";
    }
    if (not -e $location) {
        return ("Definition not found at $location");
    }
    
}

=head2 mull_over

Here, we build the dependency graph that constitutes the structure of the root item, and check for the existence and updatedness of each source file.

=cut

sub mull_over {
    my $self = shift;
}

=head2 load_content

Now we load and parse all changed content and mark index nodes whose input has changed.

This method can also be called multiple times to define live content (to do that, of course, you'll need to 

=cut

sub load_content {
    my $self = shift;
}

=head2 index

Here, we build or rebuild all index nodes.  This can optionally rebuild from scratch, but normally only builds index nodes
whose source elements have changed.

=cut

sub index {
    my $self = shift;
}

=head2 generate

This generates the target chunks of text that will be woven together to form the output.  It can include running example code.

=cut

sub generate {
    my $self = shift;
}

=head2 express

Here, we take all the templates that make up the structure of the thing being built, and use the target chunks to express them into the
final text.  The result goes into our target directory.  The entire project is always expressed (that is, if we have an HTML version and a
LaTeX version, both are always built - they will then always match).

=cut

sub express {
    my $self = shift;
}

=head2 post_build

Finally, we execute arbitrary commands on the target directory to finish the process.

=cut

sub post_build {
    my $self = shift;
}

=head1 TOOLS

=head2 xmlquote, accentquote, regex_sanitize

=cut

sub regex_sanitize {
   my $str = shift;

   $str =~ s/\\/\\\\/g;
   $str =~ s/\[/\\[/g;
   $str =~ s/\?/\\?/g;
   $str =~ s/\*/\\*/g;
   $str =~ s/\+/\\+/g;
   $str =~ s/\(/\\(/g;
   $str =~ s/\)/\\)/g;

   return $str;
}
sub xmlquote {
   my $str = shift;
   $str =~ s/&/&amp;/g;
   $str =~ s/</&lt;/g;
   $str =~ s/>/&gt;/g;
   return $str;
}

sub accentquote { # There's probably a better way of doing this.
   my $str = shift;
   $str =~ s/á/&aacute;/g;
   $str =~ s/Á/&Aacute;/g;
   $str =~ s/é/&eacute;/g;
   $str =~ s/É/&Eacute;/g;
   $str =~ s/ó/&oacute;/g;
   $str =~ s/Ó/&Oacute;/g;
   $str =~ s/ú/&uacute;/g;
   $str =~ s/Ú/&Uacute;/g;
   $str =~ s/ä/&auml;/g;
   $str =~ s/Ä/&Auml;/g;
   $str =~ s/ö/&eacut;/g;
   $str =~ s/Ö/&Oacut;/g;
   $str =~ s/ü/&uacut;/g;
   $str =~ s/Ü/&Uacut;/g;
   $str =~ s/ñ/&ntilde;/g;
   return $str;
}

=head2 write_file, load_file

Simple file handling. A file is associated with additional index information; if that includes a checksum, write_file
will only write a file to disk if its content has changed (this makes things easier for git or make; generated files
that aren't changed won't trigger further action)

=cut

sub write_file {
   open OUT, ">" . shift;
   print OUT shift;
   close OUT;
   return 1;
}

sub load_file {
   open IN, shift;
   my $r = '';
   while (<IN>) { $r .= $_; }
   close IN;
   $r;
}

=head2 get_tag, get_up_tag, get_template

There is a simple filesystem-based tag system that permits low-level embedding of information. This will probably be
replaced at some point.

=cut

sub get_up_tag {
   my ($tag, $values, @where) = @_;
   my $full = File::Spec->catfile(@where, "dummy.txt");
   my $text = get_tag ($tag, $full, $values);
   while ($text =~ /\[##(.*?)##\]/) {
      my $tag = $1;
      $text =~ s/\[##$tag##\]/get_tag($tag, $full, $values)/ge;
   }
   return $text;
}

sub get_tag {
   my ($tag, $full, $values) = @_;
   $values = {} unless defined $values;
   $tag =~ s/^tag +//;
   return $values->{$tag} if defined $values->{$tag};
   my ($vol, $dir, $f) = File::Spec->splitpath($full);
   my @where = ('.', File::Spec->splitdir($dir));
   if ($tag =~ / +\.(\.+)$/) {
      my $len = 1 + length $1;
      $tag =~ s/ +\.+$//;
      while ($len) {
         pop @where;
         $len -= 1;
      }
      return get_up_tag ($tag, $values, @where);
   } elsif ($tag =~ / \.\.$/) {
      $tag =~ s/ \.\.$//;
      pop @where;
   }
   while (@where) {
      my $tagfile = File::Spec->catfile(@where, "$tag.tag");
      if (-e $tagfile) {
         return load_file($tagfile);
      }
      pop @where;
   }
   print "page: unresolved tag $tag\n";
   return "(unresolved tag $tag)"; # TODO: log
}

sub get_template {
   my ($full) = @_;
   my ($vol, $dir, $f) = File::Spec->splitpath($full);
   my @where = ('.', File::Spec->splitdir($dir));
   while (@where) {
      my $tfile = File::Spec->catfile(@where, "template.template");
      if (-e $tfile) {
         return load_file($tfile);
      }
      pop @where;
   }
   return ""; # TODO: log
}


=head2 load_markdown

Loads a file and returns a hashref of tags (one of which is "content", the readable text of the file)

=cut

# Special fields:
# !title:      - the title for the page
# !posted:     - the explicit post date/time
# !keywords:   - the blog tag keywords for the post
# !query:      - an SQL query to be run before anything else happens (at the caller's responsibility).
#                'list-item' will then contain an array of hashrefs for rows.
# !generates:  - may appear multiple times, names blocks to map to filenames that are produced by this index, if any.
# !block:      - may appear multiple times, names blocks that can be used for other purposes. I have no particular plan for this at the moment.
#
# Special values:
# content:     - contains the preprocessed markdown-ish text loaded.
# links:       - contains a list of all *xx"..." links encountered in the text.
# <blocks>:    - each "generates" or "block" block defined in the text creates one value.
# <???>:       - Perl can naturally do anything with these values.
# brief:       - either equivalent to the content, or (if a !FOLD line appears) all the content up to the fold.
# folded:      - if true, indicates that an explicit !FOLD line was used.
# query-item:  - Perl code block to execute against each row of the query before anything else.  Passed the hashref for that row.
# run:         - generic Perl code block to be run before formatting starts. Passed the values hashref.

sub load_markdown {
   open IN, shift;
   my $tags = {};
   $tags->{links} = [];
   $tags->{keywords} = '';
   my $content = 0;
   my $code = 0;
   my $block = '';
   while (<IN>) {
      chomp;
      if (!$content and /^!(.*?): *(.*)/) {
         if ($1 eq 'generates' or $1 eq 'block') {        # May appear multiple times
            $tags->{$1} = [] unless defined $tags->{$1};
            push @{$tags->{$1}}, $2;
         } else {
            $tags->{$1} = $2;
         }
         next;
      }
      
      $content = 1;
      my $line = $_;
      
      if ($line =~ /^--start +([^ ]*?)--$/) {
         # We are starting a block.
         $block = $1;
         $tags->{$block} = '' unless defined $tags->{$block};  # Blocks append. Not sure if this is stupid.
         next;
      }
      if ($line =~ /^--end +([^ ]*?)--$/) {
         # Ending the current block (the name is really just for clarity)
         $block = '';
         next;
      }
      if ($line =~ /^(---+)(start|end)( +[^ ]*?)-+$/) {   # Unquote quoted delimiters one level
         my $dashes = $1;
         $line = "$2$3";
         $dashes =~ s/^-//;
         $line = "$dashes$line$dashes";
      }
      if ($block) {
         $tags->{$block} .= "$line\n";
         next;
      }

      # If we're not in a block, we preprocess the text as our content.
      if ($line =~ /^!FOLD/) {
         $tags->{brief} = $tags->{content};
         $tags->{folded} = 1;
         next;
      }
      $code = 0 if $code and $line =~ /<\/pre>/;
      $line = xmlquote ($line) if $code;
      $line = accentquote ($line);
      $code = 1 if $line =~ /<pre class="*code"*>/;

      $line =~ s/{(\/?[a-z]+?)}/<$1>/g;  # -- this was for quoting tags within code, I think. Not sure if I use it any more.

      $line = "</p><p>" unless $line or $code;  # Blank lines turn into paragraphs, but not in code blocks.

      while (!$code && $line =~ /\*([^ ]*?)"(.*?)"/) {
          my $url = $1;
          my $text = $2;
          
          my $src = regex_sanitize($url);
          my $qtext = regex_sanitize($text);
          if ($url =~ /^\/linkout\// || $url =~ /http:/ || $url =~ /https:/) {
             # Off-site link
             push @{$tags->{links}}, $url;
          } elsif ($src =~ /\[/ || $src =~ /\?/) {
             # Dynamically-generated link
          } else {
             my ($vol,$dir,$file) = File::Spec->splitpath($url);
             if ($file eq '') { $file = "index.html"; }
             if ($file !~ /\./) { $url .= ".html"; }
          }
          $line =~ s/\*$src"$qtext"/<a href="$url">$text<\/a>/g;
      }

      $tags->{content} .= "$line\n";
   }
   $tags->{brief} = $tags->{content} unless defined $tags->{brief};
   $tags->{'query-item'} = eval 'sub { ' . $tags->{'query-item'} . '}' if defined $tags->{'query-item'};
   $tags->{run}          = eval 'sub { ' . $tags->{run}          . '}' if defined $tags->{run};
   return $tags;
}

=head2 targeter

This is a simple targeter that examines files and determines their type

=cut

sub targeter {
   my ($node, $get_data, $mode) = @_;
   $mode = 'normal' unless defined $mode;
   #print "tar: node $node, mode $mode\n";
   my ($file, $role, $indent, $full) = @$node;
   #print "tar: $file - $full\n";
   
   return undef if $full =~ /^\.git/;     # Probably should build proper pruning into the walker, not here, but whatever.
   return undef if $full =~ /^_exeg-lib/;
   my $action = 'zip';
   if (-d $full) {
      my $target = File::Spec->catdir ('../github', $full);
      if (not -e $target) {
         $action = 'add';
      } elsif (not $mode eq 'return_all') {
         return undef;
      }
      return [$action, 'dir', 'dir', $target, @$node];
   }

   return undef if $file =~ /\.tag$/;  # TODO: better tree specification.  (This can already be done, I'm just lazy.)
   return undef if $file =~ /\.template$/;
   return undef if $file =~ /\.pl$/;   # Build scripts
   return undef if $file =~ /\.sqlt$/; # Tracking database
   
   my $target = File::Spec->catfile ('../github', $full);
   
   my $type;
   if ($file =~ /\.html$/) {
      $type = 'html';
   } elsif ($file =~ /\.wiki$/) {
      $target =~ s/\.wiki$/\.html/;
      $type = 'wiki';
   } elsif ($file =~ /\.wikx$/) {
      $target =~ s/\.wikx$/\.html/;
      $type = 'wikx';
      $action = 'index';
   } else {
      $type = 'copy';
   }

   if (!-e $target) {
      $action = 'add';
   } else {
      $action = 'mod' if -M $target > -M $full;
   }
   return undef if $action eq 'zip' and not $mode eq 'return_all';
   
   my $cat = 'page';
   $cat = 'proj' if $full =~ /\\/;
   $cat = 'blog' if $full =~ /^blog\\/;
   
   return [$action, $type, $cat, $target, @$node];
}

=head2 vivtek_builder

This is the builder I wrote for my site.

=cut

sub vivtek_builder {
    my $publisher = shift;
    my $rebuild = $publisher->{rebuild};
    
    #my $iterator = Tree::Tracker->new ('.', \&targeter, $rebuild ? ('target_mode', 'return_all') : ())->walk;
    my $walker = Tree::Tracker->new ('.', \&targeter, $rebuild ? (target_mode => 'return_all') : (),
                                          connect => 'dbi:SQLite:dbname=pages.sqlt',
                                          table => 'pages',
                                          add_date => 'added',
                                          unique => 'path',
                                          targeter_fields => [qw(action ttype category target_path)],
                                          fields => [qw(name path target_path ttype category mtime modestr)],
                                          #load_all => 1,  -- probably will never need this again.
                                      );

    my $title_sth = $walker->{dbh}->prepare ('update pages set title=? where path=?');
    my $keyword_clear_sth = $walker->{dbh}->prepare ('delete from keywords where path=?');
    my $links_clear_sth   = $walker->{dbh}->prepare ('delete from links where path=?');
    my $keyword_add_sth   = $walker->{dbh}->prepare ('insert into keywords (keyword, path) values (?, ?)');
    my $link_add_sth      = $walker->{dbh}->prepare ('insert into links (link, path) values (?, ?)');

    my $tt2 = Template->new({POST_CHOMP => 1, EVAL_PERL => 1});

    RUN_AGAIN:
    my $iterator = $walker->walk;

    #print $w->{add_sql} . "\n";
    #print $w->{mod_sql} . "\n";
    #die;

    my $count = 0;

    my @to_index = ();

    # First pass: find everything.
    while (my $node = $iterator->()) {    # TODO 243: slick <> notation like Iterator::Simple
       my ($action, $type, $cat, $target, $file, $role, $indent, $full) = @$node;
       
       #print "$action, $type, $cat, $full -> $target\n";
       $count ++;
       #die if $count > 20;
       #next;
       
       if ($type eq 'dir') {
          print "New directory $full\n";
          make_path($target);
       } elsif ($type eq 'html') {
          print "($action) $full\n";
          my $text = load_file ($full);
          while ($text =~ /\[##(.*?)##\]/) {
             my $tag = $1;
             $text =~ s/\[##$tag##\]/get_tag($tag, $full)/ge;
          }
          my $title = $file;
          if ($text =~ /<title>(.*)<\/title>/i) {
             $title = $1;
          }
          $title_sth->execute ($title, $full);
          
          write_file($target, $text);
          # Open and push through [##tagger##] to produce target.
       } elsif ($type eq 'wiki') {
          print "($action) $full\n";
          # Find appropriate template and push through [##tagger##] to produce target.
          my $text = get_template($full);
          my $values = load_markdown($full);
          my $explicit_post = '';
          $explicit_post = $values->{'posted'}       if defined $values->{'posted'};
          $explicit_post = $values->{'submit-time'}  if defined $values->{'submit-time'};
          $explicit_post = $values->{'created-time'} if defined $values->{'created-time'};
          $walker->adjust_add_time ($full, $explicit_post) if $explicit_post;
          $title_sth->execute ($values->{'title'}, $full);
          if ($values->{keywords}) {
             my @keywords = split (/ +/, $values->{keywords});
             $keyword_clear_sth->execute($full);
             $values->{blogline} = '';
             foreach my $kw (@keywords) {
                $keyword_add_sth->execute($kw, $full);
                if (not $values->{blogline}) {
                   $values->{blogline} = $explicit_post || '';
                   $values->{blogline} =~ s/ .*//;
                }
                $values->{blogline} .= " <a href=\"keyword_$kw.html\">$kw</a>";
             }
          }
          if (@{$values->{links}}) {
             $links_clear_sth->execute($full);
             foreach my $link (@{$values->{links}}) {
                $link_add_sth->execute($link, $full);
             }
          }
          while ($text =~ /\[##(.*?)##\]/) {
             my $tag = $1;
             $text =~ s/\[##$tag##\]/get_tag($tag, $full, $values)/ge;
          }
          #write_file($target, $text);
          my $output;
          $tt2->process(\$text, $values, \$output);
          write_file($target, $output);
       } elsif ($type eq 'wikx') {
          push @to_index, $node;  # Save for later, since later modifications might affect query results used in an index page.
          $count-- if $action eq 'index';  # Don't count this as a change for pushing the source to github.
       } else {
          # Copy over without further ado.
          next if $action eq 'zip'; # Even on rebuild, there's seriously no reason to copy a file that hasn't changed. Let's save a minute.
          print "($action) $full -> $target\n";
          copy ($full, $target);
       }
    }

    # Second pass: handle indexers. We'll probably want to have some kind of special indexer extension so we can identify them
    #                               without opening them (that'll speed stuff up).
    # This is starting to get kind of unwieldy, so pretty soon we'll want to start condensing and abstracting.
    my $run_again = 0;
    foreach my $node (@to_index) {
        my ($action, $type, $cat, $target, $file, $role, $indent, $full) = @$node;

        print "($action) $full\n";

        # Find appropriate template and push through [##tagger##] to produce target. 
        # -- TODO: obviously largely duplicates wiki handling above. work in progress.
        my $text = get_template($full);
        my $values = load_markdown($full);

        my $explicit_post = '';
        $explicit_post = $values->{'posted'}       if defined $values->{'posted'};
        $explicit_post = $values->{'submit-time'}  if defined $values->{'submit-time'};
        $explicit_post = $values->{'created-time'} if defined $values->{'created-time'};

        $walker->adjust_add_time ($full, $explicit_post) if $explicit_post;
        $title_sth->execute ($values->{'title'}, $full);

        if ($values->{'query'}) {
           my $sth = $walker->{dbh}->prepare ($values->{'query'});
           $sth->execute(); # Note: do we want a way to pass variables here?
           my @return_data = ();
           while (my $row = $sth->fetchrow_hashref) {
              $values->{'query-item'}->($row) if defined $values->{'query-item'};
              push @return_data, $row;
           }
           $values->{list_item} = \@return_data;
        }
        $values->{run}->($values) if defined $values->{run};
        
        if (defined $values->{generates}) {
           foreach my $gen (@{$values->{generates}}) {
              my ($block, $target) = split /=/, $gen;
              foreach my $row (@{$values->{list_item}}) {
                 my $output = $target;
                 while ($output =~ /\[(.*?)\]/) {
                    my $tag = $1;
                    $output =~ s/\[$tag\]/$row->{$tag}/ge;
                 }
                 my $text = $values->{$block};
                 while ($text =~ /\[##(.*?)##\]/) {
                    my $tag = $1;
                    $text =~ s/\[##$tag##\]/$row->{$tag}/ge;
                 }
                 if (write_file($output, $text)) {
                    $run_again = 1;
                    print "  -> $output\n";
                 }
              }
           }
        }

        while ($text =~ /\[##(.*?)##\]/) {
           my $tag = $1;
           $text =~ s/\[##$tag##\]/get_tag($tag, $full, $values)/ge;
        }
        
        #write_file($target, $text);
        #$tt2->process(\$text, $values, $target);
        my $output = '';
        $tt2->process(\$text, $values, \$output);
        write_file($target, $output);
    }
    if ($run_again) {
        print "Queries caused changes to publishable files, so the publisher is running again.\n";
        #goto RUN_AGAIN;
    }

    if ($count) {
       print "There were changes.\n";  # --> Here's where we can autocommit to github if there are changes or a rebuild.
    } else {
       print "No changes.\n";   # --> Still want to push target to github; nothing happens if no actual content changed.
    }
}

=head1 AUTHOR

Michael Roberts, C<< <michael at vivtek.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-app-heckle at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=App-Exegete>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Exegete


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Exegete>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Exegete>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Exegete>

=item * Search CPAN

L<http://search.cpan.org/dist/Exegete/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 Michael Roberts.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Exegete
