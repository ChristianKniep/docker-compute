#! /usr/bin/env python
# -*- coding: utf-8 -*-

"""

Usage:
    check_ib.py [options]

Options:
    --exp-cnt <int>         Number of active ports expceted [default: 1]
    --exp-state <str>       State to expect [default: active]
Generic Options:
    --loglevel, -L=<str>    Loglevel [default: INFO]
                            (ERROR, CRITICAL, WARN, INFO, DEBUG)
    --log2stdout, -l        Log to stdout, otherwise to logfile. [default: False]
    --logfile, -f=<path>    Logfile to log to (default: <scriptname>.log)
    --cfg, -c=<path>        Configuration file.
    -h --help               Show this screen.
    --version               Show version.

"""

# load librarys
import logging
import os
import re
import time
import codecs
import ast
import sys
from ConfigParser import RawConfigParser, NoOptionError
import envoy

try:
    from docopt import docopt
except ImportError:
    HAVE_DOCOPT = False
else:
    HAVE_DOCOPT = True

__author__ = 'Christian Kniep <christian()qnib.org>'
__copyright__ = 'Copyright 2015 QNIB Solutions'
__license__ = """GPL v2 License (http://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)"""


class QnibConfig(RawConfigParser):
    """ Class to abstract config and options
    """
    specials = {
        'TRUE': True,
        'FALSE': False,
        'NONE': None,
    }

    def __init__(self, opt):
        """ init """
        RawConfigParser.__init__(self)
        if opt is None:
            self._opt = {
                "--log2stdout": False,
                "--logfile": None,
                "--loglevel": "ERROR",
            }
        else:
            self._opt = opt
            self.logformat = '%(asctime)-15s %(levelname)-5s [%(module)s] %(message)s'
            self.loglevel = opt['--loglevel']
            self.log2stdout = opt['--log2stdout']
            if self.loglevel is None and opt.get('--cfg') is None:
                print "please specify loglevel (-L)"
                sys.exit(0)
            self.eval_cfg()

        self.eval_opt()
        self.set_logging()
        logging.info("SetUp of QnibConfig is done...")

    def do_get(self, section, key, default=None):
        """ Also lent from: https://github.com/jpmens/mqttwarn
            """
        try:
            val = self.get(section, key)
            if val.upper() in self.specials:
                return self.specials[val.upper()]
            return ast.literal_eval(val)
        except NoOptionError:
            return default
        except ValueError:  # e.g. %(xxx)s in string
            return val
        except:
            raise
            return val

    def config(self, section):
        """ Convert a whole section's options (except the options specified
                explicitly below) into a dict, turning

                    [config:mqtt]
                    host = 'localhost'
                    username = None
                    list = [1, 'aaa', 'bbb', 4]

                into

                    {u'username': None, u'host': 'localhost', u'list': [1, 'aaa', 'bbb', 4]}

                Cannot use config.items() because I want each value to be
                retrieved with g() as above
            SOURCE: https://github.com/jpmens/mqttwarn
        """

        d = None
        if self.has_section(section):
            d = dict((key, self.do_get(section, key))
                     for (key) in self.options(section) if key not in ['targets'])
        return d

    def eval_cfg(self):
        """ eval configuration which overrules the defaults
            """
        cfg_file = self._opt.get('--cfg')
        if cfg_file is not None:
            fd = codecs.open(cfg_file, 'r', encoding='utf-8')
            self.readfp(fd)
            fd.close()
            self.__dict__.update(self.config('defaults'))

    def eval_opt(self):
        """ Updates cfg according to options """

        def handle_logfile(val):
            """ transforms logfile argument
                """
            if val is None:
                logf = os.path.splitext(os.path.basename(__file__))[0]
                self.logfile = "%s.log" % logf.lower()
            else:
                self.logfile = val

        self._mapping = {
            '--logfile': lambda val: handle_logfile(val),
        }
        for key, val in self._opt.items():
            if key in self._mapping:
                if isinstance(self._mapping[key], str):
                    self.__dict__[self._mapping[key]] = val
                else:
                    self._mapping[key](val)
                break
            else:
                if val is None:
                    continue
                mat = re.match("\-\-(.*)", key)
                if mat:
                    self.__dict__[mat.group(1)] = val
                else:
                    logging.info("Could not find opt<>cfg mapping for '%s'" % key)

    def set_logging(self):
        """ sets the logging """
        self._logger = logging.getLogger()
        self._logger.setLevel(logging.DEBUG)
        if self.log2stdout:
            hdl = logging.StreamHandler()
            hdl.setLevel(self.loglevel)
            formatter = logging.Formatter(self.logformat)
            hdl.setFormatter(formatter)
            self._logger.addHandler(hdl)
        else:
            hdl = logging.FileHandler(self.logfile)
            hdl.setLevel(self.loglevel)
            formatter = logging.Formatter(self.logformat)
            hdl.setFormatter(formatter)
            self._logger.addHandler(hdl)

    def __str__(self):
        """ print human readble """
        ret = []
        for key, val in self.__dict__.items():
            if not re.match("_.*", key):
                ret.append("%-15s: %s" % (key, val))
        return "\n".join(ret)

    def __getitem__(self, item):
        """ return item from opt or __dict__
        :param item: key to lookup
        :return: value of key
        """
        if item in self.__dict__.keys():
            return self.__dict__[item]
        else:
            return self._opt[item]


