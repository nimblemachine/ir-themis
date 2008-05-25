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
package org.themis.ir.etvsm;

import java.sql.CallableStatement;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;

import org.themis.DBConnection;

public class eTVSMOntology extends DBConnection implements IeTVSMOntology
{
	// schema
	private final String SQL_SCHEMA = "etvsm_ontology";
	private final String SQL_THEMIS_SCHEMA = "etvsm_ontology";
	
	// sql strings
	private final String SQL_AUTO_ISIMS				= "{? = call "+SQL_SCHEMA+".isims_auto(?)}";
	private final String SQL_UPD_ISIMS 				= "{? = call "+SQL_SCHEMA+".isims_update()}";
	private final String SQL_DUMP_WN_DOC_SYN_NVSAR	= "{? = call "+SQL_SCHEMA+".wordnet_dump_doc_syn_nvsar(?)}";
	private final String SQL_DUMP_WN_DOC_SYNSET_MF	= "{? = call "+SQL_SCHEMA+".wordnet_dump_doc_synset_mf(?)}";
	private final String SQL_CLEAR					= "{? = call "+SQL_SCHEMA+".clear()}";
	private final String SQL_ADD_INTERPRETATION		= "{? = call "+SQL_SCHEMA+".interpretation_add(?,?)}";
	private final String SQL_ADD_TERM				= "{? = call "+SQL_SCHEMA+".term_add(?)}";
	private final String SQL_ADD_TOPIC				= "{? = call "+SQL_SCHEMA+".topic_add(?,?)}";
	private final String SQL_GET_INTERPRETATION_N	= "SELECT count(*) FROM "+SQL_SCHEMA+".interpretation";
	private final String SQL_GET_TERM_N				= "SELECT count(*) FROM "+SQL_SCHEMA+".term";
	private final String SQL_GET_TOPIC_N			= "SELECT count(*) FROM "+SQL_SCHEMA+".topic";
	private final String SQL_GET_INTERPRETATIONS	= "SELECT t1.id, t2.word, t1.descr FROM "+SQL_SCHEMA+".interpretation t1, "+SQL_THEMIS_SCHEMA+".word t2 WHERE t1.name = t2.id ORDER BY t1.id ASC LIMIT ? OFFSET ?";
	private final String SQL_GET_TERMS				= "SELECT * FROM "+SQL_SCHEMA+".term ORDER BY id ASC LIMIT ? OFFSET ?";
	private final String SQL_GET_TOPICS				= "SELECT t1.id, t2.word, t1.descr FROM "+SQL_SCHEMA+".topic t1, "+SQL_THEMIS_SCHEMA+".word t2 WHERE t1.name = t2.id ORDER BY t1.id ASC LIMIT ? OFFSET ?";
	private final String SQL_DEL_INTERPRETATION		= "{? = call "+SQL_SCHEMA+".interpretation_remove(?)}";
	private final String SQL_DEL_TERM				= "{? = call "+SQL_SCHEMA+".term_remove(?)}";
	private final String SQL_DEL_TOPIC				= "{? = call "+SQL_SCHEMA+".topic_remove(?)}";
	private final String SQL_LINK_TOPICS			= "{? = call "+SQL_SCHEMA+".map_add(?,?,?)}";
	private final String SQL_UNLINK_TOPICS			= "{? = call "+SQL_SCHEMA+".map_remove(?,?)}";
	private final String SQL_LINK_TOPIC_INTER		= "{? = call "+SQL_SCHEMA+".imap_add(?,?)}";
	private final String SQL_UNLINK_TOPIC_INTER		= "{? = call "+SQL_SCHEMA+".imap_remove(?,?)}";
	private final String SQL_LINK_INTER_TERM		= "{? = call "+SQL_SCHEMA+".tmap_add(?,?)}";
	private final String SQL_UNLINK_INTER_TERM		= "{? = call "+SQL_SCHEMA+".tmap_remove(?,?)}";
	
