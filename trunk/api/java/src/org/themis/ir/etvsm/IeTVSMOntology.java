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

import java.sql.SQLException;
import java.util.List;
import java.util.Set;

public interface IeTVSMOntology {
	
	/**
	 * Clear eTVSM ontology
	 * @throws SQLException
	 */
	public abstract void clear() throws SQLException;
	
	/**
	 * Get number of topics in eTVSM ontology
	 * @return Number of topics
	 * @throws SQLException
	 */
	public abstract int getNumberOfTopics() throws SQLException;
	
	/**
	 * Get number of interpretations in eTVSM ontology
	 * @return Number of interpretations
	 * @throws SQLException
	 */
	public abstract int getNumberOfInterpretations() throws SQLException;
	
	/**
	 * Get number of terms in eTVSM ontology
	 * @return Number of terms
	 * @throws SQLException
	 */
	public abstract int getNumberOfTerms() throws SQLException;
	
	/**
	 * Get range of topics from eTVSM ontology
	 * @param offset Start from topic at position 'offset' (start from position 0)
	 * @param limit Get 'limit' number of topics
	 * @return List of topics in the requested interval
	 * @throws SQLException
	 */
	public abstract List<Topic> getTopics(int offset, int limit) throws SQLException;
	
	/**
	 * Get topic at specific position
	 * @param offset Topic position (start from position 0)
	 * @return Topic at requested position, null if there is no such topic
	 * @throws SQLException
	 */
	public abstract Topic getTopic(int offset) throws SQLException;
	
	/**
	 * Get range of interpretations from eTVSM ontology
	 * @param offset Start from interpretation at position 'offset' (start from position 0)
	 * @param limit Get 'limit' number of interpretations
	 * @return List of interpretations in the requested interval
	 * @throws SQLException
	 */
	public abstract List<Interpretation> getInterpretations(int offset, int limit) throws SQLException;
	
	/**
	 * Get interpretation at specific position
	 * @param offset Interpretation position (start from position 0)
	 * @return Interpretation at requested position, null if there is no such interpretation
	 * @throws SQLException
	 */
	public abstract Interpretation getInterpretation(int offset) throws SQLException;
	
	/**
	 * Get range of terms from eTVSM ontology
	 * @param offset Start from term at position 'offset' (start from position 0)
	 * @param limit Get 'limit' number of terms
	 * @return List of terms in the requested interval
	 * @throws SQLException
	 */
	public abstract List<Term> getTerms(int offset, int limit) throws SQLException;
	
	/**
	 * Get term at specific position
	 * @param offset Term position (start from position 0)
	 * @return Term at requested position, null if there is no such term
	 * @throws SQLException
	 */
	public abstract Term getTerm(int offset) throws SQLException;
	
	/**
	 * Add topic to eTVSM ontology (if topic exists, it remains unchanged)
	 * @param t Topic to add
	 * @return Added topic
	 * @throws SQLException
	 */
	public abstract Topic addTopic(Topic t) throws SQLException;
	
	/**
	 * Add interpretation to eTVSM ontology (if interpretation exists, it remains unchanged)
	 * @param i Interpretation to add
	 * @return Added interpretation
	 * @throws SQLException
	 */
	public abstract Interpretation addInterpretation(Interpretation i) throws SQLException;
	
	/**
	 * Add term to eTVSM ontology (if term exists, it remains unchanged)
	 * @param t Term to add
	 * @return Added term
	 * @throws SQLException
	 */
	public abstract Term addTerm(Term t) throws SQLException;
	
	/**
	 * Remove topic from eTVSM ontology (only topic without children will be removed)
	 * @param t Topic to remove
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean removeTopic(Topic t) throws SQLException;
	
	/**
	 * Remove interpretation from eTVSM ontology (only interpretation without children will be removed)
	 * @param i Interpretation to remove
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean removeInterpretation(Interpretation i) throws SQLException;
	
	/**
	 * Remove term from eTVSM ontology
	 * @param t Term to remove
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean removeTerm(Term t) throws SQLException;
	
	/**
	 * Link two topics in eTVSM ontology
	 * @param parent Parent topic
	 * @param child Child topic
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean linkTopics(Topic parent, Topic child) throws SQLException;
	
	/**
	 * Unlink two topics in eTVSM ontology
	 * @param parent Parent topic
	 * @param child Child topic
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean unlinkTopics(Topic parent, Topic child) throws SQLException;
	
	/**
	 * Link topic with interpretation in eTVSM ontology
	 * @param parent Parent topic
	 * @param child Child interpretation
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean linkTopicWithInterpretation(Topic parent, Interpretation child) throws SQLException;
	
	/**
	 * Unlink topic with interpretation in eTVSM ontology
	 * @param parent Parent topic
	 * @param child Child interpretation
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean unlinkTopicWithInterpretation(Topic parent, Interpretation child) throws SQLException;
	
	/**
	 * Link interpretation with term in eTVSM ontology
	 * @param parent Parent interpretation
	 * @param child Child term
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean linkInterpretationWithTerm(Interpretation parent, Term child) throws SQLException;
	
	/**
	 * Unlink interpretation with term in eTVSM ontology
	 * @param parent Parent interpretation
	 * @param child Child term
	 * @return true on success, false otherwise
	 * @throws SQLException
	 */
	public abstract boolean unlinkInterpretationWithTerm(Interpretation parent, Term child) throws SQLException;
	
	/**
	 * Get topic sub topics in eTVSM ontology
	 * @param t Topic
	 * @return Sub topics of proposed topic
	 * @throws SQLException
	 */
	public abstract Set<Topic> getSubTopics(Topic t) throws SQLException;
	
	/**
	 * Get topic sub interpretations in eTVSM ontology
	 * @param t Topic
	 * @return Sub interpretations of proposed topic
	 * @throws SQLException
	 */
	public abstract Set<Interpretation> getSubInterpretation(Topic t) throws SQLException;
	
	/**
	 * Get interpretation sub terms in eTVSM ontology
	 * @param i Interpretation
	 * @return Sub terms of proposed interpretation
	 * @throws SQLException
	 */
	public abstract Set<Term> getSubTerms(Interpretation i) throws SQLException;
}
