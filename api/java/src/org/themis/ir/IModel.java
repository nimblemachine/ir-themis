package org.themis.ir;

import java.sql.ResultSet;
import java.sql.SQLException;

public interface IModel
{
	/**
	 * Reset Information Model. Clear all data except configuration.
	 * 
	 * @throws SQLException
	 */
	public abstract void clear() throws SQLException;
	
	/**
	 * Crawl document into Information Retrieval model. Existing document with provided URI gets re-crawled.
	 *  
	 * @param uri Document Uniform Resource Identifier
	 * @param doc Document in plain text
	 * @param isQuery Query document flag
	 * @return Document unique ID
	 * @throws SQLException
	 */
	public abstract int addDocument(String uri, String doc, boolean isQuery) throws SQLException;
	
	/**
	 * Crawl query into Information Retrieval model. Existing query does not get re-crawled.
	 * 
	 * @param doc Query in plain text
	 * @return Query unique ID 
	 * @throws SQLException
	 */
	public abstract int addQuery(String doc) throws SQLException;
	
	/**
	 * Add stopword to consider in Information Retrieval model.
	 * 
	 * @param word Stopword to add
	 * @return Stopword Themis unique ID
	 * @throws SQLException
	 */
	public abstract int addStopword(String word) throws SQLException;
	
	/**
	 * Remove document from Information Retrieval model.
	 * 
	 * @param docID Document/query unique ID
	 * @return Removed document unique ID
	 * @throws SQLException
	 */
	public abstract int removeDocument(int docID) throws SQLException;
	
	/**
	 * Remove document from Information Retrieval model.
	 * 
	 * @param uri Document/query Uniform Resource Identifier
	 * @return Removed document unique ID
	 * @throws SQLException
	 */
	public abstract int removeDocument(String uri) throws SQLException;
	
	/**
	 * Obtain similarity of two documents.
	 * 
	 * @param doc1ID Document/query unique ID
	 * @param doc2ID Document/query unique ID
	 * @return Information Retrieval model documents similarity value in [0...1]
	 * @throws SQLException
	 */
	public abstract double similarity(int doc1ID, int doc2ID) throws SQLException;
	
	/**
	 * Search for similar documents.
	 * 
	 * @param query Query in plain text
	 * @param start Relative start position in an ordered (by similarity) list of documents  
	 * @param n Number of documents to return
	 * @return Search results (DocID, URI, similarity)
	 * @throws SQLException
	 */
	public abstract ResultSet search(String query, int start, int n) throws SQLException;
	
	/**
	 * Search for similar documents. Return documents intros.
	 * 
	 * @param query Query in plain text
	 * @param start Relative start position in an ordered (by similarity) list of documents  
	 * @param n Number of documents to return
	 * @return Search results (DocID, URI, similarity, First 256 characters of document text)
	 * @throws SQLException
	 */
	public abstract ResultSet searchIntro(String query, int start, int n) throws SQLException;
	
	/**
	 * Search for similar documents. Return complete documents.
	 * 
	 * @param query Query in plain text
	 * @param start Relative start position in an ordered (by similarity) list of documents  
	 * @param n Number of documents to return
	 * @return Search results (DocID, URI, similarity, Full document text)
	 * @throws SQLException
	 */
	public abstract ResultSet searchFull(String query, int start, int n) throws SQLException;
}
