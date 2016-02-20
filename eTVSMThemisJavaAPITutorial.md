# eTVSM Themis Java API tutorial #

This tutorial shows how to write a java program that uses Themis Java API to connect to Themis backend and perform eTVSM document similarity judgments:

```
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;

import org.themis.ir.Document;
import org.themis.ir.etvsm.eTVSM;
import org.themis.ir.etvsm.eTVSMOntology;
import org.themis.util.LETTERCASE;
import org.themis.util.PREPROCESS;
import org.themis.util.STEMMER;


public class TestETVSM
{
	public static void main(String[] args) throws SQLException, ClassNotFoundException
	{
		eTVSM etvsm = new eTVSM("localhost","themis","postgres","postgres");
		eTVSMOntology o = new eTVSMOntology("localhost","themis","postgres","postgres");
		
		etvsm.clear();
		o.clear();
		
		o.autoISims(true);
		
		o.dumpWNSynsetMF("fast red car");
		o.dumpWNSynsetMF("the ruby auto");
		o.dumpWNSynsetMF("fast motorcar");
        
		etvsm.setParameter(PREPROCESS.LETTERCASE.toString(), LETTERCASE.UPPER.toString());
		etvsm.setParameter(PREPROCESS.STEMMER.toString(), STEMMER.NONE.toString());
        
		etvsm.addStopword("a");
		etvsm.addStopword("the");
        
		etvsm.addDocument("URL1", "fast red car", false);
		etvsm.addDocument("URL2", "the ruby auto", false);
		etvsm.addDocument("URL3", "fast motorcar", false);
        
		List<Document> res = etvsm.searchFull("red car", 0, 10);
		Iterator<Document> i = res.iterator();
        
		while (i.hasNext())
		{
			Document doc = i.next();
			System.out.println(String.format("%1s \t | \t %1.4f \t | \t %3s", doc.getId(), doc.getSimilarity(), doc.getContent()));
		}
	}
}
```

Let us investigate proposed code extract line by line:

  1. First we create eTVSM and eTVSMOntology objects - _vsm_ and _o_ that connect to the Themis backend (we connect to the database "themis" at "localhost"; username and password are both "postgres"):
```
eTVSM etvsm = new eTVSM("localhost","themis","postgres","postgres");
eTVSMOntology o = new eTVSMOntology("localhost","themis","postgres","postgres");
```
  1. Then we clear the eTVSM IR model and the eTVSMOntology data structure(remove all eTVSM document models and eTVSMOntology concepts). Note, eTVSM model configuration stays unchanged:
```
etvsm.clear();
o.clear();
```
  1. Build eTVSM ontology (setting autoISims to _true_ signals that eTVSM should automatically maintain concept similarity values upon ontology change; dumpWNSynsetMF method loads WordNet synset for every recognized term from the proposed document into eTVSM ontology):
```
o.autoISims(true);
                
o.dumpWNSynsetMF("fast red car");
o.dumpWNSynsetMF("the ruby auto");
o.dumpWNSynsetMF("fast motorcar");
```
  1. Configure eTVSM model by setting: all the words in the documents to be treated as uppercase (letter casing does not influence similarity judgments) and usage of no stemmer when deriving eTVSM document similarity judgments:
```
etvsm.setParameter(PREPROCESS.LETTERCASE.toString(), LETTERCASE.UPPER.toString());
etvsm.setParameter(PREPROCESS.STEMMER.toString(), STEMMER.NONE.toString());
```
  1. Add stopwords to use with eTVSM model:
```
etvsm.addStopword("a");
etvsm.addStopword("the");
```
  1. Build eTVSM document models for documents "fast red car", "the ruby auto", and "fast motorcar". One should specify document URL to possess the original document reference. The _false_ flag symbols that document is not a query, and is intended for later retrieval:
```
etvsm.addDocument("URL1", "fast red car", false);
etvsm.addDocument("URL2", "the ruby auto", false);
etvsm.addDocument("URL3", "fast motorcar", false);
```
  1. Perform the eTVSM document search for the query "red car". Second and third arguments specify retrieved documents interval (start from 0 most relevant document and retrieve 10 documents):
```
List<Document> res = etvsm.searchFull("red car", 0, 10);
```
  1. The last chunk of code outputs retrieved results to the console. If you did everything right you should see the output:
```
2	|	1.0		|	the ruby auto
1	|	0.816497	|	fast red car
3	|	0.5		|	fast motorcar
```

The output means that the document "the ruby auto" was retrieved as the most relevant document to the search query with the eTVSM similarity level of 1.0. The document "fast red car" is the second most relevant document with the similarity level of 0.816497. The document "fast motorcar" was retrieved by eTVSM with the similarity level of 0.5