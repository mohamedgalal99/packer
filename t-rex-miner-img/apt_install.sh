export DEBIAN_FRONTEND=noninteractive

# install Nvidia Drivers
sudo apt-get update
sudo apt-get install -y wget build-essential gcc-multilib dkms
wget https://us.download.nvidia.com/tesla/470.82.01/NVIDIA-Linux-x86_64-470.82.01.run -q
# || true is to make packer ignore the error code because of missing X lib path
sudo sh NVIDIA-Linux-x86_64-470.82.01.run --silent --dkms || true 
rm NVIDIA-Linux-x86_64-470.82.01.run

# Install t-rex miner
wget https://github.com/trexminer/T-Rex/releases/download/0.24.5/t-rex-0.24.5-linux.tar.gz -q
mkdir t-rex-miner
tar -xvzf t-rex-0.24.5-linux.tar.gz --directory t-rex-miner
sudo cp t-rex-miner/t-rex /opt/t-rex
sudo chmod +x /opt/t-rex
