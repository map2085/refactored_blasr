To pull this project from git hub to your local system:

    $ git clone git@github.com:PacificBiosciences/refactored_blasr.git --recursive

To sync your code with the latest git code base:

    $ make pullfromgit


To specify HDF5 headers and lib on your system, please edit git_blasr_common.mk

To Make 'blasr' only:

    $ make blasr

To compile all tools, including blasr, pls2fasta, loadPusles, sawriter:

    $ make 

To clean all compiled tools and lib:

    $ make clean

To clean blasr and compiled lib:

    $ make clean_blasr

For developers:

    $ make debug



