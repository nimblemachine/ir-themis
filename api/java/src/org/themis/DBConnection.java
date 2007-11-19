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
package org.themis;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;


public class DBConnection
{
	private String dbConnectionString = "";
	private String dbHost = "";
	private String dbName = "";
	private String dbUser = "";
	private String dbPassword = "";
	
	private Connection conn = null;
	
	public Connection getConnection() throws ClassNotFoundException, SQLException
	{
		Class.forName("org.postgresql.Driver");
		
		if (conn == null)
			conn = DriverManager.getConnection(getDBConnectionString(),getDBUser(), getDBPassword());
		   
		return conn;
	}
	
	public void setDBHost(String host)
	{
		dbHost = host;
	}

	public String getDBHost()
	{
		return dbHost;
	}

	public void setDBName(String name)
	{
		dbName = name;
	}

	public String getDBName()
	{
		return dbName;
	}

	public void setDBUser(String user)
	{
		dbUser = user;
	}

	public String getDBUser()
	{
		return dbUser;
	}

	public void setDBPassword(String password)
	{
		dbPassword = password;
	}

	public String getDBPassword()
	{
		return dbPassword;
	}

	private void setDbConnectionString(String connectionString)
	{
		dbConnectionString = connectionString;
	}

	public String getDBConnectionString()
	{
		constructConnectionString();
		return dbConnectionString;
	}
	
	private void constructConnectionString()
	{
		setDbConnectionString("jdbc:postgresql://"+dbHost+"/"+dbName+"/");
	}
}
