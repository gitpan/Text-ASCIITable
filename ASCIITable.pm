#
# Module Text::ASCIITable
# By H�kon Nessj�en <lunatic@skonux.net>
#
package Text::ASCIITable;

@ISA=qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
$VERSION = '0.02';
use Exporter;
use strict;
use Carp;

sub new {
  my $self = {tbl_cols => [],tbl_rows => [],tbl_alignright => []};
  bless $self;
  return $self;
}

=head1 NAME

Text::ASCIITable - Create a nice formatted table using ASCII characters. Nice, if you want to output dynamic
text to your console or other fixed-size displays.

=head1 SYNOPSIS

use Text::ASCIITable;

$t = new Text::ASCIITable;
$t->setCols(['Nickname','Name']);
$t->addRow('Lunatic-|','H�kon Nessj�en');
$t->addRow('tesepe','William Viker');
$t->addRow('espen','Espen Ursin-Holm');
$t->addRow('mamikk','Martin Mikkelsen');
$t->addRow('p33r','Espen A. J�tte');
print $t->draw();

=head1 FUNCTIONS

=head2 setCols(@cols)

Define the columns for the table(compare with <TH> in HTML). For example C<setCols(['Id','Nick','Name'])>.
B<Note> that you cannot add Cols after you have added a row.

=cut

sub setCols {
  my $self = shift;
  my $tmp = shift;
  do { print STDERR Carp::shortmess "setCols needs an array"; return 1; } unless defined($tmp);
  my @cols = @{$tmp};
  do { print STDERR Carp::shortmess "setCols needs an array"; return 1; } unless scalar(@cols) != 0;
  do { print STDERR Carp::shortmess "Cannot edit cols at this state"; return 1; } unless scalar(@{$self->{tbl_rows}}) == 0;
  @{$self->{tbl_cols}} = @cols;
  return undef;
}

=head2 addCol($col)

Add a column to the columnlist. This still can't be done after you have added a row.

=cut

sub addCol {
  my ($self,$col) = @_;
  do { print STDERR Carp::shortmess "addCol needs a string"; return 1; } unless defined($col);
  do { print STDERR Carp::shortmess "Cannot add cols at this state"; return 1; } if (scalar(@{$self->{tbl_rows}}) != 0);
  push @{$self->{tbl_cols}},$col;
  return undef;
}

=head2 addRow(@collist)

Adds one row to the table. This must be an array of strings. If you defined 3 columns. This array must
have 3 items in it. And so on. Should be self explanatory.

=cut

sub addRow {
  my $self = shift;
  do { print STDERR Carp::shortmess "Received too few columns"; return 1; } if scalar(@_) < scalar(@{$self->{tbl_cols}});
  do { print STDERR Carp::shortmess "Received too many columns"; return 1; } if scalar(@_) > scalar(@{$self->{tbl_cols}});
  push @{$self->{tbl_rows}}, [@_];
  return undef;
}

=head2 alignColRight($col)

Given a columnname, it aligns all data to the right in the table. This looks nice on numerical displays
in a column. The column names in the table will not be unaffected by the alignment.

=cut

sub alignColRight {
  my ($self,$col) = @_;
  do { print STDERR Carp::shortmess "alignColRight needs a string"; return 1; } unless defined($col);
  do { print STDERR Carp::shortmess "Could not find '$col' in columnlist"; return 1; } unless defined(finn($col,$self->{tbl_cols}));
  return undef if defined(finn($col,$self->{tbl_alignright}));
  push @{$self->{tbl_alignright}}, $col;

  return undef;
}

# now the real stuff

sub getColWidth {
  my ($self,$colname) = @_;
  my $pos = finn($colname,$self->{tbl_cols});
  my $maxsize = length($colname);

  do { print STDERR Carp::shortmess "Could not find '$colname' in columnlist"; return 1; } unless defined($pos);
  for my $row (@{$self->{tbl_rows}}) {
    $maxsize = length(@{$row}[$pos]) if (length(@{$row}[$pos]) > $maxsize);
  }

  # maxsize pluss the spaces on each side
  return $maxsize + 2;
}

=head2 getTableWidth()

If you need to know how wide your table will be before you draw it. Use this function.

=cut

sub getTableWidth {
  my $self = shift;
  my $totalsize = 1;
  for (@{$self->{tbl_cols}}) {
    $totalsize += $self->getColWidth($_) + 1;
  }
  return $totalsize;
}

