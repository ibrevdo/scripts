
#!/bin/bash

USER=mago
sudo su -c 'DISPLAY=:1 vncserver -geometry 1920x1080 -depth 24' $USER 
