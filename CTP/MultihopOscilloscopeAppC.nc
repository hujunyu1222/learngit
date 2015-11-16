/*
 * Copyright (c) 2006 Intel Corporation
 * All rights reserved.
 *
 * This file is distributed under the terms in the attached INTEL-LICENSE     
 * file. If you do not find these files, copies can be found by writing to
 * Intel Research Berkeley, 2150 Shattuck Avenue, Suite 1300, Berkeley, CA, 
 * 94704.  Attention:  Intel License Inquiry.
 */

/**
 * MultihopOscilloscope demo application using the collection layer. 
 * See README.txt file in this directory and TEP 119: Collection.
 *
 * @author David Gay
 * @author Kyle Jamieson
 */

configuration MultihopOscilloscopeAppC { }
implementation {
  components MainC, MultihopOscilloscopeC, LedsC, new TimerMilliC(), 
    new DemoSensorC() as Sensor;
  
  //hjy change
  components CC2420ActiveMessageC as CC2420Reader;
  MultihopOscilloscopeC.CC2420Packet -> CC2420Reader;
  //hjy change
  components CollectionC as CtpReader;
  MultihopOscilloscopeC.CtpPacket -> CtpReader;
  MultihopOscilloscopeC.CtpInfo -> CtpReader;
  //hjy change 
  components CC2420ControlC as RssiReader;
  MultihopOscilloscopeC.ReadRssi -> RssiReader.ReadRssi;
  //hjy change
  components new AlarmMicro16C();


  //MainC.SoftwareInit -> Sensor;
  
  MultihopOscilloscopeC.Boot -> MainC;
  MultihopOscilloscopeC.Timer -> TimerMilliC;
  //hjy change: add Timer1
  MultihopOscilloscopeC.Timer1 ->TimerMilliC;

  //hjy change: add Alarm0
  MultihopOscilloscopeC.Alarm0 -> AlarmMicro16C;

  MultihopOscilloscopeC.Read -> Sensor;
  MultihopOscilloscopeC.Leds -> LedsC;

  //
  // Communication components.  These are documented in TEP 113:
  // Serial Communication, and TEP 119: Collection.
  //
  components CollectionC as Collector,  // Collection layer
    ActiveMessageC,                         // AM layer
    new CollectionSenderC(AM_OSCILLOSCOPE), // Sends multihop RF
    SerialActiveMessageC,                   // Serial messaging
    new SerialAMSenderC(AM_OSCILLOSCOPE);   // Sends to the serial port

  MultihopOscilloscopeC.RadioControl -> ActiveMessageC;
  MultihopOscilloscopeC.SerialControl -> SerialActiveMessageC;
  MultihopOscilloscopeC.RoutingControl -> Collector;

  MultihopOscilloscopeC.Send -> CollectionSenderC;
  MultihopOscilloscopeC.SerialSend -> SerialAMSenderC.AMSend;
  MultihopOscilloscopeC.Snoop -> Collector.Snoop[AM_OSCILLOSCOPE];
  MultihopOscilloscopeC.Receive -> Collector.Receive[AM_OSCILLOSCOPE];
  MultihopOscilloscopeC.RootControl -> Collector;
  //hjy add Intercept
  MultihopOscilloscopeC.Intercept -> Collector.Intercept[AM_OSCILLOSCOPE];
  //hjy add Timestamp
  components CC2420PacketC;
  MultihopOscilloscopeC.PacketTimeStamp -> CC2420PacketC.PacketTimeStampMilli;

  components new PoolC(message_t, 10) as UARTMessagePoolP,
    new QueueC(message_t*, 10) as UARTQueueP;
 

  MultihopOscilloscopeC.UARTMessagePool -> UARTMessagePoolP;
  MultihopOscilloscopeC.UARTQueue -> UARTQueueP;
  
  components new PoolC(message_t, 20) as DebugMessagePool,
    new QueueC(message_t*, 20) as DebugSendQueue,
    new SerialAMSenderC(AM_CTP_DEBUG) as DebugSerialSender,
    UARTDebugSenderP as DebugSender;

  DebugSender.Boot -> MainC;
  DebugSender.UARTSend -> DebugSerialSender;
  DebugSender.MessagePool -> DebugMessagePool;
  DebugSender.SendQueue -> DebugSendQueue;
  Collector.CollectionDebug -> DebugSender;

}
