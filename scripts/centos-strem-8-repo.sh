#!/bin/bash 
set -e 

sudo tee /etc/yum.repos.d/CentOS-Stream-AppStream.repo >/dev/null << EOF
[appstream]
name=CentOS Linux \$releasever - AppStream
baseurl=https://vault.centos.org/8-stream/AppStream/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-BaseOS.repo >/dev/null << EOF
[baseos]
name=CentOS Linux \$releasever - BaseOS
baseurl=https://vault.centos.org/8-stream/BaseOS/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-ContinuousRelease.repo >/dev/null << EOF
[cr]
name=CentOS Linux \$releasever - ContinuousRelease
baseurl=https://vault.centos.org/8-stream/cr/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Debuginfo.repo >/dev/null << EOF
[debuginfo]
name=CentOS Linux \$releasever - Debuginfo
baseurl=https://debuginfo.centos.8-streamch/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Devel.repo >/dev/null << EOF
[devel]
name=CentOS Linux \$releasever - Devel WARNING! FOR BUILDROOT USE ONLY!
baseurl=https://vault.centos.org/8-stream/Devel/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Extras.repo >/dev/null << EOF
[extras]
name=CentOS Linux \$releasever - Extras
baseurl=https://vault.centos.org/8-stream/extras/\$basearch/os/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-FastTrack.repo >/dev/null << EOF
[fasttrack]
name=CentOS Linux \$releasever - FastTrack
baseurl=https://vault.centos.org/8-stream/fasttrack/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-HighAvailability.repo >/dev/null << EOF
[ha]
name=CentOS Linux \$releasever - HighAvailability
baseurl=https://vault.centos.org/8-stream/HighAvailability/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Media.repo >/dev/null << EOF
[media-baseos]
name=CentOS Linux \$releasever - Media - BaseOS
baseurl=file:///media/CentOS/BaseOS
        file:///media/cdrom/BaseOS
        file:///media/cdrecorder/BaseOS
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[media-appstream]
name=CentOS Linux \$releasever - Media - AppStream
baseurl=file:///media/CentOS/AppStream
        file:///media/cdrom/AppStream
        file:///media/cdrecorder/AppStream
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Plus.repo >/dev/null << EOF
[plus]
name=CentOS Linux \$releasever - Plus
baseurl=https://vault.centos.org/8-stream/centosplus/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-PowerTools.repo >/dev/null << EOF
[powertools]
name=CentOS Linux \$releasever - PowerTools
baseurl=https://vault.centos.org/8-stream/PowerTools/\$basearch/os/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Sources.repo >/dev/null << EOF
[baseos-source]
name=CentOS Linux \$releasever - BaseOS - Source
baseurl=https://vault.centos.org/8-stream/BaseOS/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[appstream-source]
name=CentOS Linux \$releasever - AppStream - Source
baseurl=https://vault.centos.org/8-stream/AppStream/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[powertools-source]
name=CentOS Linux \$releasever - PowerTools - Source
baseurl=https://vault.centos.org/8-stream/PowerTools/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[extras-source]
name=CentOS Linux \$releasever - Extras - Source
baseurl=https://vault.centos.org/8-stream/extras/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial

[plus-source]
name=CentOS Linux \$releasever - Plus - Source
baseurl=https://vault.centos.org/8-stream/centosplus/Source/
gpgcheck=1
enabled=0
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-centosofficial
EOF

sudo tee /etc/yum.repos.d/CentOS-Stream-Extras-common.repo >/dev/null << EOF
[extras-common]
name=CentOS Stream $releasever - Extras common packages
baseurl=http://vault.centos.org/8-stream/extras/\$basearch/extras-common/
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-SIG-Extras
EOF
