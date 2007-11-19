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

--
-- PostgreSQL database dump
--

SET client_encoding = 'SQL_ASCII';
SET standard_conforming_strings = off;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET escape_string_warning = off;

--
-- Name: vsm; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA vsm;


SET search_path = vsm, pg_catalog;

--
-- Name: add_document(text, text, boolean); Type: FUNCTION; Schema: vsm; Owner: -
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
  SELECT INTO document_id id FROM vsm.document WHERE is_query=is_q AND uri=url;
  IF document_id IS NULL THEN
    INSERT INTO vsm.document (uri, doc_text, is_query, last_update)
    VALUES (url, trim(both ' ' FROM doc), is_q, now());

    document_id = currval('vsm.document_id_seq'::regclass);
  ELSE
    UPDATE vsm.document SET doc_text = trim(both ' ' FROM doc), last_update = NOW() WHERE id = document_id;
  END IF;
  
  PERFORM vsm.add_document_model(document_id);
  
  RETURN document_id;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: add_document_model(integer); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION add_document_model(integer) RETURNS integer
    AS $_$
DECLARE
  did ALIAS FOR $1;
  document_text TEXT;
  vlength REAL;
BEGIN
  SELECT INTO document_text doc_text FROM vsm.document WHERE id = did;
  -- update model
  DELETE FROM vsm.document_model WHERE doc_id=did;
  DELETE FROM vsm.document_model_pc WHERE doc_id=did;

  -- stopword removal and lowercasing included
  INSERT INTO vsm.document_model (doc_id, word_id, weight, nocc)
  SELECT
    did AS doc_id,
    themis.add_word(preprocess) AS word_id,
    count(preprocess) AS weight,
    count(preprocess) AS nocc
  FROM
    vsm.preprocess(document_text)
  GROUP BY preprocess;

  -- update doc vector lengt data
  SELECT INTO vlength SQRT(SUM(weight*weight)) FROM vsm.document_model WHERE doc_id = did GROUP BY doc_id;
  IF vlength IS NULL THEN vlength = 1.0; END IF;
  
  INSERT INTO vsm.document_model_pc (doc_id, vec_length) VALUES (did,vlength);
  
  RETURN did;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: add_query(text); Type: FUNCTION; Schema: vsm; Owner: -
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
  SELECT INTO query_id id FROM vsm.document WHERE is_query=true AND uri=query;

  IF query_id IS NULL THEN
    query_id = vsm.add_document(query,query,true);
  END IF;

  RETURN query_id;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: add_stopword(character varying); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION add_stopword(character varying) RETURNS integer
    AS $_$
DECLARE
  sw ALIAS FOR $1;
  wid INTEGER;
BEGIN
  wid = themis.add_word(sw);
  INSERT INTO vsm.stopword (word_id) VALUES (wid);
  
  RETURN wid;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: add_word_stats(); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION add_word_stats() RETURNS "trigger"
    AS $$
DECLARE
  n INTEGER;
BEGIN
  SELECT INTO n nocc FROM vsm.word_stats WHERE word_id = NEW.word_id;
  IF n IS NULL THEN
    INSERT INTO vsm.word_stats (word_id,nocc) VALUES (NEW.word_id,NEW.nocc);
  ELSE
    UPDATE vsm.word_stats SET nocc=nocc+NEW.nocc WHERE word_id=NEW.word_id;
  END IF;

  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: clear(); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION clear() RETURNS integer
    AS $$
--------------------------------------------------------------------------------
-- Clear VSM database
-- Reset sequence to start from 1
-- RETURN - always 1
--------------------------------------------------------------------------------
BEGIN
  DELETE FROM vsm.document;
  DELETE FROM vsm.stopword;
  DELETE FROM vsm.word_stats;

  ALTER SEQUENCE "vsm"."document_id_seq"
    INCREMENT 1  MINVALUE 1
    MAXVALUE 9223372036854775807  RESTART 1
    CACHE 1  NO CYCLE;

  RETURN 1;
END;
$$
    LANGUAGE plpgsql STRICT;


--
-- Name: del_document_by_id(integer); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION del_document_by_id(integer) RETURNS integer
    AS $_$
DECLARE
  did ALIAS FOR $1;
BEGIN
  DELETE FROM vsm.document WHERE id = did;

  RETURN did;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: del_document_by_uri(text, boolean); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION del_document_by_uri(text, boolean) RETURNS integer
    AS $_$
DECLARE
  url ALIAS FOR $1;
  is_q ALIAS FOR $2;
  did INTEGER;
BEGIN
  SELECT INTO did id FROM vsm.document WHERE uri = url;
  DELETE FROM vsm.document WHERE id = did;

  RETURN did;
END
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: del_word_stats(); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION del_word_stats() RETURNS "trigger"
    AS $$
DECLARE
  n INTEGER;
