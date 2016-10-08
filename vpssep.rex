/**REXX****************************************************************
*                                                                     *
* VPSSEP v1.3 - VPS Dynamic Separator Page Printer                    *
*                                                                     *
* Copyright (C) 1998-2016 Andrew J. Armstrong                         *
* androidarmstrong@gmail.com                                          *
*                                                                     *
* This program is free software; you can redistribute it and/or modify*
* it under the terms of the GNU General Public License as published by*
* the Free Software Foundation; either version 2 of the License, or   *
* (at your option) any later version.                                 *
* This program is distributed in the hope that it will be useful,     *
* but WITHOUT ANY WARRANTY; without even the implied warranty of      *
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the       *
* GNU General Public License for more details.                        *
* You should have received a copy of the GNU General Public License   *
* along with this program; if not, write to the Free Software         *
* Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307*
*                                                                     *
**********************************************************************/
/**REXX****************************************************************
**                                                                   **
** NAME     - VPSSEP                                                 **
**                                                                   **
** FUNCTION - Converts a binary PCL file to an editable format.      **
**            The resulting template is read by the VPS separator    **
**            page exit in order to print the separator page on a    **
**            PCL or Postscript printer.                             **
**                                                                   **
**            As the exit scans the template, it substitutes any     **
**            variables with their current values before sending the **
**            resulting text to the printer.  The variables are      **
**            described in the OUTPUT section below.                 **
**                                                                   **
**            NOTE: A Postscript file can also be processed, but the **
**            resulting template will be a series of text records    **
**            with no special formating of any embedded variables.   **
**            If you want to create a separator page for a Postscript**
**            printer then you will have to manually edit the        **
**            template to ensure that any variables begin in column1.**
**                                                                   **
**                                                                   **
** SYNTAX   - VPSSEP [indsn [outdsn]] [(options...]                  **
**                                                                   **
**            Where,                                                 **
**                                                                   **
**            indsn  = Input dataset containing PCL driver binary    **
**                     output.                                       **
**                                                                   **
**            outdsn = Output dataset to contain the template.       **
**                     Both the input and output dataset names are   **
**                     remembered across invocations so you do not   **
**                     have to re-specify them each time.            **
**                                                                   **
**                     If you initially specify a PDS dataset and    **
**                     member name - e.g. MY.PDS(INPUT1) - then you  **
**                     can specify just a member name the next time  **
**                     - e.g. INPUT2 - and the last PDS will be      **
**                     used.                                         **
**                                                                   **
**                     You can ask to be prompted for a dataset name **
**                     by specifying '..' for indsn or outdsn.       **
**                                                                   **
**                     You can ask that the last dataset be used     **
**                     by specifying '.' for indsn or outdsn.        **
**                                                                   **
**                     A typical session might look like:            **
**                                                                   **
**                     1. Upload PCL file to a.b.c(m1), then:        **
**                        tso vpssep                                 **
**                        Enter input dataset name:                  **
**                        a.b.c(m1)                                  **
**                        Converting a.b.c(m1) to a.b.c(m1$)         **
**                        Building PCL command table...              **
**                        Reading a.b.c(m1)...                       **
**                        a.b.c(m1) contains 142 bytes of data       **
**                        Processing...                              **
**                        Processed 0%                               **
**                        Processed 88%                              **
**                        Processed 92%                              **
**                        Done                                       **
**                        ***                                        **
**                                                                   **
**                                                                   **
**                     2. Upload another PCL file to a.b.c(m2), then:**
**                        tso vpssep m2                              **
**                        Converting a.b.c(m2) to a.b.c(m2$)         **
**                        Building PCL command table...              **
**                        Reading a.b.c(m2)...                       **
**                        a.b.c(m2) contains 111 bytes of data       **
**                        Processing...                              **
**                        Processed 0%                               **
**                        Processed 88%                              **
**                        Processed 92%                              **
**                        Done                                       **
**                        ***                                        **
**                                                                   **
**                                                                   **
**            options= ASM    - Emit assembly language source code   **
**                     COM    - Emit * records documenting font      **
**                              headers and HP/GL2 PE commands       **
**                     DRAW   - Emit * records that draw each font   **
**                              character definition (pclxl only).   **
**                     HEX    - Emit * records for binary data (in   **
**                              printable hex)                       **
**                     SPACE  - Emit blank lines                     **
**                     TRACE  - Trace conversion process             **
**                     VAR    - Emit & record for variable names     **
**                     X      - Emit X (printable hex) records rather**
**                              than B (binary) records for binary   **
**                              data.                                **
**                                                                   **
**                     Prefix any option with 'NO' to negate it.     **
**                     For example, NOSPACE to supress blank lines.  **
**                                                                   **
**                                                                   **
**                                                                   **
** NOTES    - 1.  You can create the output file manually, or you can**
**                speed up the process considerably by using the     **
**                following procedure:                               **
**                                                                   **
**                1.  Use a PC-based program such as MS Word to      **
**                    create a mock-up banner page.                  **
**                    Variables may be included in the mock-up (see  **
**                    SYNTAX below for a list of variables).         **
**                                                                   **
**                2.  Select a PCL printer driver for the printer on **
**                    which the separator page will ulimately be     **
**                    printed.  Print the mock-up banner page to a   **
**                    PC file.                                       **
**                                                                   **
**                3.  Upload the PC file to a mainframe partitioned  **
**                    dataset called sFile (see below) to a member   **
**                    name of your choice.  The sFile                **
**                    dataset *MUST* be RECFM=VB and can be any      **
**                    LRECL, but it has been found that a workable   **
**                    LRECL is around 256.  ISPF edit switches to    **
**                    browse mode if the record length is too big    **
**                    because it has to allocate a full record buffer**
**                    for each record regardless of individual       **
**                    record lengths...so LRECL=27994 rapidly uses   **
**                    up memory.                                     **
**                                                                   **
**                4.  Run this Rexx procedure, specifying the input  **
**                    member name and, optionally, the output member **
**                    name.  If you dont specify the output member   **
**                    name then the default name is the input member **
**                    name with a '$' suffix.                        **
**                                                                   **
**                5.  Check that the output member looks OK - there  **
**                    is always room to optimise the output from a   **
**                    PCL print driver.  The following section       **
**                    describes the syntax of the output file (ie    **
**                    this file).                                    **
**                                                                   **
**            2.  To get VPS to print this separator page for a      **
**                particular printer, specify the following in the   **
**                printer definition member:                         **
**                                                                   **
**                SEPAR=(B,exitname,...)                             **
**                DEVTYPE=member                                     **
**                                                                   **
**                Where, exitname  is the name of the separator page **
**                                 exit WHICH READS THE OUTPUT OF    **
**                                 THIS REXX PROCEDURE.              **
**                       member    is the name of the separator page **
**                                 created by this Rexx procedure.   **
**                                                                   **
**            3.  You must also have the sFile dataset (see below)   **
**                allocated in the VPS started task with a DD name   **
**                of SEPAR.  The separator page exit will read the   **
**                member sepcified by DEVTYPE from the partitioned   **
**                dataset defined by the SEPAR DD.                   **
**                                                                   **
**            4.  If you want to run this rexx code on a PC, you can **
**                install Regina Rexx (free) from:                   **
**                                                                   **
**                http://regina-rexx.sourceforge.net/                **
**                                                                   **
**                This code has been tested with Regina 3.2.         **
**                                                                   **
** INPUT    - A dataset containing raw PCL5, PCLXL (PCL6) or         **
**            Postscript datastream...'raw' means all ASCII code     **
**            points must NOT have been translated to EBCDIC.        **
**            This datastream is typically the output from a Windows **
**            PCL printer driver directed to a file and uploaded to  **
**            the mainframe *without* ASCII/EBCDIC conversion.       **
**                                                                   **
** OUTPUT   - A dataset that contains either:                        **
**                                                                   **
**            1. A special editable version of the input file that   **
**               is readable by the VPS separator page exit. This is **
**               called a template.                                  **
**               For example: TSO VPSSEP indsn                       **
**                                                                   **
**               or,                                                 **
**                                                                   **
**            2. IBM High Level Assembler source statements that     **
**               can be assembled into a load module using HLASM.    **
**               You specify the ASM option to create this format.   **
**               For example: TSO VPSSEP indsn (ASM                  **
**                                                                   **
**            When the ASM option is NOT specified, then column 1 is **
**            a record type indicator and is used as follows:        **
**                                                                   **
**            Col1 Usage                                             **
**            ---- ------------------------------------------------  **
**             *   Signifies a comment line.  The entire record is   **
**                 ignored.                                          **
**                                                                   **
**             B   Signifies that the following text is binary data  **
**                 and is to be appended to the data stream to be    **
**                 sent to the printer 'as is'.  That is, the data   **
**                 is not translated to ASCII.                       **
**                                                                   **
**             C   Signifies that the following text is binary data  **
**                 and is to be appended to the data stream to be    **
**                 sent to the printer 'as is' AFTER REMOVING THE    **
**                 TRAILING X'FF'.  Apparently, MVS removes trailing **
**                 blanks (X'40' code points) from each record before**
**                 it is written to a RECFM=V partitioned dataset    **
**                 member.  The C record is identical to the B       **
**                 record except that the C record has X'FF' appended**
**                 before it is written.  So, if a block of binary   **
**                 data would end in X'40', a C record is written,   **
**                 else a B record is written.                       **
**                                                                   **
**             X   Signifies that the following text is binary data  **
**                 in printable hex format. The data stream to be    **
**                 converted to binary before being sent to the      **
**                 printer.                                          **
**                                                                   **
**             E   Signifies that the following text is a PCL escape **
**                 sequence (excluding the escape character). The    **
**                 remaining text up to, but not including, the      **
**                 first blank is translated to ASCII and appended   **
**                 to the PCL escape character (X'1B').              **
**                 The resulting escape sequence is appended to the  **
**                 data stream to be sent to the printer.            **
**                 Any characters after the first blank are treated  **
**                 as comments and are ignored.                      **
**                                                                   **
**             &   Signifies that the following text is the name of  **
**                 a variable.                                       **
**                 The current content of the variable is translated **
**                 to ASCII and appended to the data stream. The     **
**                 first blank after the & indicates the end of the  **
**                 variable name.                                    **
**                 Any characters after the first blank are treated  **
**                 as comments and are ignored.                      **
**                                                                   **
**             Any other character in column 1 is the delimiter for  **
**             the following text.  The text bounded by these        **
**             delimiters is translated to ASCII and appended to the **
**             data stream to be sent to the printer.                **
**                                                                   **
** NOTES    - 1.  Lines beginning with two blanks are ignored        **
**                because blank is the delimiter and there is no     **
**                text between the first and second blanks.          **
**                                                                   **
**            2.  Variable names are defined by the VAR parameters   **
**                below.  Variable names are not case-sensitive. For **
**                example, the following names are all equivalent:   **
**                                                                   **
**                     &USERNAME                                     **
**                     &username                                     **
**                     &UserName                                     **
**                                                                   **
**            3.  Substrings of the variables can be specified with  **
**                the following syntax:                              **
**                                                                   **
**                &varname(firstchar,numchars)                       **
**                                                                   **
**                For example, &REPCDATE(1,4) returns the first four **
**                characters of the report creation date (ie yyyy).  **
**                                                                   **
**                If numchars is omitted then the remainder of the   **
**                variable starting with firstchar is printed.       **
**                                                                   **
**                The syntax does not enforce the use of '(' or ','. **
**                Any non-blank non-digit may be used to delimit the **
**                firstchar and numchars values.  Parsing for values **
**                stops at the first blank encountered.              **
**                                                                   **
**                For example, the following are all equivalent:     **
**                                                                   **
**                   &REPCDATE(1,4)                                  **
**                   &REPCDATE=1:4                                   **
**                   &REPCDATE-FROM-POSITION-1-FOR-4-CHARACTERS      **
**                                                                   **
**                This feature is useful when you only want a fixed  **
**                number of characters printed for a variable.  The  **
**                &username variable is a good candidate for trunc-  **
**                ation since user names can be quite long.  To      **
**                truncate the &username to, say, 20 characters, you **
**                should specify: &username(1,20)                    **
**                                                                   **
**                                                                   **
** AUTHOR   - Andrew J. Armstrong <androidarmstrong@gmail.com>       **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By Reason (most recent at the top please)     **
**            ------- --- ------------------------------------------ **
**           20161008 AJA Initial commit to github.                  **
**           20041015 AJA Added some new GL2 commands.               **
**           20040412 AJA Support for running on a PC using Regina   **
**                        Rexx (see http://regina-rexx.sf.net).      **
**                        Improved (marginally) option handling.     **
**           20030613 AJA Packaged for distribution via cbttape.org  **
**           20010928 AJA Added loop detection and disk full check.  **
**           20000322 AJA Create IBM HLASM source file as output.    **
**           19980421 AJA Allow PCL5 commands to have null values.   **
**           19971216 AJA Added record type C                        **
**           19970204 AJA Original version                           **
**                                                                   **
**********************************************************************/

  parse arg sFileIn sFileOut' ('sOptions')'
  parse source g.0SYSTEM . sMe .
  say sMe': VPS Dynamic Separator Page Generator v1.3'

  g.0ALLOPTIONS = 'ASM COM DRAW HEX SPACE TRACE VAR X'
  g.0DESC.ASM   = 'emit assembly language source code'
  g.0DESC.COM   = 'emit * records documenting font ' ||,
                  'headers and HP/GL2 PE commands'
  g.0DESC.DRAW  = 'emit * records to draw (PCLXL) soft font characters'
  g.0DESC.HEX   = 'emit * records for binary data (in printable hex)'
  g.0DESC.SPACE = 'emit blank lines'
  g.0DESC.TRACE = 'trace conversion process'
  g.0DESC.VAR   = 'emit & record for variable names'
  g.0DESC.X     = 'emit X record type for binary data (in printable hex)'

