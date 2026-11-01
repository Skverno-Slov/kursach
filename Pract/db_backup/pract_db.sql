--
-- PostgreSQL database dump
--

\restrict VwMtRyqIxGam8DlKymTAk0HVAVtiXO0SaPQvDcbYNGmhhv3s5qiEVfa9ZFfRtTo

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-11-01 15:08:06

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 255 (class 1255 OID 17035)
-- Name: check_reading_status(); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.check_reading_status() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_min NUMERIC;
    v_max NUMERIC;
    v_numeric_value NUMERIC;
    v_ok_id INT;
    v_warning_id INT;
    v_error_id INT;
BEGIN
    SELECT status_id INTO v_ok_id FROM "status" WHERE "name" ILIKE 'OK' LIMIT 1;
    SELECT status_id INTO v_warning_id FROM "status" WHERE "name" ILIKE 'WARNING' LIMIT 1;
    SELECT status_id INTO v_error_id FROM "status" WHERE "name" ILIKE 'ERROR' LIMIT 1;

    SELECT min_value, max_value 
    INTO v_min, v_max 
    FROM "reading_type" 
    WHERE "reading_type_id" = NEW.reading_type_id;

    IF v_min IS NULL AND v_max IS NULL THEN
        NEW.status_id := v_ok_id;
        RETURN NEW;
    END IF;

    BEGIN
        v_numeric_value := CAST(NEW.value AS NUMERIC);
    EXCEPTION WHEN others THEN
        v_numeric_value := NULL;
    END;

    IF v_numeric_value IS NULL THEN
        NEW.status_id := v_error_id;
        RETURN NEW;
    END IF;

    IF v_min IS NOT NULL AND v_numeric_value < v_min THEN
        NEW.status_id := v_error_id;
    ELSIF v_max IS NOT NULL AND v_numeric_value > v_max THEN
        NEW.status_id := v_warning_id;
    ELSE
        NEW.status_id := v_ok_id;
    END IF;

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.check_reading_status() OWNER TO user1;

--
-- TOC entry 256 (class 1255 OID 17036)
-- Name: clean_expired_sessions(); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.clean_expired_sessions() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM "session" 
    WHERE "user_id" = NEW."user_id" 
      AND "session_end_date_time" < NOW();

    RETURN NEW;
END;
$$;


ALTER FUNCTION public.clean_expired_sessions() OWNER TO user1;

--
-- TOC entry 257 (class 1255 OID 17037)
-- Name: clean_old_reading_logs(); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.clean_old_reading_logs() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    DELETE FROM reading_log 
    WHERE write_date_time < NOW() - INTERVAL '1 year';
    
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.clean_old_reading_logs() OWNER TO user1;

--
-- TOC entry 258 (class 1255 OID 17038)
-- Name: create_new_user(character varying, character varying, character varying, character varying, character varying, character varying); Type: PROCEDURE; Schema: public; Owner: user1
--

