import os
import shutil
from lxml import etree

from utils import xml_to_csv


if __name__ == '__main__':

    # Where to look for saved IATI XML via registry-refresher and save output
    rootdir = "/home/alex/git/IATI-Registry-Refresher/data"
    outdir = "/home/alex/git/universal-iati-flattener/output/"

    # Clean-up of old data; Make sure nothing important is in whatever folder you put here because it will be irrevocably erased
    shutil.rmtree(outdir)
    os.mkdir(outdir)

    # Loop through all the folders downloaded via IATI registry refresh, and pass XML roots to our xml_to_csv function.
    for subdir, dirs, files in os.walk(rootdir):
        for filename in files:
            filepath = os.path.join(subdir, filename)
            publisher = os.path.basename(subdir)
            out_filepath = os.path.join(outdir, publisher, filename)
            try:
                xml_to_csv(filepath, out_filepath)
            except (etree.XMLSyntaxError, KeyError, TypeError) as _:
                pass
