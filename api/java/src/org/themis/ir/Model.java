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

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;

import org.themis.DBConnection;

public class Model extends DBConnection implements IModel
{
	// sql strings
	private final String SQL_ADD_DOCUMENT;
	private final String SQL_ADD_QUERY;
	private final String SQL_ADD_STOPWORD;
	private final String SQL_DEL_STOPWORD;
	private final String SQL_CLEAR_STOPWORD;
	private final String SQL_CLEAR;
	private final String SQL_DEL_DOC_ID;
	private final String SQL_DEL_DOC_URI;
	private final String SQL_SIM;
	private final String SQL_SEARCH;
	private final String SQL_SEARCH_INTRO;
	private final String SQL_SEARCH_FULL;
	private final String SQL_SET_PARAM;
	
	// callable statements
	private CallableStatement addDocProc		= null;
	private CallableStatement addQueryProc		= null;
	private CallableStatement addStopwordProc	= null;
	private CallableStatement delStopwordProc	= null;
	private CallableStatement clearStopwordProc	= null;
	private CallableStatement clearProc			= null;
	private CallableStatement delDocIDProc		= null;
	private CallableStatement delDocURIProc		= null;
	private CallableStatement simProc			= null;
	private PreparedStatement searchProc		= null;
	private PreparedStatement searchIntroProc	= null;
	private PreparedStatement searchFullProc	= null;
	private CallableStatement setParamProc		= null;
	
	/**
	 * Constructor
	 * @param SQL_SCHEMA SQL schema name
	 * @param host Database host server
	 * @param name Database name
	 * @param user Database user
	 * @param pwd User password
	 * @throws SQLException
	 * @throws ClassNotFoundException
	 */
	public Model(String SQL_SCHEMA, String host, String name, String user, String pwd) throws SQLException, ClassNotFoundException
	{
		setDBHost(host);
		setDBName(name);
		setDBUser(user);
		setDBPassword(pwd);
		
		SQL_ADD_DOCUMENT	= "{? = call "+SQL_SCHEMA+".add_document(?,?,?)}";
		SQL_ADD_QUERY		= "{? = call "+SQL_SCHEMA+".add_query(?)}";
		SQL_ADD_STOPWORD	= "{? = call "+SQL_SCHEMA+".add_stopword(?)}";
		SQL_DEL_STOPWORD	= "{? = call "+SQL_SCHEMA+".del_stopword(?)}";
		SQL_CLEAR_STOPWORD	= "{? = call "+SQL_SCHEMA+".clear_stopword()}";
		SQL_CLEAR			= "{? = call "+SQL_SCHEMA+".clear()}";
		SQL_DEL_DOC_ID		= "{? = call "+SQL_SCHEMA+".del_document_by_id(?)}";
		SQL_DEL_DOC_URI		= "{? = call "+SQL_SCHEMA+".del_document_by_uri(?)}";
		SQL_SIM				= "{? = call "+SQL_SCHEMA+".sim(?,?)}";
		SQL_SEARCH			= "SELECT * FROM "+SQL_SCHEMA+".search(?,?,?)";
		SQL_SEARCH_INTRO	= "SELECT * FROM "+SQL_SCHEMA+".search_intro(?,?,?)";
		SQL_SEARCH_FULL		= "SELECT * FROM "+SQL_SCHEMA+".search_full(?,?,?)";
		SQL_SET_PARAM		= "{? = call "+SQL_SCHEMA+".set_config(?,?)}";
		
		initializeSQLStatements();
	}
	