	// callable statements
	private CallableStatement autoIsimsProc			= null;
	private CallableStatement updIsimsProc			= null;
	private CallableStatement dumpWNDocSynNvsarProc	= null;
	private CallableStatement dumpWNDocSynsetMFProc	= null;
	private CallableStatement clearProc				= null;
	private CallableStatement addInterpretationProc	= null;
	private CallableStatement addTermProc			= null;
	private CallableStatement addTopicProc			= null;
	private PreparedStatement getInterpretationN	= null;
	private PreparedStatement getTermN				= null;
	private PreparedStatement getTopicN				= null;
	private PreparedStatement getInterpretations	= null;
	private PreparedStatement getTerms				= null;
	private PreparedStatement getTopics				= null;
	private CallableStatement delInterpretationProc	= null;
	private CallableStatement delTermProc			= null;
	private CallableStatement delTopicProc			= null;
	private CallableStatement linkTopics			= null;
	private CallableStatement unlinkTopics			= null;
	private CallableStatement linkTopicInter		= null;
	private CallableStatement unlinkTopicInter		= null;
	private CallableStatement linkInterTerm			= null;
	private CallableStatement unlinkInterTerm		= null;
	
	
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
		addInterpretationProc	= getConnection().prepareCall(SQL_ADD_INTERPRETATION);
		addTermProc				= getConnection().prepareCall(SQL_ADD_TERM);
		addTopicProc			= getConnection().prepareCall(SQL_ADD_TOPIC);
		getInterpretationN		= getConnection().prepareStatement(SQL_GET_INTERPRETATION_N);
		getTermN				= getConnection().prepareStatement(SQL_GET_TERM_N);
		getTopicN				= getConnection().prepareStatement(SQL_GET_TOPIC_N);
		getInterpretations		= getConnection().prepareStatement(SQL_GET_INTERPRETATIONS);
		getTerms				= getConnection().prepareStatement(SQL_GET_TERMS);
		getTopics				= getConnection().prepareStatement(SQL_GET_TOPICS);
		delInterpretationProc	= getConnection().prepareCall(SQL_DEL_INTERPRETATION);
		delTermProc				= getConnection().prepareCall(SQL_DEL_TERM);
		delTopicProc			= getConnection().prepareCall(SQL_DEL_TOPIC);
		linkTopics				= getConnection().prepareCall(SQL_LINK_TOPICS);
		unlinkTopics			= getConnection().prepareCall(SQL_UNLINK_TOPICS);
		linkTopicInter			= getConnection().prepareCall(SQL_LINK_TOPIC_INTER);
		unlinkTopicInter		= getConnection().prepareCall(SQL_UNLINK_TOPIC_INTER);
		linkInterTerm			= getConnection().prepareCall(SQL_LINK_INTER_TERM);
		unlinkInterTerm			= getConnection().prepareCall(SQL_UNLINK_INTER_TERM);
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
	
	@Override
	public void clear() throws SQLException
	{
		clearProc.registerOutParameter(1, Types.INTEGER);
		
		clearProc.execute();		
	}

	@Override
	public Interpretation addInterpretation(Interpretation i) throws SQLException {
		addInterpretationProc.registerOutParameter(1, Types.INTEGER);
		addInterpretationProc.setString(2, i.getName());
		addInterpretationProc.setString(3, i.getDescription());
		
		addInterpretationProc.execute();
		i.setId(addInterpretationProc.getInt(1));
		return i;
	}

	@Override
	public Term addTerm(Term t) throws SQLException {
		addTermProc.registerOutParameter(1, Types.INTEGER);
		addTermProc.setString(2, t.getName());
		
		addTermProc.execute();
		t.setId(addTermProc.getInt(1));
		return t;
	}

	@Override
	public Topic addTopic(Topic t) throws SQLException {
		addTopicProc.registerOutParameter(1, Types.INTEGER);
		addTopicProc.setString(2, t.getName());
		addTopicProc.setString(3, t.getDescription());
		
		addTopicProc.execute();
		t.setId(addTopicProc.getInt(1));
		return t;
	}

	@Override
	public Interpretation getInterpretation(int offset) throws SQLException {
		List<Interpretation> is = getInterpretations(offset, 1);
		
		if (is.size()<=0) return null;
		
		return is.get(0);
	}

	@Override
	public List<Interpretation> getInterpretations(int offset, int limit) throws SQLException {
		getInterpretations.setInt(1, limit);
		getInterpretations.setInt(2, offset);
		
		ResultSet res = getInterpretations.executeQuery();
		
		List<Interpretation> result = new ArrayList<Interpretation>();
		
		while (res.next())
		{
			Interpretation i = new Interpretation(res.getInt(1),res.getString(2),res.getString(3));
			result.add(i);
		}
		
		return result;
	}

	@Override
	public int getNumberOfInterpretations() throws SQLException {
		ResultSet res = getInterpretationN.executeQuery();
		
		if (res.next())
			return res.getInt(1);
		
		return 0;
	}

	@Override
	public int getNumberOfTerms() throws SQLException {
		ResultSet res = getTermN.executeQuery();
		
		if (res.next())
			return res.getInt(1);
		
		return 0;
	}

	@Override
	public int getNumberOfTopics() throws SQLException {
		ResultSet res = getTopicN.executeQuery();
		
		if (res.next())
			return res.getInt(1);
		
		return 0;
	}

