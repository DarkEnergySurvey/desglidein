#!/usr/bin/env python

import os,sys
import time
import socket

"""
A very simple script to start the glide in on the Campus Cluster and
Blue Waters using the set of files packaged by Greg.

F Menanteau, NCSA June 2015

TODO:
 - Configure the location of the input condor
 - change args to kwargs?
 - add the same stamp to worker sh and pbs file

"""

def replace_fh(fh,pattern,subst='',prompt=''):
    """ Replace in place for file-handle"""
    if prompt != '':
        subst = raw_input(prompt+' ')
    fh = fh.replace(pattern,subst)
    return fh

def update_shell_template(template,newfile,args): 
    print "# Reading template: %s" % template
    f = open(template,'r')
    fh = f.read()
    fh = replace_fh(fh,'{DESGLIDEIN_DIR}',subst=os.environ['DESGLIDEIN_DIR'])
    fh = replace_fh(fh,'{CONDORSTRIPPED_DIR}',subst=os.environ['CONDORSTRIPPED_DIR'])
    fh = replace_fh(fh,'{SUBMIT_SITE}',subst=args.submit_site)
    fh = replace_fh(fh,'{IP_SUBMIT_SITE}',subst=args.ip_submit_site)
    fh = replace_fh(fh,'{NCPU}',subst=str(args.ncpu))

    n = open(newfile,'w')
    n.write(fh)
    n.close()
    os.chmod(newfile, 0755)
    print "# New file: %s" % newfile
    return

def update_template_generic(template,newfile,**kwargs):
    print "# Reading template: %s" % template

    f = open(template,'r')
    fh = f.read()
    for key,val in kwargs.items():
        fh = replace_fh(fh,'{%s}'% key.upper(),subst=str(val))
    n = open(newfile,'w')
    n.write(fh)
    n.close()
    os.chmod(newfile, 0755)
    print "# New file: %s" % newfile
    return

def update_pbs_template(template,newfile,args): 

    print "# Reading template: %s" % template
    f = open(template,'r')
    fh = f.read()
    fh = replace_fh(fh,'{NODES}',subst=str(args.nodes))
    fh = replace_fh(fh,'{NCPU}',subst=str(args.ncpu))
    fh = replace_fh(fh,'{QUEUE}',subst=str(args.queue))
    fh = replace_fh(fh,'{JOBNAME}',subst=args.submit_site+time.strftime("-%Y%b%d"))
    fh = replace_fh(fh,'{WALLTIME}',subst=args.walltime)
    fh = replace_fh(fh,'{SHELL_SCRIPT}',subst=args.shell_script)
    fh = replace_fh(fh,'{USER}',subst=args.user)
    n = open(newfile,'w')
    n.write(fh)
    n.close()
    print "# New file: %s" % newfile
    return

def get_walltime(seconds):
    m, s = divmod(seconds, 60)
    h, m = divmod(m, 60)
    walltime = "%02d:%02d:%02d" % (h, m, s)
    return walltime

def getComputeSite():
    address = socket.getfqdn()
    if address.find('campuscluster') >= 0:
        COMPUTE_SITE = 'CC' 
    elif address.find('h2ologin') >= 0:
        COMPUTE_SITE = 'BW'
    elif address.find('iforge') >= 0:
        COMPUTE_SITE = 'iForge'
    else:
        sys.exit('ERROR: Compute Site not defined for glide in')
    return COMPUTE_SITE

def cmdline():

    import argparse
    parser = argparse.ArgumentParser(description="Create a Condor glindein pbs script")
    # The positional arguments
    parser.add_argument("time", action="store",default=None,type=float,
                        help="Total required time in hours (can be a fraction)")
    parser.add_argument("--ncpu", action="store", default=12, type=int,
                        help="Number of CPUs per node")
    parser.add_argument("--nodes", action="store", default=1, type=int,
                        help="Number of nodes to request")
    parser.add_argument("--queue", action="store", default=None,
                        help="Queue Name (i.e.: ncsa, test, normal, high, low, debug, etc)")
    parser.add_argument("--submit_site", action="store", default='dessub',
                        help="Name of Submit Site")
    parser.add_argument("--compute_site", action="store", default=None,
                        help="Name of Compute Site")
    parser.add_argument("--user", action="store", default=os.environ['USER'],
                        help="Change user to notify via email [default is $USER]")
    
    args = parser.parse_args()
    # Add extra args to namespace
    args.walltime = get_walltime(args.time*3600)
    args.ip_submit_site = socket.gethostbyname(args.submit_site+".cosmology.illinois.edu")
    # Check Compute Site
    if not args.compute_site:
        args.compute_site = getComputeSite()

    if not args.queue:
        if args.compute_site == 'CC': args.queue = 'ncsa'
        if args.compute_site == 'BW': args.queue = 'normal'
        if args.compute_site == 'iForge': args.queue = 'normal'
        
    return args

if __name__ == "__main__":

    # Get the options
    args  = cmdline()

    # Check for CONDOR location
    if 'DESGLIDEIN_DIR' not in os.environ.keys():
        exit("ERROR: Please define $DESGLIDEIN_DIR")
    else:
        DESGLIDEIN_DIR = os.environ['DESGLIDEIN_DIR']
    # Local pbs/sh scripts
    try:
        CONDOR_USER_EXEC   = os.environ['CONDOR_USER_EXEC']
        print "# Will put files in %s" % CONDOR_USER_EXEC 
    except:
        CONDOR_USER_EXEC   = os.path.join(os.environ['HOME'],'CONDOR_USER_EXEC')
        print "# CONDOR_USER_EXEC in not defined, will use: %s" % CONDOR_USER_EXEC 
        
    # Make sure that output path exists
    if not os.path.exists(CONDOR_USER_EXEC):
        print "# Creating %s" % CONDOR_USER_EXEC
        os.mkdir(CONDOR_USER_EXEC)
    
    # Shell template
    sh_template = os.path.join(DESGLIDEIN_DIR,"scripts/worker-%s-template-condor_8_2_6.sh" % args.compute_site)
    sh_script   = os.path.join(CONDOR_USER_EXEC,"worker-%s-%scpu-condor_8_2_6.sh" % (args.submit_site,args.ncpu))
    update_shell_template(sh_template,sh_script,args)

    # PBS template
    args.shell_script=sh_script
    pbs_template   = os.path.join(DESGLIDEIN_DIR,"runtime/glidein-%s-template-condor-8.2.6.pbs" % args.compute_site)
    pbs_script     = os.path.join(CONDOR_USER_EXEC,"glidein-%s-%shr-%snodes-%scpu-condor-8.2.6.pbs" % (args.submit_site,args.time,args.nodes,args.ncpu))
    update_pbs_template(pbs_template,pbs_script,args)

    print "\nTo start glidein:\n"
    print "\t qsub %s\n " % pbs_script
    

