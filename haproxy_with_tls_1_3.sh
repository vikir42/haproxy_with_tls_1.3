#!/bin/bash
yum install -y make gcc gcc-c++ pcre-devel openssl-devel readline-devel systemd-devel zlib-devel
## Compile OpenSSL
OPENSSL=openssl-1.1.1k.tar.gz

DONE=haproxy-compile-done

if [ ! -f "${DONE}" ] ;then
    wget https://www.openssl.org/source/${OPENSSL}

    tar zxvf ${OPENSSL}

    cd $(basename $OPENSSL .tar.gz)

    ./config shared no-idea no-md2 no-mdc2 no-rc5 no-rc4 --prefix=/usr/local/

    make

    sudo make install

    cd ..
fi

export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64/

echo '@reboot export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64/' >> /etc/crontab
echo "OPENSSL installation completed"


## Compile LUA
LUA=lua-5.4.3.tar.gz

if [ ! -f "${DONE}" ] ;then
    wget https://www.lua.org/ftp/${LUA}

    tar zxvf ${LUA}

    cd $(basename $LUA .tar.gz)

    make linux test

    sudo make install

    cd ..
fi

echo "LUA installation completed"

## Compile HAProxy
HAPROXY=haproxy-2.0.21.tar.gz

DONE=haproxy-compile-done

if [ ! -f "${DONE}" ] ;then
    wget http://www.haproxy.org/download/2.2/src/${HAPROXY}

    tar zxvf ${HAPROXY}

    cd $(basename $HAPROXY .tar.gz)

    make -j $(nproc) TARGET=linux-glibc USE_OPENSSL=1 SSL_LIB=/usr/local/lib64 SSL_INC=/usr/local/include USE_ZLIB=1 USE_LUA=1 LUA_LIB=/usr/local/lib/ LUA_INC=/usr/local/include/ USE_PCRE=1 USE_SYSTEMD=1

    sudo make install

    cd ..

    touch ${DONE}
fi

read -n1 -r -p "$(/usr/local/bin/haproxy -vv) - Press any key to continue..." key


echo '[Unit]
Description=HAProxy Load Balancer
Documentation=man:haproxy(1)
After=syslog.target network.target

[Service]
Environment=LD_LIBRARY_PATH=/usr/local/lib64/
EnvironmentFile=-/etc/sysconfig/haproxy
EnvironmentFile=-/etc/sysconfig/haproxy
Environment="CONFIG=/etc/haproxy/haproxy.cfg" "PIDFILE=/run/haproxy.pid" "EXTRAOPTS=-S /run/haproxy-master.sock"
ExecStartPre=/usr/local/sbin/haproxy -f $CONFIG -c -q $EXTRAOPTS
ExecStart=/usr/local/sbin/haproxy -Ws -f $CONFIG -p $PIDFILE $EXTRAOPTS
ExecReload=/usr/local/sbin/haproxy -f $CONFIG -c -q $EXTRAOPTS
ExecReload=/bin/kill -USR2 $MAINPID
KillMode=mixed
Restart=always
SuccessExitStatus=143
Type=notify

[Install]' > /usr/lib/systemd/system/haproxy.service