class CheckIB(object):
    def __init__(self, cfg):
        """ Init of instance
        """
        self._cfg = cfg
        self.ib_dev = {}
        self.ib_state_cnt = {}

    def run(self):
        """ do the work
        """
        self.eval_ibstat()
        self.check_ib()

    def eval_ibstat(self):
        cmd = "ibstat"
        proc = envoy.run(cmd)
        if proc.status_code != 0:
            print "Something went wrong... "
            print proc.std_err
            sys.exit(proc.status_code) 
        rx_ca = re.compile("^CA '(?P<ib_dev>.*)'$")
        rx_port = re.compile("^\s+Port\s+(?P<ib_port>\d+):")
        for line in proc.std_out.split("\n"):
            mat_ca = re.match(rx_ca, line)
            mat_port = re.match(rx_port, line)
            if mat_ca:
                ib_dev = mat_ca.groupdict()['ib_dev']
                self.ib_dev[ib_dev] = {}
                ib_port = None
            elif mat_port:
                ib_port = mat_port.groupdict()['ib_port']
                self.ib_dev[ib_dev][ib_port] = {}
            else:
                try:
                   key, val = line.split(":")
                   key = key.strip()
                   val = val.strip()
                except:
                   continue
                if ib_port is None:
                   self.ib_dev[ib_dev][key] = val
                else:
                   if key == "State":
                       if val not in self.ib_state_cnt.keys():
                           self.ib_state_cnt[val.lower()] = 0
                       self.ib_state_cnt[val.lower()] += 1
                   self.ib_dev[ib_dev][ib_port][key] = val.lower()

    def check_ib(self):
        ec = 0
        for key, val in self.ib_state_cnt.items():
             if key == self._cfg['--exp-state'] and self.ib_state_cnt[key] < int(self._cfg['--exp-cnt']):
                  print "%-10s : %-2s [FAIL] expected:%s" % (key, val, self._cfg['--exp-cnt'])
                  ec = max(ec, 2)
             elif key == self._cfg['--exp-state'] and self.ib_state_cnt[key] >= int(self._cfg['--exp-cnt']):
                  print "%-10s : %-2s [OK] expected:%s" % (key, val, self._cfg['--exp-cnt'])
             else:
                  print "%-10s : %-2s" % (key, val)
        sys.exit(ec)

def main():
    """ main function """
    options = None
    if HAVE_DOCOPT:
        options = docopt(__doc__, version='Test Script 0.1')
    qcfg = QnibConfig(options)
    cib = CheckIB(qcfg)
    cib.run()


if __name__ == "__main__":
    main()
