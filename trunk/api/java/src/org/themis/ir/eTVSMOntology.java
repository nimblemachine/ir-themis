package org.themis.ir;

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.sql.Types;

import org.themis.DBConnection;

public class eTVSMOntology extends DBConnection
{
	// schema
	private final String SQL_SCHEMA = "etvsm_ontology";
	
	// sql strings
	private final String SQL_AUTO_ISIMS				= "{? = call "+SQL_SCHEMA+".isims_auto(?)}";
	private final String SQL_UPD_ISIMS 				= "{? = call "+SQL_SCHEMA+".isims_update()}";
	private final String SQL_DUMP_WN_DOC_SYN_NVSAR	= "{? = call "+SQL_SCHEMA+".wordnet_dump_doc_syn_nvsar(?)}";
	private final String SQL_DUMP_WN_DOC_SYNSET_MF	= "{? = call "+SQL_SCHEMA+".wordnet_dump_doc_synset_mf(?)}";
	private final String SQL_CLEAR					= "{? = call "+SQL_SCHEMA+".clear()}";
	
	// callable statements
	private CallableStatement autoIsimsProc			= null;
	private CallableStatement updIsimsProc			= null;
	private CallableStatement dumpWNDocSynNvsarProc	= null;
	private CallableStatement dumpWNDocSynsetMFProc	= null;
	private CallableStatement clearProc				= null;
	
	public eTVSMOntology(String host, String name, String user, String pwd) throws SQLException, ClassNotFoundException
	{
		setDBHost(host);
		setDBName(name);
		setDBUser(user);
		setDBPassword(pwd);
		
		initializeSQLStatements();
	}
	
	private void initializeSQLStatements() throws SQLException, ClassNotFoundException
	{
		autoIsimsProc			= getConnection().prepareCall(SQL_AUTO_ISIMS);
		updIsimsProc			= getConnection().prepareCall(SQL_UPD_ISIMS);
		dumpWNDocSynNvsarProc	= getConnection().prepareCall(SQL_DUMP_WN_DOC_SYN_NVSAR);
		dumpWNDocSynsetMFProc	= getConnection().prepareCall(SQL_DUMP_WN_DOC_SYNSET_MF);
		clearProc				= getConnection().prepareCall(SQL_CLEAR);
	}
	
	public void autoISims(boolean flag) throws SQLException
	{
		autoIsimsProc.registerOutParameter(1, Types.INTEGER);
		autoIsimsProc.setBoolean(2,flag);
		
		autoIsimsProc.execute();
	}
	
	public void updateIsims() throws SQLException
	{
		updIsimsProc.registerOutParameter(1, Types.INTEGER);
		updIsimsProc.execute();
	}
	
	public int dumpWNSynNVSAR(String doc) throws SQLException
	{
		dumpWNDocSynNvsarProc.registerOutParameter(1, Types.INTEGER);
		dumpWNDocSynNvsarProc.setString(2,doc);
		
		dumpWNDocSynNvsarProc.execute();
		return dumpWNDocSynNvsarProc.getInt(1);
	}
	
	public int dumpWNSynsetMF(String doc) throws SQLException
	{
		dumpWNDocSynsetMFProc.registerOutParameter(1, Types.INTEGER);
		dumpWNDocSynsetMFProc.setString(2,doc);
		
		dumpWNDocSynsetMFProc.execute();
		return dumpWNDocSynsetMFProc.getInt(1);
	}
	
	public void clear() throws SQLException
	{
		clearProc.registerOutParameter(1, Types.INTEGER);
		
		clearProc.execute();		
	}
}
