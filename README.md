simply add the siles to ure project and connect with a feamle rs232 to usb connecter and use a serial device like putty or terra term to listen to the message being sent by the fpga at 115200 buad 
in practice there is an error , first try listening at 9600 , u will see garbage values, turn off and then turn on at 115200

this is a simple idea to transmit some code, u also recive using similar logic, and if u want to connect ure project straight to python for some quick analysis or some iot applications , this can be a great choice, 

also if u have a male connector , change the pin to M14 in the ucf file
