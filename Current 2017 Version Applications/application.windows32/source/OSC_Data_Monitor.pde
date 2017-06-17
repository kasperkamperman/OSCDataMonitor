/**
 * OSC DATA MONITOR. By Kasper Kamperman
 * 23-08-2011
 * 17-06-2017 (update Processing 3 and controlP5)
 * based on the excellent controlP5 and oscP5 examples and libraries from Andreas Schlegel.
 * http://www.sojamo.de/libraries/controlP5/
 * http://www.sojamo.de/libraries/oscP5/
 *
 * http://www.kasperkamperman.com
 *
 * Licensed under the MIT license:
 * http://www.opensource.org/licenses/mit-license.php
 *
 * Processing 3 or higher and ControlP5 2.2.6
 *
**/

final String version = "17-06-2017";

import oscP5.*;
import controlP5.*;
import java.net.InetAddress;
import java.util.Iterator;

// get IP address from this computer
InetAddress inet;
String myIP;

// store oscP5 objects
HashMap oscP5Objects;

// variabels to display incoming data
ArrayList monitorList;
HashMap monitorHash;
boolean monitorValueView = true; // switch between list and update view

int monitorListLength = 32;
String monitor;
String typetag;
char tag;
String monitorDisplay;

// variabels to filter incoming data
HashMap   oscaddressesHash;
ArrayList oscaddressesList;
int oscaddressCounter = 0;
int countFilteredaddresses; // to check if addresses are filtered

// ControlP5 interface
ControlP5 controlP5;

Textarea mTextarea;
Textlabel ipTextlabel, infoTextlabel, text1, text2, text3, text4, text5;
ScrollableList listActiveOscPorts, listCommonOscPorts, listReceivedOscAddresses, listMonitorOSCAddresses;
Textfield textInput;
Button buttonAddPort, buttonEmptyLists;
RadioButton radio;

void setup() {
  size(800,630,P2D);
  frameRate(25);

  try {
    inet = InetAddress.getLocalHost();
    myIP = inet.getHostAddress();
  }
  catch (Exception e) {
    e.printStackTrace();
    myIP = "couldn't get IP";
  }

  oscP5Objects = new HashMap();
  monitorList  = new ArrayList();
  monitorHash  = new HashMap();   // view the last value of all addresses.

  oscaddressesHash         = new HashMap();
  oscaddressesList         = new ArrayList();
  countFilteredaddresses   = 0;

  controlP5 = new ControlP5(this);

  ipTextlabel   = controlP5.addTextlabel("ipTextlabel","IP address: "+myIP+" ",24,24);
  infoTextlabel = controlP5.addTextlabel("info label","OSC DATA MONITOR, version " +version+ " by kasperkamperman.com      ",24,600);

  listActiveOscPorts = controlP5.addScrollableList("listActiveOscPorts")
                                .setPosition(20,50)
                                .setSize(170,130)
                                .setType(ScrollableList.LIST)
                                .setLabel("now listening to OSC ports:");
                                
  listCommonOscPorts = controlP5.addScrollableList("listCommonOscPorts")
                                .setPosition(20,220)
                                .setSize(170,130)
                                .setType(ScrollableList.LIST)
                                .setLabel("list with common OSC ports");

  text1 = controlP5.addTextlabel("text1","click on item to stop listening",24,180);
  text2 = controlP5.addTextlabel("text2","click on item to start listening",24,350);

  // add some common port numbers
  listCommonOscPorts.addItem(str(3333),3333);
  listCommonOscPorts.addItem(str(8000),8000);
  listCommonOscPorts.addItem(str(8338),8338);

  // start listening to port 8000 by default
  startListeningToPort(8000);

  // field to add a custom port number
  textInput = controlP5.addTextfield("textInput",20,370,170,20);
  textInput.setLabel("");
  textInput.setFocus(true);
  textInput.setAutoClear(true);
  textInput.keepFocus(true);

  // button to add the port number to listCommonOscPorts
  buttonAddPort = controlP5.addButton("add Port")
                    //.setValue(1)
                    .setPosition(20,395)
                    .setSize(60,16);

  radio = controlP5.addRadioButton("radioButton",20,430);
  radio.setNoneSelectedAllowed(false);
  radio.setSize(20,20);
  radio.setSpacingRow(10);
  radio.addItem("view updated values",1);
  radio.addItem("view updated addresses",0);

  // text area for displaying incoming OSC data (monitor)
  mTextarea = controlP5.addTextarea(
  "textarea", "", 210,20,570,395);
  mTextarea.setLineHeight(12);

  //mTextarea.valueLabel().setFont(ControlP5.grixel);
  mTextarea.hideScrollbar();
  mTextarea.setColorBackground(0xff222222);

  listReceivedOscAddresses = controlP5.addScrollableList("listReceivedOscAddresses")
                                      .setPosition(210,430)
                                      .setSize(275,130)
                                      .setType(ScrollableList.LIST)
                                      .setLabel("received OSC addresses:");

  listMonitorOSCAddresses = controlP5.addScrollableList("listMonitorOSCAddresses")
                                      .setPosition(505,430)
                                      .setSize(275,130)
                                      .setType(ScrollableList.LIST)
                                      .setLabel("monitor only OSC addresses below:");

  text3 = controlP5.addTextlabel("text3","Click on item to pass through data from this address.",214,560);
  text4 = controlP5.addTextlabel("text4","Click on item to remove filter.",509,560);
  text5 = controlP5.addTextlabel("text5","When the list above is empty all data is monitored.",509,572);

  buttonEmptyLists = controlP5.addButton("Clear views")
                              //.setValue(1)
                              .setPosition(20,535)
                              .setSize(170,20);

  if(monitorValueView) radio.activate("view updated values");
  else                 radio.activate("view updated addresses");

}

