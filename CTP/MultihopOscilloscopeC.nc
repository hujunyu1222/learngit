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

#include "Timer.h"
#include "MultihopOscilloscope.h"
//hjy change
//#include "printf.h"

module MultihopOscilloscopeC @safe(){
  uses {
    // Interfaces for initialization:
    interface Boot;
    interface SplitControl as RadioControl;
    interface SplitControl as SerialControl;
    interface StdControl as RoutingControl;
    
    // Interfaces for communication, multihop and serial:
    interface Send;
    interface Receive as Snoop;
    interface Receive;
    interface AMSend as SerialSend;
    interface CollectionPacket;
    interface RootControl;
        //hjy add Intercept to forward
    interface Intercept;

    interface Queue<message_t *> as UARTQueue;
    interface Pool<message_t> as UARTMessagePool;

    // Miscalleny:
    interface Timer<TMilli>;
    //hjy change:add Timer1
    interface Timer<TMilli> as Timer1;
    //hjy change:add Alarm0
    interface Alarm<TMicro,uint16_t> as Alarm0;

    interface Read<uint16_t>;
    interface Leds;

    //hjy change CC2420
    interface CC2420Packet;
    //hjy change
    interface CtpPacket;
    interface CtpInfo;
    //hjy change Timestamp
    interface PacketTimeStamp<TMilli,uint32_t>;
    //hjy change
    //interface CC2420Register as ReadRssi;
    interface Read<uint16_t> as ReadRssi;
  }
}

