#!/bin/bash

bin/wait-for --timeout=300 pushgateway:9091 
cover -test -report Coveralls 
