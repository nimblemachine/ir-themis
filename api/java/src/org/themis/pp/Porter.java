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
package org.themis.pp;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import org.themis.DBConnection;

public class Porter extends DBConnection
{
	private static final String SQL_SCHEMA = "stemmer";
	private static final String SQL_PORTER_STEM = "{? = call "+SQL_SCHEMA+".stem(?)}";
	
	// CallableStatements
	private static CallableStatement stemProc = null;
	
	public Porter(String host, String name, String user, String pwd) throws SQLException, ClassNotFoundException
	{
		setDBHost(host);
		setDBName(name);
		setDBUser(user);
		setDBPassword(pwd);
		initializeSQLStatements();
	}
	
	private void initializeSQLStatements() throws SQLException, ClassNotFoundException
	{
		stemProc = getConnection().prepareCall(SQL_PORTER_STEM);	
	}
	
	public String stem(String word) throws SQLException, ClassNotFoundException
	{		
		stemProc.registerOutParameter(1, Types.VARCHAR);
		stemProc.setString (2, word);
		
		stemProc.execute();		
		return stemProc.getString(1);
	}
}
