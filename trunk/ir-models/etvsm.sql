--  Themis - Information Retrieval framework
--  Copyright (C) 2007 Artem Polyvyanyy
--
--  This file is part of Themis.
--
--  Themis is free software: you can redistribute it and/or modify
--  it under the terms of the GNU Lesser General Public License as published by
--  the Free Software Foundation, either version 3 of the License, or
--  (at your option) any later version.
--
--  Themis is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU Lesser General Public License for more details.
--
--  You should have received a copy of the GNU Lesser General Public License
--  along with this program.  If not, see <http://www.gnu.org/licenses/>

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: etvsm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA etvsm;


SET search_path = etvsm, pg_catalog;

--
-- Name: term_seq; Type: TYPE; Schema: etvsm; Owner: -
--

CREATE TYPE term_seq AS (
	term_id integer,
	seq real
);


--
-- Name: add_document(text, text, boolean); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION add_document(text, text, boolean) RETURNS integer
    AS $_$
------------------------------------------------------------
-- add/update document and document model
------------------------------------------------------------
DECLARE
  url ALIAS FOR $1;
  doc ALIAS FOR $2;
  is_q ALIAS FOR $3;
  document_id INTEGER;
BEGIN
  -- add new document if it is not yet in database
  SELECT INTO document_id id FROM etvsm.document WHERE is_query=is_q AND uri=url;
  IF document_id IS NULL THEN
    INSERT INTO etvsm.document (uri, doc_text, is_query, last_update)
    VALUES (url, trim(both ' ' FROM doc), is_q, now());

    document_id = currval('etvsm.document_id_seq'::regclass);
  ELSE
    UPDATE etvsm.document SET doc_text = trim(both ' ' FROM doc), last_update = NOW() WHERE id = document_id;
  END IF;

  PERFORM etvsm.add_document_model(document_id);

  RETURN document_id;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: add_document_model(integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION add_document_model(integer) RETURNS integer
    AS $_$
DECLARE
  did ALIAS FOR $1;
  document_text TEXT;
  vlength REAL;
BEGIN
  SELECT INTO document_text doc_text FROM etvsm.document WHERE id = did;
  -- update model
  DELETE FROM etvsm.document_model WHERE doc_id=did;
  DELETE FROM etvsm.document_model_pc WHERE doc_id=did;

  INSERT INTO etvsm.document_model (doc_id, inter_id, weight, nocc)
    SELECT did, terms_to_inters, count(terms_to_inters), count(terms_to_inters)
    FROM etvsm.terms_to_inters(did)
    GROUP BY terms_to_inters;

  -- get weighted document vector length
  SELECT INTO vlength SQRT(SUM(t1.weight*t2.weight*t3.sim))
  FROM etvsm.document_model t1, etvsm.document_model t2, etvsm_ontology.isim t3
  WHERE t1.doc_id=did AND t2.doc_id=did AND t3.inter1=t1.inter_id AND t3.inter2=t2.inter_id;

  IF vlength IS NULL THEN vlength = 1.0; END IF;

  INSERT INTO etvsm.document_model_pc (doc_id, vec_length) VALUES (did,vlength);

  RETURN did;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: add_query(text); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION add_query(text) RETURNS integer
    AS $_$
--------------------------------------------------------------------------------
-- Get query id. If query text exists do not refresh document model - saves time
-- $1 - query text
-- RETURN - query id with provided query text
--------------------------------------------------------------------------------
DECLARE
  query ALIAS FOR $1;
  query_id INTEGER;
BEGIN
  -- add new query if it is not yet in database
  SELECT INTO query_id id FROM etvsm.document WHERE is_query=true AND uri=query;

  IF query_id IS NULL THEN
    query_id = etvsm.add_document(query,query,true);
  END IF;

  RETURN query_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: add_stopword(character varying); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION add_stopword(character varying) RETURNS integer
    AS $_$
DECLARE
  sw ALIAS FOR $1;
  wid INTEGER;
BEGIN
  wid = themis.add_word(sw);
  INSERT INTO etvsm.stopword (word_id) VALUES (wid);

  RETURN wid;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: array_compare(integer[], integer[], integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION array_compare(integer[], integer[], integer) RETURNS integer
    AS $_$
--------------------------------------------------------------------------------
-- Compare two one-dimentional arrays (arr1, arr2)
-- RETURN
--  0 - equal arrays
-- -1 - arr1 is not starting arr2
--  1 - arr1 starts arr2
--------------------------------------------------------------------------------
DECLARE
  arr1 ALIAS FOR $1;
  arr2 ALIAS FOR $2;
  n ALIAS FOR $3;
  i INTEGER;
  j INTEGER;
  result INTEGER;
BEGIN
  IF arr1=arr2 THEN RETURN 0; END IF;

  IF n IS NOT NULL THEN
  BEGIN
    FOR i IN COALESCE(array_lower(arr1,1),0) .. COALESCE(array_upper(arr1,1),-1) LOOP
      IF arr1[i]<>COALESCE(arr2[n-1+i],-1) THEN RETURN -1; END IF;
    END LOOP;
  END;
  ELSE
  BEGIN
    FOR i IN COALESCE(array_lower(arr1,1),0) .. COALESCE(array_upper(arr1,1),-1) LOOP
      IF arr1[i]<>COALESCE(arr2[i],-1) THEN RETURN -1; END IF;
    END LOOP;
  END;
  END IF;

  RETURN 1;
END;
$_$
    LANGUAGE plpgsql SECURITY DEFINER;


--
-- Name: clear(); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION clear() RETURNS integer
    AS $$
--------------------------------------------------------------------------------
-- Clear eTVSM database
-- Reset sequence to start from 1
-- RETURN - always 1
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM etvsm.document;
  DELETE FROM etvsm.stopword;
  
  
  ALTER SEQUENCE "etvsm"."document_id_seq"
    INCREMENT 1  MINVALUE 1
    MAXVALUE 9223372036854775807  RESTART 1
    CACHE 1  NO CYCLE;
  
  RETURN 1;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: clear_stopword(); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION clear_stopword() RETURNS integer
    AS $$
BEGIN
  DELETE FROM etvsm.stopword;

  RETURN 1;
END;
$$
    LANGUAGE plpgsql STRICT;


--
-- Name: del_document_by_id(integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION del_document_by_id(integer) RETURNS integer
    AS $_$
DECLARE
  d_id ALIAS FOR $1;
BEGIN
  DELETE FROM etvsm.document WHERE id = d_id;
  
  RETURN d_id;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: del_document_by_uri(text, boolean); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION del_document_by_uri(text, boolean) RETURNS integer
    AS $_$
DECLARE
  url ALIAS FOR $1;
  is_q ALIAS FOR $2;
  did INTEGER;
BEGIN
  SELECT INTO did id FROM etvsm.document WHERE uri = url;
  DELETE FROM etvsm.document WHERE id = did;

  RETURN did;
END
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: del_stopword(character varying); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION del_stopword(character varying) RETURNS integer
    AS $_$
DECLARE
  sw ALIAS FOR $1;
  wid INTEGER;
BEGIN
  wid := themis.add_word(sw);
  DELETE FROM etvsm.stopword WHERE word_id = wid;

  RETURN wid;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: imap_weight(integer, integer, integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION imap_weight(integer, integer, integer) RETURNS integer
    AS $_$
DECLARE
  doc_id ALIAS FOR $1;
  term_id ALIAS FOR $2;
  inter_id ALIAS FOR $3;
  res INTEGER;
BEGIN
  SELECT INTO res count(*)
  FROM etvsm.words_to_terms(doc_id) AS t
  WHERE t.term_id IN (SELECT support_terms FROM etvsm.support_terms(term_id, inter_id));
  
  RETURN res;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: preprocess(text); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION preprocess(text) RETURNS SETOF text
    AS $_$
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  param VARCHAR;
  pw TEXT;
BEGIN

  FOR occ IN
    SELECT doc_to_words AS w FROM themis.doc_to_words(doc)
    WHERE doc_to_words NOT IN (SELECT t1.word FROM themis.word t1,etvsm.stopword t2 WHERE t1.id=t2.word_id)
  LOOP
    -- do preprocessing in model specific order

    -- stemming
    SELECT INTO param value FROM etvsm.config WHERE name = 'stemmer';
    IF param = 'porter' THEN
      pw = stemmer.stem(occ.w);
    ELSE
      pw = occ.w;
    END IF;

    -- always lower casing!!!
    pw = LOWER(pw);

    RETURN NEXT pw;
  END LOOP;

  RETURN;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: search(text, integer, integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION search(text, integer, integer) RETURNS SETOF themis.search_result
    AS $_$
--------------------------------------------------------------------------------
-- Find document similarities between given query text and all non-query
--   documents from the eTVSM databse
-- RETURN - set of {document.id, document.url, similarity} ordered descending by similarity
--------------------------------------------------------------------------------
DECLARE
  q ALIAS FOR $1;
  num ALIAS FOR $2;
  first ALIAS FOR $3;
  q_id INTEGER;
  len REAL;
  occ RECORD;
  res themis.search_result;
BEGIN
  q_id = etvsm.add_query(q);
  SELECT INTO len vec_length FROM etvsm.document_model_pc WHERE doc_id=q_id;

  -- SEARCH! query
  FOR occ IN
    SELECT t2.doc_id AS id, t4.uri, SUM(t1.weight*t2.weight*t3.sim)/(len*t5.vec_length) AS s
    FROM
      etvsm.document_model t1,
      etvsm.document_model t2,
      etvsm_ontology.isim t3,
      etvsm.document t4,
      etvsm.document_model_pc t5
    WHERE
      t1.doc_id=q_id AND
      t4.is_query=false AND
      t3.inter1=t1.inter_id AND
      t3.inter2=t2.inter_id AND
      t4.id=t2.doc_id AND
      t5.doc_id = t4.id
    GROUP BY t2.doc_id,t5.vec_length, t4.uri
    ORDER BY s DESC
    LIMIT num OFFSET first
  LOOP
    res.doc_id = occ.id;
    res.uri = occ.uri;
    res.sim = occ.s;
    RETURN NEXT res;
  END LOOP;

  RETURN;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: search_full(text, integer, integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION search_full(text, integer, integer) RETURNS SETOF themis.search_result_ext
    AS $_$
DECLARE
  q ALIAS FOR $1;
  num ALIAS FOR $2;
  first ALIAS FOR $3;
  occ RECORD;
  result themis.search_result_ext;
BEGIN
  FOR occ IN
    SELECT t1.*, t2.doc_text AS doc
    FROM
        etvsm.search(q,num,first) t1,
        etvsm.document t2
    WHERE
        t1.doc_id = t2.id
  LOOP
    result.doc_id = occ.doc_id;
    result.uri = occ.uri;
    result.doc = occ.doc;
    result.sim = occ.sim;
    RETURN NEXT result;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: search_intro(text, integer, integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION search_intro(text, integer, integer) RETURNS SETOF themis.search_result_ext
    AS $_$
DECLARE
  q ALIAS FOR $1;
  num ALIAS FOR $2;
  first ALIAS FOR $3;
  occ RECORD;
  result themis.search_result_ext;
BEGIN
  FOR occ IN
    SELECT t1.*, SUBSTRING(t2.doc_text,1,256) AS doc
    FROM
        etvsm.search(q,num,first) t1,
        etvsm.document t2
    WHERE
        t1.doc_id = t2.id
  LOOP
    result.doc_id = occ.doc_id;
    result.uri = occ.uri;
    result.doc = occ.doc;
    result.sim = occ.sim;
    RETURN NEXT result;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: set_config(character varying, character varying); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION set_config(character varying, character varying) RETURNS integer
    AS $_$
DECLARE
  param ALIAS FOR $1;
  val ALIAS FOR $2;
  p VARCHAR;
BEGIN
  SELECT INTO p name FROM etvsm.config WHERE name=param;

  IF p IS NULL THEN
    INSERT INTO etvsm.config (name,value) VALUES (param,val);
  ELSE
    UPDATE etvsm.config SET value=val WHERE name=param;
  END IF;

  RETURN 1;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: sim(integer, integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION sim(integer, integer) RETURNS real
    AS $_$
--------------------------------------------------------------------------------
-- Find document similarity between two given documents from the eTVSM database
--   provided document.id's
-- RETURN - provided document similarity value
--------------------------------------------------------------------------------
DECLARE
  doc1_id ALIAS FOR $1;
  doc2_id ALIAS FOR $2;
  len1 REAL;
  len2 REAL;
  prod REAL;
BEGIN
  SELECT INTO len1 vec_length FROM etvsm.document_model_pc WHERE doc_id=doc1_id;
  SELECT INTO len2 vec_length FROM etvsm.document_model_pc WHERE doc_id=doc2_id;
  
  SELECT INTO prod SUM(t1.weight*t2.weight*t3.sim)
  FROM etvsm.document_model t1, etvsm.document_model t2, etvsm_ontology.isim t3
  WHERE t1.doc_id=doc1_id AND t2.doc_id=doc2_id AND t3.inter1=t1.inter_id AND t3.inter2=t2.inter_id;
  
  RETURN prod/(len1*len2);
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: support_terms(integer, integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION support_terms(integer, integer) RETURNS SETOF integer
    AS $_$
DECLARE
  t_id ALIAS FOR $1;
  i_id ALIAS FOR $2;
  occ RECORD;
BEGIN
  IF EXISTS (SELECT * FROM etvsm_ontology.tmap WHERE term_id=t_id AND inter_id=i_id) THEN
  FOR occ IN
    SELECT term_id AS id FROM (
    (SELECT term_id FROM etvsm_ontology.tmap WHERE inter_id=i_id)
    UNION
    (SELECT term_id FROM etvsm_ontology.imap, etvsm_ontology.tmap WHERE imap.inter_id=tmap.inter_id AND topic_id IN (SELECT topic_id FROM etvsm_ontology.imap WHERE inter_id=i_id))
    UNION
    (SELECT term_id FROM etvsm_ontology.imap, etvsm_ontology.tmap WHERE imap.inter_id=tmap.inter_id AND topic_id IN (SELECT parent_id FROM etvsm_ontology.map WHERE child_id IN (SELECT topic_id FROM etvsm_ontology.imap WHERE inter_id=i_id)))
    UNION
    (SELECT term_id FROM etvsm_ontology.imap, etvsm_ontology.tmap WHERE imap.inter_id=tmap.inter_id AND topic_id IN (SELECT child_id FROM etvsm_ontology.map WHERE parent_id IN (SELECT parent_id FROM etvsm_ontology.map WHERE child_id IN (SELECT topic_id FROM etvsm_ontology.imap WHERE inter_id=i_id))))
    ) AS t
  LOOP
    IF (occ.id!=t_id) THEN
      RETURN NEXT occ.id;
    END IF;
  END LOOP;
  END IF;
  
  RETURN;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: terms_to_inters(integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION terms_to_inters(integer) RETURNS SETOF integer
    AS $_$
--------------------------------------------------------------------------------
-- Get a set of inter''s from the document after preprocessing provided
--     document id
-- RETURN - set of interpretations in the order they appear in the document
-- NOTICE: support terms included - most common (if 0 - return ?inter?)!
--------------------------------------------------------------------------------
-- bottle neck
DECLARE
  d_id ALIAS FOR $1;
  occ RECORD;
  occ2 RECORD;
  inter_ret INTEGER;
  def_inter_id INTEGER;
  term_cur INTEGER;
  term_n INTEGER;
  last_id INTEGER;
  temp TEXT;
  c INTEGER;
  c1 INTEGER;
  m INTEGER;
  mc INTEGER;
  i INTEGER;
BEGIN
  inter_ret := NULL;
  term_cur := NULL;
  
  DELETE FROM etvsm.document_term WHERE doc_id = d_id;
  
  INSERT INTO etvsm.document_term (doc_id, term_id, nocc)
  SELECT d_id, words_to_terms.term_id, count(term_id)
  FROM etvsm.words_to_terms(d_id)
  GROUP BY words_to_terms.term_id;
  
  -- assign interpretations
  FOR occ IN
    SELECT term_id, nocc
    FROM etvsm.document_term
    WHERE doc_id = d_id
  LOOP
    m = NULL;
    inter_ret = NULL;
    FOR occ2 IN
      SELECT * FROM etvsm_ontology.tmap WHERE term_id = occ.term_id
    LOOP
      SELECT INTO mc sum(document_term.nocc)
      FROM etvsm.support_terms(occ2.term_id,occ2.inter_id), etvsm.document_term
      WHERE document_term.doc_id = d_id AND support_terms = document_term.term_id;
      
      SELECT INTO temp substr(word,1,1)
      FROM etvsm_ontology.interpretation, themis.word
      WHERE interpretation.name = word.id AND
      interpretation.id = occ2.inter_id;
      
      IF mc IS NULL THEN mc = 0; END IF;
      IF m IS NULL THEN m=0; inter_ret = occ2.inter_id; END IF;
      IF mc=m AND temp!='?' THEN inter_ret = occ2.inter_id; END IF;
      IF mc IS NOT NULL AND mc>m THEN m=mc; inter_ret = occ2.inter_id; END IF;

    END LOOP;
    
    UPDATE etvsm.document_term SET inter_id = inter_ret WHERE doc_id = d_id AND term_id = occ.term_id;
    FOR i IN 1..occ.nocc LOOP
      RETURN NEXT inter_ret;
    END LOOP;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: words_to_terms(integer); Type: FUNCTION; Schema: etvsm; Owner: -
--

CREATE FUNCTION words_to_terms(integer) RETURNS SETOF term_seq
    AS $_$
--------------------------------------------------------------------------------
-- Get a set of terms from the document after preprocessing provided document id
-- RETURN - set of term ids in the order they appear in the document
-- NEEDS TESTING !!!
--------------------------------------------------------------------------------
DECLARE
  doc_id ALIAS FOR $1;
  doc TEXT;
  occ RECORD;
  occ2 RECORD;
  term_id INTEGER;
  t INTEGER[];
  i INTEGER;
  j INTEGER;
  k INTEGER;
  m INTEGER;
  do_ret BOOLEAN;
  cmp INTEGER;
  ret etvsm.term_seq;
  words INTEGER[];
BEGIN
  i = 1;
  j = 1;
  k = 1;
  
  SELECT INTO doc doc_text FROM etvsm.document WHERE id = doc_id;
  FOR occ IN
    SELECT themis.add_word(preprocess) AS word_id FROM etvsm.preprocess(doc)
  LOOP
    words[i] = occ.word_id;
    i = i+1;
  END LOOP;
  
  WHILE k <= COALESCE(array_upper(words,1),-1) LOOP
    do_ret = false;
    FOR occ2 IN
      SELECT * FROM etvsm_ontology.term WHERE term[1] = words[k] ORDER BY term ASC
    LOOP
      cmp = etvsm.array_compare(occ2.term,words,k);
      IF cmp=0 OR cmp=1 THEN
        term_id = occ2.id;
        t = occ2.term;
        do_ret = true;
      END IF;
    END LOOP;
    
    IF do_ret THEN
    BEGIN
      ret.term_id = term_id;
      ret.seq = j;
      k = k + COALESCE(array_upper(t,1),1);
      IF COALESCE(array_upper(t,1),1)=1 THEN
        IF NOT EXISTS (SELECT * FROM etvsm.stopword WHERE word_id=t[1]) THEN
          j = j+1;
          RETURN NEXT ret;
        END IF;
      ELSE
        j = j+1;
        RETURN NEXT ret;
      END IF;
    END;
    ELSE
    BEGIN
      k = k + 1;
    END;
    END IF;
  END LOOP;

END;
$_$
    LANGUAGE plpgsql;


SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: config; Type: TABLE; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE TABLE config (
    name character varying(32) NOT NULL,
    value character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: document_id_seq; Type: SEQUENCE; Schema: etvsm; Owner: -
--

CREATE SEQUENCE document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: document_id_seq; Type: SEQUENCE SET; Schema: etvsm; Owner: -
--

SELECT pg_catalog.setval('document_id_seq', 1, false);


SET default_with_oids = false;

--
-- Name: document; Type: TABLE; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE TABLE document (
    id integer DEFAULT nextval('document_id_seq'::regclass) NOT NULL,
    uri text NOT NULL,
    doc_text text NOT NULL,
    is_query boolean DEFAULT false NOT NULL,
    last_update timestamp(0) with time zone DEFAULT now() NOT NULL
);


--
-- Name: document_model; Type: TABLE; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE TABLE document_model (
    doc_id integer NOT NULL,
    inter_id integer NOT NULL,
    weight real NOT NULL,
    nocc integer DEFAULT 0 NOT NULL
);


SET default_with_oids = true;

--
-- Name: document_model_pc; Type: TABLE; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE TABLE document_model_pc (
    doc_id integer NOT NULL,
    vec_length real DEFAULT 1 NOT NULL
);


SET default_with_oids = false;

--
-- Name: document_term; Type: TABLE; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE TABLE document_term (
    doc_id integer NOT NULL,
    term_id integer NOT NULL,
    inter_id integer,
    nocc integer
);


SET default_with_oids = true;

--
-- Name: stopword; Type: TABLE; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE TABLE stopword (
    word_id integer NOT NULL
);


--
-- Data for Name: config; Type: TABLE DATA; Schema: etvsm; Owner: -
--

INSERT INTO config VALUES ('stemmer', '');


--
-- Data for Name: document; Type: TABLE DATA; Schema: etvsm; Owner: -
--



--
-- Data for Name: document_model; Type: TABLE DATA; Schema: etvsm; Owner: -
--



--
-- Data for Name: document_model_pc; Type: TABLE DATA; Schema: etvsm; Owner: -
--



--
-- Data for Name: document_term; Type: TABLE DATA; Schema: etvsm; Owner: -
--



--
-- Data for Name: stopword; Type: TABLE DATA; Schema: etvsm; Owner: -
--



--
-- Name: config_pkey; Type: CONSTRAINT; Schema: etvsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (name);


--
-- Name: document_model_idx; Type: CONSTRAINT; Schema: etvsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document_model
    ADD CONSTRAINT document_model_idx PRIMARY KEY (doc_id, inter_id);


--
-- Name: document_model_pc_pkey; Type: CONSTRAINT; Schema: etvsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document_model_pc
    ADD CONSTRAINT document_model_pc_pkey PRIMARY KEY (doc_id);


--
-- Name: document_pkey; Type: CONSTRAINT; Schema: etvsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);


--
-- Name: document_url_key; Type: CONSTRAINT; Schema: etvsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document
    ADD CONSTRAINT document_url_key UNIQUE (uri);


--
-- Name: stopword_pkey; Type: CONSTRAINT; Schema: etvsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stopword
    ADD CONSTRAINT stopword_pkey PRIMARY KEY (word_id);


--
-- Name: document_idx; Type: INDEX; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE INDEX document_idx ON document USING btree (is_query);


--
-- Name: document_idx1; Type: INDEX; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE INDEX document_idx1 ON document USING btree (last_update);


--
-- Name: document_term_idx; Type: INDEX; Schema: etvsm; Owner: -; Tablespace: 
--

CREATE INDEX document_term_idx ON document_term USING btree (doc_id, term_id);


--
-- Name: document_model_fk; Type: FK CONSTRAINT; Schema: etvsm; Owner: -
--

ALTER TABLE ONLY document_model
    ADD CONSTRAINT document_model_fk FOREIGN KEY (doc_id) REFERENCES document(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: document_model_pc_fk; Type: FK CONSTRAINT; Schema: etvsm; Owner: -
--

ALTER TABLE ONLY document_model_pc
    ADD CONSTRAINT document_model_pc_fk FOREIGN KEY (doc_id) REFERENCES document(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: document_term_fk; Type: FK CONSTRAINT; Schema: etvsm; Owner: -
--

ALTER TABLE ONLY document_term
    ADD CONSTRAINT document_term_fk FOREIGN KEY (doc_id) REFERENCES document(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

