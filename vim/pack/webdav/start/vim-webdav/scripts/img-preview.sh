#!/bin/bash
# Render a remote image as text for a vim popup, one line per row.
# A popup draws characters, not pixels, so the picture is carried by glyphs.
#
# Usage: img-preview.sh <url> <width> [auth_arg] [style]
# Example: img-preview.sh "https://host/a/b.webp" 48 "-u user:pass" color
#
# color (default) prints two xterm-256 cube indices per cell, "top,bottom".
#   The caller draws an upper half block and paints the top pixel as the
#   foreground and the bottom one as the background, which doubles the vertical
#   resolution and keeps the colours. Indices, not hex, because the same number
#   gives both the cterm colour and the gui one.
# braille packs 2x4 dots into a cell, so a cell carries 8 samples instead of 1.
#   Monochrome, but the finest detail of the three.
# blocks uses five shades of block per cell. Coarsest, and the only one that
#   needs neither colour nor a dither pattern to read.

set -euo pipefail

URL="$1"
WIDTH="${2:-48}"
AUTH_ARG="${3:-}"
STYLE="${4:-color}"

# Transparency flattens onto white so a cut-out subject does not read as solid
# ink. A terminal cell is about twice as tall as it is wide, so the geometry
# below differs by how many samples each style takes from a cell.
flatten=(-background white -alpha remove -alpha off)

case "$STYLE" in
  blocks)
    # One sample per cell, so the height is halved after fitting the width.
    convert=(-colorspace gray -auto-level -resize "${WIDTH}x" -resize 100%x50%)
    format=pgm
    ;;
  braille)
    # Two samples across and four down. Those subsamples are near enough to
    # square that fitting the width alone keeps the proportions.
    convert=(-colorspace gray -auto-level -resize "$((WIDTH * 2))x" -monochrome)
    format=pgm
    ;;
  color)
    # One sample across and two down, which makes the samples square.
    convert=(-resize "${WIDTH}x")
    format=ppm
    ;;
  *)
    echo "unknown style: $STYLE" >&2
    exit 2
    ;;
esac

curl -s --max-time 10 $AUTH_ARG "$URL" \
| magick - "${flatten[@]}" "${convert[@]}" -depth 8 "${format}:-" \
| perl -e '
    binmode(STDIN);
    binmode(STDOUT, ":utf8");
    my $style = shift @ARGV;
    local $/;
    my $data = <STDIN>;

    if ($style eq "color") {
      $data =~ s/^P6\s+(\d+)\s+(\d+)\s+(\d+)\s//s or exit 1;
      my ($w, $h) = ($1, $2);
      # The 6x6x6 xterm cube. Its levels are not evenly spaced, so the nearest
      # one is found by comparison rather than by dividing.
      my @level = (0, 95, 135, 175, 215, 255);
      my $step = sub {
        my $v = shift;
        my ($best, $dist) = (0, 256);
        for my $i (0 .. 5) {
          my $d = abs($level[$i] - $v);
          ($best, $dist) = ($i, $d) if $d < $dist;
        }
        $best;
      };
      my $cube = sub {
        my ($x, $y) = @_;
        return 215 if $y >= $h;   # past the bottom edge, show white
        my $o = ($y * $w + $x) * 3;
        36 * $step->(ord(substr($data, $o, 1)))
          + 6 * $step->(ord(substr($data, $o + 1, 1)))
          + $step->(ord(substr($data, $o + 2, 1)));
      };
      for (my $y = 0; $y < $h; $y += 2) {
        print join(" ", map { $cube->($_, $y) . "," . $cube->($_, $y + 1) } 0 .. $w - 1), "\n";
      }
      exit 0;
    }

    $data =~ s/^P5\s+(\d+)\s+(\d+)\s+(\d+)\s//s or exit 1;
    my ($w, $h) = ($1, $2);
    my $at = sub { my ($x, $y) = @_; ord(substr($data, $y * $w + $x, 1)) };

    if ($style eq "blocks") {
      my @ramp = split //, " \x{2591}\x{2592}\x{2593}\x{2588}";
      for my $y (0 .. $h - 1) {
        my $line = "";
        $line .= $ramp[int((255 - $at->($_, $y)) * $#ramp / 255)] for 0 .. $w - 1;
        print "$line\n";
      }
      exit 0;
    }

    # U+2800 plus a bitmask. Dots 1-6 fill the top three rows column by column
    # and dots 7-8 form the fourth row, which is why the fourth entry of each
    # column jumps to bit 6 or 7 instead of continuing in sequence.
    my @bit = ([0, 1, 2, 6], [3, 4, 5, 7]);
    for (my $y = 0; $y < $h; $y += 4) {
      my $line = "";
      for (my $x = 0; $x < $w; $x += 2) {
        my $mask = 0;
        for my $dx (0 .. 1) {
          for my $dy (0 .. 3) {
            my ($px, $py) = ($x + $dx, $y + $dy);
            next if $px >= $w || $py >= $h;
            $mask |= 1 << $bit[$dx][$dy] if $at->($px, $py) < 128;
          }
        }
        $line .= chr(0x2800 + $mask);
      }
      print "$line\n";
    }
  ' "$STYLE"
