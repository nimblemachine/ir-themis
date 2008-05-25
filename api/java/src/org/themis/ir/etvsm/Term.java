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
package org.themis.ir.etvsm;

/**
 * Class representing eTVSM ontology term
 *
 */
public class Term {
	private int id;
	private String name;
	
	/**
	 * Get term unique ID
	 * @return Term ID
	 */
	public int getId() {
		return id;
	}
	
	/**
	 * Set term unique ID
	 * @param id Term ID
	 */
	public void setId(int id) {
		this.id = id;
	}

	/**
	 * Get term unique name 
	 * @return Term name
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * Set term name 
	 * @param name Term name
	 */
	public void setName(String name) {
		this.name = name;
	}

	/**
	 * Constructor
	 * @param id Topic unique ID
	 * @param name Topic unique name
	 * @param description Topic description
	 */
	public Term(int id, String name) {
		super();
		this.id = id;
		this.name = name;
	}
}
