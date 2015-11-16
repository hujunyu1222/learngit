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
 * @author David Gay
 * @author Kyle Jamieson
 */

#ifndef MULTIHOP_OSCILLOSCOPE_H
#define MULTIHOP_OSCILLOSCOPE_H

enum {
  /* Number of readings per message. If you increase this, you may have to
     increase the message_t size. */
  //NREADINGS = 5,
    NREADINGS = 0,

  /* Default sampling period. */
  //DEFAULT_INTERVAL = 1024,
  //hjy change interval
  DEFAULT_INTERVAL = 2048,
  //hjy change 0x93 to 0x92
  AM_OSCILLOSCOPE = 0x93,
  //hjy change: RSSIREADINGS
   RSSIREADINGS = 3,

};

typedef nx_struct oscilloscope {
  nx_uint16_t version; /* Version of the interval. */
  nx_uint16_t interval; /* Samping period. */
  nx_uint16_t id; /* Mote id of sending mote. */
  nx_uint16_t count; /* The readings are samples count * NREADINGS onwards */
  nx_uint16_t readings[NREADINGS];
  //hjy change
  nx_uint8_t rssi;   //get Rssi use CC2420
  nx_uint16_t etx;    //get etx use CtpPacket
  nx_uint16_t origin;   //get origin use CtpPacket
  nx_uint8_t thl; //get thl use CtpPacket
  nx_uint8_t seq;  //num of sequence
  nx_uint8_t parent[5];//get parentId of each hop use Intercept.forward
  nx_uint8_t hopRssi[5]; //
  nx_uint32_t receiveTime; //Timestamp of receive
  nx_uint16_t regRssi[3]; //get Rssi from Register
} oscilloscope_t;

typedef nx_struct sense {
  nx_uint16_t id;
  nx_uint16_t channelRssi;

} sense_t;
#endif
