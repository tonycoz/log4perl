###########################################
# Test Suite for Log::Log4perl::Filter
# Mike Schilli, 2003 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Test::More tests => 9;

use Log::Log4perl;

#############################################
# Use a pattern-matching subroutine as filter
#############################################

Log::Log4perl->init(\ <<'EOT');
  log4perl.logger.Some = INFO, A1
  log4perl.filter.MyFilter    = sub { /let this through/ }
  log4perl.appender.A1        = Log::Log4perl::Appender::TestBuffer
  log4perl.appender.A1.Filter = MyFilter
  log4perl.appender.A1.layout = Log::Log4perl::Layout::SimpleLayout
EOT

my $buffer = Log::Log4perl::Appender::TestBuffer->by_name("A1");

    # Define a logger
my $logger = Log::Log4perl->get_logger("Some.Where");

    # Let this through
$logger->info("Here's the info, let this through!");

    # Suppress this
$logger->info("Here's the info, suppress this!");

like($buffer->buffer(), qr(let this through), "pattern-match let through");
unlike($buffer->buffer(), qr(suppress), "pattern-match block");

Log::Log4perl->reset();
$buffer->reset();

#############################################
# Block in filter based on message level
#############################################
Log::Log4perl->init(\ <<'EOT');
  log4perl.logger.Some = INFO, A1
  log4perl.filter.MyFilter        = sub {    \
       my %p = @_;                           \
       ($p{log4p_level} eq "WARN") ? 1 : 0;  \
                                          }
  log4perl.appender.A1        = Log::Log4perl::Appender::TestBuffer
  log4perl.appender.A1.Filter = MyFilter
  log4perl.appender.A1.layout = Log::Log4perl::Layout::SimpleLayout
EOT

$buffer = Log::Log4perl::Appender::TestBuffer->by_name("A1");

    # Define a logger
$logger = Log::Log4perl->get_logger("Some.Where");

    # Suppress this
$logger->info("This doesn't make it");

    # Let this through
$logger->warn("This passes the hurdle");


like($buffer->buffer(), qr(passes the hurdle), "level-match let through");
unlike($buffer->buffer(), qr(make it), "level-match block");

Log::Log4perl->reset();
$buffer->reset();

#############################################
# Filter combination with Filter::Bool
#############################################
Log::Log4perl->init(\ <<'EOT');
    log4perl.logger = INFO, A1

    log4perl.filter.Match1       = sub { /let this through/ }
    log4perl.filter.Match2       = sub { /and that, too/ }
    log4perl.filter.Match3       = sub { /suppress/ }
    log4perl.filter.MyBool       = Log::Log4perl::Filter::Bool
    log4perl.filter.MyBool.logic = !Match3 && (Match1 || Match2)

    log4perl.appender.A1        = Log::Log4perl::Appender::TestBuffer
    log4perl.appender.A1.Filter = MyBool
    log4perl.appender.A1.layout = Log::Log4perl::Layout::SimpleLayout
EOT

$buffer = Log::Log4perl::Appender::TestBuffer->by_name("A1");

    # Define a logger
$logger = Log::Log4perl->get_logger("Some.Where");

    # Let through
$logger->info("let this through");
like($buffer->buffer(), qr(let this through), "Boolean 1");
$buffer->buffer("");

    # Block
$logger->info("suppress, let this through");
is($buffer->buffer(), "", "Boolean 2");
$buffer->buffer("");

    # Let through
$logger->info("and that, too");
like($buffer->buffer(), qr(and that, too), "Boolean 3");
$buffer->buffer("");

    # Block
$logger->info("and that, too suppress");
is($buffer->buffer(), "", "Boolean 4");
$buffer->buffer("");

    # Block
$logger->info("let this through - and that, too - suppress");
is($buffer->buffer(), "", "Boolean 5");
$buffer->buffer("");

Log::Log4perl->reset();
$buffer->reset();