implementation {
  task void uartSendTask();
  static void startTimer();
  static void fatal_problem();
  static void report_problem();
  static void report_sent();
  static void report_received();

  //hjy change
  void fillPacket();
  //hjy change
  bool changeSend(message_t* msg, void *payload, uint8_t len);
  uint8_t uartlen;
  message_t sendbuf;
  message_t uartbuf;
  bool sendbusy=FALSE, uartbusy=FALSE;

  /* Current local state - interval, version and accumulated readings */
  oscilloscope_t local;
  //hjy change to get the channel RSSI
  sense_t channelState;
  //hjy change: control the amount of the Packets(sender)
  uint16_t maxSend;

  uint8_t reading; /* 0 to NREADINGS */

  //hjy change:
  uint8_t rssReading; /* 0 to RSSIREADINGS*/

  /* When we head an Oscilloscope message, we check it's sample count. If
     it's ahead of ours, we "jump" forwards (set our count to the received
     count). However, we must then suppress our next count increment. This
     is a very simple form of "time" synchronization (for an abstract
     notion of time). */
  bool suppress_count_change;

  // 
  // On bootup, initialize radio and serial communications, and our
  // own state variables.
  //
  event void Boot.booted() {
    local.interval = DEFAULT_INTERVAL;
    local.id = TOS_NODE_ID;
    //local.id = 12;
    //local.version = 0;
    local.version = TOS_NODE_ID;
    
    //hjy change:maxSend
    maxSend = 300;

    // Beginning our initialization phases:
    if (call RadioControl.start() != SUCCESS)
      fatal_problem();

    if (call RoutingControl.start() != SUCCESS)
      fatal_problem();
    //start the Timer. if the node is not root, send the message_t every 2000
    
    //hjy change :set timer, control the interval between every packet
    //	call Timer1.startPeriodic(2000);
  }

  event void RadioControl.startDone(error_t error) {
    if (error != SUCCESS)
      fatal_problem();

    if (sizeof(local) > call Send.maxPayloadLength())
      fatal_problem();

    if (call SerialControl.start() != SUCCESS)
      fatal_problem();
  }

  event void SerialControl.startDone(error_t error) {
    if (error != SUCCESS)
      fatal_problem();

    // This is how to set yourself as a root to the collection layer:
    if (local.id % 500 == 0)
      call RootControl.setRoot();

    startTimer();
  }

  static void startTimer() {
	//hjy change
    if (call Timer.isRunning()) call Timer.stop();
	if (call Timer1.isRunning()) call Timer1.stop();

     call Timer.startPeriodic(20);
     call Timer1.startPeriodic(2000);
	 //call Alarm0.start(128);
    reading = 0;
    rssReading =0;
  }

  event void RadioControl.stopDone(error_t error) { }
  event void SerialControl.stopDone(error_t error) { }

  //
  // Only the root will receive messages from this interface; its job
  // is to forward them to the serial uart for processing on the pc
  // connected to the sensor network.
  //
  event message_t*
  Receive.receive(message_t* msg, void *payload, uint8_t len) {
    oscilloscope_t* in = (oscilloscope_t*)payload;
    oscilloscope_t* out;
    nx_uint16_t tmp;

    //hjy change get information 
    in->rssi = call CC2420Packet.getRssi(msg);
    in->etx = call CtpPacket.getEtx(msg);
    in->origin =(nx_uint16_t*)call CtpPacket.getOrigin(msg);
    in->thl = call CtpPacket.getThl(msg);
    in->seq = call CtpPacket.getSequenceNumber(msg);
    if (call PacketTimeStamp.isValid(msg) == TRUE)
    	in->receiveTime = (nx_uint32_t)call PacketTimeStamp.timestamp(msg);
    //hjy change led1
    //call Leds.led2Toggle();


    if (uartbusy == FALSE) {
      out = (oscilloscope_t*)call SerialSend.getPayload(&uartbuf, sizeof(oscilloscope_t));
      if (len != sizeof(oscilloscope_t) || out == NULL) {
	return msg;
      }
      else {
	memcpy(out, in, sizeof(oscilloscope_t));
      }
      uartlen = sizeof(oscilloscope_t);
      post uartSendTask();
    } else {
      // The UART is busy; queue up messages and service them when the
      // UART becomes free.
      message_t *newmsg = call UARTMessagePool.get();
      if (newmsg == NULL) {
        // drop the message on the floor if we run out of queue space.
        report_problem();
        return msg;
      }

      //Serial port busy, so enqueue.
      out = (oscilloscope_t*)call SerialSend.getPayload(newmsg, sizeof(oscilloscope_t));
      if (out == NULL) {
	return msg;
      }
      memcpy(out, in, sizeof(oscilloscope_t));

      if (call UARTQueue.enqueue(newmsg) != SUCCESS) {
        // drop the message on the floor and hang if we run out of
        // queue space without running out of queue space first (this
        // should not occur).
        call UARTMessagePool.put(newmsg);
        fatal_problem();
        return msg;
      }
    }

    return msg;
  }

  task void uartSendTask() {
  	//hjy change 0xffff --> 0x1919
    if (call SerialSend.send(0x1919, &uartbuf, uartlen) != SUCCESS) {
      report_problem();
    } else {
      uartbusy = TRUE;
    }
    
  }

  event void SerialSend.sendDone(message_t *msg, error_t error) {
   uartbusy = FALSE;
    if (call UARTQueue.empty() == FALSE) {
      // We just finished a UART send, and the uart queue is
      // non-empty.  Let's start a new one.
      message_t *queuemsg = call UARTQueue.dequeue();
      if (queuemsg == NULL) {
        fatal_problem();
        return;
      }
      memcpy(&uartbuf, queuemsg, sizeof(message_t));
      if (call UARTMessagePool.put(queuemsg) != SUCCESS) {
        fatal_problem();
        return;
      }
      post uartSendTask();
    }
    
  }

  //
  // Overhearing other traffic in the network.
  //
  event message_t* 
  Snoop.receive(message_t* msg, void* payload, uint8_t len) {
    oscilloscope_t *omsg = payload;

    //hjy change
    call Leds.led2On();
   // report_received();

    // If we receive a newer version, update our interval. 
    if (omsg->version > local.version) {
      local.version = omsg->version;
      local.interval = omsg->interval;
      startTimer();
    }

    // If we hear from a future count, jump ahead but suppress our own
    // change.
    if (omsg->count > local.count) {
      local.count = omsg->count;
      suppress_count_change = TRUE;
    }

    return msg;
  }

  /*hjy add Intercept

  */
  event bool Intercept.forward(message_t* msg, void* payload, uint8_t len) {
 	
//	oscilloscope_t* in = (oscilloscope_t*)payload;
//	if (in -> origin == 25)

		//call Leds.led0Toggle();
		//fillPacket();
		//return TRUE;
	return changeSend(msg, payload, len);

  }

  /*hjy add change packet

  */
  bool changeSend(message_t* msg, void* payload, uint8_t len) {
  	//change Packet
	oscilloscope_t *in = (oscilloscope_t*) payload;
	oscilloscope_t *out;
	int parentIndex = (int)call CtpPacket.getThl(msg);

	in->parent[parentIndex-1] = TOS_NODE_ID;
	in->hopRssi[parentIndex-1] = call CC2420Packet.getRssi(msg); 
	call Leds.led0Toggle();
	return TRUE;
  	//
	/*
	if (sendbusy == FALSE) {
		call Leds.led0Toggle();
	        out = (oscilloscope_t *)call Send.getPayload(&sendbuf, sizeof(oscilloscope_t));
		if (out == NULL) {
			fatal_problem();
		}
		else {
			memcpy(out, in, sizeof(oscilloscope_t));
		}

	    	if (call Send.send(&sendbuf, sizeof(oscilloscope_t)) == SUCCESS) {
	    		sendbusy = TRUE;
			return TRUE;
	       	}
		else {
			report_problem();
			return FALSE;
		}
	    

	     }

	else {
		return FALSE;
	}
	*/
  }
  


  /* At each sample period:
     - if local sample buffer is full, send accumulated samples
     - read next sample
  */
  event void Timer.fired() {
    /*
    if (reading == NREADINGS) {
      if (!sendbusy) {
	oscilloscope_t *o = (oscilloscope_t *)call Send.getPayload(&sendbuf, sizeof(oscilloscope_t));
	if (o == NULL) {
	  fatal_problem();
	  return;
	}
	memcpy(o, &local, sizeof(local));
	if (call Send.send(&sendbuf, sizeof(local)) == SUCCESS)
	  sendbusy = TRUE;
        else
          report_problem();
      }
      
      reading = 0;
     // Part 2 of cheap "time sync": increment our count if we didn't
     //    jump ahead.
      if (!suppress_count_change)
      //hjy change
       local.count ++;
      //local.count += 7;
      suppress_count_change = FALSE;
    }

    if (call Read.read() != SUCCESS)
      fatal_problem();
   */
   call ReadRssi.read();
   /* CC2420SpiC
   if (call ReadRssi.read(&data) != SUCCESS) {
   	report_problem();
   }
   channelState.channelRssi = data;
   call SerialSend.send(0x18, &channelState, sizeof(sense_t));
   */
   }
   
   //hjy change
   event void ReadRssi.readDone(error_t error, uint16_t data) {
//	rssiData = data;
  	channelState.channelRssi = 9;
	if (rssReading < RSSIREADINGS)
	{
		local.regRssi[rssReading++] = data;
		//local.regRssi[2] = data;
	}
	else
	{
		call SerialSend.send(0x1818, &local, sizeof(local));
		rssReading = 0;
	}
	//startTimer();
   }


   

   //hjy change ReadRssi.readDone()
   /*
   event void ReadRssi.readDone(error_t result, uint16_t data) {
   	if (result != SUCCESS) {
	 report_problem();
	}
	channelState.channelRssi =data;
	if (call SerialSend.send(0x18, &data, sizeof(uint16_t))!= SUCCESS) {
		report_problem();
	}
	else {
		uartbusy = TRUE;
	}
   }
   */
   event void Timer1.fired()
   {
      //call SerialSend.send(0x1818, &local, sizeof(local));
      //hjy change:maxSend
       if (maxSend != 0) {
    if (reading == NREADINGS) {
      if (!sendbusy) {
	oscilloscope_t *o = (oscilloscope_t *)call Send.getPayload(&sendbuf, sizeof(oscilloscope_t));
	if (o == NULL) {
	  fatal_problem();
	  return;
	}
	memcpy(o, &local, sizeof(local));
	if (call Send.send(&sendbuf, sizeof(local)) == SUCCESS)
	  sendbusy = TRUE;
        else
          report_problem();
      }
      
      reading = 0;
     // Part 2 of cheap "time sync": increment our count if we didn't
     //    jump ahead.
      if (!suppress_count_change)
      //hjy change
       local.count ++;
      //local.count += 7;
      suppress_count_change = FALSE;

    }

    if (call Read.read() != SUCCESS)
      fatal_problem();
      
      maxSend = maxSend -1;
      }
      
   }

   async event void Alarm0.fired() {
		call ReadRssi.read();

   }


  event void Send.sendDone(message_t* msg, error_t error) {
    if (error == SUCCESS)
      report_sent();
    else
      report_problem();
    //hjy change 
    /* if (call PacketTimeStamp.isValid(msg) == TRUE)
    	{
		uint32_t timeofsend;
		timeofsend = (uint32_t)call PacketTimeStamp.timestamp(msg);
		//use printf
		//printf("sendtime = %lu\n", timeofsend);

	}
     */
	

    sendbusy = FALSE;
  }

  event void Read.readDone(error_t result, uint16_t data) {
    if (result != SUCCESS) {
      data = 0xffff;
      report_problem();
    }
    if (reading < NREADINGS)
      local.readings[reading++] = data;
  }

  void fillPacket()
  {
  	nx_uint16_t tmp;
	call CtpInfo.getParent(&tmp);
	//local.parentId = tmp;

  }


  // Use LEDs to report various status issues.
  static void fatal_problem() { 
    call Leds.led0On(); 
    call Leds.led1On();
    call Leds.led2On();
    call Timer.stop();
  }

  static void report_problem() { call Leds.led0Toggle(); }
  static void report_sent() { call Leds.led1Toggle(); }
  static void report_received() { call Leds.led2Toggle(); }
}
