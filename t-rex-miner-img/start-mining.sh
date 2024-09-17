#!/bin/bash

HOSTNAME=$(hostname)
/opt/t-rex -a ethash -o stratum+tcp://eth.2miners.com:2020 -u 3P4ZdLh6EbJUgG1LJ4ZDV1NMVi2zLhah21 -p x -w ${HOSTNAME} --pl 145