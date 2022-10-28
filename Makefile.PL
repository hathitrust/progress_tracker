use ExtUtils::MakeMaker;

WriteMakefile(
  NAME => 'ProgressTracker',
  VERSION_FROM => 'lib/ProgressTracker.pm',
  AUTHOR => 'Aaron Elkiss (aelkiss@umich.edu)',
  ABSTRACT => 'Progress tracking and reporting to Prometheus push gateway',
  PREREQ_PM => {
    'Net::Prometheus' => '0.11',
  },
  TEST_REQUIRES => {
    'Test::Spec'       => 0,
    'Test::Time'       => 0,
    'LWP::UserAgent'   => 0,
  },
  CONFIGURE_REQUIRES => { "ExtUtils::MakeMaker" => 0 },
);