/*--------------------------------------------------------------------*
 * Determine the input and output file names                          *
 *-------------------------------------------------------------------*/

  if g.0SYSTEM = 'TSO'
  then do
    address TSO 'CLEAR'
    g.0LINES = 0
    address ISPEXEC
    parse arg sInDSN sOutDSN' ('sOptions')'
    'VGET (VPSSEPI VPSSEPO) PROFILE'
    sFileIn  = getDSN('Enter input dataset name:' ,sInDSN,  VPSSEPI)

    if sOutDSN = ''
    then do
       parse var sFileIn sDataset'('sMember')'
       if VPSSEPO <> ''
       then parse var VPSSEPO sDataset'('
       sOutDSN = sDataset'('strip(left(sMember,7))'$)'
    end
    sFileOut = getDSN('Enter output dataset name:',sOutDSN, VPSSEPO)

    VPSSEPI = sFileIn
    VPSSEPO = sFileOut
  end

  call parseOptions sOptions

  if sFileIn = ''
  then do
    say
    say 'Syntax:' sMe 'inputfile [outputfile] [(options]'
    exit 4
  end


/*--------------------------------------------------------------------*
 *                                                                    *
 *-------------------------------------------------------------------*/

  numeric digits 20

  say 'Converting' sFileIn 'to' sFileOut

  g.0bLastWasBlank = 0
  g.0bModeGL2   = 0 /* 1=HP-GL/2 mode, 0=Not HP-GL/2 mode */
  g.0bPCLXL     = 0 /* 1=PCLXL mode,   0=Not PCLXL mode   */
  g.0bText      = 0 /* 1=Print text,   0=Print binary     */
  g.0bData      = 0 /* 1=Print data,   0=Dont print data  */
  g.0UNITSIZE   = 1 /* For PCLXL command values */
  s. = ''
  u. = ''
  v. = ''
  call Prolog

  g.0hFileIn = openFile(sFileIn,'INPUT')
  g.0hFileOut = openFile(sFileOut,'OUTPUT')

/*--------------------------------------------------------------------*
 *  Insert function box in the output file...                         *
 *--------------------------------------------------------------------*/

  select
    when g.0OPTION.ASM then queue 'VPSSEP   CSECT'
    otherwise nop
  end


  do i = 1 by 1 while sourceline(i) <> '/*BOX'
  end

  nFirstLine = i + 1

  do i = nFirstLine while sourceline(i) <> '//'
    sLine = sourceline(i)
    select
      when sLine = '&name' then,
           queue '** NAME     -' left(sFileOut,55)'**'
      when sLine = '&title' then do
           sData = 'SEPARATOR PAGE FOR',
                   '<insert printer type here>'
           queue '** TITLE    -' left(sData,55)'**'
      end
      when sLine = '&date' then,
           queue '**           ' left(date('SORTED'),
                                      left(userid(),8),
                                     'Initial version.',55)'**'
      otherwise queue sLine
    end
  end

  call DoComment 'Generated on' date() 'by' userid()

  call putQueued g.0hFileOut

  if g.0OPTION.ASM
  then do
    call Log '*    ' left('Hex Data',16) ' CharData Explanation'
    call Log '*    ' copies('-',     16) ' --------' copies('-',38)
  end

/*--------------------------------------------------------------------*
 *  Read the binary input file into a single REXX variable...         *
 *--------------------------------------------------------------------*/

  say 'Reading' sFileIn'...'
  sData = getEntireFile(g.0hFileIn)

  call closeFile g.0hFileIn

  nTotalBytes = length(sData)
  say sFileIn 'contains' nTotalBytes 'bytes of data'

/*--------------------------------------------------------------------*
 *  Convert the binary data into editable-PCL format...               *
 *--------------------------------------------------------------------*/

  say 'Processing...'
  nCheckPoint = 0
  do while length(sData) > 0

    if length(sData) = nCheckPoint
    then do
      call Log 'Loop detected at' nTotalBytes - length(sData)
      call Log c2x(substr(sData,1,32))
      call Abort 'Loop detected'
    end
    nCheckPoint = length(sData)

    nBytesDone = nTotalBytes - length(sData)
    nPercent   = trunc(nBytesDone/nTotalBytes * 100)
    nSlot      = trunc(nPercent/10)
    if nSlot <> nSlotLast
    then do
      say 'Processed' nPercent'%'
      nSlotLast = nSlot
    end

    if g.0OPTION.TRACE then say '+'nTotalBytes - length(sData)
    if g.0bPCLXL
    then call DoPCLXL
    else do
      parse var sData sText '1b'x sData

     /*-----------------------------------------------------------------*
      *  Output text or binary data, if any                             *
      *-----------------------------------------------------------------*/

      if length(sText) > 0
      then do
        if g.0bModeGL2
        then call LogGL2 ' ',sText
        else call DoText
        if g.0bPCLXL
        then do      /* Reconstruct data stream and treat it as PCLXL */
          sData = sText || '1b'x || sData
        end
      end

     /*-----------------------------------------------------------------*
      *  Output PCL command                                             *
      *-----------------------------------------------------------------*/

      if \g.0bPCLXL & length(sData) > 0 then call DoPCL5
    end
  end

/*--------------------------------------------------------------------*
 *  Output end-of-file comment                                        *
 *--------------------------------------------------------------------*/

  call DoComment 'End of File'

  select
    when g.0OPTION.ASM then queue '         END'
    otherwise nop
  end

  call putQueued g.0hFileOut

  call Epilog
exit

/*-------------------------------------------------------------------*
 * Parse commmand-line options
 *-------------------------------------------------------------------*/

parseOptions: procedure expose g.
  arg sOptions
  call setOptions 'NOASM COM NODRAW HEX SPACE NOTRACE VAR NOX'
  if sOptions <> ''
  then say 'User specified options:' sOptions
  call setOptions sOptions
  say 'Options in effect:'
  call showOptions
return

showOptions: procedure expose g.
  do i = 1 to words(g.0ALLOPTIONS)
    sOption = word(g.0ALLOPTIONS,i)
    if g.0OPTION.sOption
    then say right(sOption,8),
      translate(left(g.0DESC.sOption,1))substr(g.0DESC.sOption,2)
    else say right('NO'sOption,8) 'Do not' g.0DESC.sOption
  end
return

setOptions: procedure expose g.
  arg sOptions
  do i = 1 to words(sOptions)
    sOption = word(sOptions,i)
    if left(sOption,2) = 'NO'
    then sBaseOption = substr(sOption,3)
    else sBaseOption = sOption
    g.0OPTION.sBaseOption = left(sOption,2) <> 'NO'
    sNoBaseOption = 'NO'sBaseOption
    g.0OPTION.sNoBaseOption = \g.0OPTION.sBaseOption
  end
return

/*-------------------------------------------------------------------*
 * Open a file
 *-------------------------------------------------------------------*/

openFile: procedure expose g.
  parse arg sFile,sOptions
  hFile = ''
  select
    when g.0SYSTEM = 'TSO' then do
      parse var sFile sDataset'('sMember')'
      if sMember <> '' then sFile = sDataset
      if wordpos('OUTPUT',sOptions) = 0 /* if not opening for output */
      then 'LMINIT  DATAID(hFile) DATASET(&sFile)'
      else 'LMINIT  DATAID(hFile) DATASET(&sFile) ENQ(EXCLU)'
      g.0OPTIONS.hFile = sOptions
      'LMOPEN  DATAID(&hFile) OPTION(INPUT)' /* Input initially */
      if sMember <> ''
      then do
        g.0MEMBER.hFile = sMember
        'LMMFIND DATAID(&hFile) MEMBER('sMember') STATS(YES)'
        if wordpos('OUTPUT',sOptions) > 0
        then do
          if rc = 0
          then g.0STATS.hFile = zlvers','zlmod','zlc4date
          else g.0STATS.hFile = '1,0,0000/00/00'
          'LMCLOSE DATAID(&hFile)'
          'LMOPEN  DATAID(&hFile) OPTION(&sOptions)'
        end
      end
      g.0rc = rc
    end
    when g.0SYSTEM = 'WIN32' then do
      if wordpos('OUTPUT',sOptions) > 0
      then junk = stream(sFile,'COMMAND','OPEN WRITE REPLACE')
      else junk = stream(sFile,'COMMAND','OPEN READ')
      hFile = sFile
      if stream(sFile,'STATUS') = 'READY'
      then g.0rc = 0
      else g.0rc = 4
    end
    when g.0SYSTEM = 'UNIX' then do
      if sFile = '' 
      then g.0rc = 0
      else do
        if wordpos('OUTPUT',sOptions) > 0
        then junk = stream(sFile,'COMMAND','OPEN WRITE REPLACE')
        else junk = stream(sFile,'COMMAND','OPEN READ')
        hFile = sFile
        if junk = 'READY:'
        then g.0rc = 0
        else g.0rc = 4
      end
    end
    otherwise call Abort,
      'Do not know how to open files on system type:' g.0SYSTEM
  end
return hFile

/*-------------------------------------------------------------------*
 * Read a line from the specified file
 *-------------------------------------------------------------------*/

getLine: procedure expose g.
  parse arg hFile
  sLine = ''
  select
    when g.0SYSTEM = 'TSO' then do
      'LMGET DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN(nLine) MAXLEN(32768)'
      g.0rc = rc
      sLine = strip(sLine,'TRAILING')
      if sLine = '' then sLine = ' '
    end
    when g.0SYSTEM = 'WIN32' | g.0SYSTEM = 'UNIX' then do
    trace r
      g.0rc = 0
      if chars(hFile) > 0
      then sLine = linein(hFile)
      else g.0rc = 4
    trace o
    end
    otherwise nop
  end
return sLine

/*-------------------------------------------------------------------*
 * Append a line to the specified file
 *-------------------------------------------------------------------*/

putLine: procedure expose g.
  parse arg hFile,sLine
  if g.0OPTION.NOSPACE & sLine = ''
  then return 0
  select
    when g.0SYSTEM = 'TSO' then do
      g.0LINES = g.0LINES + 1
      if sLine = '' then sLine = ' '
      'LMPUT DATAID(&hFile) MODE(INVAR)',
            'DATALOC(sLine) DATALEN('length(sLine)')'
    end
    when g.0SYSTEM = 'WIN32' | g.0SYSTEM = 'UNIX' then do
      junk = lineout(hFile,sLine)
      rc = 0
    end
    otherwise nop
  end