void draw() {
  // draw some background rectangles
  background(128);

  fill(32);
  rect(20,20,170,15);    // textlabel
  rect(20,596,760,15);   // bottom textlabel
  fill(196);
  rect(20,50,170,125);   // list 1
  rect(20,220,170,125);  // list 2
  rect(210,430,275,125); // list 3
  rect(505,430,275,125); // list 4

  // empty the monitorDisplay string
  monitorDisplay = "";

  if(monitorValueView)
  { // fill string with data from the monitorList.
    for(int i = 0; i < monitorList.size(); i++)
    { monitorDisplay = monitorDisplay + (String) monitorList.get(i) + "\n";
    }
  }
  else
  { Iterator iter = monitorHash.values().iterator();

    while (iter.hasNext()) {
      monitorDisplay = monitorDisplay + (String) iter.next() + "\n";
    }
  }

  // remove items from beginning of the monitor list when size is bigger than
  // set monitorListLength
  while(monitorList.size()>monitorListLength)
  { monitorList.remove(0);
  }

  mTextarea.setText(monitorDisplay);
}

// == ControlP5 events ===========================================

//void listActiveOscPorts(int value) {
//  println(value);
//}

void controlEvent(ControlEvent theEvent) {

  if(theEvent.isController()) {
    
    int value = int(theEvent.getController().getValue());
    String name  = theEvent.getController().getName();
    //print("control event from : "+name);
    //println(", value : "+value);
    
    if(name == "listActiveOscPorts") {
      int val = (int)listActiveOscPorts.getItem(value).get("value");
      stopListeningToPort(val);
    }

    if(name == "listCommonOscPorts") {
      int val = (int)listCommonOscPorts.getItem(value).get("value");
      startListeningToPort(val);
    }

    if(name == "listReceivedOscAddresses") {
      // check if item is already filtered
      String s = (String) oscaddressesList.get(value);

      if((Integer)oscaddressesHash.get(s) == 0) { 
        listMonitorOSCAddresses.addItem(s, value);
        oscaddressesHash.put(s,new Integer(1));
        countFilteredaddresses++;
      }
    }

    if(name == "listMonitorOSCAddresses") {
      String s = (String) oscaddressesList.get(value);

      listMonitorOSCAddresses.removeItem(s);
      countFilteredaddresses--;

      oscaddressesHash.put(s,new Integer(0));
    }
    
    if(name == "add Port") {
      // trigger the textInput function below with the textInput data
      textInput.submit();
    }
    
  }
  
  if (theEvent.isGroup()) {
    //int value = int(theEvent.getGroup().getValue());

    //print("control event from : "+theEvent.getGroup().getName());
    //println(", value : "+ value);

    if(theEvent.getGroup().getName()=="radioButton")
    { if(theEvent.getGroup().getValue() == 1)
      { monitorValueView = true;
        mTextarea.showScrollbar();
      }
      else
      { monitorValueView = false;
        mTextarea.hideScrollbar();
      }
    }

    
  }
  
}

