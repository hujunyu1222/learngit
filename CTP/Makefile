COMPONENT=MultihopOscilloscopeAppC
CFLAGS += -I$(TOSDIR)/lib/net/ -I$(TOSDIR)/lib/net/ctp  -I$(TOSDIR)/lib/net/4bitle

# To change the transmit power
#CFLAGS += -DCC2420_DEF_RFPOWER=10

#remove ACK
#CFLAGS += -DCC2420_NO_ACKNOWLEDGEMENTS

#printf
#CFLAGS += -I$(TOSDIR)/lib/printf

#change channel
CFLAGS += -DCC2420_DEF_CHANNEL=25

#change the message_t size
CFLAGS +=-D'TOSH_DATA_LENGTH=48'

include $(MAKERULES)


