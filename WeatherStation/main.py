import time
import os
WEEK_IN_SECONDS = 604800
while True:
    time.sleep(WEEK_IN_SECONDS)
    os.system('./main.sh init')