BEGIN
  UPDATE vsm.word_stats SET nocc = nocc-OLD.nocc WHERE word_id=OLD.word_id;

  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: preprocess(text); Type: FUNCTION; Schema: vsm; Owner: -
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
    WHERE doc_to_words NOT IN (SELECT t1.word FROM themis.word t1,vsm.stopword t2 WHERE t1.id=t2.word_id)
  LOOP
    -- do preprocessing in model specific order

    -- stemming
    SELECT INTO param value FROM vsm.config WHERE name = 'stemmer';
    IF param = 'porter' THEN
      pw = stemmer.stem(occ.w);
    ELSE
      pw = occ.w;
    END IF;
    
    -- casing
    SELECT INTO param value FROM vsm.config WHERE name = 'casing';
    IF param = 'lower' THEN
      pw = LOWER(pw);
    ELSIF param = 'upper' THEN
      pw = UPPER(pw);
    END IF;
    
    RETURN NEXT pw;
  END LOOP;
  
  RETURN;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: search(text, integer, integer); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION search(text, integer, integer) RETURNS SETOF themis.search_result
    AS $_$
------------------------------------------------------------
-- get ordered similarities for all the documents
------------------------------------------------------------
DECLARE
  doc ALIAS FOR $1;
  num ALIAS FOR $2;
  first ALIAS FOR $3;
  occ RECORD;
  q_id INTEGER;
  result themis.search_result;
BEGIN
  q_id = vsm.add_query(doc);
  
  FOR occ IN
    SELECT t.id, t.uri, (v.product/t1.vec_length/t2.vec_length) AS s
    FROM
      vsm.document_product AS v,
      vsm.document_model_pc AS t1,
      vsm.document_model_pc AS t2,
      vsm.document AS t
    WHERE
      v.doc1_id = q_id AND
      v.doc2_id = t.id AND
      t.is_query = false AND
      t1.doc_id=q_id AND
      t2.doc_id=t.id
    ORDER BY s DESC
    LIMIT num OFFSET first
  LOOP
    -- prepare result
    result.doc_id = occ.id;
    result.uri = occ.uri;
    result.sim = occ.s;
    RETURN NEXT result;
  END LOOP;
  
  RETURN;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: search_full(text, integer, integer); Type: FUNCTION; Schema: vsm; Owner: -
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
        vsm.search(q,num,first) t1,
        vsm.document t2
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
-- Name: search_intro(text, integer, integer); Type: FUNCTION; Schema: vsm; Owner: -
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
        vsm.search(q,num,first) t1,
        vsm.document t2
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
-- Name: sim(integer, integer); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION sim(integer, integer) RETURNS real
    AS $_$
------------------------------------------------------------
-- return VSM document similarity
------------------------------------------------------------
DECLARE
  doc1_id ALIAS FOR $1;
  doc2_id ALIAS FOR $2;
  result REAL;
BEGIN
  -- get similarity
  SELECT INTO result (v.product/t1.vec_length/t2.vec_length)
  FROM
    vsm.document_product AS v,
    vsm.document_model_pc AS t1,
    vsm.document_model_pc AS t2
  WHERE
    v.doc1_id=doc1_id AND
    v.doc2_id=doc2_id AND
    t1.doc_id=v.doc1_id AND
    t2.doc_id=v.doc2_id;

  RETURN result;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: upd_word_stats(); Type: FUNCTION; Schema: vsm; Owner: -
--

CREATE FUNCTION upd_word_stats() RETURNS "trigger"
    AS $$
DECLARE
  n INTEGER;
BEGIN
  UPDATE vsm.word_stats SET nocc = nocc+(NEW.nocc-OLD.nocc) WHERE word_id=OLD.word_id;

  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: config; Type: TABLE; Schema: vsm; Owner: -; Tablespace: 
--

CREATE TABLE config (
    name character varying(32) NOT NULL,
    value character varying(32) DEFAULT ''::character varying NOT NULL
);


--
-- Name: document_id_seq; Type: SEQUENCE; Schema: vsm; Owner: -
--

CREATE SEQUENCE document_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: document_id_seq; Type: SEQUENCE SET; Schema: vsm; Owner: -
--

SELECT pg_catalog.setval('document_id_seq', 1, false);


SET default_with_oids = false;

--
-- Name: document; Type: TABLE; Schema: vsm; Owner: -; Tablespace: 
--

CREATE TABLE document (
    id integer DEFAULT nextval('document_id_seq'::regclass) NOT NULL,
    uri text NOT NULL,
    doc_text text NOT NULL,
    is_query boolean DEFAULT false NOT NULL,
    last_update timestamp(0) with time zone DEFAULT now() NOT NULL
);


--
-- Name: document_model; Type: TABLE; Schema: vsm; Owner: -; Tablespace: 
--

CREATE TABLE document_model (
    doc_id integer NOT NULL,
    word_id integer NOT NULL,
    weight real NOT NULL,
    nocc integer DEFAULT 0 NOT NULL
);


