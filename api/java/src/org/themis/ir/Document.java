/**
    Themis - Information Retrieval framework
    Copyright (C) 2008 Artem Polyvyanyy

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

import java.util.Date;

/**
 * Class representing plain text document
 *
 */
public class Document {
	private int id;
	private String uri;
	private String content;
	private boolean is_query;
	private Date last_update;
	private double similarity;
	
	/**
	 * Get document unique ID
	 * @return Document ID
	 */
	public int getId() {
		return id;
	}
	
	/**
	 * Get document URI
	 * @return Document URI
	 */
	public String getURI() {
		return uri;
	}
	
	/**
	 * Set document unique URI
	 * @param uri Document URI
	 */
	public void setURI(String uri) {
		this.uri = uri;
	}
	
	/**
	 * Get document content
	 * @return Document content
	 */
	public String getContent() {
		return content;
	}
	
	/**
	 * Set document content
	 * @param document Document content
	 */
	public void setContent(String document) {
		this.content = document;
	}
	
	/**
	 * Check if document is a query or a crawled document
	 * @return true if query, false otherwise
	 */
	public boolean isQuery() {
		return is_query;
	}
	
	/**
	 * Last date document model was re-crawled
	 * @return Last document update date
	 */
	public Date getLastUpdate() {
		return last_update;
	}
	
	public double getSimilarity() {
		return similarity;
	}

	/**
	 * Constructor
	 * 
	 * @param id Document unique ID
	 * @param uri Document URI
	 * @param document Document content
	 * @param is_query Document query flag (true-query,false-document)
	 * @param last_update Last document update
	 */
	public Document(int id, String uri, String document, boolean is_query, Date last_update) {
		super();
		this.id = id;
		this.uri = uri;
		this.content = document;
		this.is_query = is_query;
		this.last_update = last_update;
		this.similarity = 0.0;
	}
	
	/**
	 * Constructor
	 * 
	 * @param id Document unique ID
	 * @param uri Document URI
	 * @param document Document content
	 * @param is_query Document query flag (true-query,false-document)
	 * @param last_update Last document update
	 * @param sim DOcument similarity value (depends on context document is used)
	 */
	public Document(int id, String uri, String document, boolean is_query, Date last_update, double sim) {
		super();
		this.id = id;
		this.uri = uri;
		this.content = document;
		this.is_query = is_query;
		this.last_update = last_update;
		this.similarity = sim;
	}
}
