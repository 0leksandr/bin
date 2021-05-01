#!/bin/sh
sudo service ntp stop
sudo ntpd -gq
sudo service ntp start
exit 0
