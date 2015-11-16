#!/bin/sh

make telosb
make telosb install,17 bsl,/dev/ttyUSB1
java net.tinyos.tools.Listen -comm serial@/dev/ttyUSB0:telosb