	private void initializeSQLStatements() throws SQLException, ClassNotFoundException
	{
		addDocProc			= getConnection().prepareCall(SQL_ADD_DOCUMENT);
		addQueryProc		= getConnection().prepareCall(SQL_ADD_QUERY);
		addStopwordProc		= getConnection().prepareCall(SQL_ADD_STOPWORD);
		delStopwordProc		= getConnection().prepareCall(SQL_DEL_STOPWORD);
		clearStopwordProc	= getConnection().prepareCall(SQL_CLEAR_STOPWORD);
		clearProc			= getConnection().prepareCall(SQL_CLEAR);
		delDocIDProc		= getConnection().prepareCall(SQL_DEL_DOC_ID);
		delDocURIProc		= getConnection().prepareCall(SQL_DEL_DOC_URI);
		simProc				= getConnection().prepareCall(SQL_SIM);
		searchProc			= getConnection().prepareStatement(SQL_SEARCH);
		searchIntroProc		= getConnection().prepareStatement(SQL_SEARCH_INTRO);
		searchFullProc		= getConnection().prepareStatement(SQL_SEARCH_FULL);
		setParamProc		= getConnection().prepareCall(SQL_SET_PARAM);
	}

	@Override
	public int addDocument(String uri, String doc, boolean isQuery) throws SQLException
	{
		addDocProc.registerOutParameter(1, Types.INTEGER);
		addDocProc.setString(2, uri);
		addDocProc.setString(3, doc);
		addDocProc.setBoolean(4, isQuery);
		
		addDocProc.execute();		
		return addDocProc.getInt(1);
	}

	@Override
	public int addQuery(String doc) throws SQLException
	{
		addQueryProc.registerOutParameter(1, Types.INTEGER);
		addQueryProc.setString(2, doc);
		
		addQueryProc.execute();		
		return addQueryProc.getInt(1);
	}

	@Override
	public int addStopword(String word) throws SQLException
	{
		addStopwordProc.registerOutParameter(1, Types.INTEGER);
		addStopwordProc.setString(2, word);
		
		addStopwordProc.execute();		
		return addStopwordProc.getInt(1);
	}

	@Override
	public void clear() throws SQLException
	{
		clearProc.registerOutParameter(1, Types.INTEGER);
		
		clearProc.execute();		
	}

	@Override
	public int removeDocument(int docID) throws SQLException
	{
		delDocIDProc.registerOutParameter(1, Types.INTEGER);
		delDocIDProc.setInt(2, docID);
		
		delDocIDProc.execute();		
		return delDocIDProc.getInt(1);
	}

	@Override
	public int removeDocument(String uri) throws SQLException
	{
		delDocURIProc.registerOutParameter(1, Types.INTEGER);
		delDocURIProc.setString(2, uri);
		
		delDocURIProc.execute();		
		return delDocURIProc.getInt(1);
	}

	@Override
	public double similarity(int doc1ID, int doc2ID) throws SQLException
	{
		simProc.registerOutParameter(1, Types.REAL);
		simProc.setInt(2, doc1ID);
		simProc.setInt(3, doc2ID);
		
		simProc.execute();		
		return simProc.getFloat(1);
	}

	@Override
	public ResultSet search(String query, int start, int n) throws SQLException
	{
		searchProc.setString(1, query);
		searchProc.setInt(2, n);
		searchProc.setInt(3, start);
		
		return searchProc.executeQuery();
	}

	@Override
	public ResultSet searchFull(String query, int start, int n) throws SQLException
	{
		searchFullProc.setString(1, query);
		searchFullProc.setInt(2, n);
		searchFullProc.setInt(3, start);
		
		return searchFullProc.executeQuery();
	}

	@Override
	public ResultSet searchIntro(String query, int start, int n) throws SQLException
	{
		searchIntroProc.setString(1, query);
		searchIntroProc.setInt(2, n);
		searchIntroProc.setInt(3, start);
		
		return searchIntroProc.executeQuery();
	}

	@Override
	public void setParameter(String param, String value) throws SQLException
	{
		setParamProc.registerOutParameter(1, Types.INTEGER);
		setParamProc.setString(2, param);
		setParamProc.setString(3, value);
		
		setParamProc.execute();
	}

	@Override
	public void clearStopwords() throws SQLException
	{
		clearStopwordProc.registerOutParameter(1, Types.INTEGER);
		
		clearStopwordProc.execute();
	}

	@Override
	public int removeStopword(String word) throws SQLException
	{
		delStopwordProc.registerOutParameter(1, Types.INTEGER);
		delStopwordProc.setString(2, word);
		
		delStopwordProc.execute();		
		return delStopwordProc.getInt(1);
	}
}
