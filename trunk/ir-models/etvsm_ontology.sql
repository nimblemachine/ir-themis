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
-- Name: etvsm_ontology; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA etvsm_ontology;


SET search_path = etvsm_ontology, pg_catalog;

--
-- Name: clear(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION clear() RETURNS integer
    AS $$
BEGIN
  BEGIN
    DROP TRIGGER "imap_delete" ON "etvsm_ontology"."imap";
    DROP TRIGGER "imap_insert" ON "etvsm_ontology"."imap";
    DROP TRIGGER "map_delete" ON "etvsm_ontology"."map";
    DROP TRIGGER "map_insert" ON "etvsm_ontology"."map";
    DROP TRIGGER "topic_delete" ON "etvsm_ontology"."topic";
    DROP TRIGGER "topic_insert" ON "etvsm_ontology"."topic";
  EXCEPTION
    WHEN others THEN
  END;
  
  DELETE FROM etvsm_ontology.imap;
  DELETE FROM etvsm_ontology.tmap;
  DELETE FROM etvsm_ontology.map;
  DELETE FROM etvsm_ontology.term;
  DELETE FROM etvsm_ontology.vector;
  DELETE FROM etvsm_ontology.ivector;
  DELETE FROM etvsm_ontology.topic;
  DELETE FROM etvsm_ontology.map_type;
  DELETE FROM etvsm_ontology.isim;
  DELETE FROM etvsm_ontology.interpretation;
  
  
  ALTER SEQUENCE "etvsm_ontology"."map_type_id_seq"
    INCREMENT 1  MINVALUE 1
    MAXVALUE 9223372036854775807  RESTART 1
    CACHE 1  NO CYCLE;
    
  ALTER SEQUENCE "etvsm_ontology"."interpretation_id_seq"
    INCREMENT 1  MINVALUE 1
    MAXVALUE 9223372036854775807  RESTART 1
    CACHE 1  NO CYCLE;
    
  ALTER SEQUENCE "etvsm_ontology"."term_id_seq"
    INCREMENT 1  MINVALUE 1
    MAXVALUE 9223372036854775807  RESTART 1
    CACHE 1  NO CYCLE;
    
  ALTER SEQUENCE "etvsm_ontology"."topic_id_seq"
    INCREMENT 1  MINVALUE 1
    MAXVALUE 9223372036854775807  RESTART 1
    CACHE 1  NO CYCLE;
  
  RETURN 1;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: contains(integer[], integer, integer, integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION contains(integer[], integer, integer, integer) RETURNS boolean
    AS $_$
DECLARE
  arr ALIAS FOR $1;
  low ALIAS FOR $2;
  high ALIAS FOR $3;
  item ALIAS FOR $4;
  i INTEGER;
BEGIN
  FOR i IN REVERSE high .. low LOOP
    IF arr[i]=item THEN
      RETURN true;
    END IF;
  END LOOP;
  
  RETURN false;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: get_inter_vectors(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION get_inter_vectors() RETURNS integer
    AS $$
BEGIN
  PERFORM etvsm_ontology.ivector_update_only(id) FROM etvsm_ontology.interpretation;
  
  RETURN 1;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: get_isims(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION get_isims() RETURNS integer
    AS $$
BEGIN
  INSERT INTO etvsm_ontology.isim
    SELECT t1.inter_id AS inter1, t2.inter_id AS inter2, sum((t1.value * t2.value)) AS sim
    FROM etvsm_ontology.ivector t1, etvsm_ontology.ivector t2
    WHERE (t1.comp_id = t2.comp_id)
    GROUP BY t1.inter_id, t2.inter_id;
  
  RETURN 1;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: get_topic_vectors(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION get_topic_vectors() RETURNS integer
    AS $$
DECLARE
  occ RECORD;
  occ2 RECORD;
  occ3 RECORD;
  queue INTEGER[];
  top INTEGER;
  bot INTEGER;
  poped INTEGER;
  d REAL;
  c INTEGER;
BEGIN
  top=0;
  bot=0;
  
  -- initil load
  FOR occ IN
    SELECT id FROM etvsm_ontology.topic WHERE id NOT IN (SELECT parent_id FROM etvsm_ontology.map)
  LOOP
    DELETE FROM etvsm_ontology.vector WHERE topic_id = occ.id;
    INSERT INTO etvsm_ontology.vector (topic_id,comp_id,value) VALUES (occ.id,occ.id,1);
    INSERT INTO etvsm_ontology.vector (topic_id,comp_id,value)
    SELECT DISTINCT occ.id, topic_all_parents, 1 FROM etvsm_ontology.topic_all_parents(occ.id);
    -- normalize
    SELECT INTO c count(*) FROM etvsm_ontology.vector WHERE topic_id = occ.id;
    UPDATE etvsm_ontology.vector SET value = (1.0/SQRT(c)) WHERE topic_id = occ.id;
  
    FOR occ2 IN
      SELECT topic_parents AS parent_id FROM etvsm_ontology.topic_parents(occ.id)
    LOOP
      IF NOT etvsm_ontology.contains(queue,bot,top,occ2.parent_id) THEN
        queue[top] = occ2.parent_id;
        top = top + 1;
      END IF;
    END LOOP;
  END LOOP;
  
  -- main loop
  WHILE  bot<=top LOOP
    poped = queue[bot];
    bot = bot + 1;
    -- calculate
    DELETE FROM etvsm_ontology.vector WHERE topic_id = poped;
    INSERT INTO etvsm_ontology.vector (topic_id,comp_id,value)
    SELECT
      poped AS topic_id,
      comp_id,
      SUM(value)
    FROM etvsm_ontology.vector
    WHERE topic_id IN
      (SELECT topic_children FROM etvsm_ontology.topic_children(poped))
    GROUP BY comp_id;
    -- normalize
    SELECT INTO d SUM(value*value) FROM etvsm_ontology.vector WHERE topic_id = poped;
    UPDATE etvsm_ontology.vector SET value = (value/SQRT(d)) WHERE topic_id = poped;
    
    -- get next topics
    FOR occ3 IN
      SELECT topic_parents AS parent_id FROM etvsm_ontology.topic_parents(poped)
    LOOP
      IF NOT etvsm_ontology.contains(queue,bot,top,occ3.parent_id) THEN
        queue[top] = occ3.parent_id;
        top = top + 1;
      END IF;
    END LOOP;
  END LOOP;
  
  RETURN 1;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: imap_add(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION imap_add(text, text) RETURNS integer
    AS $_$
DECLARE
  topic ALIAS FOR $1;
  inter ALIAS FOR $2;
  t_id INTEGER;
  i_id INTEGER;
BEGIN
  t_id = etvsm_ontology.topic_add(topic, '');
  i_id = etvsm_ontology.interpretation_add(inter, '');

  IF EXISTS (SELECT * FROM etvsm_ontology.imap WHERE topic_id=t_id AND inter_id=i_id) THEN
    RETURN 0; -- map exists
  ELSE
    INSERT INTO etvsm_ontology.imap (topic_id, inter_id) VALUES (t_id, i_id);
    RETURN 1; -- map added
  END IF;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: imap_delete_trigger(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION imap_delete_trigger() RETURNS "trigger"
    AS $$
DECLARE
  i_id INTEGER;
BEGIN
  i_id = etvsm_ontology.ivector_update(OLD.inter_id);
  RETURN NULL;
END;
$$
    LANGUAGE plpgsql IMMUTABLE;


--
-- Name: imap_insert_trigger(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION imap_insert_trigger() RETURNS "trigger"
    AS $$
DECLARE
  i_id INTEGER;
BEGIN
  i_id = etvsm_ontology.ivector_update(NEW.inter_id);
  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: imap_remove(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION imap_remove(text, text) RETURNS integer
    AS $_$
DECLARE
  topic ALIAS FOR $1;
  inter ALIAS FOR $2;
BEGIN
  DELETE FROM etvsm_ontology.imap
  WHERE
    topic_id=(SELECT id FROM etvsm_ontology.topic WHERE name=(SELECT id FROM themis.word WHERE word=topic)) AND
    inter_id=(SELECT id FROM etvsm_ontology.interpretation WHERE name=(SELECT id FROM themis.word WHERE word=inter));

  RETURN 0;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: interpretation_add(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION interpretation_add(text, text) RETURNS integer
    AS $_$
DECLARE
  inter ALIAS FOR $1;
  description ALIAS FOR $2;
  w_id INTEGER;
  res INTEGER;
BEGIN
  SELECT INTO w_id themis.add_word(inter);

  SELECT INTO res id FROM etvsm_ontology.interpretation WHERE name=w_id;
  IF res IS NULL THEN
    INSERT INTO etvsm_ontology.interpretation (name, descr) VALUES (w_id, description);
    res = currval('etvsm_ontology.interpretation_id_seq'::regclass);
  END IF;

  RETURN res;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: interpretation_remove(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION interpretation_remove(text) RETURNS integer
    AS $_$
DECLARE
  inter ALIAS FOR $1;
  w_id INTEGER;
  i_id INTEGER;
  res INTEGER;
BEGIN
  SELECT INTO i_id id FROM etvsm_ontology.interpretation WHERE name=themis.add_word(inter);

  DELETE FROM etvsm_ontology.imap WHERE inter_id = i_id;
  DELETE FROM etvsm_ontology.interpretation WHERE id = i_id;

  RETURN i_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: isim_update(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION isim_update(integer) RETURNS integer
    AS $_$
DECLARE
  iid ALIAS FOR $1;
BEGIN
  DELETE FROM etvsm_ontology.isim WHERE inter1 = iid;
  DELETE FROM etvsm_ontology.isim WHERE inter2 = iid;
  
  INSERT INTO etvsm_ontology.isim
  (SELECT t1.inter_id AS inter1, t2.inter_id AS inter2, sum((t1.value * t2.value)) AS sim
  FROM etvsm_ontology.ivector t1, etvsm_ontology.ivector t2
  WHERE (t1.comp_id = t2.comp_id AND t1.inter_id=iid)
  GROUP BY t1.inter_id, t2.inter_id);
  
  INSERT INTO etvsm_ontology.isim
  (SELECT t1.inter_id AS inter1, t2.inter_id AS inter2, sum((t1.value * t2.value)) AS sim
  FROM etvsm_ontology.ivector t1, etvsm_ontology.ivector t2
  WHERE (t1.comp_id = t2.comp_id AND t2.inter_id=iid AND t1.inter_id!=t2.inter_id)
  GROUP BY t1.inter_id, t2.inter_id);
  
  RETURN iid;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: isims_auto(boolean); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION isims_auto(boolean) RETURNS integer
    AS $_$
DECLARE
  do_auto ALIAS FOR $1;
BEGIN
  IF do_auto THEN
    BEGIN
      CREATE TRIGGER "imap_delete" AFTER DELETE
      ON "etvsm_ontology"."imap" FOR EACH ROW
      EXECUTE PROCEDURE "etvsm_ontology"."imap_delete_trigger"();
    
      CREATE TRIGGER "imap_insert" AFTER INSERT
      ON "etvsm_ontology"."imap" FOR EACH ROW
      EXECUTE PROCEDURE "etvsm_ontology"."imap_insert_trigger"();

      CREATE TRIGGER "map_delete" AFTER DELETE
      ON "etvsm_ontology"."map" FOR EACH ROW
      EXECUTE PROCEDURE "etvsm_ontology"."map_delete_trigger"();

      CREATE TRIGGER "map_insert" AFTER INSERT
      ON "etvsm_ontology"."map" FOR EACH ROW
      EXECUTE PROCEDURE "etvsm_ontology"."map_insert_trigger"();

      CREATE TRIGGER "topic_delete" AFTER DELETE
      ON "etvsm_ontology"."topic" FOR EACH ROW
      EXECUTE PROCEDURE "etvsm_ontology"."topic_delete_trigger"();

      CREATE TRIGGER "topic_insert" AFTER INSERT
      ON "etvsm_ontology"."topic" FOR EACH ROW
      EXECUTE PROCEDURE "etvsm_ontology"."topic_insert_trigger"();
    EXCEPTION
      WHEN others THEN
    END;
  ELSE
    BEGIN
      DROP TRIGGER "imap_delete" ON "etvsm_ontology"."imap";
      DROP TRIGGER "imap_insert" ON "etvsm_ontology"."imap";
      DROP TRIGGER "map_delete" ON "etvsm_ontology"."map";
      DROP TRIGGER "map_insert" ON "etvsm_ontology"."map";
      DROP TRIGGER "topic_delete" ON "etvsm_ontology"."topic";
      DROP TRIGGER "topic_insert" ON "etvsm_ontology"."topic";
    EXCEPTION
      WHEN others THEN
    END;
  END IF;
  
  RETURN 1;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: isims_update(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION isims_update() RETURNS integer
    AS $$
BEGIN
  DELETE FROM etvsm_ontology.isim;
  DELETE FROM etvsm_ontology.vector;
  DELETE FROM etvsm_ontology.ivector;
  
  PERFORM etvsm_ontology.get_topic_vectors();
  PERFORM etvsm_ontology.get_inter_vectors();
  PERFORM etvsm_ontology.get_isims();
  
  RETURN 1;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: itopic_add(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION itopic_add(text, text) RETURNS integer
    AS $_$
DECLARE
  t ALIAS FOR $1;
  d ALIAS FOR $2;
  t_id INTEGER;
  i_id INTEGER;
BEGIN
  t_id = etvsm_ontology.topic_add(t,d);
  i_id = etvsm_ontology.interpretation_add(t,d);
  i_id = etvsm_ontology.imap_add(t,t);

  RETURN t_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: itopic_remove(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION itopic_remove(text) RETURNS integer
    AS $_$
DECLARE
  t ALIAS FOR $1;
  t_id INTEGER;
  i_id INTEGER;
BEGIN
  i_id = etvsm_ontology.imap_remove(t,t);
  i_id = etvsm_ontology.interpretation_remove(t);
  t_id = etvsm_ontology.topic_remove(t);

  RETURN t_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: ivector_update(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION ivector_update(integer) RETURNS integer
    AS $_$
DECLARE
  i_id ALIAS FOR $1;
  len REAL;
  id INTEGER;
BEGIN
  -- !!! interpretation weights are 1s
  -- clear old interpretation vector data
  DELETE FROM etvsm_ontology.ivector WHERE inter_id=i_id;

  -- insert sum of all connected topic vectors
  INSERT INTO etvsm_ontology.ivector (inter_id,comp_id,value)
    SELECT
      i_id,
      comp_id,
      SUM(value)
    FROM etvsm_ontology.vector
    WHERE topic_id IN
      (SELECT topic_id FROM etvsm_ontology.imap WHERE inter_id=i_id)
    GROUP BY comp_id;

  -- get interpretation vector length
  SELECT INTO len sqrt(sum(value*value))
  FROM etvsm_ontology.ivector
  WHERE inter_id=i_id;

  -- normalize
  UPDATE etvsm_ontology.ivector
  SET value = value/len
  WHERE inter_id=i_id;
  
  id = etvsm_ontology.isim_update(i_id);

  RETURN i_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: ivector_update_only(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION ivector_update_only(integer) RETURNS integer
    AS $_$
DECLARE
  i_id ALIAS FOR $1;
  len REAL;
  id INTEGER;
BEGIN
  -- !!! interpretation weights are 1s
  -- clear old interpretation vector data
  DELETE FROM etvsm_ontology.ivector WHERE inter_id=i_id;

  -- insert sum of all connected topic vectors
  INSERT INTO etvsm_ontology.ivector (inter_id,comp_id,value)
    SELECT
      i_id,
      comp_id,
      SUM(value)
    FROM etvsm_ontology.vector
    WHERE topic_id IN
      (SELECT topic_id FROM etvsm_ontology.imap WHERE inter_id=i_id)
    GROUP BY comp_id;

  -- get interpretation vector length
  SELECT INTO len sqrt(sum(value*value))
  FROM etvsm_ontology.ivector
  WHERE inter_id=i_id;

  -- normalize
  UPDATE etvsm_ontology.ivector
  SET value = value/len
  WHERE inter_id=i_id;

  RETURN i_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: map_add(text, text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION map_add(text, text, text) RETURNS integer
    AS $_$
DECLARE
  p_topic ALIAS FOR $1;
  c_topic ALIAS FOR $2;
  card ALIAS FOR $3;
  p_id INTEGER;
  c_id INTEGER;
  cc_id INTEGER;
BEGIN
  p_id = etvsm_ontology.topic_add(p_topic, '');
  c_id = etvsm_ontology.topic_add(c_topic, '');
  cc_id = etvsm_ontology.map_type_add(card, '');
  
  IF EXISTS (SELECT * FROM etvsm_ontology.map WHERE parent_id=p_id AND child_id=c_id) THEN
    UPDATE etvsm_ontology.map SET card_id=cc_id WHERE parent_id=p_id AND child_id=c_id;
    RETURN 0;
  ELSE
    -- cyclic topic map gateway
    IF c_id IN (SELECT * FROM etvsm_ontology.topic_all_parents(p_id)) THEN
      RETURN -1; -- cyclic check positive
    END IF;
    -- insert
    INSERT INTO etvsm_ontology.map (parent_id, child_id,card_id) VALUES (p_id,c_id,cc_id);
    RETURN 1;
  END IF;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: map_delete_trigger(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION map_delete_trigger() RETURNS "trigger"
    AS $$
DECLARE
  t_id INTEGER;
BEGIN
  t_id = etvsm_ontology.topic_vector_update(OLD.parent_id);
  t_id = etvsm_ontology.topic_vector_update(OLD.child_id);
  RETURN NULL;
END;
$$
    LANGUAGE plpgsql IMMUTABLE;


--
-- Name: map_insert_trigger(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION map_insert_trigger() RETURNS "trigger"
    AS $$
DECLARE
  t_id INTEGER;
BEGIN
  t_id = etvsm_ontology.topic_vector_update(NEW.parent_id);
  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: map_remove(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION map_remove(text, text) RETURNS integer
    AS $_$
DECLARE
  p_topic ALIAS FOR $1;
  c_topic ALIAS FOR $2;
BEGIN
  DELETE FROM etvsm_ontology.map
  WHERE
    parent_id=(SELECT id FROM etvsm_ontology.topic WHERE name=(SELECT id FROM themis.word WHERE word=p_topic)) AND
    child_id=(SELECT id FROM etvsm_ontology.topic WHERE name=(SELECT id FROM themis.word WHERE word=c_topic));

  RETURN 1;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: map_type_add(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION map_type_add(text, text) RETURNS integer
    AS $_$
DECLARE
  ctag ALIAS FOR $1;
  description ALIAS FOR $2;
  res INTEGER;
BEGIN
  SELECT INTO res id FROM etvsm_ontology.map_type WHERE tag=ctag;
  IF res IS NULL THEN
    INSERT INTO etvsm_ontology.map_type (tag, descr) VALUES (ctag, description);
    res = currval('etvsm_ontology.map_type_id_seq'::regclass);
  END IF;
  
  RETURN res;
  
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: map_type_remove(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION map_type_remove(text) RETURNS integer
    AS $_$
DECLARE
  t ALIAS FOR $1;
  c_id INTEGER;
BEGIN
  SELECT INTO c_id id FROM etvsm_ontology.map_type WHERE LOWER(tag)=LOWER(t);
  DELETE FROM etvsm_ontology.map_type WHERE id = c_id;

  RETURN c_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: preprocess_smart(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION preprocess_smart(text) RETURNS SETOF text
    AS $_$
--------------------------------------------------------------------------------
-- Do document preprocessing
-- Currently supported (in order of appllicability):
--   - stopword removal
--   - lowercasing
-- RETURN - set of word ids after preprocessing (stopward+stemming)
--------------------------------------------------------------------------------
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  stem TEXT;
  temp INTEGER;
BEGIN
  FOR occ IN
    SELECT doc_to_words AS word FROM themis.doc_to_words(doc)
  LOOP
    --IF NOT EXISTS (SELECT * FROM etvsm_ontology.stopword WHERE word_id = (SELECT id FROM themis.word WHERE word=occ.word)) THEN
      stem := stemmer.smart_stem(LOWER(occ.word));
      --stem := occ.word;
      PERFORM themis.add_word(stem);
      RETURN NEXT stem;
    --END IF;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: preprocess_smart_sw(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION preprocess_smart_sw(text) RETURNS SETOF text
    AS $_$
--------------------------------------------------------------------------------
-- Do document preprocessing
-- Currently supported (in order of appllicability):
--   - stopword removal
--   - lowercasing
-- RETURN - set of word ids after preprocessing (stopward+stemming)
--------------------------------------------------------------------------------
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  stem TEXT;
  temp INTEGER;
BEGIN
  FOR occ IN
    SELECT doc_to_words AS word FROM themis.doc_to_words(doc)
  LOOP
    IF NOT EXISTS (SELECT * FROM etvsm_ontology.stopword WHERE word_id = (SELECT id FROM themis.word WHERE word=occ.word)) THEN
      stem := stemmer.smart_stem(LOWER(occ.word));
      PERFORM themis.add_word(stem);
      RETURN NEXT stem;
    END IF;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: preprocess_sw(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION preprocess_sw(text) RETURNS SETOF text
    AS $_$
--------------------------------------------------------------------------------
-- Do document preprocessing
-- Currently supported (in order of appllicability):
--   - stopword removal
--   - lowercasing
-- RETURN - set of word ids after preprocessing (stopward+stemming)
--------------------------------------------------------------------------------
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  stem TEXT;
  temp INTEGER;
BEGIN
  FOR occ IN
    SELECT doc_to_words AS word FROM themis.doc_to_words(doc)
  LOOP
    IF NOT EXISTS (SELECT * FROM etvsm_ontology.stopword WHERE word_id = (SELECT id FROM themis.word WHERE value=occ.word)) THEN
      stem := stemmer.stem(LOWER(occ.word));
      PERFORM themis.add_word(stem);
      RETURN NEXT stem;
    END IF;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: stopword_add(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION stopword_add(text) RETURNS integer
    AS $_$
--------------------------------------------------------------------------------
-- Add stopword to the eTVSM database
-- RETURN - stopword id
--------------------------------------------------------------------------------
DECLARE
  word ALIAS FOR $1;
  w_id INTEGER;
BEGIN
  SELECT INTO w_id themis.add_word(word);

  IF NOT EXISTS (SELECT * FROM etvsm_ontology.stopword WHERE word_id=w_id) THEN
    INSERT INTO etvsm_ontology.stopword (word_id)
    VALUES (w_id);
  END IF;

  RETURN w_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: stopword_remove(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION stopword_remove(text) RETURNS integer
    AS $_$
DECLARE
  word ALIAS FOR $1;
  w_id INTEGER;
BEGIN
  SELECT INTO w_id themis.add_word(word);

  DELETE FROM etvsm_ontology.stopword WHERE word_id = w_id;

  RETURN w_id;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: term_add(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION term_add(text) RETURNS integer
    AS $_$
DECLARE
  term_str ALIAS FOR $1;
  term_str_lower TEXT;
  arrt TEXT[];
  arri INTEGER[];
  result INTEGER;
  i INTEGER;
BEGIN
  term_str_lower = LOWER(term_str);
  arrt = string_to_array (term_str_lower, ' ');

  FOR i IN COALESCE(array_lower(arrt,1),0) .. COALESCE(array_upper(arrt,1),-1) LOOP
    IF arrt[i]!='' THEN
      arri[i] = themis.add_word(arrt[i]);
    END IF;
  END LOOP;

  SELECT INTO result id FROM etvsm_ontology.term WHERE name = trim(both ' ' from term_str_lower);
  IF result IS NULL THEN
    INSERT INTO etvsm_ontology.term (name, term)
    VALUES (trim(both ' ' from term_str_lower), arri);
    result = currval('etvsm_ontology.term_id_seq'::regclass);
  END IF;
  
  RETURN result;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: term_remove(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION term_remove(text) RETURNS integer
    AS $_$
DECLARE
  term_str ALIAS FOR $1;
  term_str_lower TEXT;
  t_id INTEGER;
BEGIN
  term_str_lower = LOWER(term_str);
  
  SELECT INTO t_id id FROM etvsm_ontology.term WHERE name=trim(both ' ' from term_str_lower);
  DELETE FROM etvsm_ontology.term WHERE id = t_id;

  RETURN t_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: tmap_add(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION tmap_add(text, text) RETURNS integer
    AS $_$
DECLARE
  i ALIAS FOR $1;
  t ALIAS FOR $2;
  i_id INTEGER;
  t_id INTEGER;
BEGIN
  i_id = etvsm_ontology.interpretation_add(i, '');
  t_id = etvsm_ontology.term_add(t);

  IF EXISTS (SELECT * FROM etvsm_ontology.tmap WHERE inter_id=i_id AND term_id=t_id) THEN
    RETURN 0; -- tmap exists
  ELSE
    INSERT INTO etvsm_ontology.tmap (inter_id, term_id) VALUES (i_id, t_id);
    RETURN 1; -- tmap added
  END IF;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: tmap_remove(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION tmap_remove(text, text) RETURNS integer
    AS $_$
DECLARE
  i ALIAS FOR $1;
  t ALIAS FOR $2;
BEGIN
  DELETE FROM etvsm_ontology.tmap
  WHERE
    inter_id=(SELECT id FROM etvsm_ontology.interpretation WHERE name=(SELECT id FROM themis.word WHERE word=i)) AND
    term_id=(SELECT id FROM etvsm_ontology.term WHERE name=trim(both ' ' from LOWER(t)));

  RETURN 0;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_add(text, text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_add(text, text) RETURNS integer
    AS $_$
DECLARE
  topic ALIAS FOR $1;
  description ALIAS FOR $2;
  w_id INTEGER;
  res INTEGER;
BEGIN
  SELECT INTO w_id themis.add_word(topic);

  SELECT INTO res id FROM etvsm_ontology.topic WHERE name=w_id;
  IF res IS NULL THEN
    INSERT INTO etvsm_ontology.topic (name, descr) VALUES (w_id, description);
    res = currval('etvsm_ontology.topic_id_seq'::regclass);
  END IF;

  RETURN res;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_all_children(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_all_children(integer) RETURNS SETOF integer
    AS $_$
DECLARE
  topic_id ALIAS FOR $1;
  foo INTEGER;
  occ RECORD;
  stack INTEGER[];
  top INTEGER;
  poped INTEGER;
BEGIN
  top = 0;
  stack[top] = topic_id;
  top = 1;

  WHILE top > 0 LOOP
    poped = stack[top-1];
    top = top - 1;
    FOR occ IN
      SELECT * FROM etvsm_ontology.topic_children(poped) AS id
    LOOP
      foo = occ.id;
      RETURN NEXT foo;
      stack[top] = foo;
      top = top + 1;
    END LOOP;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql IMMUTABLE;


--
-- Name: topic_all_parents(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_all_parents(integer) RETURNS SETOF integer
    AS $_$
DECLARE
  topic_id ALIAS FOR $1;
  foo INTEGER;
  occ RECORD;
  stack INTEGER[];
  top INTEGER;
  poped INTEGER;
BEGIN
  top = 0;
  stack[top] = topic_id;
  top = 1;

  WHILE top > 0 LOOP
    poped = stack[top-1];
    top = top - 1;
    FOR occ IN
      SELECT * FROM etvsm_ontology.topic_parents(poped) AS id
    LOOP
      foo = occ.id;
      RETURN NEXT foo;
      stack[top] = foo;
      top = top + 1;
    END LOOP;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_children(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_children(integer) RETURNS SETOF integer
    AS $_$
DECLARE
  topic_id ALIAS FOR $1;
  foo INTEGER;
  occ RECORD;
BEGIN
  FOR occ IN
    SELECT child_id FROM etvsm_ontology.map WHERE parent_id=topic_id
  LOOP
    foo = occ.child_id;
    RETURN NEXT foo;
  END LOOP;
  RETURN;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_delete_trigger(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_delete_trigger() RETURNS "trigger"
    AS $$
BEGIN
  DELETE FROM etvsm_ontology.vector WHERE topic_id = OLD.id;
  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: topic_insert_trigger(); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_insert_trigger() RETURNS "trigger"
    AS $$
BEGIN
  -- insert unlinked topic
  INSERT INTO etvsm_ontology.vector
  VALUES (NEW.id, NEW.id, 1);

  RETURN NULL;
END;
$$
    LANGUAGE plpgsql;


--
-- Name: topic_ivector_update(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_ivector_update(text) RETURNS integer
    AS $_$
DECLARE
  t_id ALIAS FOR $1;
BEGIN
  PERFORM etvsm_ontology.ivector_update(inter_id) FROM etvsm_ontology.imap WHERE topic_id=t_id;
  RETURN 1;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_leaves(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_leaves(integer) RETURNS SETOF integer
    AS $_$
DECLARE
  topic_id ALIAS FOR $1;
  foo INTEGER;
  occ RECORD;
BEGIN
  FOR occ IN
    SELECT DISTINCT topic_all_children AS topic_leaves
    FROM etvsm_ontology.topic_all_children(topic_id)
    WHERE topic_all_children NOT IN
    (SELECT DISTINCT parent_id FROM etvsm_ontology.map)
    --ORDER BY topic_all_children ASC
  LOOP
    foo = occ.topic_leaves;
    RETURN NEXT foo;
  END LOOP;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_parents(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_parents(integer) RETURNS SETOF integer
    AS $_$
DECLARE
  topic_id ALIAS FOR $1;
  foo INTEGER;
  occ RECORD;
BEGIN
  FOR occ IN
    SELECT parent_id FROM etvsm_ontology.map WHERE child_id=topic_id
  LOOP
    foo = occ.parent_id;
    RETURN NEXT foo;
  END LOOP;
  RETURN;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_remove(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_remove(text) RETURNS integer
    AS $_$
DECLARE
  w ALIAS FOR $1;
  w_id INTEGER;
BEGIN
  SELECT INTO w_id themis.add_word(w);
  DELETE FROM etvsm_ontology.topic WHERE name = w_id;

  RETURN w_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: topic_vector_update(integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION topic_vector_update(integer) RETURNS integer
    AS $_$
DECLARE
  t_id ALIAS FOR $1;
  c INTEGER;
  d REAL;
  occ RECORD;
  queue INTEGER[];
  top INTEGER;
  bot INTEGER;
  poped INTEGER;
BEGIN
  top=0;
  bot=0;

  -- check if leave node
  IF NOT EXISTS (SELECT DISTINCT topic_all_children AS id FROM etvsm_ontology.topic_all_children(t_id)) THEN
    DELETE FROM etvsm_ontology.vector WHERE topic_id = t_id;
    INSERT INTO etvsm_ontology.vector VALUES (t_id, t_id, 1);
    --
    PERFORM etvsm_ontology.topic_ivector_update(t_id);
  END IF;

  -- calculate leave-nodes
  FOR occ IN
    SELECT DISTINCT topic_all_children AS id
    FROM etvsm_ontology.topic_all_children(t_id)
  LOOP
    queue[top] = occ.id;
    top = top + 1;
    DELETE FROM etvsm_ontology.vector WHERE topic_id = occ.id;
    INSERT INTO etvsm_ontology.vector (topic_id,comp_id,value)
      SELECT
        occ.id AS topic_id,
        topic_all_parents AS comp_id,
        1 AS value
      FROM etvsm_ontology.topic_all_parents(occ.id)
      GROUP BY topic_all_parents;
    INSERT INTO etvsm_ontology.vector (topic_id,comp_id,value) VALUES (occ.id, occ.id, 1);
    -- normalize
    SELECT INTO c count(*) FROM etvsm_ontology.vector WHERE topic_id = occ.id;
    UPDATE etvsm_ontology.vector SET value = (1.0/SQRT(c)) WHERE topic_id = occ.id;
    --
    PERFORM etvsm_ontology.topic_ivector_update(occ.id);
  END LOOP;

  -- calculate core_nodes
  WHILE  bot<=top LOOP
    poped = queue[bot];
    bot = bot + 1;
    FOR occ IN
      SELECT DISTINCT topic_parents AS id FROM etvsm_ontology.topic_parents(poped)
    LOOP
      queue[top] = occ.id;
      top = top + 1;
      DELETE FROM etvsm_ontology.vector WHERE topic_id = occ.id;
      INSERT INTO etvsm_ontology.vector (topic_id,comp_id,value)
        SELECT
          occ.id AS topic_id,
          comp_id,
          SUM(value)
        FROM etvsm_ontology.vector
        WHERE topic_id IN
          (SELECT topic_children FROM etvsm_ontology.topic_children(occ.id))
        GROUP BY comp_id;
      -- normalize
      SELECT INTO d SUM(value*value) FROM etvsm_ontology.vector WHERE topic_id = occ.id;
      UPDATE etvsm_ontology.vector SET value = (value/SQRT(d)) WHERE topic_id = occ.id;
      --
      PERFORM etvsm_ontology.topic_ivector_update(occ.id);
    END LOOP;
  END LOOP;

  RETURN t_id;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: wordnet_dump_doc_dummy(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_doc_dummy(text) RETURNS integer
    AS $_$
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  i INTEGER;
BEGIN
  i = 0;
  FOR occ IN
    SELECT preprocess FROM etvsm.preprocess(doc)
    GROUP BY preprocess
  LOOP
    PERFORM etvsm_ontology.wordnet_dump_word_dummy(occ.preprocess);
    i = i + 1;
  END LOOP;
  
  RETURN i;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_doc_syn(text, character); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_doc_syn(text, character) RETURNS integer
    AS $_$
DECLARE
  doc ALIAS FOR $1;
  x ALIAS FOR $2;
  occ RECORD;
  i INTEGER;
BEGIN
  i = 0;
  FOR occ IN
    SELECT preprocess FROM etvsm.preprocess(doc)
    GROUP BY preprocess
  LOOP
    PERFORM etvsm_ontology.wordnet_dump_word_syn(occ.preprocess,x);
    i = i + 1;
  END LOOP;

  RETURN i;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_doc_syn_nvsar(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_doc_syn_nvsar(text) RETURNS integer
    AS $_$
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  i INTEGER;
BEGIN
  i = 0;
  FOR occ IN
    SELECT preprocess FROM etvsm.preprocess(doc)
    GROUP BY preprocess
  LOOP
    PERFORM etvsm_ontology.wordnet_dump_word_syn_nvsar(occ.preprocess);
    i = i + 1;
  END LOOP;

  RETURN i;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_doc_synset_mf(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_doc_synset_mf(text) RETURNS integer
    AS $_$
DECLARE
  doc ALIAS FOR $1;
  occ RECORD;
  i INTEGER;
BEGIN
  i = 0;
  FOR occ IN
    SELECT preprocess FROM etvsm.preprocess(doc)
    GROUP BY preprocess
  LOOP
    PERFORM etvsm_ontology.wordnet_dump_synset_mf(occ.preprocess);
    i = i + 1;
  END LOOP;

  RETURN i;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_has_part(text, integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_has_part(text, integer) RETURNS integer
    AS $_$
DECLARE
  sid ALIAS FOR $1;
  n ALIAS FOR $2;
  occ RECORD;
  id INTEGER;
  i INTEGER;
  p_name TEXT;
  c_name TEXT;
  ssid TEXT;
  next_node INTEGER;
BEGIN
  ssid = sid;
  IF n<=0 THEN RETURN 1; END IF;

  FOR occ IN
    SELECT synset2id, definition, linkid
    FROM wordnet.semlinkref, wordnet.synset
    WHERE
      synset1id = ssid AND
      (linkid = 12 OR linkid = 14) AND
      synset2id = synsetid
  LOOP
    p_name = occ.synset2id;
    next_node = occ.synset2id;
    c_name = ssid;
    PERFORM etvsm_ontology.itopic_add(p_name, occ.definition);

    IF occ.linkid = 12 THEN
      id = etvsm_ontology.map_add(p_name, c_name,'HAS PART');
    ELSIF occ.linkid = 14 THEN
      id = etvsm_ontology.map_add(p_name,c_name,'HAS MEMBER');
    END IF;
    
    PERFORM etvsm_ontology.wordnet_dump_has_part(next_node,n-1);
  END LOOP;
  
  RETURN 1;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_is_a(text, integer); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_is_a(text, integer) RETURNS integer
    AS $_$
DECLARE
  sid ALIAS FOR $1;
  n ALIAS FOR $2;
  occ RECORD;
  id INTEGER;
  i INTEGER;
  p_name TEXT;
  c_name TEXT;
  ssid TEXT;
  next_node INTEGER;
BEGIN
  ssid = sid;
  IF n<=0 THEN RETURN 1; END IF;
  
  FOR occ IN
    SELECT synset2id, definition, linkid
    FROM wordnet.semlinkref, wordnet.synset
    WHERE
      synset1id = ssid AND
      (linkid = 1 OR linkid = 3) AND
      synset2id = synsetid
  LOOP
    p_name = occ.synset2id;
    next_node = occ.synset2id;
    c_name = ssid;
    PERFORM etvsm_ontology.itopic_add(p_name, occ.definition);
    IF occ.linkid = 1 THEN
      id = etvsm_ontology.map_add(p_name,c_name,'IS A');
    ELSIF occ.linkid = 3 THEN
      id = etvsm_ontology.map_add(p_name,c_name,'HAS INSTANCE');
    END IF;
      
    PERFORM etvsm_ontology.wordnet_dump_is_a(next_node,n-1);
  END LOOP;
  
  RETURN 1;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_synset_mf(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_synset_mf(text) RETURNS integer
    AS $_$
DECLARE
  word ALIAS FOR $1;
  occ RECORD;
  occ2 RECORD;
  occ3 RECORD;
  term_id INTEGER;
BEGIN
  IF EXISTS (SELECT * FROM etvsm_ontology.term WHERE name = word) THEN
    RETURN 0; -- this term is already inside
  END IF;

   IF NOT EXISTS (SELECT * FROM wordnet.word WHERE lemma = word) THEN
     PERFORM etvsm_ontology.wordnet_dump_word_dummy(word);
     RETURN -1; -- dummy ontology created
   END IF;

  FOR occ IN
    SELECT t.synsetid, t.definition
    FROM
    ((SELECT sense.synsetid, synset.definition, sense.rank, sense.tagcount
    FROM wordnet.sense, wordnet.word, wordnet.synset
    WHERE
      word.lemma = word AND
      sense.wordid = word.wordid AND
      synset.synsetid = sense.synsetid AND
      sense.tagcount IS NOT NULL
    )
    UNION
    (SELECT sense.synsetid, synset.definition, sense.rank, 0
    FROM wordnet.sense, wordnet.word, wordnet.synset
    WHERE
      word.lemma = word AND
      sense.wordid = word.wordid AND
      synset.synsetid = sense.synsetid AND
      sense.tagcount IS NULL)) as t
    ORDER BY t.tagcount DESC,t.rank ASC
    LIMIT 1 OFFSET 0
  LOOP
    PERFORM etvsm_ontology.itopic_add(occ.synsetid, occ.definition);
    
    FOR occ2 IN
      SELECT word.lemma
      FROM wordnet.sense, wordnet.word
      WHERE
        synsetid = occ.synsetid AND
        word.wordid = sense.wordid
    LOOP
      term_id = NULL;
      SELECT INTO term_id id FROM etvsm_ontology.term WHERE name = occ2.lemma;
      IF term_id IS NOT NULL THEN
        PERFORM etvsm_ontology.interpretation_add('?' || occ2.lemma || '?','?' || occ2.lemma || '?');
        PERFORM etvsm_ontology.tmap_add('?' || occ2.lemma || '?',occ2.lemma);
        PERFORM etvsm_ontology.tmap_add(occ.synsetid,occ2.lemma);
        FOR occ3 IN
          SELECT themis.word.word
          FROM themis.word, etvsm_ontology.topic, etvsm_ontology.imap, etvsm_ontology.tmap, etvsm_ontology.term
          WHERE
            term.name = occ2.lemma AND
            tmap.term_id = term.id AND
            imap.inter_id = tmap.inter_id AND
            topic.id = imap.topic_id AND
            word.id = topic.name
        LOOP
          PERFORM etvsm_ontology.imap_add(occ3.word, '?' || occ2.lemma || '?');
        END LOOP;
      ELSE
        PERFORM etvsm_ontology.term_add(occ2.lemma);
        PERFORM etvsm_ontology.tmap_add(occ.synsetid,occ2.lemma);
      END IF;
    END LOOP;
  END LOOP;
  
  RETURN 1;
END;
$_$
    LANGUAGE plpgsql;


--
-- Name: wordnet_dump_word_dummy(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_word_dummy(text) RETURNS integer
    AS $_$
DECLARE
  w ALIAS FOR $1;
BEGIN
  IF EXISTS (SELECT * FROM etvsm_ontology.term WHERE name = w) THEN
    RETURN 0; -- this term is already inside
  END IF;

  PERFORM etvsm_ontology.topic_add(w, w);
  PERFORM etvsm_ontology.imap_add(w, w);
  PERFORM etvsm_ontology.tmap_add(w, w);
    
  RETURN 1;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_word_syn(text, character); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_word_syn(text, character) RETURNS integer
    AS $_$
DECLARE
  word ALIAS FOR $1;
  pos ALIAS FOR $2;
  occ RECORD;
  occ2 RECORD;
  occ3 RECORD;
  term_id INTEGER;
  res INTEGER;
BEGIN
  IF EXISTS (SELECT * FROM etvsm_ontology.term WHERE name = word) THEN
    RETURN 0; -- this term is already inside
  END IF;

  IF NOT EXISTS (SELECT * FROM wordnet.word WHERE lemma = word) THEN
    PERFORM etvsm_ontology.wordnet_dump_word_dummy(word);
    RETURN -1; -- dummy ontology created
  END IF;

  FOR occ IN
    SELECT t.synsetid, t.definition
    FROM
    ((SELECT sense.synsetid, synset.definition, sense.rank, sense.tagcount
    FROM wordnet.sense, wordnet.word, wordnet.synset
    WHERE
      word.lemma = word AND
      sense.wordid = word.wordid AND
      synset.synsetid = sense.synsetid AND
      synset.pos = pos AND
      sense.tagcount IS NOT NULL
    )
    UNION
    (SELECT sense.synsetid, synset.definition, sense.rank, 0
    FROM wordnet.sense, wordnet.word, wordnet.synset
    WHERE
      word.lemma = word AND
      sense.wordid = word.wordid AND
      synset.synsetid = sense.synsetid AND
      synset.pos = pos AND
      sense.tagcount IS NULL)) as t
    ORDER BY t.tagcount DESC,t.rank ASC
    LIMIT 1 OFFSET 0
  LOOP
    PERFORM etvsm_ontology.itopic_add(occ.synsetid, occ.definition);
    res = occ.synsetid;
    
    PERFORM etvsm_ontology.term_add(word);
    PERFORM etvsm_ontology.tmap_add(occ.synsetid,word);
  END LOOP;

  RETURN res;
END;
$_$
    LANGUAGE plpgsql STRICT;


--
-- Name: wordnet_dump_word_syn_nvsar(text); Type: FUNCTION; Schema: etvsm_ontology; Owner: -
--

CREATE FUNCTION wordnet_dump_word_syn_nvsar(text) RETURNS integer
    AS $_$
DECLARE
  word ALIAS FOR $1;
  w TEXT;
  res INTEGER;
BEGIN
  w = LOWER (word);
  res = etvsm_ontology.wordnet_dump_word_syn(w,'n');
  IF res IS NULL THEN res = etvsm_ontology.wordnet_dump_word_syn(w,'v'); END IF;
  IF res IS NULL THEN res = etvsm_ontology.wordnet_dump_word_syn(w,'s'); END IF;
  IF res IS NULL THEN res = etvsm_ontology.wordnet_dump_word_syn(w,'a'); END IF;
  IF res IS NULL THEN res = etvsm_ontology.wordnet_dump_word_syn(w,'r'); END IF;
  
  RETURN res;
END;
$_$
    LANGUAGE plpgsql;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: imap; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE imap (
    topic_id integer NOT NULL,
    inter_id integer NOT NULL
);


--
-- Name: interpretation_id_seq; Type: SEQUENCE; Schema: etvsm_ontology; Owner: -
--

CREATE SEQUENCE interpretation_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: interpretation; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE interpretation (
    id integer DEFAULT nextval('interpretation_id_seq'::regclass) NOT NULL,
    name integer NOT NULL,
    descr text
);


--
-- Name: ivector; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE ivector (
    inter_id integer NOT NULL,
    comp_id integer NOT NULL,
    value real
);


--
-- Name: interpretation_sim; Type: VIEW; Schema: etvsm_ontology; Owner: -
--

CREATE VIEW interpretation_sim AS
    SELECT t1.inter_id AS inter1, t2.inter_id AS inter2, sum((t1.value * t2.value)) AS sim FROM ivector t1, ivector t2 WHERE (t1.comp_id = t2.comp_id) GROUP BY t1.inter_id, t2.inter_id;


--
-- Name: isim; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE isim (
    inter1 integer NOT NULL,
    inter2 integer NOT NULL,
    sim real NOT NULL
);


--
-- Name: map; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE map (
    parent_id integer NOT NULL,
    child_id integer NOT NULL,
    card_id integer NOT NULL
);


--
-- Name: map_type_id_seq; Type: SEQUENCE; Schema: etvsm_ontology; Owner: -
--

CREATE SEQUENCE map_type_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: map_type; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE map_type (
    id integer DEFAULT nextval('map_type_id_seq'::regclass) NOT NULL,
    tag text NOT NULL,
    descr text
);


--
-- Name: term_id_seq; Type: SEQUENCE; Schema: etvsm_ontology; Owner: -
--

CREATE SEQUENCE term_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: term; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE term (
    id integer DEFAULT nextval('term_id_seq'::regclass) NOT NULL,
    name text,
    term integer[]
);


--
-- Name: tmap; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE tmap (
    inter_id integer NOT NULL,
    term_id integer NOT NULL
);


--
-- Name: topic_id_seq; Type: SEQUENCE; Schema: etvsm_ontology; Owner: -
--

CREATE SEQUENCE topic_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    NO MINVALUE
    CACHE 1;


--
-- Name: topic; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE topic (
    id integer DEFAULT nextval('topic_id_seq'::regclass) NOT NULL,
    name integer NOT NULL,
    descr text
);


--
-- Name: vector; Type: TABLE; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE TABLE vector (
    topic_id integer NOT NULL,
    comp_id integer NOT NULL,
    value real NOT NULL
);


--
-- Name: topic_sim; Type: VIEW; Schema: etvsm_ontology; Owner: -
--

CREATE VIEW topic_sim AS
    SELECT t1.topic_id AS topic1, t2.topic_id AS topic2, sum((t1.value * t2.value)) AS sim FROM vector t1, vector t2 WHERE (t1.comp_id = t2.comp_id) GROUP BY t1.topic_id, t2.topic_id;


--
-- Name: imap_idx; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY imap
    ADD CONSTRAINT imap_idx PRIMARY KEY (topic_id, inter_id);


--
-- Name: interpretation_name_key; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interpretation
    ADD CONSTRAINT interpretation_name_key UNIQUE (name);


--
-- Name: interpretation_pkey; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY interpretation
    ADD CONSTRAINT interpretation_pkey PRIMARY KEY (id);


--
-- Name: isim_idx; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY isim
    ADD CONSTRAINT isim_idx PRIMARY KEY (inter1, inter2);


--
-- Name: ivector_idx; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY ivector
    ADD CONSTRAINT ivector_idx PRIMARY KEY (inter_id, comp_id);


--
-- Name: map_idx; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY map
    ADD CONSTRAINT map_idx PRIMARY KEY (parent_id, child_id);


--
-- Name: map_type_pkey; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY map_type
    ADD CONSTRAINT map_type_pkey PRIMARY KEY (id);


--
-- Name: map_type_tag_key; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY map_type
    ADD CONSTRAINT map_type_tag_key UNIQUE (tag);


--
-- Name: term_pkey; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY term
    ADD CONSTRAINT term_pkey PRIMARY KEY (id);


--
-- Name: tmap_idx; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tmap
    ADD CONSTRAINT tmap_idx PRIMARY KEY (inter_id, term_id);


--
-- Name: topic_name_key; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topic
    ADD CONSTRAINT topic_name_key UNIQUE (name);


--
-- Name: topic_pkey; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY topic
    ADD CONSTRAINT topic_pkey PRIMARY KEY (id);


--
-- Name: vector_idx; Type: CONSTRAINT; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

ALTER TABLE ONLY vector
    ADD CONSTRAINT vector_idx PRIMARY KEY (topic_id, comp_id);


--
-- Name: term_idx; Type: INDEX; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX term_idx ON term USING btree (term);


--
-- Name: term_idx1; Type: INDEX; Schema: etvsm_ontology; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX term_idx1 ON term USING btree (name);


--
-- Name: imap_fk; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY imap
    ADD CONSTRAINT imap_fk FOREIGN KEY (topic_id) REFERENCES topic(id);


--
-- Name: imap_fk1; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY imap
    ADD CONSTRAINT imap_fk1 FOREIGN KEY (inter_id) REFERENCES interpretation(id);


--
-- Name: map_fk; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY map
    ADD CONSTRAINT map_fk FOREIGN KEY (parent_id) REFERENCES topic(id);


--
-- Name: map_fk1; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY map
    ADD CONSTRAINT map_fk1 FOREIGN KEY (child_id) REFERENCES topic(id);


--
-- Name: map_fk2; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY map
    ADD CONSTRAINT map_fk2 FOREIGN KEY (card_id) REFERENCES map_type(id);


--
-- Name: tmap_fk; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY tmap
    ADD CONSTRAINT tmap_fk FOREIGN KEY (inter_id) REFERENCES interpretation(id);


--
-- Name: tmap_fk1; Type: FK CONSTRAINT; Schema: etvsm_ontology; Owner: -
--

ALTER TABLE ONLY tmap
    ADD CONSTRAINT tmap_fk1 FOREIGN KEY (term_id) REFERENCES term(id);


--
-- PostgreSQL database dump complete
--

