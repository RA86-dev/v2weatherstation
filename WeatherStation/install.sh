echo "=========================="
echo "Weather Installer [Debian/Ubuntu]"
echo "Date: January 12th, 2024"
echo "Author: RA86-dev"
echo "=========================="
echo "Installing Python Libraries"
pip install -r requirements.txt
echo "Please update weather information by running update_weather_information.py and dragging it to assets/"
sudo apt install tmux -y
clear
echo "Finalized installation! Run gen_sh.sh to run the script."

echo """
echo "Running index.py"
cd weather_station/
python3 index.py
""" > "gen_sh.sh"

chmod +x ./gen_sh.sh