public void textInput(String s) {
  s = trim(s);

  // check if text input is a valid port number.
  String[] m = match(s, "[^0-9]|[0-9]{6}");

  if(m != null)
  { // print error in monitor
    monitorList.add((String) "- Please enter a number between 0 - 65535 ");
  }
  else
  { if(int(s)>65535)
    { // print error in monitor
      monitorList.add((String) "- Please enter a number between 0 - 65535 ");
    }
    else
    { // add the port number to listCommonOscPorts.
      listCommonOscPorts.addItem(s, int(s));
    }
  }
}

public void startListeningToPort(int port)
{ // triggered when clicking item in listCommonOscPorts.

  // check if we are not already listening by checking the Hashmap
  // add new OscListener object to the oscP5Objects HashMap
  if(!oscP5Objects.containsKey(port))
  { println(oscP5Objects.size());
    // check if HashMap size() < 10
    if(oscP5Objects.size()<10)
    { MyOSCListener o = new MyOSCListener(port);

      oscP5Objects.put(port,o);
      // add item to listActiveOscPorts
      listActiveOscPorts.addItem(str(port), port);
      listCommonOscPorts.removeItem(str(port));
      monitorList.add((String) "- Listening to port: "+port);
    }
    else
    { monitorList.add((String) "- Cannot listen to more than 10 ports");
    }
  }
  else
  { monitorList.add((String) "- Already listening to port: "+port);
  }
}

public void stopListeningToPort(int port)
{ // triggered when clicking item in listActiveOscPorts

  if(oscP5Objects.containsKey(port))
  { // get the port from the HashMap
    MyOSCListener o = (MyOSCListener) oscP5Objects.get(port);

    o.stop();                   // stop listening
    oscP5Objects.remove(port);  // remove port from HashMap

    // remove item from listActiveOscPorts
    String item = Integer.toString(port);
    listActiveOscPorts.removeItem(item);
    //listActiveOscPorts.addItem(str(port), port);
    listCommonOscPorts.addItem(str(port), port);
    monitorList.add((String) "- Stopped listening to port: "+port);
  }
}

public void buttonEmptyLists(int theValue) {
  listReceivedOscAddresses.clear();
  listMonitorOSCAddresses.clear();
  monitorHash.clear();
  monitorList.clear();
  oscaddressesHash.clear();
  oscaddressesList.clear();
  countFilteredaddresses = 0;
  oscaddressCounter = 0;
}

void addOSCaddress(String s) {

   if (!oscaddressesHash.containsKey(s))
   { // Hash used to check if the adres already was used before.
     //println("not in list yet: "+s+" "+oscaddressCounter);
     oscaddressesHash.put(s,new Integer(0));

     // show in list.
     listReceivedOscAddresses.addItem(s,oscaddressCounter);
     oscaddressesList.add(new String(s)); // index will be the same as the oscaddressCounter
     oscaddressCounter++;
   }

}