return rc

/*-------------------------------------------------------------------*
 * Close the specified file
 *-------------------------------------------------------------------*/

closeFile: procedure expose g.
  parse arg hFile
  rc = 0
  select
    when g.0SYSTEM = 'TSO' then do
      if g.0MEMBER.hFile <> '',
      & wordpos('OUTPUT',g.0OPTIONS.hFile) > 0 /* if opened for output */
      then do
        parse value date('STANDARD') with yyyy +4 mm +2 dd +2
        parse var g.0STATS.hFile zlvers','zlmod','zlc4date
        zlcnorc  = min(g.0LINES,65535)   /* Number of lines   */
        nVer = right(zlvers,2,'0')right(zlmod,2,'0')  /* vvmm */
        nVer = right(nVer+1,4,'0')       /* vvmm + 1          */
        parse var nVer zlvers +2 zlmod +2
        if zlc4date = '0000/00/00'
        then zlc4date = yyyy'/'mm'/'dd   /* Creation date     */
        zlm4date = yyyy'/'mm'/'dd        /* Modification date */
        zlmtime  = time()                /* Modification time */
        zluser   = userid()              /* Modification user */
        zlc4date = zlm4date
        'LMMREP DATAID(&hFile) MEMBER('g.0MEMBER.hFile') STATS(YES)'
      end
      'LMCLOSE DATAID(&hFile)'
      'LMFREE  DATAID(&hFile)'
    end
    when g.0SYSTEM = 'WIN32' | g.0SYSTEM = 'UNIX' then do
      if stream(hFile,'COMMAND','CLOSE') = 'UNKNOWN'
      then rc = 0
      else rc = 4
    end
    otherwise nop
  end
return rc

putQueued: procedure expose g.
  parse arg hFile
  do queued() until rc <> 0
    parse pull sLine
    rc = putLine(hFile,sLine)
  end
return rc

getEntireFile: procedure expose g.
  parse arg hFile
  sData = ''
  select
    when g.0SYSTEM = 'TSO' then do
      sLine = getLIne(hFile)
      do i = 1 by 1 while g.0RC = 0
        sData = sData || sLine
        sLine = getLIne(hFile)
      end
    end
    when g.0SYSTEM = 'WIN32' | g.0SYSTEM = 'UNIX' then do
      g.0rc = 0
      if chars(hFile) > 0
      then sData = charin(hFile,1,chars(hFile))
      else g.0rc = 4
    end
    otherwise nop
  end
return sData

Epilog:
  say 'Done'
  if g.0SYSTEM = 'TSO'
  then do
    'VPUT (VPSSEPI VPSSEPO) PROFILE'
  end
  call closeFile g.0hFileOut
return

/*
* Prompt the user if necessary for a dataset name and return only
* if the dataset exists. The user can force the use of the last
* dataset by specifying '.' and can ask to be prompted for a new
* dataset by specifying '..'.
*
*/
getDSN: procedure
  parse arg sPrompt,sArg,sVar

  select
    when sArg = ''   then sDSN = sVar
    when sArg = '.'  then sDSN = sVar
    when sArg = '..' then sDSN = ''
    otherwise             sDSN = sArg
  end

  if sDSN = ''
  then do                  /* Prompt if no current value */
    say sPrompt
    pull sDSN
    if sDSN = '' then exit /* Abandon if user supplies no value */
  end
  else do
    if isMemberName(sDSN) & pos('(',sVar) > 0
    then do                /* Use new member in same PDS */
      parse var sVar sDataset'('
      sDSN = sDataset'('sDSN')'
    end
  end

  sResult = SYSDSN(sDSN)

  select
    when sResult = 'OK'               then return sDSN
    when sResult = 'MEMBER NOT FOUND' then return sDSN
    otherwise say sDSN':' sResult
  end
exit

isMemberName: procedure
  arg sMember
  if length(sMember) > 8 then return 0
  if length(sMember) = 0 then return 0
  if datatype(left(sMember,1),'WHOLE') then return 0
return datatype(substr(sMember,2),'ALPHANUMERIC')

DoComment: procedure expose g.
  parse arg sComment
  queue
  queue '*'copies('-',69)'*'
  queue '*        'left(sComment,61)'*'
  queue '*'copies('-',69)'*'
  queue
return

DoPCLXL:
/*
The general PCLXL data stream format seems to a repeated sequence of:
     <operand><operand>...<command>
Where,
     <operand> begins with 'C0'x to 'FF'x and is followed by a value
               All values are in little-endian format.
               For example: C0xx        - 1-byte value
                            C1xxxx      - 2-byte value
                            C2xxxxxxxx  - 4-byte value
                            C5xxyyxxyy  - 1-byte coord pair(x1,y1,x2,y2)
                            C8          - 1-byte data units follow
                            C9          - 2-byte unicode values follow
                            CB          - 2-byte data units follow
                            D0wwhh      - 1-byte dimension (w x h)
                            D1wwwwhhhh  - 2-byte dimension (w x h)
                            D3xxxxyyyy  - 2-byte coordinate (x,y)
                            D5xxxxxxxxyyyyyyyy  - 2-byte coordinate
                            E3xxxxyyyyxxxxyyyy  - 2-byte coordinate pair
                            EBxxyyzz    - 3-byte triplet
                            29          - comment terminated by LF
                            FAxxxxxxxx  - 4-byte length followed by data
                            FBxx        - 1-byte length followed by data

     <command> begins with 'F8'x and is followed by a command byte
               For example: F8ccmmmmmm  - 1-byte command optionally
                                          followed by modifier bytes

*/
  say 'PCLXL processing...'
  say

  /* Log the LF (or whatever) before the first PCLXL command first...*/
  i = verify(sData,xrange('C0'x,'FF'x)'29'x,'MATCH')
  nLen = i - 1
  if nLen > 0
  then do
    parse var sData sChunk +(nLen) sData
    call LogBinary sChunk
  end

  do while length(sData) > 0
    c = left(sData,1)
    select
      when c = '1b'x then do
        g.0bPCLXL = 0
        say 'PCLXL mode ended'
        return
      end
      when c = 'F8'x then do  /* Escape code... */
        cc = substr(sData,2,1)
        select
          when cc = '04'x then sCommand = 'SetFill (0=Off,1=On)'
          when cc = '05'x then sCommand = 'SetOutline (0=Off,1=On)'
          when cc = '06'x then sCommand = 'SetColorSpace'
          when cc = '09'x then sCommand = 'SetColor'
          when cc = '25'x then sCommand = 'SetPaperSize'
          when cc = '26'x then sCommand = 'SetPaperSource'
          when cc = '27'x then sCommand = 'SetPaperStock'
          when cc = '28'x then sCommand = 'SetOrientation (0=Pt,1=Ls,2=1800)'
          when cc = '2A'x then sCommand = 'SetPageScale'
          when cc = '2B'x then sCommand = '?SetPageDimension'
          when cc = '31'x then sCommand = 'SetCopyCount'
          when cc = '42'x then sCommand = 'DrawRectangle'
          when cc = '45'x then sCommand = 'DrawLine'
          when cc = '48'x then sCommand = '?SetEllipse (0=Off,1=On)'
          when cc = '4B'x then sCommand = 'SetPenWidth'
          when cc = '4C'x then sCommand = 'SetCursorXY'
          when cc = '4D'x then sCommand = 'SetPolyLineCount'
          when cc = '50'x then sCommand = 'DrawPolyLine'
          when cc = '67'x then sCommand = 'SetImageSize'
          when cc = '6D'x then sCommand = 'ImageData'
          when cc = '89'x then sCommand = 'SetResolution'
          when cc = 'A1'x then sCommand = '?ResetTextBuffer'
          when cc = 'A2'x then sCommand = 'SetCharacterIndex'
          when cc = 'A3'x then sCommand = 'DefineCharacter'
          when cc = 'A7'x then sCommand = 'SetSoftFontDataLength'
          when cc = 'A8'x then sCommand = 'SetFont'
          when cc = 'AB'x then sCommand = 'SetText'
          when cc = 'AF'x then sCommand = 'SetTextWidths'
          otherwise            sCommand = '?'
        end
        i = verify(sData,xrange('C0'x,'FF'x)'1b'x,'MATCH', 2)
        nLen = i - 1
        if nLen > 0
        then parse var sData sChunk +(nLen) sData
        else parse var sData sChunk sData
        call LogPCL6Cmd sChunk,'Command',c2x(sChunk),sCommand
      end

      when c = 'C0'x then do  /* 1-Byte value */
        parse var sData sChunk +2 2 cXX +1 sData
        call LogPCL6Arg sChunk,'1-byte Value','C0',c2d(cXX)
      end

      when c = 'C1'x then do  /* 2-Byte byte-reversed length*/
        if substr(sData,4,1) <> 'F8'x
        then do  /* print command C1xxxx and xxxx data units */
          parse var sData 2 sLen +2
          nCount = d(sLen)
          nLen = nCount * g.0UNITSIZE
          parse var sData sChunk +3 sChunk2 +(nLen) sData
          call LogPCL6Arg sChunk,'2-byte Count','C1',nCount
          if g.0OPTION.NOX
          then call Log '*       'nCount' x 'g.0UNITSIZE'-byte values...'
          if g.0UNITSIZE = 1 & IsPrintable(sChunk2)
          then call LogText a2e(sChunk2)
          else call LogBinary sChunk2
        end
        else do  /* just print the command: C1xxxx */
          parse var sData sChunk +3 2 sLen +2 sData
          nValue = d(sLen)
          call LogPCL6Arg sChunk,'2-byte Value','C1',nValue
        end
      end

      when c = 'C2'x then do  /* 4-byte byte-reversed value */
        parse var sData sChunk +5 2 sX +4 sData
        call LogPCL6Arg sChunk,'4-byte Value','C2',d(sX)
      end

      when c = 'C3'x then do  /* 2-byte byte-reversed value */
        parse var sData sChunk +3 2 sX +2 sData
        call LogPCL6Arg sChunk,'2-byte Value','C3',d(sX)
      end

      when c = 'C5'x then do  /* xxyyxxyy rectangle */
        parse var sData sChunk +5 2 s1 +1 s2 +1 s3 +1 s4 +1 sData
        sRect = '('c2d(s1)','c2d(s2)','c2d(s3)','c2d(s4)')'
        call LogPCL6Arg sChunk,'1-byte Rectangle','C5',sRect
      end

      when c = 'C8'x then do  /* Array unit size = 1 byte values */
        g.0UNITSIZE = 1
        parse var sData sChunk +1 sData
        call LogPCL6Arg sChunk,'Array unit size','C8','1-byte'
      end

      when c = 'C9'x then do  /* Array of 2-byte Unicode values */
        g.0UNITSIZE = 2
        parse var sData sChunk +1 sData
        call LogPCL6Arg sChunk,'Array of Unicode values','CB','2-byte'
      end

      when c = 'CB'x then do  /* Array unit size = 2 byte values */
        g.0UNITSIZE = 2
        parse var sData sChunk +1 sData
        call LogPCL6Arg sChunk,'Array unit size','CB','2-byte'
      end

      when c = 'D0'x then do  /* xxyy 1-byte w x h dimension */
        parse var sData sChunk +3 2 sX +1 sY +1 sData
        sDim = d(sX) 'x' d(sY)
        call LogPCL6Arg sChunk,'1-byte Dimension','D0',sDim
      end

      when c = 'D1'x then do  /* xxxxyyyy byte-reversed dimension */
        parse var sData sChunk +5 2 sX +2 sY +2 sData
        sDim = d(sX) 'x' d(sY)
        call LogPCL6Arg sChunk,'2-byte Dimension','D1',sDim
      end

      when c = 'D3'x then do  /* xxxxyyyy byte-reversed co-ord */
        parse var sData sChunk +5 2 sX +2 sY +2 sData
        sCoord = d(sX)','d(sY)
        call LogPCL6Arg sChunk,'2-byte Coordinate','D3',sCoord
      end

      when c = 'D5'x then do  /* xxxxyyyyxxxxyyyy byte-reversed rect*/
        parse var sData sChunk +9 2 sX +2 sY +2 sX2 +2 sY2 +2 sData
        sRect = '('d(sX)','d(sY)','d(sX2)','d(sY2)')'
        call LogPCL6Arg sChunk,'2-byte Rectangle','D5',sRect
      end

      when c = 'E3'x then do  /* xxxxyyyyxxxxyyyy byte-reversed rect*/
        parse var sData sChunk +9 2 sX +2 sY +2 sX2 +2 sY2 +2 sData
        sRect = '('d(sX)','d(sY)','d(sX2)','d(sY2)')'
        call LogPCL6Arg sChunk,'2-byte Rectangle','E3',sRect
      end

      when c = 'EB'x then do  /* xxyyzz */
        parse var sData sChunk +4 sData
        sValue = c2x(substr(sChunk,2))
        call LogPCL6Arg sChunk,'3-byte Value','EB',sValue
      end

      when c = '29'x then do  /* )...comment...LF */
        parse var sData sComment '0a'x sData
        if g.0OPTION.NOX
        then call Log '*       Comment (29)...'
        call LogText a2e(sComment)
        call LogBinary '0a'x
      end

      when c = 'FA'x then do  /* xxxxxxxx byte-reversed length, data*/
        parse var sData sChunk +5 2 sLen +4
        nLen = d(sLen)
        call LogPCL6Arg sChunk,'4-byte Count','FA',nLen
        if g.0OPTION.NOX
        then call Log '*       'nLen 'bytes of data...'
        parse var sData 6 sChunk +(nLen) sData
        if cc = 'A3'x & g.0OPTION.DRAW
        then call drawCharacter sChunk
        call LogBinary sChunk
        i = verify(sData,xrange('C0'x,'FF'x),'MATCH')
        if i > 1
        then do
          i = i - 1
          parse var sData sChunk +(i) sData
          if g.0OPTION.NOX
          then call Log '*       Modifiers...'
          call LogBinary sChunk
        end
      end

      when c = 'FB'x then do  /* xx bytes of data */
        parse var sData sChunk +2 2 sLen +1 sData
        nLen = d(sLen)
        call LogPCL6Arg sChunk,'1-byte Count','FB',nLen
        if g.0OPTION.NOX
        then call Log '*       'nLen 'bytes of data...'
        parse var sData sChunk +(nLen) sData
        if cc = 'A3'x & g.0OPTION.DRAW
        then call drawCharacter sChunk
        call LogBinary sChunk
        i = verify(sData,xrange('C0'x,'FF'x),'MATCH')
        if i > 1
        then do
          i = i - 1
          parse var sData sChunk +(i) sData
          call LogPCL6Arg sChunk,'Modifiers of','FB'
        end
      end

      otherwise do
        parse var sData sChunk +1 sData
        call LogPCL6Arg sChunk,'Unknown PCLXL data type',c2x(sChunk)
        say 'Unknown PCLXL data type:' c2x(sChunk)
      end
    end
  end
