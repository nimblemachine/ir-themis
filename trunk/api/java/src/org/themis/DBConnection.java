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
