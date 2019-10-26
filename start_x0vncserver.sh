
#!/bin/bash

USER=mago
sudo su -c 'DISPLAY=:0 x0vncserver -passwordfile /home/$USER/.vnc/passwd ' $USER 2> /home/$USER/vnc.log
