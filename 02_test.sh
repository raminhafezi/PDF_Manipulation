#!/usr/bin/env python
import sys
from PyPDF2 import PdfFileReader as reader
from PyPDF2 import PdfFileWriter as writer

pdfFile = fname = sys.argv[1]

fileObj = open(pdfFile, 'rd')

#Create PDF reader object
pdfReader = reader(fileObj)

#Create PDF writer obejct
pdfWriter = writer()

print(pdfReader.numPages)
for i in range(pdfReader.numPages):
	pdfWriter.addPage(pdfReader.getPage(i))

pdfWriter.removeLinks

output_file = open('new_M1-toc_With_.pdf','wb')
pdfWriter.write(output_file)
output_file.close()
