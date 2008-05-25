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
 * Class representing eTVSM ontology topic
 *
 */
public class Topic {
	private int id;
	private String name;
	private String description;
	
	/**
	 * Get topic unique ID
	 * @return Topic ID
	 */
	public int getId() {
		return id;
	}
	
	/**
	 * Set topic unique ID
	 * @param id Topic ID
	 */
	public void setId(int id) {
		this.id = id;
	}

	/**
	 * Get topic unique name 
	 * @return Topic name
	 */
	public String getName() {
		return name;
	}
	
	/**
	 * Set topic name 
	 * @param name Topic name
	 */
	public void setName(String name) {
		this.name = name;
	}
	
	/**
	 * Get topic description
	 * @return Topic description
	 */
	public String getDescription() {
		return description;
	}
	
	/**
	 * Set topic description
	 * @param description Topic description
	 */
	public void setDescription(String description) {
		this.description = description;
	}

	/**
	 * Constructor
	 * @param id Topic unique ID
	 * @param name Topic unique name
	 * @param description Topic description
	 */
	public Topic(int id, String name, String description) {
		super();
		this.id = id;
		this.name = name;
		this.description = description;
	}
}