return

d: procedure
  parse arg s
return c2d(reverse(s))

drawCharacter: procedure expose g.
  parse arg 1 sType +2 7 sBitsPerRow +2 9 sRows +2 sCharDef
  if sType <> '0000'x then return
  nRows = c2d(sRows)
  nBytesPerRow = trunc(c2d(sBitsPerRow)/8)
  do i = 1 to nRows
    sRow = substr(sCharDef,(i-1)*nBytesPerRow+1,nBytesPerRow)
    call Log '*' translate(x2b(c2x(sRow)),' X','01')
  end
return

LogPCL6Arg: procedure expose g.
  parse arg sChunk,sType,xCmd,sValue
  select
    when g.0OPTION.ASM then do
      call LogASM sChunk,,sType '=' sValue
    end
    when g.0OPTION.X then do
      call Log 'o'left(c2x(sChunk),18) sType '=' sValue
    end
    otherwise do
      call Log '*      ' sType '('xCmd') =' sValue'...'
      call LogBinary sChunk
    end
  end
return

LogPCL6Cmd: procedure expose g.
  parse arg sChunk,sType,xCmd,sValue
  select
    when g.0OPTION.ASM then do
      call LogASM sChunk,,sType '=' sValue
      call Log
    end
    when g.0OPTION.X then do
      call Log 'c'left(c2x(sChunk),18) sValue
      call Log
    end
    otherwise do
      call Log '*      ' sType '('xCmd') =' sValue'...'
      call LogBinary sChunk
    end
  end
return




DoPCL5:
  c = left(sData,1)
  c = a2e(c)
  if pos(c,'=EYZ9') > 0   /* ...commands without values */
  then do
    select
      when g.0OPTION.ASM then call LogASM '1B'x || left(sData,1),'.'c,s.c
      otherwise call Log left('E'c,g.0nMargin) s.c
    end
    sData = substr(sData,2)
  end
  else do
    /* A capital letter is the end of a set of PCL commands */
    i = verify(sData,g.0sTerminators,'MATCH')
    if i <> 0 /* i is the first capital letter (ie end of command) */
    then do
      if substr(sData,i,1) = '1b'x
      then i = i - 1              /* lower-case terminated in error */
      parse var sData sCmd +(i) sData
      sCmd = a2e(sCmd)            /* ...command set */
      parse var sCmd 1 c1 +1 2 c2 +1
      sSuffix = right(sCmd,1)
      if pos(c1,'()') > 0,        /* If 1st char is ( or ) */
       & pos(c2,'0123456789') > 0,/* and 2nd char is a number */
       & pos(sSuffix,'@X') = 0    /* and last char is not @ or X */
      then do                     /* Font selection */
        sID = '(I '
        sComment = s.sID
        sValue   = substr(sCmd,2)
        sValueForComment = strip(sValue,'LEADING','0')
        sComment = sComment '=' sValueForComment u.sID
        sIDValue = sID || sValueForComment
        sMeaning = s.sIDValue
        if sMeaning <> ''
        then sComment = sComment '('sMeaning')'
        select
          when g.0OPTION.ASM then,
            call LogASM '1B'x || e2a(sCmd),'.'sCmd,sComment
          otherwise call Log left('E'sCmd,g.0nMargin) sComment
        end
      end
      else do                     /* ccnnnxnnnxnnnX */
        if pos(c2,'0123456789') > 0,/* If 2nd char is a number      */
         | (c1 = '%' & c2 <> '-')   /* Sodding sodding sodding...   */
        then nPrefix = 1            /* Then prefix is 1 char long   */
        else nPrefix = 2            /* Else prefix is 2 chars long  */
        sPrefix = left(sCmd,nPrefix)
        sCmd = substr(sCmd,nPrefix+1)
        cSuffix = right(sCmd,1)     /* Pick off last character */
        if pos(cSuffix,'@'xrange('A','Z')) = 0
        then do /* command is not terminated by an upper case letter */
          sComment = 'WARNING:    INVALID PCL COMMAND TERMINATOR',
                                '<'sCmd'>'
          say sComment
          call Log '*                'sComment
        end
        sTemp  = sCmd              /* For example: 1vt2G */
        do j = 1 by 1 while length(sTemp) > 0
          sValue = ''
          sOrder = ''
          nValue = verify(sTemp,g.0sNumerics,'MATCH')
          nAlpha = verify(sTemp,g.0sAlphas, 'MATCH')
          select
            when nValue = 0 then do
              sOrder = substr(sTemp,nAlpha,1)
              sTemp  = substr(sTemp,nAlpha+1)
            end
            when nValue < nAlpha then do
              sValue = substr(sTemp,nValue,nAlpha-nValue)
              sOrder = substr(sTemp,nAlpha,1)
              sTemp  = substr(sTemp,nAlpha+1)
            end
            when nValue > nAlpha then do
              sOrder = substr(sTemp,nAlpha,1)
              sTemp  = substr(sTemp,nAlpha+1)
            end
            otherwise nop
          end
          call DoCommand j sPrefix sOrder sValue
        end
      end
    end
  end
return




DoCommand:
  parse arg nCommand sPrefix sSuffix sValue
  sSuffixUpper = sSuffix
  upper sSuffixUpper
  sID = sPrefix || sSuffixUpper
  sComment = s.sID
  if sComment = ''
  then do
    sComment = 'ERROR:      UNKNOWN PCL COMMAND',
                  '<'sPrefix || sValue || sSuffix'>'
    say sComment
    call Log '*                'sComment
  end
  sValueForComment = sValue
  if sValue = '' then sValueForComment = '0'
  if datatype(sValueForComment,'NUMBER')
  then sValueForComment = format(sValueForComment)
  if left(sValue,1) = '+'
  then sValueForComment = '+'sValueForComment
  sComment = sComment '=' sValueForComment u.sID
  sIDValue = sID || sValueForComment
  sMeaning = s.sIDValue
  if sID = '*cE' /* Font Create, Character Code */
  then sMeaning = "Hex='"d2x(sValueForComment,2)"'",
                 "Char='"d2c(sValueForComment)"'"
  if sMeaning <> ''
  then sComment = sComment '('sMeaning')'

  if sID = '%A' then call Log /* If we are leaving HP-GL/2 mode...*/

  if nCommand = 1 /* If this is the first command after an escape...*/
  then do
    sCmd = sPrefix || sValue || sSuffix
    select
      when g.0OPTION.ASM then call LogASM '1B'x || e2a(sCmd),'.'sCmd,sComment
      otherwise call Log left('E'sCmd,max(length(sCmd)+1,g.0nMargin)) sComment
    end
  end
  else do
    sCmd = sValue || sSuffix
    select
      when g.0OPTION.ASM then call LogASM e2a(sCmd),sCmd,sComment
      otherwise call Log left(' 'sCmd,max(length(sCmd)+1,g.0nMargin)) sComment
    end
  end

  /* Special processing for some PCL commands */

  select
    when sID = '%B' then do
      g.0bModeGL2 = 1 /* Enter HP-GL/2 mode */
      call Log
    end
    when sID = '%A' then do
      g.0bModeGL2 = 0 /* Enter PCL mode     */
    end
    when sID = '%-X' then do /* Universal Exit Language */
      g.0bModeGL2 = 0 /* Enter PCL mode     */
    end
         /* PCL commands with binary data operands... */
    when sSuffix = 'W' | sID = '&pX' | sID = '*bV' then do
      nBytes = sValue
      if nBytes > 0
      then do
        parse var sData sBinary +(nBytes) sData
        call LogBinary sBinary   /* Write binary data */
        if sID = ')sW' & g.0OPTION.COM /* Font Header */
        then call showFontHeader sBinary
        if sID = '(sW' & g.0OPTION.DRAW /* Character Data */
        then call showCharacterData sBinary
      end
    end

    when sID = '&fX' & sValueForComment = '1' then do
      call Log     /* Add a blank line after end of macro definition */
    end

    otherwise nop
  end

return

