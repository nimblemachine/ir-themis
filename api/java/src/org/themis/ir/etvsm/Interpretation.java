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
 * Class representing eTVSM ontology interpretation
 *
 */
public class Interpretation {
	private int id;
	private String name;
	private String description;
	
	/**
	 * Get interpretation unique ID
	 * @return Interpretation ID
	 */
	public int getId() {
		return id;
	}
	
	/**
	 * Set interpretation unique ID
	 * @param id Interpretation ID
	 */
	public void setId(int id) {
		this.id = id;
	}

	/**
	 * Get interpretation unique name 
	 * @return Interpretation name
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * Set interpretation name 
	 * @param name Interpretation name
	 */
	public void setName(String name) {
		this.name = name;
	}
	
	/**
	 * Get interpretation description
	 * @return Interpretation description
	 */
	public String getDescription() {
		return description;
	}
	
	/**
	 * Set interpretation description
	 * @param description Interpretation description
	 */
	public void setDescription(String description) {
		this.description = description;
	}

	/**
	 * Constructor
	 * @param id Interpretation unique ID
	 * @param name Interpretation unique name
	 * @param description Interpretation description
	 */
	public Interpretation(int id, String name, String description) {
		super();
		this.id = id;
		this.name = name;
		this.description = description;
	}
}