sub drawLine {
  my ($self,$start,$stop,$line,$delim) = @_;
  do { print STDERR Carp::shortmess "Missing reqired parameters"; return 1; } unless defined($stop);
  $line = defined($line) ? $line : '-'; 
  $delim = defined($delim) ? $delim : '+'; 

  my $contents;

  $contents = $start;

  for (my $i=0;$i < scalar(@{$self->{tbl_cols}});$i++) {
    my $offset = 0;
    $offset = length($start) - 1 if ($i == 0);
    $offset = length($stop) - 1 if ($i == scalar(@{$self->{tbl_cols}}) -1);

    $contents .= $line x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - $offset);

    $contents .= $delim if ($i != scalar(@{$self->{tbl_cols}}) - 1);
  }
  return $contents .= $stop."\n";
}

sub drawRow {
  my ($self,$row,$allowalign,$delim) = @_;
  do { print STDERR Carp::shortmess "Missing reqired parameters"; return 1; } unless defined($row);
  $allowalign = defined($allowalign) ? $allowalign : 1;
  $delim = defined($delim) ? $delim : '|';

  my $contents = $delim;
  for (my $i=0;$i<scalar(@{$row});$i++) {
    my $text = @{$row}[$i];
    if ($allowalign == 1 && scalar(@{$self->{tbl_alignright}}) && defined(finn(@{$self->{tbl_cols}}[$i],$self->{tbl_alignright}))) {
      $contents .= ' ' x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - length($text) - 1);
      $contents .= $text.' '.$delim;
    } else {
      $contents .= ' '.$text;
      $contents .= ' ' x ($self->getColWidth(@{$self->{tbl_cols}}[$i]) - length($text) - 1);
      $contents .= $delim;
    }
  }
  $contents .= "\n";
}

=head2 draw([@topdesign,@rowdelims,@middle,@bottom])

All the arrays containing the layout is optional. If you want to make your own "design" to the table, you
can do that by giving this method these arrays containing information about which characters to use
where.

Examples:

The easiest way:
 $t->draw();

Explanatory example:
 $t->draw( ['L','R','-','D'],   # L------D------R
           ['H','M'],           # | info H info |  (the M is delemiter on the rows, like H is on the colums-row)
           ['L','R','-','D'],   # L------D------R
           ['L','R ','_','D']   # L______D______R
          ));

Nice example:
 $t->draw( ['.','.','-','-'],   # .-------------.
           ['|','|'],           # | info | info |
           ['|','|','-','-'],   # |-------------|
           [' \\','/ ','_','|'] #  \_____|_____/
          ));

Nice example2:
 $t->draw( ['.=','=.','-','-'],   # .=-----------=.
           ['|','|'],             # | info | info |
           ['|=','=|','-','+'],    # |=-----+-----=|
           ["'=","='",'-','-']    # '=-----------='
          ));

=cut

sub draw {
  my $self = shift;
  my ($top,$rowdelims,$middle,$bottom) = @_;
  my ($tstart,$tstop,$tline,$tdelim) = defined($top) ? @{$top} : undef;
  my ($mstart,$mstop,$mline,$mdelim) = defined($middle) ? @{$middle} : undef;
  my ($bstart,$bstop,$bline,$bdelim) = defined($bottom) ? @{$bottom} : undef;
  my ($trowdelim,$browdelim) = defined($rowdelims) ? @{$rowdelims} : undef;
  my $contents="";
  $contents .= $self->drawLine(iif($tstart,'.'),iif($tstop,'.'),$tline,$tdelim);
  $contents .= $self->drawRow($self->{tbl_cols},0,$trowdelim);
  $contents .= $self->drawLine(iif($mstart,' >'),iif($mstop,'< '),$mline,$mdelim);
  for (@{$self->{tbl_rows}}) {
    $contents .= $self->drawRow($_,1,$browdelim);
  }
  $contents .= $self->drawLine(iif($bstart,"'"),iif($bstop,"'"),$bline,$bdelim);
  return $contents;
}
sub iif {
  my ($if,$els) = @_;
  return $els unless defined $if;
  return $if
}
# couldn't find a better way to search in an array, than to make this function. Please tell me the right way..
sub finn {
  my $naal = shift;
  my $arr = shift;
  return undef unless defined $arr;
  for (my $i=0;$i < scalar(@{$arr});$i++) {
    if (@{$arr}[$i] eq $naal) {
      return $i;
    }
  }
  return undef;
}


1;

__END__

=head1 REQUIRES

Exporter, Carp

=head1 AUTHOR

H�kon Nessj�en, lunatic@skonux.net

=head1 COPYRIGHT

Copyright 2002-2003 by H�kon Nessj�en.
All rights reserved.
This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