showFontHeader: procedure expose g. s.
  parse arg         sSize         +2,
                    sFormat       +1,
                    sType         +1,
                    sStyleMSB     +1,
                    sReserved     +1,
                    sBaselinePos  +2,
                    sCellWidth    +2,
                    sCellHeight   +2,
                    sOrientation  +1,
                    sSpacing      +1,
                    sSymbolSet    +2,
                    sPitch        +2,
                    sHeight       +2,
                    sxHeight      +2,
                    sWidthType    +1,
                    sStyleLSB     +1,
                    sWeight       +1,
                    sTypefaceLSB  +1,
                    sTypefaceMSB  +1,
                    sSerifStyle   +1,
                    sQuality      +1,
                    sPlacement    +1,
                    sUnderlineW   +1,
                    sUnderlineH   +1,
                    sTextHeight   +2,
                    sTextWidth    +2
  call Log '*--------------------------- Font descriptor'
  call LogFont
  call LogFont sSize       ,'Font Descriptor Size'
  nFormat = c2d(sFormat)
  call LogFont sFormat     ,'Header Format',g.0FONTFORMAT.nFormat
  call LogFont sType       ,'Font Type'
  call LogFont sStyleMSB   ,'Style MSB'
  call LogFont sReserved   ,'Reserved'
  call LogFont sBaselinePos,'Baseline Position'
  call LogFont sCellWidth  ,'Cell Width'
  call LogFont sCellHeight ,'Cell Height'
  call LogFont sOrientation,'Orientation'
  sIDValue = '(sP'c2d(sSpacing)
  call LogFont sSpacing    ,'Spacing',s.sIDValue
  call LogFont sSymbolSet  ,'Symbol Set'
  call LogFont sPitch      ,'Pitch (Default HMI)'
  call LogFont sHeight     ,'Height'
  call LogFont sxHeight    ,'x-Height'
  call LogFont sWidthType  ,'Width Type'
  call LogFont sStyleLSB   ,'Style LSB'
  sIDValue = '(sB'c2d(sWeight)
  call LogFont sWeight     ,'Stroke Weight',s.sIDValue
  call LogFont sTypefaceLSB,'Typeface LSB'
  call LogFont sTypefaceMSB,'Typeface MSB'
  call LogFont sSerifStyle ,'Serif Style'
  call LogFont sQuality    ,'Quality'
  call LogFont sPlacement  ,'Placement'
  call LogFont sUnderlineW ,'Underline Position'
  call LogFont sUnderlineH ,'Underline Thickness'
  call LogFont sTextHeight ,'Text Height'
  call LogFont sTextWidth  ,'Text Width'
  call Log '*--------------------------- End of common part'
  call Log
return

LogFont: procedure expose g.
  parse arg sItem,sDesc,sValue
  if sItem = ''
  then do
    g.0LogFontOffset = 0
    return
  end
  nOffset = g.0LogFontOffset
  xItem = c2x(sItem)
  if sValue = ''
  then sValue = c2d(sItem)
  else sValue = c2d(sItem) '('sValue')'
  call Log '*   +'right(nOffset,2,'0') left(xItem,20) sDesc '=' sValue
  g.0LogFontOffset = g.0LogFontOffset + length(sItem)
return

showCharacterData: procedure expose g.
  parse arg         sFormat       +1,
                    sCont         +1,
                    sSize         +1,
                    sClass        +1,
                    sOrientation  +1,
                    sReserved     +1,
                    sLeftOffset   +2,
                    sTopOffset    +2,
                    sCharWidth    +2,
                    sCharHeight   +2,
                    sDeltaX       +2,
                    sRasterData
  select
    when sFormat = '04'x then do /* LaserJet Family (raster) */
      if sCont <> '00'x then return /* coninuation: bail out! */
      nCharWidth = c2d(sCharWidth)
      nCharHeight = c2d(sCharHeight)
      nBytesPerRaster = trunc((nCharWidth+7)/8)
      select
        when sClass = '01'x then do /* Uncompressed Bitmap */
          do i = 1 to nCharHeight
            sRaster = substr(sRasterData,(i-1)*nBytesPerRaster+1,nBytesPerRaster)
            call Log '*' translate(x2b(c2x(sRaster)),' X','01')
          end
        end
        when sClass = '02'x then nop /* Compressed Bitmap */
        when sClass = '03'x then nop /* Contour (Intellifont Scalable) */
        when sClass = '04'x then nop /* Compound Contour (Intellifont) */
        when sClass = '0f'x then nop /* TrueType Scalable */
        otherwise nop
      end
    end
    when sFormat = '0A'x then nop /* Intellifont Scalable */
    when sFormat = '0F'x then nop /* TrueType Scalable */
    otherwise nop
  end
return

DoText:
  nMaxLen = length(sText) + 1
  n = 1
  do while n < nMaxLen

    iNextBinary = verify(sText, xrange('00'x,'1f'x), 'MATCH',   n)
    iNextAlpha  = verify(sText, xrange('00'x,'1f'x), 'NOMATCH', n)
    if iNextAlpha  = 0 then iNextAlpha  = nMaxLen
    if iNextBinary = 0 then iNextBinary = nMaxLen

    if iNextAlpha < iNextBinary
    then do                 /* EXTRACT NEXT PRINTABLE STRING */
      nLen = iNextBinary - iNextAlpha
      sChunk = substr(sText, n, nLen)
      n = iNextBinary
      sChunk = a2e(sChunk)
      call LogText sChunk
      if left(sChunk,4) = '@PJL'
      then do
        parse var sChunk 'LANGUAGE' '=' sLanguage .
        if sLanguage = 'PCLXL'
        then do
          say 'PCLXL detected'
          g.0bPCLXL = 1
          sText = substr(sText,n)
          return
        end
      end
    end
    else do                 /* EXTRACT NEXT BINARY STRING */
      nLen = iNextAlpha - iNextBinary
      sChunk = substr(sText, n, nLen)
      n = iNextAlpha
      call LogBinary sChunk
    end

  end
return

LogText:
  parse arg sOut
  call Log
  if g.0OPTION.NOVAR
  then do /* Do not scan text for variable names */
    call LogTextChunks sOut
  end
  else do /* Scan text for variable names */
    do while pos('&',sOut) > 0
      parse var sOut sBeforeVar'&'sVar sOut
      if length(sBeforeVar) > 0
      then call LogTextChunks sBeforeVar
      sVar = '&'sVar
      parse upper var sVar sVarName'(' /* todo: fix this kludge */
      if v.sVarName <> ''     /* If it is a known variable name */
      then do
        select
          when g.0OPTION.ASM then,
            call Log left('*'sVar,g.0nMargin) 'Variable   ' v.sVarName
          otherwise call Log left(sVar,g.0nMargin) 'Variable   ' v.sVarName
        end
      end
      else do
        sErrorMessage = 'ERROR:      INVALID VARIABLE NAME',
                        '<'sVarName'>'
        say sErrorMessage
        call Log left('*'sVar,16) sErrorMessage
        call Log '* Valid variable names are:'
        do i = 1 by 1 while v.i <> ''
          call Log sValid.i  /* Name and desc of variable i */
        end
      end
    end
    if length(sOut) > 0
    then call LogTextChunks sOut
  end
  call Log
return

LogTextChunks: procedure expose g.
  parse arg sOut
  /* Log the text data diced into n-byte chunks */
  nOut = length(sOut)
  nChunk = 70 /* Maximum width of a text chunk */
  do i = 1 by nChunk while i+nChunk < nOut
    sChunk = substr(sOut,i,nChunk)    /* Get a full chunk */
    call LogTextChunk sChunk          /* Log it           */
  end
  sChunk = substr(sOut,i)         /* ...either null, or a short chunk */
  if length(sChunk) > 0           /* if not null... */
  then call LogTextChunk sChunk /* then log the short chunk */
return

LogTextChunk: procedure expose g.
  parse arg sOut
  i = verify(g.0sDelimiters,sOut,'NOMATCH') /* Use one not in text*/
  if i = 0 then i = 1 /* else use the first one and hope for the best*/
  cDelimiter = substr(g.0sDelimiters,i,1)
  select
    when g.0OPTION.ASM
    then do
      if length(sOut) > 8
      then call Log '*' sOut
      call LogASM e2a(sOut),sOut
    end
    otherwise call Log cDelimiter || sOut || cDelimiter
  end
return

LogASM: procedure expose g.
  parse arg sOut,sTxt,sCom
/*
 Format into blocks of 8 bytes...

 DC X'aabbccddeeffgghh' abcdefgh comment up to column 71...............
 DC X'aabbccddee'       abcde    comment continued.....................
*                                comment continued.....................
*/
  nOut = length(sOut)
  nCom = length(sCom)
  nChunk = 8 /* Maximum width of a text chunk */
  nComment = 38 /* Maximum width of a comment chunk */
  j = 1
  do i = 1 by nChunk while i+nChunk <= nOut
    sChunk = substr(sOut,i,nChunk)    /* Get a full chunk */
    sText  = substr(sTxt,i,nChunk)
    sComm  = substr(sCom,j,nComment)
    j = j + nComment
    call LogASMChunk sChunk,sText,sComm
  end
  sChunk = substr(sOut,i)         /* ...either null, or a short chunk */
  sText  = substr(sTxt,i)
  sComm  = substr(sCom,j,nComment)
  if length(sChunk) > 0           /* if not null... */
  then call LogASMChunk sChunk,sText,sComm /* log the short chunk */
  j = j + nComment
  do while j <= nCom
    sComm  = substr(sCom,j,nComment)
    call LogASMChunk ,,sComm
    j = j + nComment
  end
  if nOut > nChunk /* Insert blank line after multiline data */
  then call Log
return

LogASMChunk: procedure expose g.
  parse arg sOut,sTxt,sCom
  if length(sOut) = 0
  then call Log left('*'                 ,23) left(sTxt,8) strip(sCom)
  else call Log left(" DC X'"c2x(sOut)"'",23) left(sTxt,8) strip(sCom)
return

Log: procedure expose g.
  parse arg sOut
  if sOut = '' & g.0bLastWasBlank then return
  g.0bLastWasBlank = sOut = ''
  if g.0OPTION.TRACE then say '<'translate(sOut,'?',xrange('00'x,'3f'x))'>'
  if g.0OPTION.ASM
  then queue left(sOut,71) /* Do not invade column 72 onwards */
  else queue sOut
  rc = putQueued(g.0hFileOut)
  if rc <> 0
  then call Abort 'Aborted during write to file' g.0hFileOut 'rc='rc
return

Abort: procedure
  parse arg sMsg
  say sMsg
  call Epilog
exit

LogGL2: procedure expose g. s. u.
  parse arg cPrefix,sOut
  do while length(sOut) > 0
    if pos(left(sOut,1),g.0sGLTerminators) > 0
    then do
      j = verify(sOut, g.0sGLTerminators, 'NOMATCH')
      if j > 0
      then do
        j = j - 1
        parse var sOut sGLTerminators +(j) sOut
        call LogBinary sGLTerminators /* Dump excess terminators */
      end
    end

    parse var sOut sCmd +2 sOut
    sCmd = a2e(sCmd)

    select
      when sCmd = 'CO' then do /* Lexmark GL/2 comment */
        cDelimiter = left(sOut,1)
        parse var sOut (cDelimiter) sComment (cDelimiter) sOut
        cDelimiter = a2e(cDelimiter)
        sComment   = a2e(sComment)
        call Log ' CO'cDelimiter
        call Log cDelimiter || sComment || cDelimiter
        call Log ' 'cDelimiter
      end
      when sCmd = 'PE' then do /*  Polyline Encoded command...*/
        parse var sOut sOperands '3B'x sOut
        call Log
        if g.0OPTION.ASM
        then call LogASM e2a(sCmd),sCmd,s.sCmd
        else call Log ' 'left('PE',g.0nMargin)s.sCmd
        call LogBinary sOperands || '3B'x
        if sOperands <> '' & g.0OPTION.COM /* If we want GL2 decoded... */
        then call DoPE sOperands /* ...decode GL2 as comment lines */
        call Log
      end
      when pos(left(sOut,1),g.0sGLOperands) > 0 then do
        /* If cmd has operands...*/
        j = verify(sOut, g.0sGLOperands, 'NOMATCH')
        if j = 0
        then j = length(sOut)
        else j = j - 1
        parse var sOut sOperands +(j) sOut
        sComment  = s.sCmd
        if sCmd = 'RF' & g.0OPTION.NOASM /* Decode the fill pattern neatly */
        then do /* RF command with operands... */
          sOperandsRF = translate(a2e(sOperands),' ',',')
          parse var sOperandsRF nIndexRF nWidthRF nHeightRF sPatternRF';'
          sCmdAll = sCmd || nIndexRF','nWidthRF','nHeightRF','
          call Log left(cPrefix || sCmdAll,g.0nMargin) sComment
          nOperandsRF = nWidthRF * nHeightRF
          do nWord = 1 to nOperandsRF by nWidthRF
            call Log cPrefix ||,
                     space(subword(sPatternRF,nWord,nWidthRF),1,',')','
          end
          call Log cPrefix';'
        end
        else do /* other commands with operands... */
          sOperands = a2e(sOperands)
          sCmdAll   = sCmd || sOperands
          if cPrefix = '*' | g.0OPTION.NOASM
          then do
            if length(sCmdAll) < g.0nMargin
            then call Log left(cPrefix || sCmdAll,g.0nMargin) sComment
            else do /* else log the operands in chunks */
              call Log left(cPrefix || sCmd,g.0nMargin) sComment
              call LogTextChunks sOperands
            end
          end
          else call LogASM e2a(sCmdAll),sCmdAll,s.sCmd
        end
      end
      otherwise do /* command with no operands... */
        if cPrefix = '*' | g.0OPTION.NOASM
        then call Log,
            left(cPrefix||sCmd,max(length(sCmd)+1,g.0nMargin)) s.sCmd
        else call LogASM e2a(sCmd),sCmd,s.sCmd
      end
    end
  end
