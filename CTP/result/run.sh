#!/bin/sh


{
	java net.tinyos.tools.Listen -comm serial@/dev/ttyUSB0:telos > ./twoNode.txt
}&
{
	java net.tinyos.tools.Listen -comm serial@/dev/ttyUSB1:telos > ./forward.txt
}
