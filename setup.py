import distutils
from distutils.core import setup
import glob

bin_files = glob.glob("bin/*.py")

# The main call
setup(name='desglidein',
      version ='0.1.1',
      license = "GPL",
      description = "Python function to create gliden in from condos/shell/pbs libraries",
      author = "Felipe Menanteau",
      author_email = "felipe@illinois.edu",
      packages = ['desglidein'],
      package_dir = {'': 'python'},
      scripts = bin_files,
      data_files=[('ups',['ups/desglidein.table']),
                  ('config',  glob.glob("config/*.config")),
                  ('runtime', glob.glob("runtime/*.pbs")),
                  ('scripts', glob.glob("scripts/*.sh")),
                  ], 
      )

