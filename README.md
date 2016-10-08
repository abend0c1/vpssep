VPS Dynamic Separator Page Printer
==================================
Converts a binary PCL file to an editable format.

This Rexx program can run on Linux, Windows or z/OS and it
produces an editable version of the PCL produced by (say) a
Windows PCL printer driver.

The resulting editable version could be browsed for your
enjoyment or, if you have a zSeries mainframe running
VPS from lrs.com, it should be uploaded to z/OS 
where is read by the VPS separator page exit in order to 
print the separator page on a PCL or Postscript printer
that has been defined to VPS.

As the exit scans the template, it substitutes any
variables with their current values before sending the 
resulting text to the printer.  The variables are
described in the OUTPUT section below.

NOTE: A Postscript file can also be processed, but the 
resulting template will be a series of text records
with no special formating of any embedded variables.
If you want to create a separator page for a Postscript
printer then you will have to manually edit the
template to ensure that any variables begin in column1.

Features
--------
* Decodes all PCL5 commands defined in the HP PCL5 Technical Reference
* Decodes some PCLXL commands that have been reverse engineered

Usage
-----

      rexx VPSSEP [infile [outfile]] [(options...]
Where:

infile  = Input dataset containing PCL driver binary 
          output.

outfile = Output dataset to contain the template.
          Both the input and output dataset names are
          have to re-specify them each time.

          If you initially specify a PDS dataset and
          member name - e.g. MY.PDS(INPUT1) - then you 
          can specify just a member name the next time 
          - e.g. INPUT2 - and the last PDS will be
          used.

          You can ask to be prompted for a dataset name
          by specifying '..' for infile or outfile.

          You can ask that the last dataset be used
          by specifying '.' for infile or outfile.

          A typical session might look like:

          1. Upload PCL file to a.b.c(m1), then:
             tso vpssep
             Enter input dataset name:
             a.b.c(m1)
             Converting a.b.c(m1) to a.b.c(m1$)
             Building PCL command table...
             Reading a.b.c(m1)...
             a.b.c(m1) contains 142 bytes of data
             Processing...
             Processed 0%
             Processed 88%
             Processed 92%
             Done
             ***

          2. Upload another PCL file to a.b.c(m2), then
             tso vpssep m2
             Converting a.b.c(m2) to a.b.c(m2$)
             Building PCL command table...
             Reading a.b.c(m2)...
             a.b.c(m2) contains 111 bytes of data
             Processing...
             Processed 0%
             Processed 88%
             Processed 92%
             Done
             ***

options = ASM    - Emit assembly language source code
          COM    - Emit * records documenting font
                   headers and HP/GL2 PE commands
          DRAW   - Emit * records that draw each font
                   character definition (pclxl only).
          HEX    - Emit * records for binary data (in
                   printable hex)
          SPACE  - Emit blank lines
          TRACE  - Trace conversion process
          VAR    - Emit & record for variable names
          X      - Emit X (printable hex) records rathe
                   than B (binary) records for binary
                   data.

          Prefix any option with 'NO' to negate it.
          For example, NOSPACE to supress blank lines.
          
Prerequisites
-------------
You need a REXX interpreter installed, such as
  * [Regina REXX](http://regina-rexx.sourceforge.net)
  * [Open Object REXX](http://www.oorexx.org/)
  * TSO REXX on z/OS


Examples
-------
    rexx vpssep.rex mypcl.pcl
    ...decodes the given PCL file to a file called mypcl$.txt