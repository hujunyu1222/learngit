#!/bin/sh

make telosb

make telosb install,500 bsl,/dev/ttyUSB0
make telosb install,23 bsl,/dev/ttyUSB1
make telosb install,25 bsl,/dev/ttyUSB2
