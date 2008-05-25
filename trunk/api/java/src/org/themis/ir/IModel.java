/**
    Themis - Information Retrieval framework
    Copyright (C) 2007 Artem Polyvyanyy

    This file is part of Themis.
	
    Themis is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    Themis is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
 */
package org.themis.ir;

import java.sql.SQLException;
import java.util.List;


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
	 * Add a stopword to consider in Information Retrieval model.
	 * 
	 * @param word Stopword to add
	 * @return Stopword Themis unique ID
	 * @throws SQLException
	 */
	public abstract int addStopword(String word) throws SQLException;
	
	/**
	 * Remove a stopword
	 * 
	 * @param word Stopword to remove
	 * @return Stopword Themis unique ID
	 * @throws SQLException
	 */
	public abstract int removeStopword(String word) throws SQLException;
	
	/**
	 * Clear all stopwords
	 * 
	 * @throws SQLException
	 */
	public abstract void clearStopwords() throws SQLException;
	
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
	public abstract List<Document> search(String query, int start, int n) throws SQLException;
	
	/**
	 * Search for similar documents. Return documents intros.
	 * 
	 * @param query Query in plain text
	 * @param start Relative start position in an ordered (by similarity) list of documents  
	 * @param n Number of documents to return
	 * @return Search results (DocID, URI, similarity, First 256 characters of document text)
	 * @throws SQLException
	 */
	public abstract List<Document> searchIntro(String query, int start, int n) throws SQLException;
	
	/**
	 * Search for similar documents. Return complete documents.
	 * 
	 * @param query Query in plain text
	 * @param start Relative start position in an ordered (by similarity) list of documents  
	 * @param n Number of documents to return
	 * @return Search results (DocID, URI, similarity, Full document text)
	 * @throws SQLException
	 */
	public abstract List<Document> searchFull(String query, int start, int n) throws SQLException;
	
	/**
	 * Set model configuration parameter
	 * @param param Parameter name
	 * @param value Parameter value
	 * @throws SQLException
	 */
	public abstract void setParameter(String param, String value) throws SQLException;
	
	/**
	 * Get number of documents crawled by the model
	 * @return Number of documents
	 * @throws SQLException
	 */
	public abstract int getNumberOfDocuments() throws SQLException;
	
	/**
	 * Get range of documents crawled by the model
	 * @param offset Start from document at position 'offset' (start from position 0)
	 * @param limit Get 'limit' number of documents
	 * @return List of documents in the requested interval
	 * @throws SQLException
	 */
	public abstract List<Document> getDocuments(int offset, int limit) throws SQLException;
	
	/**
	 * Get document crawled by the model
	 * @param offset Document position (start from position 0)
	 * @return Document at requested position, null if there is no such document
	 * @throws SQLException
	 */
	public abstract Document getDocument(int offset) throws SQLException;
}
