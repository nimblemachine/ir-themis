# Themis - Information Retrieval framework #

Themis is an Information Retrieval (IR) framework for comparison of natural language documents. It includes implementation of theoretical retrieval models (as for now, Vector Space Model (VSM) and enhanced Topic-based Vector Space Model (eTVSM)).

Themis includes implementation of common algorithms used in the Information Retrieval domain (as for now, Porter Stemmer). These algorithms might then be reused while implementation/configuration of IR models.

Themis provides support for evaluation of IR models. It includes support for IR test collections management, conducting evaluations, collecting performance measurements, performing statistical tests (initial version in development).

Themis is implemented as PostgreSQL schemas together with PL/pgSQL procedures to expose Themis functionality. Themis API (as for now, Java) is designed to access Themis functionality.

## News ##

  * 19.11.2008 - [Themis4WS](http://wi-vm565.uni-muenster.de:8080/Themis/) implemented.
  * 09.09.2008 - New version of Java API uploaded - themis-0.1.1.jar.
  * 12.05.2008 - Added [VSM tutorial](http://code.google.com/p/ir-themis/wiki/VSMThemisJavaAPITutorial) and [eTVSM tutorial](http://code.google.com/p/ir-themis/wiki/eTVSMThemisJavaAPITutorial) wiki pages. Initial java API javadoc committed to svn.

## Looking for contributions ##

Upon interest contact repository owner. The topics of interest are:
  * Themis front-end (AJAX-based)
  * Web-crawler
  * IR models (currenly supported VSM and eTVSM)