return

/*--------------------------------------------------------------------*
 * Decode the HP/GL2 Polyline Encoded (PE) command...                 *
 *-------------------------------------------------------------------*/

DoPE: procedure expose g. s. u.
  parse arg sOperands

  parse value '1 2 3' with SP FRAC COORD
  bBase32 = 0
  bBase64 = 1
  nFracBits = 0
  nDecimals = 0
  nFracDiv = 1
  bPU = 0; bLastPU = '';
  bPA = 0; bLastPA = '';
  nValue = 0
  nValueType = 0
  nMult = 1

  do i = 1 to length(sOperands)
    c = substr(sOperands,i,1)
    c7bit = bitand(c,'01111111'b)
    e7bit = a2e(c7bit)
    select
      when e7bit = ':' then do
        nValueType = SP
      end
      when e7bit = '<' then do
        bPU = 1
      end
      when e7bit = '>' then do
        nValueType = FRAC
      end
      when e7bit = '=' then do
        bPA = 1
      end
      when e7bit = '7' then do
        bBase64 = 0
        bBase32 = 1
      end

      when bBase64 then do
        n = c2d(c)
        select
          when n >= 63 & n <= 126 then do
            nValue = nValue + nMult * (n - 63)
            nMult = nMult * 64
          end
          when n >= 191 & n <= 254 & bBase64 then do
            nValue = nValue + nMult * (n - 191)
            call LogValue nValue
            nMult = 1
            nValue = 0
          end
          otherwise nop
        end
      end

      when bBase32 then do
        n = c2d(c7bit)
        select
          when n >= 63 & n <= 94 then do
            nValue = nValue + nMult * (n - 63)
            nMult = nMult * 32
          end
          when n >= 95 & n <= 126 then do
            nValue = nValue + nMult * (n - 95)
            call LogValue nValue
            nMult = 1
            nValue = 0
          end
          otherwise nop
        end
      end

      otherwise nop /* ignore c */
    end

  end /* next c */
return

LogValue:
  if nValue // 2
  then nValue = -(nValue % 2)
  else nValue = +(nValue % 2)
  if nFracBits <> 0
  then nValue = format(nValue / nFracDiv,,nDecimals)
  select
    when nValueType = SP then do
      call LogGL2 '*',e2a('SP'nValue)
      nValueType = 0
    end
    when nValueType = COORD then do
      nValueY = nValue
      sPlotCmd = ''
      if bPU <> bLastPU
      then do
        if bPU
        then sPlotCmd = 'PU'
        else sPlotCmd = 'PD'
      end
      if bPA <> bLastPA
      then do
        if bPA
        then sPlotCmd = sPlotCmd || 'PA'
        else sPlotCmd = sPlotCmd || 'PR'
      end
      if sPlotCmd <> ''
      then do
        sPlotCmd = sPlotCmd || nValueX','nValueY
        call LogGL2 '*',e2a(sPlotCmd)
      end
      else call Log '*'nValueX','nValueY
      bLastPU = bPU
      bLastPA = bPA
      bPU = 0
      bPA = 0
      nValueType = 0
    end
    when nValueType = FRAC then do
      nFracBits = nValue
      nDecimals = trunc((nValue * 3) / 10)
      nFracDiv = 2 ** nValue
      nValueType = 0
    end
    otherwise do
      nValueX = nValue
      nValueType  = COORD
    end
  end
return


LogBinary: procedure expose g.
  parse arg sOut
  call Log
  nOut = length(sOut)

  /* First...log the binary data diced into n-byte chunks */
  if g.0OPTION.NOASM  /* ...if not ASM output */
  then do
    nChunk = 128
    do i = 1 by nChunk while i+nChunk < nOut
      sChunk = substr(sOut,i,nChunk)    /* Get a full chunk */
      call LogBinaryChunk sChunk        /* Log it           */
    end
    sChunk = substr(sOut,i)         /* ...either null, or a short chunk */
    if length(sChunk) > 0           /* if not null... */
    then call LogBinaryChunk sChunk /* then log the short chunk */
  end

  if g.0OPTION.HEX | g.0OPTION.ASM
  then do /* ...log the hex translation as comments */
    do i = 1 by 32 while i+32 < nOut
      sChunk = substr(sOut,i,32)
      xChunk = c2x(sChunk)
      nOffset = right(i-1,5,'0')
      if g.0OPTION.ASM
      then call LogASM sChunk
      else call Log '*+'nOffset c2x(sChunk)
    end
    sChunk = substr(sOut,i)
    if length(sChunk) > 0
    then do
      if g.0OPTION.ASM
      then call LogASM sChunk
      else call Log '*+'right(i-1,5,'0') c2x(sChunk)
    end
  end
  call Log
return

LogBinaryChunk: procedure expose g.
  parse arg sChunk
  if IsPrintable(sChunk)
  then call LogTextChunk a2e(sChunk)
  else do
    if g.0OPTION.X
    then do
      call Log 'X'c2x(sChunk)      /* Log binary as printable hex */
    end
    else do
      if right(sChunk,1) == ' '    /* If last byte is an EBCDIC blank */
      then call Log 'C'sChunk'ff'x /* append x'ff' */
      else call Log 'B'sChunk      /* log as-is    */
    end
  end
return



Prolog:
  g.0nMargin = 16
  say 'Building PCL command table...'
  do i = 1 by 1 while left(sourceline(i),3) <> 'PCL'
  end

  nFirstLine = i
  nVar = 0

  do i = nFirstLine while sourceline(i) <> '//'
    sLine = strip(sourceline(i))
    sRecordType = left(sLine,3)
    select
      when sRecordType = 'PCL' then do
        sEntry = sLine
        do j = i+1 until sourceline(j) = ''
          sEntry = sEntry || strip(sourceline(j))';'
        end
        i = j
        call AddEntry strip(sEntry,'TRAILING',';')
      end
      when sRecordType = 'GL2' then do
        call AddEntry sLine
      end
      when sRecordType = 'VAR' then do
        parse var sLine . sVarName sVarDesc
        nVar = nVar + 1 /* Number of variables */
        v.nVar = substr(sLine,5) /* &varname   description... */
        sVarDesc = strip(sVarDesc)
        sValid.nVar = '*'substr(sVarName,2,8) ||,
                      '        Variable    'sVarDesc
        upper sVarName
        v.sVarName = sVarDesc
      end
      otherwise nop
    end
  end

  g.0sTerminators = xrange('40'x,'5a'x) || '1b'x /* '@' and 'A'...'Z' */
  g.0sAlphas   = xrange('a','z') || xrange('A','Z') || '@'
  g.0sNumerics = '0123456789.-+'
  if g.0OPTION.ASM
  then g.0sDelimiters = "'"
  else g.0sDelimiters = " '" || '"/|!\$#@-.+=:'
  g.0sGLOperands = '303132333435363738392E2C2D2B3B'x
                 /*  0 1 2 3 4 5 6 7 8 9 . , - + ; */
  g.0sGLTerminators = '00090A0D203B'x

  g.0sEBCDIC = xrange('81'x,'89'x) ||,
               xrange('91'x,'99'x) ||,
               xrange('A2'x,'A9'x) ||,
               xrange('C1'x,'C9'x) ||,
               xrange('D1'x,'D9'x) ||,
               xrange('E2'x,'E9'x) ||,
               xrange('F0'x,'F9'x) ||,
               ' !"#$%&''()*+,-./' ||,
               ':;<=>?@'           ||,
               '(\)^_`'            ||, /* LSB, BACKSLASH, RSB, HAT */
               '{|}~'              ||,
               xrange('00'x,'FF'x)     /* all others as is */

  g.0sASCII  = xrange('61'x,'69'x) ||,
               xrange('6A'x,'72'x) ||,
               xrange('73'x,'7A'x) ||,
               xrange('41'x,'49'x) ||,
               xrange('4A'x,'52'x) ||,
               xrange('53'x,'5A'x) ||,
               xrange('30'x,'39'x) ||,
               xrange('20'x,'2F'x) ||,
               xrange('3A'x,'40'x) ||,
               xrange('5B'x,'60'x) ||,
               xrange('7B'x,'7E'x) ||,
               xrange('00'x,'FF'x)     /* all others as is */

  /* The following is a list of all characters which are present in
     both the EBCDIC and ASCII character set and which print the
     same symbol in both character sets.  That is, you can translate
     in both directions and not bugger anything up visually...
  */
  g.0sPrintable = xrange('20'x,'5a'x) || '5c'x || xrange('5f'x,'7e'x)

  g.0FONTFORMAT.0  = 'PCL Bitmapped'
  g.0FONTFORMAT.10 = 'Intellifont Bound Scalable'
  g.0FONTFORMAT.11 = 'Intellifont Unbound Scalable'
  g.0FONTFORMAT.15 = 'TrueType Scalable'
  g.0FONTFORMAT.20 = 'Resolution-Specified Bitmapped'
return

AddEntry: procedure expose s. u.
  parse arg 1 sRecordType +3,
            5 sPrefix     +2,
           12 sSuffix     +1,
           22 sMeaning','sUnit','sValues
  sMeaning = strip(sMeaning)
  if sRecordType = 'GL2'
  then do /* HP-GL/2 data */
    s.sPrefix = sMeaning
  end
  else do /* PCL command */
    if sPrefix <> ''
    then sID = strip(sPrefix) || sSuffix
    else sID = strip(sSuffix)
    s.sID = sMeaning
    u.sID = sUnit
    do while sValues <> '' /* 1=meaning;2=meaning;...;n=meaning; */
      parse var sValues sValue'='sMeaning';'sValues
      sIDValue = sID || sValue
      s.sIDValue = sMeaning
    end
  end
return


a2e: PROCEDURE EXPOSE g.
  parse arg sData
  if g.0SYSTEM = 'TSO'
  then sData = translate(sData,g.0sEBCDIC,g.0sASCII,'.')
return sData

e2a: PROCEDURE EXPOSE g.
  parse arg sData
  if g.0SYSTEM = 'TSO'
  then sData = translate(sData,g.0sASCII,g.0sEBCDIC,'.')
return sData

IsPrintable: procedure expose g.
  parse arg sTextData
return verify(sTextData,g.0sPrintable) = 0

