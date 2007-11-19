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
