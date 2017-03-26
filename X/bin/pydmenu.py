#!/usr/bin/env python2

# Credit:
# https://github.com/DeeNewcum/pydmenu

import os
import cPickle
import argparse
from subprocess import Popen, PIPE
from operator import itemgetter

__author__ = "Mathias Teugels <cpf@codercpf.be>"


SAVEFILE=os.path.expanduser('~/.pydmenu_save')
DMENU=['dmenu']
DMENU_PATH=['bash', '-c', '. ~/.aliases.sh; compgen -c']

def restore_saved():
    temp = {}
    if os.path.exists(SAVEFILE):
        save_file = open(SAVEFILE, 'r+')
        temp = cPickle.load(save_file)
        save_file.close()
    return temp

def save(list):
    save_file = open(SAVEFILE, 'w+')
    cPickle.dump(list, save_file)
    save_file.close()

def mySort(list):
    # Source: http://blog.modp.com/2008/09/sorting-python-dictionary-by-value-take.html
    return sorted(list.iteritems(), key=itemgetter(1),
        reverse=True)

if __name__ == '__main__':
    _total_list = restore_saved()

    parser = argparse.ArgumentParser(description='Description of your program')
    parser.add_argument('-r', help='Remove the specified entry')
    args = vars(parser.parse_args())
    #print args

    first = Popen(DMENU_PATH, stdout=PIPE)
    total_list = first.communicate()[0]
    for prog in total_list.split('\n'):
        if not _total_list.has_key(prog):
            _total_list[prog] = 0

    _print = mySort(_total_list)

    proc = Popen(DMENU, stdin=PIPE, stdout=PIPE)
    used = proc.communicate('\n'.join([a for a,b in _print]))[0]

    if _total_list.has_key(used):
        _total_list[used] += 1
    else:
        _total_list[used] = 1
    save(_total_list)

    print(used)
