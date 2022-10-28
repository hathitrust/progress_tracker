![Tests](https://github.com/hathitrust/feed/actions/workflows/ci.yml/badge.svg)
[![Coverage Status](https://coveralls.io/repos/github/hathitrust/progress_tracker/badge.svg?branch=main)](https://coveralls.io/github/hathitrust/progress_tracker?branch=main)

# Progress Tracking with Prometheus Push Gateway

This module allows for tracking of statistics about batch jobs including number
of items or records processed in each stage of a job, how long each stage
takes, and when the job as a whole last succeeded. This enables configuration
of a single alert covering jobs that use these metrics.

## Installation

To run the tests successfully, you must set the `PUSHGATEWAY` environment variable:
```bash
export PUSHGATEWAY=http://localhost:9091
cpanm https://github.com/hathitrust/progress_tracker.git
```

Alternatively, you can install without running tests:
```bash
cpanm --notest https://github.com/hathitrust/progress_tracker.git
```

## Usage

### Summary

```perl
use ProgressTracker;
my $tracker = ProgressTracker->new();

while(my $line = <>) {
  # do some stuff..
  $tracker->inc();
}

$tracker->finalize;
```

This will report the number of lines processed to the push gateway every 1,000
lines.

### Stages

```perl
$tracker->start_stage('first_stage');

foreach my $item (@items) {
  # do some stuff
  $tracker->inc();
}

$tracker->start_stage('second_stage');

foreach my $item (@other_items) {
  # do some other stuff
  $tracker->inc();
}

$tracker->finalize();
```

You can also use this functionality to report on (for example) the number of
items performed in some other external operation:

```perl
$tracker->start_stage('first_stage');

my $count = go_do_some_things();

$tracker->inc($count);

$tracker->start_stage(second_stage');

my $second_count = go_do_some_other_things();

$tracker->inc($second_count);

$tracker->finalize();
```

Each stage will be reported with a separate `stage` label to the push gateway.

### Options

Except for `report_interval`, all can also be set with environment variables.
The URL to the push gateway must be specified either here or as an environment
variable. All other parameters are optional.

```perl
my $tracker = ProgressTracker->new(
  job => 'jobname.pl',
  pushgateway => 'http://localhost:9091',
  namespace => 'namespace',
  app => 'app',
  report_interval => 1000,
  success_interval => 65*60
);

```

* `job`: Name of the job. Defaults to the script name (`$0`) or the `JOB_NAME` env var. Populates `job` label in metrics.
* `pushgateway`: URL to the push gateway. Must be provided here or via `PUSHGATEWAY` env var.
* `namespace`: Optional. Populates `namespace` label in metrics. Typically the Kubernetes namespace the job is running in.
* `app`: Optional. Populates `app` label in metrics.
* `report_interval`: `ProgressTracker` will push metrics to the push gateway whenever this many records have been processed. Defaults to every 1,000 records processed. Ideally, set this to the number of records that can be processed between intervals when Prometheus scrapes your push gateway. By default, Prometheus scrapes the push gateway every 15 seconds, so setting this to the number of records you expect to process in 15 seconds would be reasonable.
* `success_interval`: If set, used to populate the `job_expected_success_interval` metric. Can be used with the generic `JobCompletionTimeoutExceeded` alert below. Set to the expected interval between completions of your job with some allowance for variance to prevent spurious alerts. For example, if this is a short-running job you expect to complete once per day, you might set this to 86700 seconds: 86400 seconds for one day, plus 5 minutes to cover variance in run time.

## Prometheus

### Metrics

All metrics are gauges, because they can reset between runs of the job.

* `job_duration_seconds`: Time spend running job in seconds, or a particular stage if the `stage` label is present.

* `job_expected_success_interval` Maximum expected time in seconds between job completions. Set once when the job starts.

* `job_records_processed`: Count of records processed by the job, or a particular stage if the `stage` label is set.

### Labels

* `job`: The name of the process or script that is running. Defaults to the filename of the running script (`$0`). Can be set with the `JOB_NAME` environment variable or the `job` parameter to `ProgressTracker->new()`. Required.
* `app`: The name of the application the job belongs to. Can be set with the `JOB_APP` environment variable or the `app` parameter to `ProgressTracker->new()`. Optional.
* `namespace`: The Kubernetes namespace this job is running in. Can be set with the `JOB_NAMESPACE` environment variable or the `namespace` parameter to `ProgressTracker->new()`. Optional.
* `stage`: The part of the job to which the metrics pertain. Can be set by calling `set_stage`, which then starts tracking duration and record count for that particular stage.


### Alerts

This alert will fire when a job exceeds its expected success interval.
success interval.

```
 - alert: JobCompletionTimeoutExceeded
   expr: "time() - job_last_success > job_expected_success_interval"
   for: 0m
   labels:
     severity: warning
   annotations:
      summary: "Job {{$labels.job}} has not completed successfully"
      description: "Job {{$labels.job}} has not completed successfully\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}"
```




