#! /usr/bin/env python2.7
# -*- coding: utf-8 -*-

"""
Usage:
    confd_update_slurm.py [options]

Options:
  -h --help               Show this screen.
  --version               Show version.
  --daemon=<str>          Daemon to restart [default: slurmd]
  --onetime               Just run the iteration once
  --watch-timeout=<int>   Seconds to timeout on while watch /slurm/conf/last_update [default: 180]
"""

from docopt import docopt
import re
import sys
import envoy
from etcd import *
from ClusterShell.RangeSet import RangeSet
import time
import urllib3

class SlurmConf(object):
    """ Handle slurm.conf updates
    """
    def __init__(self, opt):
        """ initial stuff
        """
        self._opt = opt
        self._etcd = Client(host="etcd.qnib")
        self._comp_regex = "compute(?P<id>\d+)"
        self._etcd_pre = "/skydns/qnib/"
        self._file_regex = "NodeName=(?P<rset>compute[0-9,\-]+)"
        preset = {
            "/slurm/conf/prolog/slurmctld": "/usr/local/bin/sctld_prolog.sh",
            "/slurm/conf/epilog/slurmctld": "/usr/local/bin/sctld_epilog.sh",
            "/slurm/conf/fast/schedule": 2,
            "/slurm/conf/control/machine": "slurmctld",
            "/slurm/conf/nodename": "compute0",
            "/slurm/conf/last_update": int(time.time()),
        }
        for key, val in preset.items():
            try:
                self._etcd.read(key)
            except KeyError:
                self._etcd.write(key, val)
        
        

    def run(self):
        """ checks file and etcd-config and reacts
        """
        old_rset = self._etcd.read('/slurm/conf/nodename').value
        self._etcd.write('/slurm/conf/nodename', old_rset)
        new_rset = "compute[%s]" % self.get_compute_rangeset()
        if old_rset != new_rset:
            key = '/slurm/conf/nodename'
            print "Update etcd-key '%s': %s" % (key, new_rset)
            self._etcd.write(key, new_rset)
        file_rset = self.get_file_rset()
        if new_rset != file_rset:
            self.update_slurm_conf()
    
    def update_slurm_conf(self):
        """ updates slurm configuration file
        """
        cmd = "confd -node=http://etcd.qnib:4001 -onetime -config-file=/etc/confd/conf.d/slurm.conf.toml"
        crun = envoy.run(cmd)
        if crun.status_code != 0:
            print "STD_OUT> "+crun.std_out
            print "STD_ERR> "+crun.std_err
            sys.exit(1)
        for line in crun.std_out.split("\n"):
            if re.match(".*INFO Target config /usr/local/etc/slurm.conf in sync", line):
                return
        cmd = "supervisorctl restart %s" % self._opt.get("--daemon")
        crun = envoy.run(cmd)
        assert crun.status_code == 0
        print crun.std_out
        
    def get_file_rset(self):
        """ extracts the Rangeset within the slurm.conf file
        """
        with open("/usr/local/etc/slurm.conf", "r") as fd:
            lines = fd.readlines()
        for line in lines:
            mat = re.match(self._file_regex, line)
            if mat:
                mdic = mat.groupdict()
                return mdic['rset']

    def get_compute_rangeset(self):
        """ returns rangeset of compute ids
        """
        rset = RangeSet()
        for child in self.get_children():
            mat = re.match(self._comp_regex, child)
            if mat:
                mdic = mat.groupdict()
                rset.union_update(RangeSet(str(mdic['id'])))
        return rset
        
    def get_children(self):
        """ extract list of children
        """
        children = []
        
        for child in self._etcd.read(self._etcd_pre).children:
            children.append(child.key[len(self._etcd_pre):])
        return children
    
    def loop(self):
        """ executes a loop to update slurm.conf as needed
        """
        while True:
            try:
                self._etcd.watch("/slurm/conf/last_update", timeout=int(self._opt.get('--watch-timeout')))
            except urllib3.exceptions.TimeoutError:
                pass
            self.run()
            if self._opt.get('--onetime'):
                break
    


def main():
    """ main function """
    # Parameter
    options =  docopt(__doc__, version='1.0.0')
    slurmc = SlurmConf(options)
    slurmc.run()
    try:
        slurmc.loop()
    except KeyboardInterrupt:
        pass

# ein Aufruf von main() ganz unten
if __name__ == "__main__":
    main()