SET default_with_oids = true;

--
-- Name: document_model_pc; Type: TABLE; Schema: vsm; Owner: -; Tablespace: 
--

CREATE TABLE document_model_pc (
    doc_id integer NOT NULL,
    vec_length real DEFAULT 1 NOT NULL
);


--
-- Name: document_product; Type: VIEW; Schema: vsm; Owner: -
--

CREATE VIEW document_product AS
    SELECT t1.doc_id AS doc1_id, t2.doc_id AS doc2_id, sum((t1.weight * t2.weight)) AS product FROM document_model t1, document_model t2 WHERE (t1.word_id = t2.word_id) GROUP BY t1.doc_id, t2.doc_id;


--
-- Name: stopword; Type: TABLE; Schema: vsm; Owner: -; Tablespace: 
--

CREATE TABLE stopword (
    word_id integer NOT NULL
);


--
-- Name: word_stats; Type: TABLE; Schema: vsm; Owner: -; Tablespace: 
--

CREATE TABLE word_stats (
    word_id integer NOT NULL,
    nocc integer DEFAULT 0 NOT NULL
);


--
-- Data for Name: config; Type: TABLE DATA; Schema: vsm; Owner: -
--

INSERT INTO config VALUES ('stemmer', 'porter');
INSERT INTO config VALUES ('casing', 'lower');


--
-- Data for Name: document; Type: TABLE DATA; Schema: vsm; Owner: -
--



--
-- Data for Name: document_model; Type: TABLE DATA; Schema: vsm; Owner: -
--



--
-- Data for Name: document_model_pc; Type: TABLE DATA; Schema: vsm; Owner: -
--



--
-- Data for Name: stopword; Type: TABLE DATA; Schema: vsm; Owner: -
--



--
-- Data for Name: word_stats; Type: TABLE DATA; Schema: vsm; Owner: -
--



--
-- Name: config_pkey; Type: CONSTRAINT; Schema: vsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY config
    ADD CONSTRAINT config_pkey PRIMARY KEY (name);


--
-- Name: document_model_idx; Type: CONSTRAINT; Schema: vsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document_model
    ADD CONSTRAINT document_model_idx PRIMARY KEY (doc_id, word_id);


--
-- Name: document_model_pc_pkey; Type: CONSTRAINT; Schema: vsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document_model_pc
    ADD CONSTRAINT document_model_pc_pkey PRIMARY KEY (doc_id);


--
-- Name: document_pkey; Type: CONSTRAINT; Schema: vsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY document
    ADD CONSTRAINT document_pkey PRIMARY KEY (id);


--
-- Name: stopword_pkey; Type: CONSTRAINT; Schema: vsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY stopword
    ADD CONSTRAINT stopword_pkey PRIMARY KEY (word_id);


--
-- Name: word_stats_pkey; Type: CONSTRAINT; Schema: vsm; Owner: -; Tablespace: 
--

ALTER TABLE ONLY word_stats
    ADD CONSTRAINT word_stats_pkey PRIMARY KEY (word_id);


--
-- Name: document_id_last_update; Type: INDEX; Schema: vsm; Owner: -; Tablespace: 
--

CREATE INDEX document_id_last_update ON document USING btree (last_update);


--
-- Name: document_idx_is_query; Type: INDEX; Schema: vsm; Owner: -; Tablespace: 
--

CREATE INDEX document_idx_is_query ON document USING btree (is_query);


--
-- Name: document_uri; Type: INDEX; Schema: vsm; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX document_uri ON document USING btree (uri);


--
-- Name: document_model_tr_add; Type: TRIGGER; Schema: vsm; Owner: -
--

CREATE TRIGGER document_model_tr_add
    AFTER INSERT ON document_model
    FOR EACH ROW
    EXECUTE PROCEDURE add_word_stats();


--
-- Name: document_model_tr_del; Type: TRIGGER; Schema: vsm; Owner: -
--

CREATE TRIGGER document_model_tr_del
    AFTER DELETE ON document_model
    FOR EACH ROW
    EXECUTE PROCEDURE del_word_stats();


--
-- Name: document_model_tr_upd; Type: TRIGGER; Schema: vsm; Owner: -
--

CREATE TRIGGER document_model_tr_upd
    AFTER UPDATE ON document_model
    FOR EACH ROW
    EXECUTE PROCEDURE upd_word_stats();


--
-- Name: document_model_fk; Type: FK CONSTRAINT; Schema: vsm; Owner: -
--

ALTER TABLE ONLY document_model
    ADD CONSTRAINT document_model_fk FOREIGN KEY (doc_id) REFERENCES document(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: document_model_pc_fk; Type: FK CONSTRAINT; Schema: vsm; Owner: -
--

ALTER TABLE ONLY document_model_pc
    ADD CONSTRAINT document_model_pc_fk FOREIGN KEY (doc_id) REFERENCES document(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

