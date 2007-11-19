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
-- Name: themis; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA themis;


SET search_path = themis, pg_catalog;

--
-- Name: search_result; Type: TYPE; Schema: themis; Owner: -
--

CREATE TYPE search_result AS (
	doc_id integer,
	uri text,
	sim real
);


--
-- Name: search_result_ext; Type: TYPE; Schema: themis; Owner: -
--

CREATE TYPE search_result_ext AS (
	doc_id integer,
	uri text,
	sim real,
	doc text
);


--
-- Name: add_word(character varying); Type: FUNCTION; Schema: themis; Owner: -
--

CREATE FUNCTION add_word(character varying) RETURNS integer
    AS $_$
DECLARE
  w ALIAS FOR $1;
  res INTEGER;
BEGIN
  res := NULL;
  
  SELECT INTO res id FROM themis.word WHERE word=w;
  IF res IS NULL THEN
    INSERT INTO themis.word (word) VALUES (w);
    res := currval('themis.word_id_seq'::regclass);
  END IF;

  RETURN res;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: doc_to_words(text); Type: FUNCTION; Schema: themis; Owner: -
--

CREATE FUNCTION doc_to_words(text) RETURNS SETOF text
    AS $_$
--------------------------------------------------------------------------------
-- Parse document text into the ordered array of words
-- Remove characters: . ! ? , : ; '
-- RETURN - array of lowercase words in the order they appear in the document
--------------------------------------------------------------------------------
DECLARE
  doc_original ALIAS FOR $1;
  doc TEXT;
  c TEXT;
  words TEXT[];
  i INTEGER;
BEGIN
  doc:='';
  -- replace punctuation
  FOR i IN 1 .. COALESCE(length(doc_original),-1) LOOP
    c := substring(doc_original from i for 1);
    IF position(c in '.,!?:;''"/\()&')=0 THEN
      doc := doc || c;
    END IF;
  END LOOP;

  words = string_to_array (trim(both ' ' FROM doc), ' ');

  FOR i IN COALESCE(array_lower(words,1),0) .. COALESCE(array_upper(words,1),-1) LOOP
    IF (words[i]!='') THEN
      RETURN NEXT words[i];
    END IF;
  END LOOP;

  RETURN;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: word_id_seq; Type: SEQUENCE; Schema: themis; Owner: -
--

CREATE SEQUENCE word_id_seq
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


SET default_tablespace = '';

SET default_with_oids = true;

--
-- Name: word; Type: TABLE; Schema: themis; Owner: -; Tablespace: 
--

CREATE TABLE word (
    id integer DEFAULT nextval('word_id_seq'::regclass) NOT NULL,
    word character varying(64) NOT NULL
);


--
-- Name: word_pkey; Type: CONSTRAINT; Schema: themis; Owner: -; Tablespace: 
--

ALTER TABLE ONLY word
    ADD CONSTRAINT word_pkey PRIMARY KEY (id);


--
-- Name: word_word_key; Type: CONSTRAINT; Schema: themis; Owner: -; Tablespace: 
--

ALTER TABLE ONLY word
    ADD CONSTRAINT word_word_key UNIQUE (word);


--
-- PostgreSQL database dump complete
--