	@Override
	public Set<Interpretation> getSubInterpretation(Topic t)
			throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Set<Term> getSubTerms(Interpretation i) throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Set<Topic> getSubTopics(Topic t) throws SQLException {
		// TODO Auto-generated method stub
		return null;
	}

	@Override
	public Term getTerm(int offset) throws SQLException {
		List<Term> ts = getTerms(offset, 1);
		
		if (ts.size()<=0) return null;
		
		return ts.get(0);
	}

	@Override
	public List<Term> getTerms(int offset, int limit) throws SQLException {
		getTerms.setInt(1, limit);
		getTerms.setInt(2, offset);
		
		ResultSet res = getTerms.executeQuery();
		
		List<Term> result = new ArrayList<Term>();
		
		while (res.next())
		{
			Term t = new Term(res.getInt(1),res.getString(2));
			result.add(t);
		}
		
		return result;
	}

	@Override
	public Topic getTopic(int offset) throws SQLException {
		List<Topic> ts = getTopics(offset, 1);
		
		if (ts.size()<=0) return null;
		
		return ts.get(0);
	}

	@Override
	public List<Topic> getTopics(int offset, int limit) throws SQLException {
		getTopics.setInt(1, limit);
		getTopics.setInt(2, offset);
		
		ResultSet res = getTopics.executeQuery();
		
		List<Topic> result = new ArrayList<Topic>();
		
		while (res.next())
		{
			Topic t = new Topic(res.getInt(1),res.getString(2),res.getString(3));
			result.add(t);
		}
		
		return result;
	}

	@Override
	public boolean linkInterpretationWithTerm(Interpretation parent, Term child) throws SQLException {
		linkInterTerm.registerOutParameter(1, Types.INTEGER);
		linkInterTerm.setString(2, parent.getName());
		linkInterTerm.setString(3, child.getName());
		
		linkInterTerm.execute();
		
		return (linkInterTerm.getInt(1) > 0) ? true : false;
	}

	@Override
	public boolean linkTopicWithInterpretation(Topic parent, Interpretation child) throws SQLException {
		linkTopicInter.registerOutParameter(1, Types.INTEGER);
		linkTopicInter.setString(2, parent.getName());
		linkTopicInter.setString(3, child.getName());
		
		linkTopicInter.execute();
		
		return (linkTopicInter.getInt(1) > 0) ? true : false;
	}

	@Override
	public boolean linkTopics(Topic parent, Topic child) throws SQLException {
		linkTopics.registerOutParameter(1, Types.INTEGER);
		linkTopics.setString(2, parent.getName());
		linkTopics.setString(3, child.getName());
		linkTopics.setString(4, "null");
		
		linkTopics.execute();
		
		return (linkTopics.getInt(1) > 0) ? true : false;
	}

	@Override
	public boolean removeInterpretation(Interpretation i) throws SQLException {
		delInterpretationProc.registerOutParameter(1, Types.INTEGER);
		delInterpretationProc.setString(2, i.getName());
		
		delInterpretationProc.execute();
		if (delInterpretationProc.getInt(1)==Types.NULL) return false;
		
		return true;
	}

	@Override
	public boolean removeTerm(Term t) throws SQLException {
		delTermProc.registerOutParameter(1, Types.INTEGER);
		delTermProc.setString(2, t.getName());
		
		delTermProc.execute();
		if (delTermProc.getInt(1)==Types.NULL) return false;
		
		return true;
	}

	@Override
	public boolean removeTopic(Topic t) throws SQLException {
		delTopicProc.registerOutParameter(1, Types.INTEGER);
		delTopicProc.setString(2, t.getName());
		
		delTopicProc.execute();
		if (delTopicProc.getInt(1)==Types.NULL) return false;
		
		return true;
	}

	@Override
	public boolean unlinkInterpretationWithTerm(Interpretation parent, Term child) throws SQLException {
		unlinkInterTerm.registerOutParameter(1, Types.INTEGER);
		unlinkInterTerm.setString(2, parent.getName());
		unlinkInterTerm.setString(3, child.getName());
		
		unlinkInterTerm.execute();
		
		return true;
	}

	@Override
	public boolean unlinkTopicWithInterpretation(Topic parent, Interpretation child) throws SQLException {
		unlinkTopicInter.registerOutParameter(1, Types.INTEGER);
		unlinkTopicInter.setString(2, parent.getName());
		unlinkTopicInter.setString(3, child.getName());
		
		unlinkTopicInter.execute();
		
		return true;
	}

	@Override
	public boolean unlinkTopics(Topic parent, Topic child) throws SQLException {
		unlinkTopics.registerOutParameter(1, Types.INTEGER);
		unlinkTopics.setString(2, parent.getName());
		unlinkTopics.setString(3, child.getName());
		
		unlinkTopics.execute();
		
		return true;
	}
}
