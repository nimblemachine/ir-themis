# VSM Themis Java API tutorial #

This tutorial shows how to write a java program that uses Themis Java API to connect to Themis backend and perform VSM document similarity judgments:

```
import java.sql.SQLException;
import java.util.Iterator;
import java.util.List;

import org.themis.ir.Document;
import org.themis.ir.vsm.VSM;
import org.themis.util.LETTERCASE;
import org.themis.util.PREPROCESS;
import org.themis.util.STEMMER;


public class TestVSM
{
	public static void main(String[] args) throws SQLException, ClassNotFoundException
	{
		VSM vsm = new VSM("localhost","themis","postgres","postgres");
		
		vsm.clear();
                
		vsm.setParameter(PREPROCESS.LETTERCASE.toString(), LETTERCASE.UPPER.toString());
		vsm.setParameter(PREPROCESS.STEMMER.toString(), STEMMER.PORTER.toString());
                
		vsm.addStopword("a");
		vsm.addStopword("the");
                
		vsm.addDocument("URL1", "a red car", false);
		vsm.addDocument("URL2", "the red auto", false);
                
		List<Document> res = vsm.searchFull("red car", 0, 10);
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

  1. First we create a VSM object - _vsm_ that connects to the Themis backend (we connect to the database "themis" at "localhost"; username and password are both "postgres"):
```
VSM vsm = new VSM("localhost","themis","postgres","postgres");
```
  1. Then we clear the VSM IR model (remove all VSM document models). Note, VSM model configuration stays unchanged:
```
vsm.clear();
```
  1. Configure VSM model by setting: all the words in the documents to be treated as uppercase (letter casing does not influence similarity judgments) and usage of Porter stemmer when deriving VSM document similarity judgments:
```
vsm.setParameter(PREPROCESS.LETTERCASE.toString(), LETTERCASE.UPPER.toString());
vsm.setParameter(PREPROCESS.STEMMER.toString(), STEMMER.PORTER.toString());
```
  1. Add stopwords to use with VSM model:
```
vsm.addStopword("a");
vsm.addStopword("the");
```
  1. Build VSM document models for documents "a red car" and "the red auto". One should specify document URL to possess the original document reference. The _false_ flag symbols that document is not a query, and is intended for later retrieval:
```
vsm.addDocument("URL1", "a red car", false);
vsm.addDocument("URL2", "the red auto", false);
```
  1. Perform the VSM document search for the query "red car". Second and third arguments specify retrieved documents interval (start from 0 most relevant document and retrieve 10 documents):
```
List<Document> res = vsm.searchFull("red car", 0, 10);
```
  1. The last chunk of code outputs retrieved results to the console. If you did everything right you should see the output:
```
1	|	1.0	|	a red car
2	|	0.5	|	the red auto
```

The output means that the document "a red car" was retrieved as the most relevant document  to the search query with the VSM similarity level of 1.0. The document "the red auto" is the second most relevant document with the similarity level of 0.5.