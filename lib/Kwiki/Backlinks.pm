package Kwiki::Backlinks;
use Kwiki::Plugin '-Base';
use Kwiki::Installer '-base';

const class_id             => 'backlinks';
const class_title          => 'Backlinks';
const css_file             => 'backlinks.css';
const separator            => '____';

field hooked => 0;

# This filesystem based style of data storage is based
# on one of the early implementation of Backlinks for MoinMoin

our $VERSION = '0.02';

sub register {
    my $registry = shift;
    $registry->add(widget => 'backlinks',
                   template => 'backlinks.html',
                   show_for => 'display',
                  );
    $registry->add(hook => 'page:store', post => 'update_hook');
}

# init is called on load class,
# which the installer does, so skip is in cgi
sub init {
    return unless $self->is_in_cgi;
    super;
    $self->assert_database;
}

sub assert_database {
    return unless io->dir($self->plugin_directory)->empty;
    for my $page ($self->hub->pages->all) {
        $self->update($page);
    }
}

sub update_hook {
    my $page = $self;
    my $hook = pop;
    $self = $self->hub->backlinks;
    # save current as we need to manipulate within update and below
    my $current = $self->hub->pages->current;
    $self->update($page);
    $self->hub->pages->current($current);
}

sub update {
    my $page = shift;
    my $units;
    my $formatter = $self->hub->formatter;
    unless ($self->hooked) {
        my $table = $formatter->table;
        for my $class (@$table{qw(titlewiki wiki forced)}) {
            $self->hooked($self->hub->add_hook(
                $class . '::matched', post => 'backlinks:add_match'
            ));
        }
        $self->hooked(1);
    }
    $self->hub->pages->current($page);
    $self->hub->formatter->text_to_parsed($page->content);
}

# XXX note that debugging work here showed that 
# matched is being called in the parser multiple
# times. Is this normal? 
sub add_match {
    my $hook = pop;
    my $match = shift or return;
    $self = $self->hub->backlinks;
    $match =~ /(\w+)]?$/;
    $self->write_link($self->uri_escape($1));
}

sub clean_current_link {
    my ($source, $dest) = @_;
    my $chunk = $source . $self->separator . $dest;
    my $dir = $self->plugin_directory . '/';
    my $path = $dir . $chunk;
    unlink($path);
}

sub write_link {
    my $destination_id = shift;
    my $source_id = $self->hub->pages->current->id;
    $self->clean_current_link($source_id, $destination_id);
    $self->touch_index_file($source_id, $destination_id);
}

sub get_filename {
    my ($source, $dest) = @_;
    my $dir = $self->plugin_directory;
    "$dir/$source" . $self->separator . $dest;
}

sub touch_index_file {
    my $file = $self->get_filename(@_);
    my $fileref = io($file);
    $fileref->touch->assert;
}

sub all_backlinks {
    my $pages = $self->hub->pages;
    [
        map {
            my $page = $pages->new_page($_);
            +{ page_uri => $page->uri, page_title => $page->title} 
        } $self->get_backlinks_for_page
    ]
}

sub get_backlinks_for_page {
    my $page_id = $self->pages->current->id;
    my $chunk = $self->separator . $page_id;
    my $dir = $self->plugin_directory . '/';
    my $path = $dir . "*$chunk";
    map { s/^$dir//; s/$chunk$//; $_} glob($path);
}


__DATA__

=head1 NAME

Kwiki::Backlinks - Maintain and display a simple database of links to the current page

=head1 DESCRIPTION

Kwiki::Backlinks uses the file system to keep track of which pages in 
a wiki link to which pages in the same wiki. That data is then used
to display on every page in the wiki. This is considered a nice
feature by some and an absolute requirement for enabling emergent 
understanding by others.

You can see Kwiki::Backlinks in action at L<http://www.burningchrome.com/wiki/>

This code also happens to demonstrate a novel use of Spoon hooks

=head1 AUTHORS

Chris Dent, <cdent@burningchrome.com>
Brian Ingerson, <ingy@ttul.org>

=head1 SEE ALSO

L<Kwiki>
L<Spoon::Hooks>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005, Chris Dent

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
__template/tt2/backlinks.html__
<!-- BEGIN backlinks -->
<style>
div#backlinks {
    font-family: Helvetica, Arial, sans-serif;
    overflow: hidden;
}
#backlinks a { 
    font-size: small;
    display: block;
    text-align: center;
    text-decoration: none;
    padding-bottom: .25em;
}
#backlinks h3 {
    font-size: small;
    text-align: center;
    letter-spacing: .25em;
    padding-bottom: .25em;
}
</style>
[% backlinks = hub.backlinks.all_backlinks %]
[% IF backlinks.size %]
<div id="backlinks">
<h3>BACKLINKS</h3>
[% FOREACH link = backlinks %]
<a href="[% script_name %]?[% link.page_uri %]">[% link.page_title %]</a>
[% END %]
</div> 
[% END %]
<!-- END backlinks -->