/*BOX
***********************************************************************
**                                                                   **
&name
**                                                                   **
&title
**                                                                   **
** FUNCTION - This member is read by the VPS separator page exit in  **
**            order to print a separator page.  As the exit scans the**
**            member it will substitute any variables with their     **
**            current values before sending the resulting text to    **
**            the printer.                                           **
**                                                                   **
** NOTES    - 1.  See the comments at the start of the VPSSEP Rexx   **
**                procedure for instructions on how to create this   **
**                member.                                            **
**                                                                   **
**            2.  Summary of column 1 record codes:                  **
**                 *  =  Comment                                     **
**                 E  =  Escape, PCL command, then comment           **
**                 &  =  Variable name, then comment                 **
**                 B  =  Binary data only (no comment allowed)       **
**                 C  =  Binary data with X'FF' appended             **
**                 X  =  Binary data in printable hex format         **
**             other  =  Delimiter delimiting text (eg 'text')       **
**                                                                   **
**                                                                   **
** HISTORY  - Date     By       Reason (most recent at the top please**
**            -------- -------- -------------------------------------**
&date
**                                                                   **
**                                                                   **
***********************************************************************
//
***********************************************************************
**                                                                   **
** TITLE    - PCL AND HP-GL/2 COMMAND DESCRIPTION FILE               **
**                                                                   **
** FUNCTION - This describes the PCL5 and HP-GL/2 command set.       **
**                                                                   **
** NOTES    - PCL6 commands (XLO and XLC entries) are for doco only  **
**            and are not actually processed.                        **
**                                                                   **
** SYNTAX   - Each record has the following format:                  **
**                                                                   **
**            Columns Meaning                                        **
**            ------- ---------------------------------------------- **
**            1 to 2  PCL command prefix, or HP-GL/2 command, or a   **
**                    comment record if '**' is present.             **
**                                                                   **
**            5       PCL command value (either a particular number, **
**                    or any number if '#' is present).              **
**                                                                   **
**            8       PCL command suffix (a single uppercase letter),**
**                    or indicates this is an HP-GL/2 command if '.' **
**                    is present.                                    **
**                                                                   **
**            18...   A description of the command, its unit if any, **
**                    and the meanings of any or all of its valid    **
**                    command values.  The following syntax applies: **
**                                                                   **
**                    description,unit,value=meaning;value=meaning...**
**                                                                   **
**                    description: Brief meaning of the command      **
**                                                                   **
**                    unit: The unit applying to the PCL command     **
**                          value (for example 'rows').  May be      **
**                          omitted if the value has no unit.        **
**                                                                   **
**                    value=meaning: A list of value/meaning pairs.  **
**                          Each pair must be terminated by a semi-  **
**                          colon.  This is used to list the meanings**
**                          of each value which may appear in this   **
**                          PCL command (for example, for the style  **
**                          0=Upright;1=Italic...).                  **
**                                                                   **
**                                                                   **
** HISTORY  - Date    By  Reason (most recent at the top please)     **
**            ------- --- ------------------------------------------ **
**           19980130 AJA Added *c # W.                              **
**           19970303 AJA Initial version.                           **
**                                                                   **
***********************************************************************

*---------------------------------------------------------------------*
*  PCL5 COMMAND CODES, CATEGORIES, MEANINGS AND TYPICAL VALUES        *
*---------------------------------------------------------------------*

*...+...10....+...20....+...30....+...40....+...50....+...60....+...70..
PCL &b  #  M         Color       Monochrome print mode,,
        0=Print in mixed render algorithm mode
        1=Print everything in gray equivalent

PCL &b  #  F         Color       Finish mode,,              
        0=Matte finish (default)               
        1=Glossy finish

PCL &p  #  C         Color       Palette control,,
        0=Delete all palettes except those in the stack
        1=Delete all palettes in stack
        2=Delete palette
        6=Copy active palette

PCL &p  #  I         Color       Palette control ID

PCL &p  #  S         Color       Select pallette

PCL *i  #  W (data)  Color       Viewing illuminant,bytes

PCL *l  #  W (data)  Color       Color lookup tables,bytes

PCL *m  #  W (data)  Color       Download dither matrix,bytes

PCL *p  #  P         Color       Push/pop palette,,
        0=Push
        1=Pop

PCL *r  #  U         Color       Simple color,,
       -3=3 planes, device CMY palette
        1=Single plane, B/W palette
        3=3 planes, device RGB palette

PCL *t  #  I         Color       Gamma correction

PCL *t  #  J         Color       Render algorithm

PCL *v  #  A         Color       Color component one

PCL *v  #  B         Color       Color component two

PCL *v  #  C         Color       Color component three

PCL *v  #  I         Color       Assign color index

PCL *v  #  S         Color       Foreground color

PCL *v  #  W (data)  Color       Configure image data,bytes

PCL        =         Cursor      Vertical = 1 half line-feed

PCL &a  #  C         Cursor      Horizontal,columns

PCL &a  #  H         Cursor      Horizontal,decipoints

PCL &a  #  R         Cursor      Vertical,rows

PCL &a  #  V         Cursor      Vertical,decipoints

PCL &f  #  S         Cursor      Push/pop cursor position,,
        0=Push
        1=Pop

PCL &k  #  G         Cursor      Line Termination,,
        0=CR=CR,LF=LF,FF=FF
        1=CR=CR+LF,LF=LF,FF=FF
        2=CR=CR,LF=CR+LF,FF=CR+LF
        3=CR=CR+LF,LF=CR+LF,FF=CR+LF

PCL *p  #  X         Cursor      Horizontal,PCL units

PCL *p  #  Y         Cursor      Vertical,PCL units

PCL        Y         Debug       Display functions (enable)

PCL        Z         Debug       Display functions (disable)

PCL &s  #  C         Debug       End-of-line wrap

PCL (s  #  W (data)  FontCreate  Character descriptor/data,bytes

PCL *c  #  E         FontCreate  Character code

PCL )s  #  W (data)  FontCreate  Font descriptor/data,bytes

PCL &n  #  W (data)  FontManage  Alphanumeric ID,bytes

PCL *c  #  D         FontManage  Font ID #

PCL *c  #  F         FontManage  Font control,,
        0=Delete all soft fonts
        1=Delete all temporary soft fonts
        2=Delete soft font
        3=Delete character code
        4=Make soft font temporary
        5=Make soft font permanent
        6=Copy/assign current invoked font as temporary

PCL (   #  X         FontSelect  Primary Soft font ID #

PCL (s  #  B         FontSelect  6/10 Primary Stroke weight,,
       -7=Ultra thin
       -6=Extra thin
       -5=Thin
       -4=Extra light
       -3=Light
       -2=Demi light
       -1=Semi light
        0=Medium
        1=Semi bold
        2=Demi bold
        3=Bold
        4=Extra bold
        5=Black
        6=Extra black
        7=Ultra black

PCL (s  #  H         FontSelect  3/10 Primary Pitch,chars/inch

PCL (s  #  P         FontSelect  2/10 Primary Spacing,,
        0=Fixed
        1=Proportional

PCL (s  #  S         FontSelect  5/10 Primary Style,,
        0=Upright
        1=Italic
        4=Condensed
        5=Condensed italic
        8=Compressed extra condensed
       24=Expanded
       32=Outline
       64=Inline
      128=Shadowed
      160=Outline shadowed

PCL (s  #  T         FontSelect  7/10 Primary Typeface,,
        0=Line Printer
        3=Courier
        4=Helvetica
        6=Gothic
        7=Script
        8=Prestige
     4099=Courier
     4101=CG Times
     4102=Letter Gothic
     4113=CG Omega
     4116=Coronet
     4140=Clarendon
     4148=Univers
     4168=Antique Olive
     4197=Garamond
     4297=Marigold
     4362=Albertus
    16602=Arial
    16901=Times New
    24579=CourierPS
    24580=Helvetica
    24591=Palatino
    24607=ITC Avant Garde Gothic
    24623=ITC Bookman
    24703=New Century Schoolbook
    25093=Times Roman

PCL (s  #  V         FontSelect  4/10 Primary Height,points

PCL (ID              FontSelect  1/10 Primary Symbol set,,
       8M=HP Math-8
       8U=HP Roman-8
      10U=PC-8
       0N=ISO 8859-1 Latin 1
       0O=OCR A
       0U=ASCII
      19U=Windows 3.1 Latin 1
       9U=Windows 3.0 Latin 1
       6J=Microsoft Publishing

PCL (3     @         FontSelect  Primary Select default font

PCL &d     @         FontSelect  Underline,,
        0=Off

PCL &d  #  D         FontSelect  Underline,,
        0=On
        3=Floating

PCL &p  #  X (data)  FontSelect  Transparent print data,bytes

PCL )   #  X         FontSelect  Secondary Soft font ID #

PCL )s  #  B         FontSelect  6/10 Secondary Stroke weight,,
       -7=Ultra thin
       -6=Extra thin
       -5=Thin
       -4=Extra light
       -3=Light
       -2=Demi light
       -1=Semi light
        0=Medium
        1=Semi bold
        2=Demi bold
        3=Bold
        4=Extra bold
        5=Black
        6=Extra black
        7=Ultra black

PCL )s  #  H         FontSelect  3/10 Secondary Pitch,chars/inch

PCL )s  #  P         FontSelect  2/10 Secondary Spacing,,
        0=Fixed
        1=Proportional

PCL )s  #  S         FontSelect  5/10 Secondary Style,,
        0=Upright
        1=Italic
        4=Condensed
        5=Condensed italic
        8=Compressed extra condensed
       24=Expanded
       32=Outline
       64=Inline
      128=Shadowed
      160=Outline shadowed

PCL )s  #  T         FontSelect  7/10 Secondary Typeface,,
        0=Line Printer
        3=Courier
        4=Helvetica
        6=Gothic
        7=Script
        8=Prestige
     4099=Courier
     4101=CG Times
     4102=Letter Gothic
     4148=Univers
     4197=Garamond Antiqua
    16602=Arial
    16901=Times New

PCL )s  #  V         FontSelect  4/10 Secondary Height,points

PCL )ID              FontSelect  1/10 Secondary Symbol set,,
      8M=HP Math-8
      8U=HP Roman-8
     10U=PC-8 0N=ISO 8859-1 Latin 1
      0O=OCR A
      0U=ASCII
     19U=Windows 3.1 Latin 1
      9U=Windows 3.0 Latin 1
      6J=Microsoft Publishing

PCL )3     @         FontSelect  Secondary Select default font

PCL        E         JobCntl     Printer reset

PCL &a  #  G         JobCntl     Duplex page side selection,,
        0=Next side
        1=Front side
        2=Back side

PCL &b  #  W (data)  JobCntl     Configuration (I/O),bytes

PCL &l  #  G         JobCntl     Output bin,,
        0=Auto
        1=Upper
        2=Rear
        3=High Capacity
        4=High Capacity 1
        5=High Capacity 2
        6=High Capacity 3
        7=High Capacity 4
        8=High Capacity 5
        9=High Capacity 6
        10=High Capacity 7
        11=High Capacity 8

PCL &l  #  S         JobCntl     Printer mode,,
        0=Simplex
        1=Duplex long-edge
        2=Duplex short-edge

PCL &l  #  U         JobCntl     Long-edge offset registration,decipoints

PCL &l  #  X         JobCntl     Number of copies

PCL &l  #  Z         JobCntl     Short-edge offset registration,decipoints

PCL &l  1  T         JobCntl     Toggle job separation mechanism

PCL &u  #  D         JobCntl     Unit-of-measure,units/inch

PCL %-12345X         JobCntl     Universal exit language,,
      12345=Reset printer

PCL &f  #  X         Macros      Macro control,,
        0=Start macro definition
        1=Stop macro definition
        2=Execute macro
        3=Call macro
        4=Enable macro for automatic overlay
        5=Disable automatic overlay
        6=Delete all macros
        7=Delete all temporary macros
        8=Delete macro
        9=Make macro temporary
       10=Make macro permanent

PCL &f  #  Y         Macros      Set macro ID #

PCL        9         PageCntl    Clear horizontal margins

PCL &a  #  L         PageCntl    Left margin column

PCL &a  #  M         PageCntl    Right margin column

PCL &a  #  P         PageCntl    Print direction,degrees

PCL &c  #  T         PageCntl    Character text path direction,,
        0=Horizontal
       -1=Vertical rotated

PCL &k  #  H         PageCntl    Horizontal motion index,x 1/120 inch

PCL &l  #  A         PageCntl    Page size,,
        1=Executive
        2=Letter
        3=Legal
        6=Ledger
       25=A5
       26=A4
       27=A3
       45=JIS B5
       46=JIS B4
       71=Hagaki postcard
       72=Oufuku-Hagaki postcard
       80=Monarch envelope
       81=Commercial envelope
       90=DL envelope
       91=C5 envelope
      100=B5 envelope

PCL &l  #  C         PageCntl    Vertical motion index,x 1/48 inch

PCL &l  #  D         PageCntl    Line spacing,lines/inch

PCL &l  #  E         PageCntl    Top margin,lines

PCL &l  #  F         PageCntl    Text length,lines

PCL &l  #  H         PageCntl    Paper source,,
        0=Print current page
        1=Main
        2=Manual
        3=Manual envelope
        4=Alternate
        5=Optional large
        6=Envelope feeder
        7=Autoselect
        8=Tray 1
        20=High Capacity 1
        21=High Capacity 2
        22=High Capacity 3
        23=High Capacity 4
        24=High Capacity 5
        25=High Capacity 6
        26=High Capacity 7
        27=High Capacity 8

PCL &l  #  L         PageCntl    Perforation skip,,
        0=Disabled
        1=Enabled

PCL &l  #  O         PageCntl    10/10 Orientation,,
        0=Portrait
        1=Landscape
        2=Reverse portrait
        3=Reverse landscape

PCL &l  #  P         PageCntl    Page length,lines (obsolete)

PCL &t  #  P         PageCntl    Text parsing method

PCL %   #  A         PictFrame   Enter PCL mode,,
        0=Restore old PCL cursor position
        1=Set PCL cursor to GL2 pen position

PCL %   #  B         PictFrame   Enter HP-GL/2 mode,,
        0=Use old GL2 pen position
        1=Use PCL cursor position
        2=Use PCL dot coord and old GL2 pen position
        3=Use PCL dot coord and cursor position

PCL *c  #  K         PictFrame   HP-GL/2 plot horz size,inches

PCL *c  #  L         PictFrame   HP-GL/2 plot vert size,inches

PCL *c  #  X         PictFrame   Picture frame horz size,decipoints

PCL *c  #  Y         PictFrame   Picture frame vert size,decipoints

PCL *c  0  T         PictFrame   Set picture frame anchor point

PCL *c  #  G         PrintModel  Pattern (area fill) ID

PCL *c  #  Q         PrintModel  Pattern control,,
        0=Delete all patterns
        1=Delete all temporary patterns
        2=Delete pattern
        4=Make pattern temporary
        5=Make pattern permanent

PCL *c  #  W (data)  PrintModel  User-defined pattern,bytes

PCL *l  #  O         PrintModel  Logical (ROP3) operation

PCL *l  #  R         PrintModel  Pixel placement,,
        0=Grid intersection
        1=Grid centered

PCL *o  #  W (data)  PrintModel  Driver configuration,bytes

PCL *p  #  R         PrintModel  Set pattern reference point

PCL *v  #  N         PrintModel  Source transparency mode,,
        0=Transparent
        1=Opaque

PCL *v  #  O         PrintModel  Pattern transparency mode,,
        0=Transparent
        1=Opaque

PCL *v  #  T         PrintModel  Select current pattern,,
        0=Solid black
        1=Solid white
        2=Shading pattern
        3=Cross-hatch pattern
        4=User-defined pattern

PCL *v  #  W (data)  PrintModel  User-defined pattern,bytes

PCL *b  #  M         Raster      Set compression method,,
        0=Unencoded
        1=Run-length
        2=TIFF
        3=Delta row
        5=Adaptive

PCL *b  #  V (data)  Raster      Transfer raster data by plane,bytes

PCL *b  #  W (data)  Raster      Transfer raster data by row/block,bytes

PCL *b  #  Y         Raster      Y offset,raster lines

PCL *r     B         Raster      End raster graphics

PCL *r     C         Raster      End raster graphics

PCL *r  #  A         Raster      Start raster graphics,,
        0=Set left graphics margin at X-position 0
        1=Set left graphics margin to current X-position
        2=Turn on scale mode/logical left
        3=Turn on scale mode/cursor position

PCL *r  #  F         Raster      Presentation,,
        0=Current print direction
        3=Along width of physical page

PCL *r  #  S         Raster      Source raster width,pixels

PCL *r  #  T         Raster      Source raster height,rows

PCL *t  #  H         Raster      Destination raster width,decipoints

PCL *t  #  K         Raster      Scale algorithm,,
        0=Light background
        1=Dark background

PCL *t  #  R         Raster      8/10 Raster resolution,dots/inch

PCL *t  #  V         Raster      Destination raster height,decipoints

PCL *c  #  A         RectArea    Horz rectangle size,dots

PCL *c  #  B         RectArea    Vert rectangle size,dots

PCL *c  #  H         RectArea    Horz rectangle size,decipoints

PCL *c  #  P         RectArea    Fill rectangular area,,
        0=Solid area fill
        1=Solid white area fill
        2=Shading fill
        3=Cross-hatch pattern fill
        4=User-defined pattern
        5=Current pattern

PCL *c  #  V         RectArea    Vert rectangle size,decipoints

PCL &r  #  F         Status      Flush all pages,,
        0=Flush all complete pages
        1=Flush all pages

PCL *s  #  I         Status      Inquire entity,,
        0=Font
        1=Macro
        2=User-defined pattern
        3=Symbol set
        4=Font extended

PCL *s  #  T         Status      9/10 Set location type,,
        0=Invalid
        1=Currently selected
        2=All locations
        3=Internal
        4=Download entity
        5=Cartridge
        7=SIMMs

PCL *s  #  U         Status      Set location unit within location type

PCL *s  #  X         Status      Echo

PCL *s  1  M         Status      Free space

PCL (f  #  W (data)  SymbolSet   Define symbol set,bytes

PCL *c  #  R         SymbolSet   Symbol set ID code

PCL *c  #  S         SymbolSet   Symbol set control,,
        0=Delete all user-defined symbol sets
        1=Delete all temporary symbol sets
        2=Delete symbol set
        4=Make symbol set temporary
        5=Make symbol set permanent

*---------------------------------------------------------------------*
*  HP-GL/2 COMMAND CODES                                              *
*---------------------------------------------------------------------*

GL2 DF               Config      Default values
GL2 IN               Config      Initialize
GL2 IP               Config      Input P1 and P2
GL2 IR               Config      Input relative P1 and P2
GL2 IW               Config      Input window
GL2 RO               Config      Rotate coordinate system
GL2 SC               Config      Scale
GL2 AA               Vector      Arc absolute
GL2 AR               Vector      Arc relative
GL2 AT               Vector      Absolute arc three point
GL2 BZ               Vector      Bezier absolute
GL2 BR               Vector      Bezier relative
GL2 CI               Vector      Circle
GL2 PA               Vector      Plot absolute
GL2 PD               Vector      Pen down
GL2 PE               Vector      Polyline Encoded...
GL2 PR               Vector      Plot relative
GL2 PU               Vector      Pen up
GL2 RT               Vector      Relative arc three point
GL2 EA               Polygon     Edge rectangle absolute
GL2 ER               Polygon     Edge rectangle relative
GL2 EW               Polygon     Edge wedge
GL2 EP               Polygon     Edge polygon
GL2 FP               Polygon     Fill polygon
GL2 PM               Polygon     Polygon mode
GL2 RA               Polygon     Fill rectangle absolute
GL2 RR               Polygon     Fill rectangle relative
GL2 WG               Polygon     Fill wedge
GL2 AC               Attrib      Anchor corner
GL2 FT               Attrib      Fill type
GL2 LA               Attrib      Line attributes
GL2 LT               Attrib      Line type
GL2 PW               Attrib      Pen width
GL2 RF               Attrib      Raster fill definition
GL2 SM               Attrib      Symbol mode
GL2 SP               Attrib      Select pen
GL2 SV               Attrib      Screened vectors
GL2 TR               Attrib      Transparency mode
GL2 UL               Attrib      User defined line type
GL2 WU               Attrib      Pen width unit selection
GL2 AD               Char        Alternate font definition
GL2 CF               Char        Character fill mode
GL2 CP               Char        Character plot
GL2 DI               Char        Absolute label direction
GL2 DR               Char        Relative label direction
GL2 DT               Char        Define label terminator
GL2 DV               Char        Define variable text path
GL2 ES               Char        Extra space
GL2 FI               Char        Select primary font ID
GL2 FN               Char        Select secondary font ID
GL2 LB               Char        Label text
GL2 LO               Char        Label origin
GL2 LM               Char        Label mode
GL2 SA               Char        Select alternate font
GL2 SB               Char        Scalable or bitmap fonts
GL2 SD               Char        Standard font definition
GL2 SI               Char        Absolute character size
GL2 SL               Char        Character slant
GL2 SR               Char        Relative character size
GL2 SS               Char        Select standard font
GL2 TD               Char        Transparent data
GL2 MC               TechDraw    Merge control
GL2 PP               TechDraw    Pixel placement
GL2 PC               TechDraw    Pen color
GL2 NP               TechDraw    Number of pens
GL2 CR               TechDraw    Color range

*---------------------------------------------------------------------*
*  PCL/XL OPERANDS (zero or more precede each 'F8'x command indicator)*
*---------------------------------------------------------------------*

XLO 29                           comment terminated by LF
XLO C0 xx                        1-byte value
XLO C1 xxxx                      2-byte value
XLO C2 xxxxxxxx                  4-byte value
XLO C5 xxyyxxyy                  1-byte coord pair(x1,y1,x2,y2)
XLO C8                           1-byte data units follow
XLO CB                           2-byte data units follow
XLO D0 wwhh                      1-byte dimension (w x h)
XLO D1 wwwwhhhh                  2-byte dimension (w x h)
XLO D3 xxxxyyyy                  2-byte coordinate (x,y)
XLO D5 xxxxxxxxyyyyyyyy          2-byte coordinate
XLO E3 xxxxyyyyxxxxyyyy          2-byte coordinate pair
XLO EB xxyyzz                    3-byte triplet
XLO FA xxxxxxxx                  4-byte length followed by data
XLO FB xx                        1-byte length followed by data

*---------------------------------------------------------------------*
*  PCL/XL COMMANDS (following 'F8'x) ...and followed by modifier bytes*
*---------------------------------------------------------------------*

XLC 04                           SetFill (0=Off,1=On)
XLC 05                           SetOutline (0=Off,1=On)
XLC 06                           SetColorSpace
XLC 09                           SetColor
XLC 25                           SetPaperSize
XLC 26                           SetPaperSource
XLC 27                           SetPaperStock
XLC 28                           SetOrientation (1=Ls,0=Pt)
XLC 2A                           SetPageScale
XLC 2B                           SetPageDimension
XLC 31                           SetCopyCount
XLC 42                           DrawRectangle
XLC 45                           DrawLine
XLC 48                           SetEllipse (0=Off,1=On)
XLC 4B                           SetPenWidth
XLC 4C                           SetCursorXY
XLC 67                           SetImageSize
XLC 6D                           ImageData
XLC 89                           SetResolution
XLC A1                           ResetTextBuffer
XLC A8                           SetFont
XLC AB                           SetText
XLC AF                           SetTextWidths


*---------------------------------------------------------------------*
*  VARIABLES                                                          *
*---------------------------------------------------------------------*

* VPS fields...
VAR &Banner   Contains either START or END or CONT

* Job fields...
VAR &JobID    Job number (eg JOBnnnnn or STCnnnnn)
VAR &JobName  Job name

* Printer fields...
VAR &PrtMemb  Printer VPS definition member name
VAR &PrtName  Printer name (luname, IP addr or hostname)

* Report fields...
VAR &RepClass Report sysout class
VAR &RepCDate Report creation date (yyyy/mm/dd hh:mm:ss)
VAR &RepDest  Report destination name
VAR &RepPDate Report print date (yyyy/mm/dd hh:mm:ss)

* Userid fields...
VAR &Userid   User logon id
VAR &UserName User name

* OUTPUT statement fields...
VAR &OutAddr1 OUTPUT card Address line 1
VAR &OutAddr2 OUTPUT card Address line 2
VAR &OutAddr3 OUTPUT card Address line 3
VAR &OutAddr4 OUTPUT card Address line 4
VAR &OutBuild OUTPUT card Building
VAR &OutClass OUTPUT card Class
VAR &OutDept  OUTPUT card Department
VAR &OutDest  OUTPUT card Destination
VAR &OutJesDS OUTPUT card JES Dataset type
VAR &OutGroup OUTPUT card Output group
VAR &OutName  OUTPUT card Name
VAR &OutRoom  OUTPUT card Room
VAR &OutTitle OUTPUT card Title

*---------------------------------------------------------------------*
*  END OF FILE (MUST BE INDICATED BY '//')                            *
*---------------------------------------------------------------------*
//
*/