CREATE PROCEDURE public.create_new_user(IN p_login character varying, IN p_hashed_password character varying, IN p_first_name character varying, IN p_last_name character varying, IN p_second_name character varying, IN p_role_name character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_user_id INT;
    v_role_id INT;
BEGIN
    SELECT role_id INTO v_role_id FROM role WHERE name = p_role_name;
    
    IF v_role_id IS NULL THEN
        RAISE EXCEPTION 'Роль % не найдена', p_role_name;
    END IF;

    INSERT INTO "user" (login, hashed_password, first_name, last_name, second_name)
    VALUES (p_login, p_hashed_password, p_first_name, p_last_name, p_second_name)
    RETURNING user_id INTO v_user_id;

    INSERT INTO user_role (user_id, role_id)
    VALUES (v_user_id, v_role_id);

    RAISE NOTICE 'Пользователь % успешно создан с ролью %', p_login, p_role_name;

EXCEPTION
    WHEN unique_violation THEN
        RAISE EXCEPTION 'Пользователь с логином % уже существует', p_login;
    WHEN OTHERS THEN
        RAISE;
END;
$$;


ALTER PROCEDURE public.create_new_user(IN p_login character varying, IN p_hashed_password character varying, IN p_first_name character varying, IN p_last_name character varying, IN p_second_name character varying, IN p_role_name character varying) OWNER TO user1;

--
-- TOC entry 259 (class 1255 OID 17039)
-- Name: get_equipment_logs(integer); Type: FUNCTION; Schema: public; Owner: user1
--

CREATE FUNCTION public.get_equipment_logs(p_id integer) RETURNS TABLE(reading_log_id integer, write_date_time timestamp with time zone, value character varying, status_id integer)
    LANGUAGE sql
    AS $$ 
    SELECT "reading_log_id", "write_date_time", "value", "status_id" 
    FROM "reading_log" 
    WHERE "equipment_id" = p_id;
$$;


ALTER FUNCTION public.get_equipment_logs(p_id integer) OWNER TO user1;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 237 (class 1259 OID 17196)
-- Name: admin_audit_log; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.admin_audit_log (
    audit_log_id integer NOT NULL,
    user_id integer,
    action character varying(100) NOT NULL,
    entity_name character varying(50) NOT NULL,
    entity_id integer,
    details jsonb,
    ip_address character varying(45),
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.admin_audit_log OWNER TO user1;

--
-- TOC entry 236 (class 1259 OID 17195)
-- Name: admin_audit_log_audit_log_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.admin_audit_log_audit_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.admin_audit_log_audit_log_id_seq OWNER TO user1;

--
-- TOC entry 5187 (class 0 OID 0)
-- Dependencies: 236
-- Name: admin_audit_log_audit_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.admin_audit_log_audit_log_id_seq OWNED BY public.admin_audit_log.audit_log_id;


--
-- TOC entry 241 (class 1259 OID 17242)
-- Name: alert; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.alert (
    alert_id integer NOT NULL,
    equipment_id integer NOT NULL,
    reading_log_id integer,
    severity character varying(20) DEFAULT 'WARNING'::character varying NOT NULL,
    message character varying(255) NOT NULL,
    is_resolved boolean DEFAULT false NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    CONSTRAINT chk_alert_severity CHECK (((severity)::text = ANY ((ARRAY['INFO'::character varying, 'WARNING'::character varying, 'CRITICAL'::character varying, 'FATAL'::character varying])::text[])))
);


ALTER TABLE public.alert OWNER TO user1;

--
-- TOC entry 240 (class 1259 OID 17241)
-- Name: alert_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.alert_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.alert_alert_id_seq OWNER TO user1;

--
-- TOC entry 5188 (class 0 OID 0)
-- Dependencies: 240
-- Name: alert_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.alert_alert_id_seq OWNED BY public.alert.alert_id;


--
-- TOC entry 219 (class 1259 OID 17040)
-- Name: equipment; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.equipment (
    equipment_id integer NOT NULL,
    status_id integer NOT NULL,
    serial_number character varying(100) NOT NULL,
    name character varying(150) NOT NULL,
    model character varying(100) NOT NULL,
    ip_address character varying(39),
    is_deleted boolean DEFAULT false NOT NULL,
    poll_enabled boolean DEFAULT true NOT NULL
);


ALTER TABLE public.equipment OWNER TO user1;

--
-- TOC entry 239 (class 1259 OID 17217)
-- Name: equipment_command; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.equipment_command (
    command_id integer NOT NULL,
    equipment_id integer NOT NULL,
    reading_type_id integer NOT NULL,
    command_string character varying(50) NOT NULL,
    invalid_value character varying(50),
    poll_interval_seconds integer DEFAULT 30 NOT NULL
);


ALTER TABLE public.equipment_command OWNER TO user1;

--
-- TOC entry 238 (class 1259 OID 17216)
-- Name: equipment_command_command_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.equipment_command_command_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_command_command_id_seq OWNER TO user1;

--
-- TOC entry 5190 (class 0 OID 0)
-- Dependencies: 238
-- Name: equipment_command_command_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.equipment_command_command_id_seq OWNED BY public.equipment_command.command_id;


--
-- TOC entry 220 (class 1259 OID 17048)
-- Name: equipment_equipment_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.equipment_equipment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.equipment_equipment_id_seq OWNER TO user1;

--
-- TOC entry 5191 (class 0 OID 0)
-- Dependencies: 220
-- Name: equipment_equipment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.equipment_equipment_id_seq OWNED BY public.equipment.equipment_id;


--
-- TOC entry 221 (class 1259 OID 17049)
-- Name: reading_log; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.reading_log (
    reading_log_id integer NOT NULL,
    equipment_id integer NOT NULL,
    status_id integer NOT NULL,
    reading_type_id integer NOT NULL,
    write_date_time timestamp with time zone DEFAULT now() NOT NULL,
    value character varying(50) NOT NULL
);


ALTER TABLE public.reading_log OWNER TO user1;

--
-- TOC entry 222 (class 1259 OID 17059)
-- Name: reading_log_reading_log_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.reading_log_reading_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_log_reading_log_id_seq OWNER TO user1;

--
-- TOC entry 5194 (class 0 OID 0)
-- Dependencies: 222
-- Name: reading_log_reading_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.reading_log_reading_log_id_seq OWNED BY public.reading_log.reading_log_id;


--
-- TOC entry 223 (class 1259 OID 17060)
-- Name: reading_type; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.reading_type (
    reading_type_id integer NOT NULL,
    identifier character varying(19) NOT NULL,
    name character varying(50) NOT NULL,
    unit character varying(20),
    min_value numeric(10,2),
    max_value numeric(10,2)
);


ALTER TABLE public.reading_type OWNER TO user1;

--
-- TOC entry 224 (class 1259 OID 17066)
-- Name: reading_type_reading_type_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.reading_type_reading_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reading_type_reading_type_id_seq OWNER TO user1;

--
-- TOC entry 5197 (class 0 OID 0)
-- Dependencies: 224
-- Name: reading_type_reading_type_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.reading_type_reading_type_id_seq OWNED BY public.reading_type.reading_type_id;


--
-- TOC entry 225 (class 1259 OID 17067)
-- Name: role; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.role (
    role_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.role OWNER TO user1;

--
-- TOC entry 226 (class 1259 OID 17072)
-- Name: role_role_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.role_role_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.role_role_id_seq OWNER TO user1;

--
-- TOC entry 5200 (class 0 OID 0)
-- Dependencies: 226
-- Name: role_role_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.role_role_id_seq OWNED BY public.role.role_id;


--
-- TOC entry 227 (class 1259 OID 17073)
-- Name: session; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.session (
    session_id integer NOT NULL,
    user_id integer NOT NULL,
    refresh_token text NOT NULL,
    device character varying(255),
    session_end_date_time timestamp with time zone NOT NULL
);


ALTER TABLE public.session OWNER TO user1;

--
-- TOC entry 228 (class 1259 OID 17082)
-- Name: session_session_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.session_session_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.session_session_id_seq OWNER TO user1;

--
-- TOC entry 5203 (class 0 OID 0)
-- Dependencies: 228
-- Name: session_session_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.session_session_id_seq OWNED BY public.session.session_id;


--
-- TOC entry 229 (class 1259 OID 17083)
-- Name: status; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.status (
    status_id integer NOT NULL,
    name character varying(50) NOT NULL
);


ALTER TABLE public.status OWNER TO user1;

--
-- TOC entry 230 (class 1259 OID 17088)
-- Name: status_status_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.status_status_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.status_status_id_seq OWNER TO user1;

--
-- TOC entry 5206 (class 0 OID 0)
-- Dependencies: 230
-- Name: status_status_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.status_status_id_seq OWNED BY public.status.status_id;


--
-- TOC entry 231 (class 1259 OID 17089)
-- Name: user; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public."user" (
    user_id integer NOT NULL,
    login character varying(50) NOT NULL,
    hashed_password character varying(255) NOT NULL,
    second_name character varying(100) NOT NULL,
    first_name character varying(100) NOT NULL,
    last_name character varying(100)
);


ALTER TABLE public."user" OWNER TO user1;

--
-- TOC entry 243 (class 1259 OID 17269)
-- Name: user_alert; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.user_alert (
    user_alert_id integer NOT NULL,
    alert_id integer NOT NULL,
    user_id integer NOT NULL,
    is_read boolean DEFAULT false NOT NULL,
    read_at timestamp with time zone
);


ALTER TABLE public.user_alert OWNER TO user1;

--
-- TOC entry 242 (class 1259 OID 17268)
-- Name: user_alert_user_alert_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.user_alert_user_alert_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_alert_user_alert_id_seq OWNER TO user1;

--
-- TOC entry 5209 (class 0 OID 0)
-- Dependencies: 242
-- Name: user_alert_user_alert_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.user_alert_user_alert_id_seq OWNED BY public.user_alert.user_alert_id;


--
-- TOC entry 232 (class 1259 OID 17099)
-- Name: user_role; Type: TABLE; Schema: public; Owner: user1
--

CREATE TABLE public.user_role (
    user_id integer NOT NULL,
    role_id integer NOT NULL
);


ALTER TABLE public.user_role OWNER TO user1;

--
-- TOC entry 233 (class 1259 OID 17104)
-- Name: user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: user1
--

CREATE SEQUENCE public.user_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.user_user_id_seq OWNER TO user1;

--
-- TOC entry 5211 (class 0 OID 0)
-- Dependencies: 233
-- Name: user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: user1
--

ALTER SEQUENCE public.user_user_id_seq OWNED BY public."user".user_id;


--
-- TOC entry 234 (class 1259 OID 17105)
-- Name: view_latest_equipment_readings; Type: VIEW; Schema: public; Owner: user1
--

CREATE VIEW public.view_latest_equipment_readings AS
 WITH ranked_readings AS (
         SELECT rl.equipment_id,
            rl.reading_type_id,
            rl.write_date_time,
            rl.value,
            rl.status_id,
            row_number() OVER (PARTITION BY rl.equipment_id, rl.reading_type_id ORDER BY rl.write_date_time DESC) AS rn
           FROM public.reading_log rl
        )
 SELECT eq.serial_number,
    rt.identifier AS metric_key,
    rt.name AS label,
    rr.value,
    rt.unit,
    st.name AS status,
    rr.write_date_time AS datetime,
    rt.min_value,
    rt.max_value
   FROM (((ranked_readings rr
     JOIN public.equipment eq ON ((rr.equipment_id = eq.equipment_id)))
     JOIN public.reading_type rt ON ((rr.reading_type_id = rt.reading_type_id)))
     JOIN public.status st ON ((rr.status_id = st.status_id)))
  WHERE (rr.rn = 1);


ALTER VIEW public.view_latest_equipment_readings OWNER TO user1;

--
-- TOC entry 235 (class 1259 OID 17110)
-- Name: view_new_equipment; Type: VIEW; Schema: public; Owner: user1
--

CREATE VIEW public.view_new_equipment AS
 SELECT equipment_id,
    status_id,
    serial_number,
    name,
    model,
    ip_address
   FROM public.equipment
  WHERE ((name)::text = 'New Equipment'::text);


ALTER VIEW public.view_new_equipment OWNER TO user1;

--
-- TOC entry 4935 (class 2604 OID 17199)
-- Name: admin_audit_log audit_log_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.admin_audit_log ALTER COLUMN audit_log_id SET DEFAULT nextval('public.admin_audit_log_audit_log_id_seq'::regclass);


--
-- TOC entry 4939 (class 2604 OID 17245)
-- Name: alert alert_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.alert ALTER COLUMN alert_id SET DEFAULT nextval('public.alert_alert_id_seq'::regclass);


--
-- TOC entry 4925 (class 2604 OID 17114)
-- Name: equipment equipment_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment ALTER COLUMN equipment_id SET DEFAULT nextval('public.equipment_equipment_id_seq'::regclass);


--
-- TOC entry 4937 (class 2604 OID 17220)
-- Name: equipment_command command_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment_command ALTER COLUMN command_id SET DEFAULT nextval('public.equipment_command_command_id_seq'::regclass);


--
-- TOC entry 4928 (class 2604 OID 17115)
-- Name: reading_log reading_log_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log ALTER COLUMN reading_log_id SET DEFAULT nextval('public.reading_log_reading_log_id_seq'::regclass);


--
-- TOC entry 4930 (class 2604 OID 17116)
-- Name: reading_type reading_type_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_type ALTER COLUMN reading_type_id SET DEFAULT nextval('public.reading_type_reading_type_id_seq'::regclass);


--
-- TOC entry 4931 (class 2604 OID 17117)
-- Name: role role_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.role ALTER COLUMN role_id SET DEFAULT nextval('public.role_role_id_seq'::regclass);


--
-- TOC entry 4932 (class 2604 OID 17118)
-- Name: session session_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session ALTER COLUMN session_id SET DEFAULT nextval('public.session_session_id_seq'::regclass);


--
-- TOC entry 4933 (class 2604 OID 17119)
-- Name: status status_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.status ALTER COLUMN status_id SET DEFAULT nextval('public.status_status_id_seq'::regclass);


--
-- TOC entry 4934 (class 2604 OID 17120)
-- Name: user user_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public."user" ALTER COLUMN user_id SET DEFAULT nextval('public.user_user_id_seq'::regclass);


--
-- TOC entry 4943 (class 2604 OID 17272)
-- Name: user_alert user_alert_id; Type: DEFAULT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_alert ALTER COLUMN user_alert_id SET DEFAULT nextval('public.user_alert_user_alert_id_seq'::regclass);


--
-- TOC entry 5174 (class 0 OID 17196)
-- Dependencies: 237
-- Data for Name: admin_audit_log; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.admin_audit_log (audit_log_id, user_id, action, entity_name, entity_id, details, ip_address, created_at) FROM stdin;
\.


--
-- TOC entry 5178 (class 0 OID 17242)
-- Dependencies: 241
-- Data for Name: alert; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.alert (alert_id, equipment_id, reading_log_id, severity, message, is_resolved, created_at, resolved_at) FROM stdin;
\.


--
-- TOC entry 5158 (class 0 OID 17040)
-- Dependencies: 219
-- Data for Name: equipment; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.equipment (equipment_id, status_id, serial_number, name, model, ip_address, is_deleted, poll_enabled) FROM stdin;
11	1	SerNumEx	Мегафон Н3	Other	192.168.100.192	f	t
12	1	SerNumEx2	Ex Eq	new model	Some IP	f	t
\.


--
-- TOC entry 5176 (class 0 OID 17217)
-- Dependencies: 239
-- Data for Name: equipment_command; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.equipment_command (command_id, equipment_id, reading_type_id, command_string, invalid_value, poll_interval_seconds) FROM stdin;
\.


--
-- TOC entry 5160 (class 0 OID 17049)
-- Dependencies: 221
-- Data for Name: reading_log; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.reading_log (reading_log_id, equipment_id, status_id, reading_type_id, write_date_time, value) FROM stdin;
309574	11	1	29	2026-06-11 09:51:58.698148+03	n/a
309575	11	1	30	2026-06-11 09:51:58.90394+03	n/a
309576	11	1	31	2026-06-11 09:51:59.008717+03	+30
309577	11	1	32	2026-06-11 09:51:59.115386+03	-47.8
309578	11	1	33	2026-06-11 09:51:59.207184+03	OFF due to front...
309579	11	1	34	2026-06-11 09:51:59.318145+03	HDB3
309580	11	1	29	2026-06-11 09:52:09.624572+03	n/a
309581	11	1	30	2026-06-11 09:52:09.720782+03	n/a
309582	11	1	31	2026-06-11 09:52:09.82816+03	+30
309583	11	1	32	2026-06-11 09:52:09.93555+03	-47.8
309584	11	1	33	2026-06-11 09:52:10.042838+03	OFF due to front...
309585	11	1	34	2026-06-11 09:52:10.131157+03	HDB3
309586	11	1	29	2026-06-11 09:52:20.386546+03	n/a
309587	11	1	30	2026-06-11 09:52:20.479244+03	n/a
309588	11	1	31	2026-06-11 09:52:20.588369+03	+31
309589	11	1	32	2026-06-11 09:52:20.697426+03	-47.8
309590	11	1	33	2026-06-11 09:52:20.789038+03	OFF due to front...
309591	11	1	34	2026-06-11 09:52:20.897339+03	HDB3
309592	11	1	29	2026-06-11 09:52:31.211556+03	n/a
309593	11	1	30	2026-06-11 09:52:31.301702+03	n/a
309594	11	1	31	2026-06-11 09:52:31.4077+03	+30
309595	11	1	32	2026-06-11 09:52:31.51562+03	-47.4
309596	11	1	33	2026-06-11 09:52:31.6127+03	OFF due to front...
309597	11	1	34	2026-06-11 09:52:31.717363+03	HDB3
309598	11	1	29	2026-06-11 09:52:42.021317+03	n/a
309599	11	1	30	2026-06-11 09:52:42.11751+03	n/a
309600	11	1	31	2026-06-11 09:52:42.236414+03	+30
309601	11	1	32	2026-06-11 09:52:42.319832+03	-47.3
309602	11	1	33	2026-06-11 09:52:42.383005+03	OFF due to front...
309603	11	1	34	2026-06-11 09:52:42.476762+03	HDB3
309604	11	1	29	2026-06-11 09:52:52.708437+03	n/a
309605	11	1	30	2026-06-11 09:52:52.815489+03	n/a
309606	11	1	31	2026-06-11 09:52:52.910758+03	+30
309607	11	1	32	2026-06-11 09:52:52.972715+03	-47.8
309608	11	1	33	2026-06-11 09:52:53.06734+03	OFF due to front...
309609	11	1	34	2026-06-11 09:52:53.13581+03	HDB3
309610	11	1	29	2026-06-11 09:53:03.475232+03	n/a
309611	11	1	30	2026-06-11 09:53:03.586116+03	n/a
309612	11	1	31	2026-06-11 09:53:03.678834+03	+30
309613	11	1	32	2026-06-11 09:53:03.790389+03	-47.7
309614	11	1	33	2026-06-11 09:53:03.896464+03	OFF due to front...
309615	11	1	34	2026-06-11 09:53:04.006449+03	HDB3
309616	11	1	29	2026-06-11 09:53:14.36331+03	n/a
309617	11	1	30	2026-06-11 09:53:14.472807+03	n/a
309618	11	1	31	2026-06-11 09:53:14.565144+03	+30
309619	11	1	32	2026-06-11 09:53:14.67715+03	-47.4
309620	11	1	33	2026-06-11 09:53:14.767253+03	OFF due to front...
309621	11	1	34	2026-06-11 09:53:14.880969+03	HDB3
309622	11	1	29	2026-06-11 09:53:25.229956+03	n/a
309623	11	1	30	2026-06-11 09:53:25.29273+03	n/a
309624	11	1	31	2026-06-11 09:53:25.386149+03	+30
309625	11	1	32	2026-06-11 09:53:25.500163+03	-47.2
309626	11	1	33	2026-06-11 09:53:25.604742+03	OFF due to front...
309627	11	1	34	2026-06-11 09:53:25.695584+03	HDB3
309628	11	1	29	2026-06-11 09:53:35.994868+03	n/a
309629	11	1	30	2026-06-11 09:53:36.083159+03	n/a
309630	11	1	31	2026-06-11 09:53:36.190758+03	+30
309631	11	1	32	2026-06-11 09:53:36.301439+03	-47.5
309632	11	1	33	2026-06-11 09:53:36.408974+03	OFF due to front...
309633	11	1	34	2026-06-11 09:53:36.49988+03	HDB3
309634	11	1	29	2026-06-11 09:53:46.846729+03	n/a
309635	11	1	30	2026-06-11 09:53:46.94735+03	n/a
309636	11	1	31	2026-06-11 09:53:47.041175+03	+30
309637	11	1	32	2026-06-11 09:53:47.103304+03	-47.4
309638	11	1	33	2026-06-11 09:53:47.211425+03	OFF due to front...
309639	11	1	34	2026-06-11 09:53:47.304668+03	HDB3
309640	11	1	29	2026-06-11 09:53:57.658804+03	n/a
309641	11	1	30	2026-06-11 09:53:57.761979+03	n/a
309642	11	1	31	2026-06-11 09:53:57.8562+03	+30
309643	11	1	32	2026-06-11 09:53:57.963855+03	-47.5
309644	11	1	33	2026-06-11 09:53:58.071881+03	OFF due to front...
309645	11	1	34	2026-06-11 09:53:58.165942+03	HDB3
309646	11	1	29	2026-06-11 09:54:08.471041+03	n/a
309647	11	1	30	2026-06-11 09:54:08.563502+03	n/a
309648	11	1	31	2026-06-11 09:54:08.67814+03	+30
309649	11	1	32	2026-06-11 09:54:08.784292+03	-47.6
309650	11	1	33	2026-06-11 09:54:08.880324+03	OFF due to front...
309651	11	1	34	2026-06-11 09:54:08.986654+03	HDB3
309652	11	1	29	2026-06-11 09:54:19.226347+03	n/a
309653	11	1	30	2026-06-11 09:54:19.34197+03	n/a
309654	11	1	31	2026-06-11 09:54:19.44047+03	+30
309655	11	1	32	2026-06-11 09:54:19.534983+03	-47.2
309656	11	1	33	2026-06-11 09:54:19.599321+03	OFF due to front...
309657	11	1	34	2026-06-11 09:54:19.719817+03	HDB3
309658	11	1	29	2026-06-11 09:54:30.060992+03	n/a
309659	11	1	30	2026-06-11 09:54:30.171665+03	n/a
309660	11	1	31	2026-06-11 09:54:30.280734+03	+30
309661	11	1	32	2026-06-11 09:54:30.373913+03	-47.7
309662	11	1	33	2026-06-11 09:54:30.481949+03	OFF due to front...
309663	11	1	34	2026-06-11 09:54:30.5772+03	HDB3
309664	11	1	29	2026-06-11 09:54:40.926707+03	n/a
309665	11	1	30	2026-06-11 09:54:41.036477+03	n/a
309666	11	1	31	2026-06-11 09:54:41.135299+03	+30
309667	11	1	32	2026-06-11 09:54:41.238166+03	-47.6
309668	11	1	33	2026-06-11 09:54:41.332934+03	OFF due to front...
309669	11	1	34	2026-06-11 09:54:41.395766+03	HDB3
309670	11	1	29	2026-06-11 09:54:51.705033+03	n/a
309671	11	1	30	2026-06-11 09:54:51.792912+03	n/a
309672	11	1	31	2026-06-11 09:54:51.901044+03	+30
309673	11	1	32	2026-06-11 09:54:52.009213+03	-47.6
309674	11	1	33	2026-06-11 09:54:52.103122+03	OFF due to front...
309675	11	1	34	2026-06-11 09:54:52.215021+03	HDB3
309676	11	1	29	2026-06-11 09:55:02.502354+03	n/a
309677	11	1	30	2026-06-11 09:55:02.611129+03	n/a
309678	11	1	31	2026-06-11 09:55:02.716605+03	+31
309679	11	1	32	2026-06-11 09:55:02.821489+03	-47.6
309680	11	1	33	2026-06-11 09:55:02.925302+03	OFF due to front...
309681	11	1	34	2026-06-11 09:55:03.024298+03	HDB3
309682	11	1	29	2026-06-11 09:55:13.330568+03	n/a
309683	11	1	30	2026-06-11 09:55:13.426236+03	n/a
309684	11	1	31	2026-06-11 09:55:13.537639+03	+30
309685	11	1	32	2026-06-11 09:55:13.62861+03	-47.4
309686	11	1	33	2026-06-11 09:55:13.739475+03	OFF due to front...
309687	11	1	34	2026-06-11 09:55:13.844761+03	HDB3
309688	11	1	29	2026-06-11 09:55:24.091738+03	n/a
309689	11	1	30	2026-06-11 09:55:24.18307+03	n/a
309690	11	1	31	2026-06-11 09:55:24.297055+03	+30
309691	11	1	32	2026-06-11 09:55:24.400502+03	-47.7
309692	11	1	33	2026-06-11 09:55:24.492984+03	OFF due to front...
309693	11	1	34	2026-06-11 09:55:24.601484+03	HDB3
309694	11	1	29	2026-06-11 09:55:34.846895+03	n/a
309695	11	1	30	2026-06-11 09:55:34.95364+03	n/a
309696	11	1	31	2026-06-11 09:55:35.049348+03	+30
309697	11	1	32	2026-06-11 09:55:35.158548+03	-47.9
309698	11	1	33	2026-06-11 09:55:35.269299+03	OFF due to front...
309699	11	1	34	2026-06-11 09:55:35.355176+03	HDB3
309700	11	1	29	2026-06-11 09:55:45.6141+03	n/a
309701	11	1	30	2026-06-11 09:55:45.706174+03	n/a
309702	11	1	31	2026-06-11 09:55:45.815154+03	+30
309703	11	1	32	2026-06-11 09:55:45.926747+03	-48.3
309704	11	1	33	2026-06-11 09:55:46.018216+03	OFF due to front...
309705	11	1	34	2026-06-11 09:55:46.129312+03	HDB3
309706	11	1	29	2026-06-11 09:55:56.433256+03	n/a
309707	11	1	30	2026-06-11 09:55:56.581975+03	n/a
309708	11	2	31	2026-06-11 09:55:56.67794+03	+30
309709	11	1	32	2026-06-11 09:55:56.791699+03	-48.7
309710	11	1	33	2026-06-11 09:55:56.895126+03	OFF due to front...
309711	11	1	34	2026-06-11 09:55:56.995989+03	HDB3
309712	11	1	29	2026-06-11 09:56:07.341548+03	n/a
309713	11	1	30	2026-06-11 09:56:07.447529+03	n/a
309714	11	2	31	2026-06-11 09:56:07.545259+03	+30
309715	11	1	32	2026-06-11 09:56:07.65414+03	-48.6
309716	11	1	33	2026-06-11 09:56:07.749255+03	OFF due to front...
309717	11	1	34	2026-06-11 09:56:07.85813+03	HDB3
309718	11	1	29	2026-06-11 09:56:18.160382+03	n/a
309719	11	1	30	2026-06-11 09:56:18.25159+03	n/a
309720	11	2	31	2026-06-11 09:56:18.364772+03	+31
309721	11	1	32	2026-06-11 09:56:18.458108+03	-48.5
309722	11	1	33	2026-06-11 09:56:18.5655+03	OFF due to front...
309723	11	1	34	2026-06-11 09:56:18.676203+03	HDB3
309724	11	1	29	2026-06-11 09:56:29.039984+03	n/a
309725	11	1	30	2026-06-11 09:56:29.140606+03	n/a
309726	11	3	31	2026-06-11 09:56:29.234088+03	+31
309727	11	1	32	2026-06-11 09:56:29.34635+03	-48.6
309728	11	1	33	2026-06-11 09:56:29.450894+03	OFF due to front...
309729	11	1	34	2026-06-11 09:56:29.542613+03	HDB3
309730	11	1	29	2026-06-11 09:56:39.838878+03	n/a
309731	11	1	30	2026-06-11 09:56:39.94671+03	n/a
309732	11	3	31	2026-06-11 09:56:40.039996+03	+30
309733	11	1	32	2026-06-11 09:56:40.16041+03	-48.4
309734	11	1	33	2026-06-11 09:56:40.256007+03	OFF due to front...
309735	11	1	34	2026-06-11 09:56:40.346691+03	HDB3
309736	11	1	29	2026-06-11 09:56:50.603546+03	n/a
309737	11	1	30	2026-06-11 09:56:50.695173+03	n/a
309738	11	1	31	2026-06-11 09:56:50.804838+03	+31
309739	11	1	32	2026-06-11 09:56:50.897447+03	-48.8
309740	11	1	33	2026-06-11 09:56:51.005929+03	OFF due to front...
309741	11	1	34	2026-06-11 09:56:51.117023+03	HDB3
309742	11	1	29	2026-06-11 09:57:01.458513+03	n/a
309743	11	1	30	2026-06-11 09:57:01.565199+03	n/a
309744	11	1	31	2026-06-11 09:57:01.658979+03	+30
309745	11	1	32	2026-06-11 09:57:01.766143+03	-48.8
309746	11	1	33	2026-06-11 09:57:01.87548+03	OFF due to front...
309747	11	1	34	2026-06-11 09:57:01.966667+03	HDB3
309748	11	1	29	2026-06-11 09:57:12.216657+03	n/a
309749	11	1	30	2026-06-11 09:57:12.31037+03	n/a
309750	11	1	31	2026-06-11 09:57:12.417827+03	+30
309751	11	1	32	2026-06-11 09:57:12.529682+03	-49.0
309752	11	1	33	2026-06-11 09:57:12.620949+03	OFF due to front...
309753	11	1	34	2026-06-11 09:57:12.729804+03	HDB3
309754	11	1	29	2026-06-11 09:57:23.032751+03	n/a
309755	11	1	30	2026-06-11 09:57:23.13195+03	n/a
309756	11	1	31	2026-06-11 09:57:23.236587+03	+30
309757	11	1	32	2026-06-11 09:57:23.346511+03	-48.9
309758	11	1	33	2026-06-11 09:57:23.439045+03	OFF due to front...
309759	11	1	34	2026-06-11 09:57:23.546738+03	HDB3
309760	11	1	29	2026-06-11 09:57:33.844832+03	n/a
309761	11	1	30	2026-06-11 09:57:33.966248+03	n/a
309762	11	1	31	2026-06-11 09:57:34.053421+03	+31
309763	11	1	32	2026-06-11 09:57:34.163231+03	-49.0
309764	11	1	33	2026-06-11 09:57:34.271434+03	OFF due to front...
309765	11	1	34	2026-06-11 09:57:34.364989+03	HDB3
309766	11	1	29	2026-06-11 09:57:44.738393+03	n/a
309767	11	1	30	2026-06-11 09:57:44.828036+03	n/a
309768	11	1	31	2026-06-11 09:57:44.93521+03	+30
309769	11	1	32	2026-06-11 09:57:45.027463+03	-48.9
309770	11	1	33	2026-06-11 09:57:45.141351+03	OFF due to front...
309771	11	1	34	2026-06-11 09:57:45.247646+03	HDB3
309772	11	1	29	2026-06-11 09:57:55.552122+03	n/a
309773	11	1	30	2026-06-11 09:57:55.647889+03	n/a
309774	11	1	31	2026-06-11 09:57:55.756443+03	+30
309775	11	1	32	2026-06-11 09:57:55.852967+03	-48.9
309776	11	1	33	2026-06-11 09:57:55.91692+03	OFF due to front...
309777	11	1	34	2026-06-11 09:57:56.009867+03	HDB3
309778	11	1	29	2026-06-11 09:58:06.265725+03	n/a
309779	11	1	30	2026-06-11 09:58:06.376434+03	n/a
309780	11	1	31	2026-06-11 09:58:06.466324+03	+30
309781	11	1	32	2026-06-11 09:58:06.576596+03	-48.9
309782	11	1	33	2026-06-11 09:58:06.684947+03	OFF due to front...
309783	11	1	34	2026-06-11 09:58:06.781071+03	HDB3
309784	11	1	29	2026-06-11 09:58:17.083716+03	n/a
309785	11	1	30	2026-06-11 09:58:17.176597+03	n/a
309786	11	1	31	2026-06-11 09:58:17.282701+03	+31
309787	11	1	32	2026-06-11 09:58:17.392441+03	-49.0
309788	11	1	33	2026-06-11 09:58:17.487071+03	OFF due to front...
309789	11	1	34	2026-06-11 09:58:17.599416+03	HDB3
309790	11	1	29	2026-06-11 09:58:27.900258+03	n/a
309791	11	1	30	2026-06-11 09:58:27.997247+03	n/a
309792	11	1	31	2026-06-11 09:58:28.10446+03	+30
309793	11	1	32	2026-06-11 09:58:28.197649+03	-48.8
309794	11	1	33	2026-06-11 09:58:28.259541+03	OFF due to front...
309795	11	1	34	2026-06-11 09:58:28.35342+03	HDB3
309796	11	1	29	2026-06-11 09:58:38.60521+03	n/a
309797	11	1	30	2026-06-11 09:58:38.693055+03	n/a
309798	11	1	31	2026-06-11 09:58:38.761805+03	+30
309799	11	1	32	2026-06-11 09:58:38.855814+03	-48.7
309800	11	1	33	2026-06-11 09:58:38.961912+03	OFF due to front...
309801	11	1	34	2026-06-11 09:58:39.061057+03	HDB3
309802	11	1	29	2026-06-11 09:58:49.352979+03	n/a
309803	11	1	30	2026-06-11 09:58:49.444107+03	n/a
309804	11	1	31	2026-06-11 09:58:49.557239+03	+31
309805	11	1	32	2026-06-11 09:58:49.648124+03	-48.9
309806	11	1	33	2026-06-11 09:58:49.709954+03	OFF due to front...
309807	11	1	34	2026-06-11 09:58:49.821747+03	HDB3
309808	11	1	29	2026-06-11 09:59:00.069102+03	n/a
309809	11	1	30	2026-06-11 09:59:00.165583+03	n/a
309810	11	1	31	2026-06-11 09:59:00.277097+03	+30
309811	11	1	32	2026-06-11 09:59:00.367545+03	-48.9
309812	11	1	33	2026-06-11 09:59:00.430697+03	OFF due to front...
309813	11	1	34	2026-06-11 09:59:00.536507+03	HDB3
309814	11	1	29	2026-06-11 09:59:10.780361+03	n/a
309815	11	1	30	2026-06-11 09:59:10.891823+03	n/a
309816	11	1	31	2026-06-11 09:59:10.994852+03	+30
309817	11	1	32	2026-06-11 09:59:11.090017+03	-48.9
309818	11	1	33	2026-06-11 09:59:11.200592+03	OFF due to front...
309819	11	1	34	2026-06-11 09:59:11.293307+03	HDB3
309820	11	1	29	2026-06-11 09:59:21.532504+03	n/a
309821	11	1	30	2026-06-11 09:59:21.64632+03	n/a
309822	11	1	31	2026-06-11 09:59:21.756423+03	+31
309823	11	1	32	2026-06-11 09:59:21.844298+03	-48.8
309824	11	1	33	2026-06-11 09:59:21.954061+03	OFF due to front...
309825	11	1	34	2026-06-11 09:59:22.058924+03	HDB3
309826	11	1	29	2026-06-11 09:59:32.402472+03	n/a
309827	11	1	30	2026-06-11 09:59:32.502941+03	n/a
309828	11	1	31	2026-06-11 09:59:32.607338+03	+31
309829	11	1	32	2026-06-11 09:59:32.718974+03	-48.9
309830	11	1	33	2026-06-11 09:59:32.812213+03	OFF due to front...
309831	11	1	34	2026-06-11 09:59:32.923335+03	HDB3
309832	11	1	29	2026-06-11 09:59:43.241435+03	n/a
309833	11	1	30	2026-06-11 09:59:43.325887+03	n/a
309834	11	1	31	2026-06-11 09:59:43.434727+03	+30
309835	11	1	32	2026-06-11 09:59:43.550008+03	-48.8
309836	11	1	33	2026-06-11 09:59:43.636595+03	OFF due to front...
309837	11	1	34	2026-06-11 09:59:43.742552+03	HDB3
309838	11	1	29	2026-06-11 09:59:54.096629+03	n/a
309839	11	1	30	2026-06-11 09:59:54.205005+03	n/a
309840	11	1	31	2026-06-11 09:59:54.300418+03	+31
309841	11	1	32	2026-06-11 09:59:54.417591+03	-48.5
309842	11	1	33	2026-06-11 09:59:54.517253+03	OFF due to front...
309843	11	1	34	2026-06-11 09:59:54.609739+03	HDB3
309844	11	1	29	2026-06-11 10:00:04.909317+03	n/a
309845	11	1	30	2026-06-11 10:00:05.004333+03	n/a
309846	11	1	31	2026-06-11 10:00:05.112373+03	+31
309847	11	1	32	2026-06-11 10:00:05.208646+03	-48.5
309848	11	1	33	2026-06-11 10:00:05.317039+03	OFF due to front...
309849	11	1	34	2026-06-11 10:00:05.428022+03	HDB3
309850	11	1	29	2026-06-11 10:00:15.746733+03	n/a
309851	11	1	30	2026-06-11 10:00:15.847212+03	n/a
309852	11	1	31	2026-06-11 10:00:15.941884+03	+30
309853	11	1	32	2026-06-11 10:00:16.049839+03	-48.0
309854	11	1	33	2026-06-11 10:00:16.143408+03	OFF due to front...
309855	11	1	34	2026-06-11 10:00:16.251394+03	HDB3
309856	11	1	29	2026-06-11 10:00:26.556098+03	n/a
309857	11	1	30	2026-06-11 10:00:26.647038+03	n/a
309858	11	1	31	2026-06-11 10:00:26.711052+03	+30
309859	11	1	32	2026-06-11 10:00:26.817845+03	-48.3
309860	11	1	33	2026-06-11 10:00:26.912409+03	OFF due to front...
309861	11	1	34	2026-06-11 10:00:27.021766+03	HDB3
309862	11	1	29	2026-06-11 10:00:37.359712+03	n/a
309863	11	1	30	2026-06-11 10:00:37.469444+03	n/a
309864	11	1	31	2026-06-11 10:00:37.579889+03	+31
309865	11	1	32	2026-06-11 10:00:37.675623+03	-48.5
309866	11	1	33	2026-06-11 10:00:37.863175+03	OFF due to front...
309867	11	1	34	2026-06-11 10:00:37.981367+03	HDB3
309868	11	1	29	2026-06-11 10:00:48.331572+03	n/a
309869	11	1	30	2026-06-11 10:00:48.448913+03	n/a
309870	11	1	31	2026-06-11 10:00:48.538187+03	+31
309871	11	1	32	2026-06-11 10:00:48.649257+03	-48.7
309872	11	1	33	2026-06-11 10:00:48.742201+03	OFF due to front...
309873	11	1	34	2026-06-11 10:00:48.850688+03	HDB3
309874	11	1	29	2026-06-11 10:00:59.08535+03	n/a
309875	11	1	30	2026-06-11 10:00:59.191928+03	n/a
309876	11	1	31	2026-06-11 10:00:59.298674+03	+30
309877	11	1	32	2026-06-11 10:00:59.396542+03	-48.4
309878	11	1	33	2026-06-11 10:00:59.50862+03	OFF due to front...
309879	11	1	34	2026-06-11 10:00:59.612752+03	HDB3
309880	11	1	29	2026-06-11 10:01:09.917882+03	n/a
309881	11	1	30	2026-06-11 10:01:10.007073+03	n/a
309882	11	1	31	2026-06-11 10:01:10.123662+03	+31
309883	11	1	32	2026-06-11 10:01:10.223546+03	-48.7
309884	11	1	33	2026-06-11 10:01:10.320229+03	OFF due to front...
309885	11	1	34	2026-06-11 10:01:10.425876+03	HDB3
309886	11	1	29	2026-06-11 10:01:20.722741+03	n/a
309887	11	1	30	2026-06-11 10:01:20.830815+03	n/a
309888	11	1	31	2026-06-11 10:01:20.927359+03	+30
309889	11	1	32	2026-06-11 10:01:21.036744+03	-48.5
309890	11	1	33	2026-06-11 10:01:21.123745+03	OFF due to front...
309891	11	1	34	2026-06-11 10:01:21.234957+03	HDB3
309892	11	1	29	2026-06-11 10:01:31.541824+03	n/a
309893	11	1	30	2026-06-11 10:01:31.648782+03	n/a
309894	11	1	31	2026-06-11 10:01:31.756393+03	+31
309895	11	1	32	2026-06-11 10:01:31.848415+03	-48.7
309896	11	1	33	2026-06-11 10:01:31.96088+03	OFF due to front...
309897	11	1	34	2026-06-11 10:01:32.071601+03	HDB3
309898	11	1	29	2026-06-11 10:01:42.42321+03	n/a
309899	11	1	30	2026-06-11 10:01:42.532574+03	n/a
309900	11	1	31	2026-06-11 10:01:42.626524+03	+31
309901	11	1	32	2026-06-11 10:01:42.735913+03	-48.4
309902	11	1	33	2026-06-11 10:01:42.84596+03	OFF due to front...
309903	11	1	34	2026-06-11 10:01:42.940113+03	HDB3
309904	11	1	29	2026-06-11 10:01:53.241222+03	n/a
309905	11	1	30	2026-06-11 10:01:53.346983+03	n/a
309906	11	1	31	2026-06-11 10:01:53.458297+03	+31
309907	11	1	32	2026-06-11 10:01:53.551096+03	-48.6
309908	11	1	33	2026-06-11 10:01:53.660758+03	OFF due to front...
309909	11	1	34	2026-06-11 10:01:53.769775+03	HDB3
309910	11	1	29	2026-06-11 10:02:04.053586+03	n/a
309911	11	1	30	2026-06-11 10:02:04.164297+03	n/a
309912	11	1	31	2026-06-11 10:02:04.272732+03	+31
309913	11	1	32	2026-06-11 10:02:04.365244+03	-48.5
309914	11	1	33	2026-06-11 10:02:04.472257+03	OFF due to front...
309915	11	1	34	2026-06-11 10:02:04.581961+03	HDB3
309916	11	1	29	2026-06-11 10:02:14.929687+03	n/a
309917	11	1	30	2026-06-11 10:02:15.039485+03	n/a
309918	11	1	31	2026-06-11 10:02:15.128662+03	+30
309919	11	1	32	2026-06-11 10:02:15.239117+03	-48.6
309920	11	1	33	2026-06-11 10:02:15.348431+03	OFF due to front...
309921	11	1	34	2026-06-11 10:02:15.441766+03	HDB3
\.


--
-- TOC entry 5162 (class 0 OID 17060)
-- Dependencies: 223
-- Data for Name: reading_type; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.reading_type (reading_type_id, identifier, name, unit, min_value, max_value) FROM stdin;
29	ber	ber	\N	\N	\N
30	ebn	ebn	\N	\N	\N
32	rsl	rsl	\N	\N	\N
33	txo	txo	\N	\N	\N
34	ttc	ttc	\N	\N	\N
31	tmp	Температура	°C	27.00	33.00
\.


--
-- TOC entry 5164 (class 0 OID 17067)
-- Dependencies: 225
-- Data for Name: role; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.role (role_id, name) FROM stdin;
2	Инженер
1	Администратор
\.


--
-- TOC entry 5166 (class 0 OID 17073)
-- Dependencies: 227
-- Data for Name: session; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.session (session_id, user_id, refresh_token, device, session_end_date_time) FROM stdin;
\.


--
-- TOC entry 5168 (class 0 OID 17083)
-- Dependencies: 229
-- Data for Name: status; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.status (status_id, name) FROM stdin;
1	ok
2	warning
3	error
\.


--
-- TOC entry 5170 (class 0 OID 17089)
-- Dependencies: 231
-- Data for Name: user; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public."user" (user_id, login, hashed_password, second_name, first_name, last_name) FROM stdin;
4	admin	$2b$12$O1iqmrfuMgMrlRtGvUgggeM1X5EJzJKmDj/qydpMUiP7UVZ.gkmpu	admin	admin	admin
\.


--
-- TOC entry 5180 (class 0 OID 17269)
-- Dependencies: 243
-- Data for Name: user_alert; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.user_alert (user_alert_id, alert_id, user_id, is_read, read_at) FROM stdin;
\.


--
-- TOC entry 5171 (class 0 OID 17099)
-- Dependencies: 232
-- Data for Name: user_role; Type: TABLE DATA; Schema: public; Owner: user1
--

COPY public.user_role (user_id, role_id) FROM stdin;
4	1
\.


--
-- TOC entry 5215 (class 0 OID 0)
-- Dependencies: 236
-- Name: admin_audit_log_audit_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.admin_audit_log_audit_log_id_seq', 1, false);


--
-- TOC entry 5216 (class 0 OID 0)
-- Dependencies: 240
-- Name: alert_alert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.alert_alert_id_seq', 1, false);


--
-- TOC entry 5217 (class 0 OID 0)
-- Dependencies: 238
-- Name: equipment_command_command_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.equipment_command_command_id_seq', 1, false);


--
-- TOC entry 5218 (class 0 OID 0)
-- Dependencies: 220
-- Name: equipment_equipment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.equipment_equipment_id_seq', 12, true);


--
-- TOC entry 5219 (class 0 OID 0)
-- Dependencies: 222
-- Name: reading_log_reading_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.reading_log_reading_log_id_seq', 309921, true);


--
-- TOC entry 5220 (class 0 OID 0)
-- Dependencies: 224
-- Name: reading_type_reading_type_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.reading_type_reading_type_id_seq', 34, true);


--
-- TOC entry 5221 (class 0 OID 0)
-- Dependencies: 226
-- Name: role_role_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.role_role_id_seq', 2, true);


--
-- TOC entry 5222 (class 0 OID 0)
-- Dependencies: 228
-- Name: session_session_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.session_session_id_seq', 162, true);


--
-- TOC entry 5223 (class 0 OID 0)
-- Dependencies: 230
-- Name: status_status_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.status_status_id_seq', 3, true);


--
-- TOC entry 5224 (class 0 OID 0)
-- Dependencies: 242
-- Name: user_alert_user_alert_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.user_alert_user_alert_id_seq', 1, false);


--
-- TOC entry 5225 (class 0 OID 0)
-- Dependencies: 233
-- Name: user_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: user1
--

SELECT pg_catalog.setval('public.user_user_id_seq', 26, true);


--
-- TOC entry 4977 (class 2606 OID 17208)
-- Name: admin_audit_log admin_audit_log_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT admin_audit_log_pkey PRIMARY KEY (audit_log_id);


--
-- TOC entry 4985 (class 2606 OID 17257)
-- Name: alert alert_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.alert
    ADD CONSTRAINT alert_pkey PRIMARY KEY (alert_id);


--
-- TOC entry 4981 (class 2606 OID 17228)
-- Name: equipment_command equipment_command_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment_command
    ADD CONSTRAINT equipment_command_pkey PRIMARY KEY (command_id);


--
-- TOC entry 4947 (class 2606 OID 17122)
-- Name: equipment equipment_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_pkey PRIMARY KEY (equipment_id);


--
-- TOC entry 4949 (class 2606 OID 17124)
-- Name: equipment equipment_serial_number_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_serial_number_key UNIQUE (serial_number);


--
-- TOC entry 4952 (class 2606 OID 17126)
-- Name: reading_log reading_log_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_pkey PRIMARY KEY (reading_log_id);


--
-- TOC entry 4954 (class 2606 OID 17128)
-- Name: reading_type reading_type_identifier_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_type
    ADD CONSTRAINT reading_type_identifier_key UNIQUE (identifier);


--
-- TOC entry 4956 (class 2606 OID 17130)
-- Name: reading_type reading_type_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_type
    ADD CONSTRAINT reading_type_pkey PRIMARY KEY (reading_type_id);


--
-- TOC entry 4958 (class 2606 OID 17132)
-- Name: role role_name_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_name_key UNIQUE (name);


--
-- TOC entry 4960 (class 2606 OID 17134)
-- Name: role role_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.role
    ADD CONSTRAINT role_pkey PRIMARY KEY (role_id);


--
-- TOC entry 4963 (class 2606 OID 17136)
-- Name: session session_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_pkey PRIMARY KEY (session_id);


--
-- TOC entry 4965 (class 2606 OID 17138)
-- Name: session session_refresh_token_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_refresh_token_key UNIQUE (refresh_token);


--
-- TOC entry 4967 (class 2606 OID 17140)
-- Name: status status_name_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_name_key UNIQUE (name);


--
-- TOC entry 4969 (class 2606 OID 17142)
-- Name: status status_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.status
    ADD CONSTRAINT status_pkey PRIMARY KEY (status_id);


--
-- TOC entry 4989 (class 2606 OID 17281)
-- Name: user_alert uq_alert_user; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_alert
    ADD CONSTRAINT uq_alert_user UNIQUE (alert_id, user_id);


--
-- TOC entry 4983 (class 2606 OID 17230)
-- Name: equipment_command uq_equipment_cmd; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment_command
    ADD CONSTRAINT uq_equipment_cmd UNIQUE (equipment_id, command_string);


--
-- TOC entry 4991 (class 2606 OID 17279)
-- Name: user_alert user_alert_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_alert
    ADD CONSTRAINT user_alert_pkey PRIMARY KEY (user_alert_id);


--
-- TOC entry 4971 (class 2606 OID 17144)
-- Name: user user_login_key; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_login_key UNIQUE (login);


--
-- TOC entry 4973 (class 2606 OID 17146)
-- Name: user user_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public."user"
    ADD CONSTRAINT user_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4975 (class 2606 OID 17148)
-- Name: user_role user_role_pkey; Type: CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_pkey PRIMARY KEY (user_id, role_id);


--
-- TOC entry 4986 (class 1259 OID 17292)
-- Name: idx_alert_equipment_active; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_alert_equipment_active ON public.alert USING btree (equipment_id) WHERE (is_resolved = false);


--
-- TOC entry 4978 (class 1259 OID 17214)
-- Name: idx_audit_created_at; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_audit_created_at ON public.admin_audit_log USING btree (created_at DESC);


--
-- TOC entry 4979 (class 1259 OID 17215)
-- Name: idx_audit_user_id; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_audit_user_id ON public.admin_audit_log USING btree (user_id);


--
-- TOC entry 4950 (class 1259 OID 17149)
-- Name: idx_metrics_device_time; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_metrics_device_time ON public.reading_log USING btree (equipment_id, write_date_time DESC);


--
-- TOC entry 4961 (class 1259 OID 17150)
-- Name: idx_sessions_user; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_sessions_user ON public.session USING btree (user_id);


--
-- TOC entry 4987 (class 1259 OID 17293)
-- Name: idx_user_alert_unread; Type: INDEX; Schema: public; Owner: user1
--

CREATE INDEX idx_user_alert_unread ON public.user_alert USING btree (user_id) WHERE (is_read = false);


--
-- TOC entry 5006 (class 2620 OID 17151)
-- Name: reading_log trg_bi_reading_log_status; Type: TRIGGER; Schema: public; Owner: user1
--

CREATE TRIGGER trg_bi_reading_log_status BEFORE INSERT ON public.reading_log FOR EACH ROW EXECUTE FUNCTION public.check_reading_status();


--
-- TOC entry 5008 (class 2620 OID 17152)
-- Name: session trg_clean_expired_sessions; Type: TRIGGER; Schema: public; Owner: user1
--

CREATE TRIGGER trg_clean_expired_sessions BEFORE INSERT ON public.session FOR EACH ROW EXECUTE FUNCTION public.clean_expired_sessions();


--
-- TOC entry 5007 (class 2620 OID 17153)
-- Name: reading_log trg_clean_old_logs; Type: TRIGGER; Schema: public; Owner: user1
--

CREATE TRIGGER trg_clean_old_logs AFTER INSERT ON public.reading_log FOR EACH STATEMENT EXECUTE FUNCTION public.clean_old_reading_logs();


--
-- TOC entry 4992 (class 2606 OID 17154)
-- Name: equipment equipment_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment
    ADD CONSTRAINT equipment_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.status(status_id) ON DELETE RESTRICT;


--
-- TOC entry 5002 (class 2606 OID 17258)
-- Name: alert fk_alert_equipment; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.alert
    ADD CONSTRAINT fk_alert_equipment FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5003 (class 2606 OID 17263)
-- Name: alert fk_alert_reading_log; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.alert
    ADD CONSTRAINT fk_alert_reading_log FOREIGN KEY (reading_log_id) REFERENCES public.reading_log(reading_log_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 4999 (class 2606 OID 17209)
-- Name: admin_audit_log fk_audit_user; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.admin_audit_log
    ADD CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- TOC entry 5000 (class 2606 OID 17231)
-- Name: equipment_command fk_cmd_equipment; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment_command
    ADD CONSTRAINT fk_cmd_equipment FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5001 (class 2606 OID 17236)
-- Name: equipment_command fk_cmd_reading_type; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.equipment_command
    ADD CONSTRAINT fk_cmd_reading_type FOREIGN KEY (reading_type_id) REFERENCES public.reading_type(reading_type_id) ON UPDATE CASCADE ON DELETE RESTRICT;


--
-- TOC entry 5004 (class 2606 OID 17282)
-- Name: user_alert fk_user_alert_alert; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_alert
    ADD CONSTRAINT fk_user_alert_alert FOREIGN KEY (alert_id) REFERENCES public.alert(alert_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 5005 (class 2606 OID 17287)
-- Name: user_alert fk_user_alert_user; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_alert
    ADD CONSTRAINT fk_user_alert_user FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4993 (class 2606 OID 17159)
-- Name: reading_log reading_log_equipment_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_equipment_id_fkey FOREIGN KEY (equipment_id) REFERENCES public.equipment(equipment_id) ON DELETE CASCADE;


--
-- TOC entry 4994 (class 2606 OID 17164)
-- Name: reading_log reading_log_reading_type_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_reading_type_id_fkey FOREIGN KEY (reading_type_id) REFERENCES public.reading_type(reading_type_id) ON DELETE RESTRICT;


--
-- TOC entry 4995 (class 2606 OID 17169)
-- Name: reading_log reading_log_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.reading_log
    ADD CONSTRAINT reading_log_status_id_fkey FOREIGN KEY (status_id) REFERENCES public.status(status_id) ON DELETE RESTRICT;


--
-- TOC entry 4996 (class 2606 OID 17174)
-- Name: session session_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.session
    ADD CONSTRAINT session_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON DELETE CASCADE;


--
-- TOC entry 4997 (class 2606 OID 17179)
-- Name: user_role user_role_role_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.role(role_id) ON DELETE CASCADE;


--
-- TOC entry 4998 (class 2606 OID 17184)
-- Name: user_role user_role_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user1
--

ALTER TABLE ONLY public.user_role
    ADD CONSTRAINT user_role_user_id_fkey FOREIGN KEY (user_id) REFERENCES public."user"(user_id) ON DELETE CASCADE;


--
-- TOC entry 5186 (class 0 OID 0)
-- Dependencies: 5
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: pg_database_owner
--

GRANT ALL ON SCHEMA public TO db_editor;
GRANT USAGE ON SCHEMA public TO engineer_reader;
GRANT ALL ON SCHEMA public TO admin_editor;


--
-- TOC entry 5189 (class 0 OID 0)
-- Dependencies: 219
-- Name: TABLE equipment; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipment TO db_editor;
GRANT SELECT ON TABLE public.equipment TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.equipment TO admin_editor;


--
-- TOC entry 5192 (class 0 OID 0)
-- Dependencies: 220
-- Name: SEQUENCE equipment_equipment_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.equipment_equipment_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.equipment_equipment_id_seq TO admin_editor;


--
-- TOC entry 5193 (class 0 OID 0)
-- Dependencies: 221
-- Name: TABLE reading_log; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_log TO db_editor;
GRANT SELECT ON TABLE public.reading_log TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_log TO admin_editor;


--
-- TOC entry 5195 (class 0 OID 0)
-- Dependencies: 222
-- Name: SEQUENCE reading_log_reading_log_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.reading_log_reading_log_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.reading_log_reading_log_id_seq TO admin_editor;


--
-- TOC entry 5196 (class 0 OID 0)
-- Dependencies: 223
-- Name: TABLE reading_type; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_type TO db_editor;
GRANT SELECT ON TABLE public.reading_type TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.reading_type TO admin_editor;


--
-- TOC entry 5198 (class 0 OID 0)
-- Dependencies: 224
-- Name: SEQUENCE reading_type_reading_type_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.reading_type_reading_type_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.reading_type_reading_type_id_seq TO admin_editor;


--
-- TOC entry 5199 (class 0 OID 0)
-- Dependencies: 225
-- Name: TABLE role; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role TO db_editor;
GRANT SELECT ON TABLE public.role TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.role TO admin_editor;


--
-- TOC entry 5201 (class 0 OID 0)
-- Dependencies: 226
-- Name: SEQUENCE role_role_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.role_role_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.role_role_id_seq TO admin_editor;


--
-- TOC entry 5202 (class 0 OID 0)
-- Dependencies: 227
-- Name: TABLE session; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.session TO db_editor;
GRANT SELECT ON TABLE public.session TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.session TO admin_editor;


--
-- TOC entry 5204 (class 0 OID 0)
-- Dependencies: 228
-- Name: SEQUENCE session_session_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.session_session_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.session_session_id_seq TO admin_editor;


--
-- TOC entry 5205 (class 0 OID 0)
-- Dependencies: 229
-- Name: TABLE status; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.status TO db_editor;
GRANT SELECT ON TABLE public.status TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.status TO admin_editor;


--
-- TOC entry 5207 (class 0 OID 0)
-- Dependencies: 230
-- Name: SEQUENCE status_status_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.status_status_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.status_status_id_seq TO admin_editor;


--
-- TOC entry 5208 (class 0 OID 0)
-- Dependencies: 231
-- Name: TABLE "user"; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."user" TO db_editor;
GRANT SELECT ON TABLE public."user" TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public."user" TO admin_editor;


--
-- TOC entry 5210 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE user_role; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_role TO db_editor;
GRANT SELECT ON TABLE public.user_role TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.user_role TO admin_editor;


--
-- TOC entry 5212 (class 0 OID 0)
-- Dependencies: 233
-- Name: SEQUENCE user_user_id_seq; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,USAGE ON SEQUENCE public.user_user_id_seq TO db_editor;
GRANT SELECT,USAGE ON SEQUENCE public.user_user_id_seq TO admin_editor;


--
-- TOC entry 5213 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE view_latest_equipment_readings; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_latest_equipment_readings TO db_editor;
GRANT SELECT ON TABLE public.view_latest_equipment_readings TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_latest_equipment_readings TO admin_editor;


--
-- TOC entry 5214 (class 0 OID 0)
-- Dependencies: 235
-- Name: TABLE view_new_equipment; Type: ACL; Schema: public; Owner: user1
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_new_equipment TO db_editor;
GRANT SELECT ON TABLE public.view_new_equipment TO engineer_reader;
GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE public.view_new_equipment TO admin_editor;


--
-- TOC entry 2119 (class 826 OID 16856)
-- Name: DEFAULT PRIVILEGES FOR SEQUENCES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO db_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,USAGE ON SEQUENCES TO admin_editor;


--
-- TOC entry 2120 (class 826 OID 16855)
-- Name: DEFAULT PRIVILEGES FOR TABLES; Type: DEFAULT ACL; Schema: public; Owner: postgres
--

ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO db_editor;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT ON TABLES TO engineer_reader;
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA public GRANT SELECT,INSERT,DELETE,UPDATE ON TABLES TO admin_editor;


-- Completed on 2026-11-01 15:08:07

--
-- PostgreSQL database dump complete
--

\unrestrict VwMtRyqIxGam8DlKymTAk0HVAVtiXO0SaPQvDcbYNGmhhv3s5qiEVfa9ZFfRtTo

