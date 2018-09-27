#!/usr/bin/env python

from PyPDF2 import PdfFileReader, PdfFileWriter

from pprint import pprint
import requests
import sys
import urllib

'''
	The check_ftp function checks a given url for a response. 
	If it fails, or if the response is empty, it returns False, along with the reason; 
	otherwise it returns True.
'''

def check_ftp(url):
    try:
        response = urllib.urlopen(url)
    except IOError as e:
        result, reason = False, e
    else:
        if response.read():
            result, reason = True, 'okay'
        else:
            result, reason = False, 'Empty Page'
    return result, reason
    
'''
	The check_url function is also simple: If the url starts with ftp, 
	it delegates to the check_ftp function. 
	Otherwise, it attempts to get the url with some timeout value using typical header values. 
	The the function returns the response along with the reason it succeeded or failed.
'''

def check_url(url, auth=None):
    headers = {'User-Agent': 'Mozilla/5.0', 'Accept': '*/*'}
    if url.startswith('ftp://'):
        result, reason = check_ftp(url)
    else:
        try:
            response = requests.get(url, timeout=6, auth=auth, headers=headers)
        except (requests.ConnectionError,
                requests.HTTPError,
                requests.Timeout) as e:
            result, reason = False, e
        else:
            if response.text:
                result, reason = response.status_code, response.reason
            else:
                result, reason = False, 'Empty Page'

    return result, reason


'''
	Now that we have this utility, we can check the PDF file. We will create four lists:
		1) 'links' The internal PDF links in the file; for example, a reference to a section or figure.
		2) 'badlinks' Of the internal links in the file, these are links that target a missing destination (broken link).
		3) 'urls' The links from the PDF to an external location; for example, a hyperlink to a web site.
		4) 'badurls' Of the external links in the file, these are the urls that target a missing destination (broken url)
	Now for the PyPDF2 goodies. The following check_pdf function loops over the pages in the PDF file object. For each page, 
	it walks through the Annots dictionary. If that dictionary has an action (\A) with a key of \D (destination?), 
	that is an internal link, so update the links list with the destination.
	If the dictionary has an action with a key of \URI, it is an external link. Check the external links with the check_url function 
	and update the urls and bad_urls lists.
	After checking each page, get a list of all the anchors in the PDF with the getNamedDestinations attribute; 
	compare that list of all known anchors to the list of internal links we just created. 
	If there is a link with no matching anchor, that link belongs in the badlinks list.
'''
def check_pdf(pdf):
    links = list()
    urls = list()
    badurls = list()

    for page in pdf.pages:
        obj = page.getObject()
        print "obj is:" , obj
        print "\n\n"
        print 'Object Type is ', type(obj)
        print "\n\n\n"
        for annot in [x.getObject() for x in obj.get('/Annots', [])]:
            dst = annot['/A'].get('/D')
            url = annot['/A'].get('/URI')
            if dst:
                links.append(dst)
            elif url:
                urls.append(url)
                result, reason = check_url(url)
                if not result:
                    badurls.append({'url':url, 'reason': '%r' % reason})

    anchors = pdf.namedDestinations.keys()
    badlinks = [x for x in links if x not in anchors]
    return links, badlinks, urls, badurls


'''
	Finally, make the code into a callable script that takes a single argument, 
	the path to the PDF file. Then print the results of the check_pdf function on stdout.
'''

if __name__ == '__main__':
    fname = sys.argv[1]
    print 'Checking %s' % fname
    pdf = PdfFileReader(fname)
    print "type of the pdf return object", type(pdf)
    links, badlinks, urls, badurls = check_pdf(pdf)
    #print 'urls: ', urls
    for item in urls:
		print item
    print
    print 'bad links: ', badlinks
    print
    print 'bad urls: ',badurls
