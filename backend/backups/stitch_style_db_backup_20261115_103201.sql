--
-- PostgreSQL database dump
--

\restrict zVILCGffbMTjSxr6EOHDbQzfZclhREDa0kxifXRumpAEIKIufqqYGPdBLidmIzW

-- Dumped from database version 18.7
-- Dumped by pg_dump version 18.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'WIN1252';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: addresses; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.addresses (
    id uuid NOT NULL,
    customer_id uuid NOT NULL,
    recipient_name character varying(150) NOT NULL,
    phone character varying(30) NOT NULL,
    street character varying(255) NOT NULL,
    city character varying(100) NOT NULL,
    state character varying(100) NOT NULL,
    postal_code character varying(20) NOT NULL,
    is_default boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.addresses OWNER TO stitch_admin;

--
-- Name: alembic_version; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.alembic_version (
    version_num character varying(32) NOT NULL
);


ALTER TABLE public.alembic_version OWNER TO stitch_admin;

--
-- Name: categories; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.categories (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    slug character varying(120) NOT NULL,
    description text,
    image_url character varying(500),
    is_active boolean NOT NULL,
    sort_order integer NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL
);


ALTER TABLE public.categories OWNER TO stitch_admin;

--
-- Name: delivery_rules; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.delivery_rules (
    id uuid NOT NULL,
    name character varying(100) NOT NULL,
    min_order_amount numeric(10,2) NOT NULL,
    max_order_amount numeric(10,2),
    charge numeric(10,2) NOT NULL,
    priority integer NOT NULL,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_rule_charge_positive CHECK ((charge >= (0)::numeric)),
    CONSTRAINT chk_rule_max_gte_min CHECK (((max_order_amount IS NULL) OR (max_order_amount >= min_order_amount))),
    CONSTRAINT chk_rule_min_positive CHECK ((min_order_amount >= (0)::numeric))
);


ALTER TABLE public.delivery_rules OWNER TO stitch_admin;

--
-- Name: delivery_settings; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.delivery_settings (
    id uuid NOT NULL,
    is_free_delivery_active boolean NOT NULL,
    free_delivery_threshold numeric(10,2),
    default_delivery_charge numeric(10,2) NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_default_delivery_charge_positive CHECK ((default_delivery_charge >= (0)::numeric)),
    CONSTRAINT chk_free_delivery_threshold_positive CHECK (((free_delivery_threshold IS NULL) OR (free_delivery_threshold >= (0)::numeric)))
);


ALTER TABLE public.delivery_settings OWNER TO stitch_admin;

--
-- Name: order_items; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.order_items (
    id uuid NOT NULL,
    order_id uuid NOT NULL,
    product_id uuid NOT NULL,
    product_name_snapshot character varying(200) NOT NULL,
    unit_price_snapshot numeric(10,2) NOT NULL,
    quantity integer NOT NULL,
    line_total numeric(10,2) NOT NULL,
    CONSTRAINT chk_order_items_line_total_positive CHECK ((line_total >= (0)::numeric)),
    CONSTRAINT chk_order_items_quantity_positive CHECK ((quantity > 0)),
    CONSTRAINT chk_order_items_unit_price_positive CHECK ((unit_price_snapshot >= (0)::numeric))
);


ALTER TABLE public.order_items OWNER TO stitch_admin;

--
-- Name: order_status_history; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.order_status_history (
    id uuid NOT NULL,
    order_id uuid NOT NULL,
    old_status character varying(30),
    new_status character varying(30) NOT NULL,
    changed_by_user_id uuid,
    comment text,
    created_at timestamp with time zone NOT NULL
);


ALTER TABLE public.order_status_history OWNER TO stitch_admin;

--
-- Name: orders; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.orders (
    id uuid NOT NULL,
    order_number character varying(50) NOT NULL,
    customer_id uuid NOT NULL,
    status character varying(30) NOT NULL,
    subtotal numeric(10,2) NOT NULL,
    delivery_charge numeric(10,2) NOT NULL,
    total numeric(10,2) NOT NULL,
    delivery_address_snapshot jsonb NOT NULL,
    note text,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_orders_delivery_charge_positive CHECK ((delivery_charge >= (0)::numeric)),
    CONSTRAINT chk_orders_subtotal_positive CHECK ((subtotal >= (0)::numeric)),
    CONSTRAINT chk_orders_total_positive CHECK ((total >= (0)::numeric))
);


ALTER TABLE public.orders OWNER TO stitch_admin;

--
-- Name: product_images; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.product_images (
    id uuid NOT NULL,
    product_id uuid NOT NULL,
    cloudinary_url character varying(500) NOT NULL,
    cloudinary_public_id character varying(255) NOT NULL,
    cloudinary_asset_id character varying(255),
    width integer NOT NULL,
    height integer NOT NULL,
    format character varying(20) NOT NULL,
    bytes_size integer NOT NULL,
    sort_order integer NOT NULL,
    is_primary boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_product_images_bytes_positive CHECK ((bytes_size >= 0))
);


ALTER TABLE public.product_images OWNER TO stitch_admin;

--
-- Name: products; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.products (
    id uuid NOT NULL,
    name character varying(200) NOT NULL,
    slug character varying(240) NOT NULL,
    description text NOT NULL,
    price numeric(10,2) NOT NULL,
    category_id uuid NOT NULL,
    is_available boolean NOT NULL,
    stock_quantity integer,
    is_active boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_products_price_positive CHECK ((price > (0)::numeric))
);


ALTER TABLE public.products OWNER TO stitch_admin;

--
-- Name: refresh_tokens; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.refresh_tokens (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    token_hash character varying(64) NOT NULL,
    family_id uuid DEFAULT gen_random_uuid() NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    revoked_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.refresh_tokens OWNER TO stitch_admin;

--
-- Name: reviews; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.reviews (
    id uuid NOT NULL,
    product_id uuid NOT NULL,
    customer_id uuid NOT NULL,
    rating integer NOT NULL,
    comment text,
    is_visible boolean NOT NULL,
    created_at timestamp with time zone NOT NULL,
    updated_at timestamp with time zone NOT NULL,
    CONSTRAINT chk_reviews_rating_range CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.reviews OWNER TO stitch_admin;

--
-- Name: users; Type: TABLE; Schema: public; Owner: stitch_admin
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    full_name character varying(100) NOT NULL,
    phone character varying(20),
    role character varying(20) DEFAULT 'customer'::character varying NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT check_user_role_valid CHECK (((role)::text = ANY ((ARRAY['customer'::character varying, 'admin'::character varying])::text[])))
);


ALTER TABLE public.users OWNER TO stitch_admin;

--
-- Data for Name: addresses; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.addresses (id, customer_id, recipient_name, phone, street, city, state, postal_code, is_default, created_at, updated_at) FROM stdin;
d620f2e4-fe43-4c93-a4bf-75e49868f443	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Kavita Sen	+91 9123456789	12 Lake View Road	Jaipur	Rajasthan	302001	t	2026-11-15 10:13:47.65909+05:30	2026-11-15 10:13:47.65909+05:30
30fed592-1eec-4b8c-9051-2c942d903626	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Kavita Sen	+91 9123456789	12 Lake View Road	Jaipur	Rajasthan	302001	f	2026-11-15 10:14:21.958303+05:30	2026-11-15 10:14:21.958303+05:30
bf67b5fa-459a-470d-b1a2-1ba7fd59fd73	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Kavita Sen	+91 9123456789	12 Lake View Road	Jaipur	Rajasthan	302001	f	2026-11-15 10:14:52.4699+05:30	2026-11-15 10:14:52.4699+05:30
94b33619-146a-4fba-afd5-af48dbf16e4e	1daafa1a-445c-4384-be91-90fec39bb341	Meera Patel	+91 9777766666	10 Palace Road	Ahmedabad	Gujarat	380001	t	2026-11-15 10:29:56.04752+05:30	2026-11-15 10:29:56.04752+05:30
abbc68b9-9e64-4f45-9b9b-da739f59c185	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Kavita Sen	+91 9123456789	12 Lake View Road	Jaipur	Rajasthan	302001	f	2026-11-15 10:29:56.747042+05:30	2026-11-15 10:29:56.747042+05:30
\.


--
-- Data for Name: alembic_version; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.alembic_version (version_num) FROM stdin;
c5cf99dd06a0
\.


--
-- Data for Name: categories; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.categories (id, name, slug, description, image_url, is_active, sort_order, created_at, updated_at) FROM stdin;
8b6ddcf4-53b3-4212-b8f1-25d5a8924b35	Active Category	active-category	\N	\N	t	0	2026-11-15 10:01:28.179591+05:30	2026-11-15 10:01:28.179591+05:30
168e8fe6-6040-4456-befc-028829726c99	Inactive Category	inactive-category	\N	\N	f	0	2026-11-15 10:01:28.201035+05:30	2026-11-15 10:01:28.201035+05:30
50d7689a-2493-4b20-a85d-af7cd476e9b1	Lehengas Cat 41bd	lehengas-cat-41bd	\N	\N	t	0	2026-11-15 10:01:28.246555+05:30	2026-11-15 10:01:28.246555+05:30
e72bd9d1-979a-41c1-9c5a-639dc8634ace	Kurti Collection 6c14	kurti-collection-6c14	\N	\N	t	0	2026-11-15 10:01:28.389541+05:30	2026-11-15 10:01:28.389541+05:30
cf2393cb-e99d-4cc7-907a-f5813c130879	Image Test Cat dbed	image-test-cat-dbed	\N	\N	t	0	2026-11-15 10:01:28.581564+05:30	2026-11-15 10:01:28.581564+05:30
ff5091d0-0bf0-441e-a120-220e6c800e6a	Rejection Test Cat 1bf3	rejection-test-cat-1bf3	\N	\N	t	0	2026-11-15 10:01:28.763826+05:30	2026-11-15 10:01:28.763826+05:30
4512def2-8df1-4d97-9550-b75991781ee8	Lehengas Cat 4774	lehengas-cat-4774	\N	\N	t	0	2026-11-15 10:01:45.544381+05:30	2026-11-15 10:01:45.544381+05:30
abc4174e-5689-4aeb-9b45-a8a099db66ff	Kurti Collection 812e	kurti-collection-812e	\N	\N	t	0	2026-11-15 10:01:45.703248+05:30	2026-11-15 10:01:45.703248+05:30
5a856a62-cbe9-4eff-81b2-380955216d0b	Image Test Cat 22b6	image-test-cat-22b6	\N	\N	t	0	2026-11-15 10:01:45.957912+05:30	2026-11-15 10:01:45.957912+05:30
0e512aa9-448a-41ba-8d3d-7bd7f149abff	Rejection Test Cat a44a	rejection-test-cat-a44a	\N	\N	t	0	2026-11-15 10:01:46.14261+05:30	2026-11-15 10:01:46.14261+05:30
8a12194b-5c2c-435a-8b73-28998e532a1e	Lehengas Cat e2ae	lehengas-cat-e2ae	\N	\N	t	0	2026-11-15 10:02:05.550184+05:30	2026-11-15 10:02:05.550184+05:30
8ff3312e-ff22-4a8b-8d25-20f2be3c0917	Kurti Collection a96f	kurti-collection-a96f	\N	\N	t	0	2026-11-15 10:02:05.705309+05:30	2026-11-15 10:02:05.705309+05:30
a9035475-ce06-4b9e-8a20-da7b7c28f95f	Image Test Cat 0f92	image-test-cat-0f92	\N	\N	t	0	2026-11-15 10:02:05.899562+05:30	2026-11-15 10:02:05.899562+05:30
6d029e3f-b360-4f80-91c2-c2f10d8efe2a	Rejection Test Cat cbd8	rejection-test-cat-cbd8	\N	\N	t	0	2026-11-15 10:02:06.083171+05:30	2026-11-15 10:02:06.083171+05:30
fa25b99d-8206-44aa-98e2-eb3f416aa2ec	Limit Cat 02e5	limit-cat-02e5	\N	\N	t	0	2026-11-15 10:02:06.154064+05:30	2026-11-15 10:02:06.154064+05:30
4df83f25-abf9-49f6-ad3b-0e514535957a	Lehengas Cat a613	lehengas-cat-a613	\N	\N	t	0	2026-11-15 10:10:40.842321+05:30	2026-11-15 10:10:40.842321+05:30
906b7a64-265f-4391-966a-e9b588fbbce5	Kurti Collection e11b	kurti-collection-e11b	\N	\N	t	0	2026-11-15 10:10:41.027208+05:30	2026-11-15 10:10:41.027208+05:30
68034739-481a-4809-b429-f7ee7cf3326f	Image Test Cat b030	image-test-cat-b030	\N	\N	t	0	2026-11-15 10:10:41.27442+05:30	2026-11-15 10:10:41.27442+05:30
b950e82e-006c-4c95-938f-e406002ec080	Rejection Test Cat 446b	rejection-test-cat-446b	\N	\N	t	0	2026-11-15 10:10:41.462878+05:30	2026-11-15 10:10:41.462878+05:30
f59c44e0-0942-42cd-89a0-d8175511f22f	Limit Cat 07db	limit-cat-07db	\N	\N	t	0	2026-11-15 10:10:41.586065+05:30	2026-11-15 10:10:41.586065+05:30
da17a607-4be3-4b8f-9b60-1eb125e56d17	Orders Cat 413f	orders-cat-413f	\N	\N	t	0	2026-11-15 10:10:42.267487+05:30	2026-11-15 10:10:42.267487+05:30
6fe9e1f5-399c-480c-84d1-cfed4eaa6ed1	Stock Cat b184	stock-cat-b184	\N	\N	t	0	2026-11-15 10:10:42.400775+05:30	2026-11-15 10:10:42.400775+05:30
f94befc7-a185-4bed-972b-76f9b043a604	Lehengas Cat 0071	lehengas-cat-0071	\N	\N	t	0	2026-11-15 10:13:44.730509+05:30	2026-11-15 10:13:44.730509+05:30
98743ad6-c6d4-4c0d-9a20-4602624d9213	Kurti Collection 83d2	kurti-collection-83d2	\N	\N	t	0	2026-11-15 10:13:44.912446+05:30	2026-11-15 10:13:44.912446+05:30
c1f0ab11-683e-447f-8fd3-92c8b7c43e2c	Image Test Cat d7dc	image-test-cat-d7dc	\N	\N	t	0	2026-11-15 10:13:45.170885+05:30	2026-11-15 10:13:45.170885+05:30
09ebe6c1-5992-473c-ad54-9b91e697125e	Rejection Test Cat 05ca	rejection-test-cat-05ca	\N	\N	t	0	2026-11-15 10:13:45.392059+05:30	2026-11-15 10:13:45.392059+05:30
fffd1980-24ce-4c91-94b7-6131cca1317d	Limit Cat 86f5	limit-cat-86f5	\N	\N	t	0	2026-11-15 10:13:45.493829+05:30	2026-11-15 10:13:45.493829+05:30
c5713b6a-44c0-4ae4-a9da-5f2f03f98d6c	Orders Cat d2aa	orders-cat-d2aa	\N	\N	t	0	2026-11-15 10:13:46.449846+05:30	2026-11-15 10:13:46.449846+05:30
da32effe-fd6f-4374-a319-fba88657fc03	Stock Cat 454b	stock-cat-454b	\N	\N	t	0	2026-11-15 10:13:46.616969+05:30	2026-11-15 10:13:46.616969+05:30
1882e2ae-479a-4684-97d6-1f62d1648fc7	Rev Test Cat 7c53	rev-test-cat-7c53	\N	\N	t	0	2026-11-15 10:13:47.491704+05:30	2026-11-15 10:13:47.491704+05:30
5b3aca88-c964-4dcc-92fd-b1f5c5bae266	Rev Cat 8048	rev-cat-8048	\N	\N	t	0	2026-11-15 10:13:47.60042+05:30	2026-11-15 10:13:47.60042+05:30
bedb0c8a-4969-4482-ad89-994e1370adc2	Lehengas Cat 24fd	lehengas-cat-24fd	\N	\N	t	0	2026-11-15 10:14:19.316229+05:30	2026-11-15 10:14:19.316229+05:30
455b8fde-36a9-4b51-a7a3-df714ff9e62f	Kurti Collection c2bb	kurti-collection-c2bb	\N	\N	t	0	2026-11-15 10:14:19.50486+05:30	2026-11-15 10:14:19.50486+05:30
3c88c48c-7051-4491-941e-c917413ebfca	Image Test Cat 8fd5	image-test-cat-8fd5	\N	\N	t	0	2026-11-15 10:14:19.821042+05:30	2026-11-15 10:14:19.821042+05:30
afc709b9-9ee1-4e96-8ea2-975446e0d8f5	Rejection Test Cat d4fe	rejection-test-cat-d4fe	\N	\N	t	0	2026-11-15 10:14:20.181862+05:30	2026-11-15 10:14:20.181862+05:30
1b996edc-2f17-4951-aa90-679ea599623f	Limit Cat 506a	limit-cat-506a	\N	\N	t	0	2026-11-15 10:14:20.280993+05:30	2026-11-15 10:14:20.280993+05:30
09155d29-0570-42df-a06a-2c12d04e64fc	Rev Test Cat 3d31	rev-test-cat-3d31	\N	\N	t	0	2026-11-15 10:14:21.586011+05:30	2026-11-15 10:14:21.586011+05:30
cfc314ef-cb7d-4527-b06f-04f672ddc453	Rev Cat 98b2	rev-cat-98b2	\N	\N	t	0	2026-11-15 10:14:21.861966+05:30	2026-11-15 10:14:21.861966+05:30
ee1e03d8-4616-4ff0-8181-ed0a763ab745	Lehengas Cat 3eef	lehengas-cat-3eef	\N	\N	t	0	2026-11-15 10:14:49.93748+05:30	2026-11-15 10:14:49.93748+05:30
0b589376-05fa-4962-8e59-f76a6dd9e6cc	Kurti Collection 2a96	kurti-collection-2a96	\N	\N	t	0	2026-11-15 10:14:50.157246+05:30	2026-11-15 10:14:50.157246+05:30
9d1b626a-5ed6-494d-8d33-86ec2061c3f8	Image Test Cat a290	image-test-cat-a290	\N	\N	t	0	2026-11-15 10:14:50.453662+05:30	2026-11-15 10:14:50.453662+05:30
ee832e73-df6e-41f0-992f-9239c69f3d48	Rejection Test Cat 358f	rejection-test-cat-358f	\N	\N	t	0	2026-11-15 10:14:50.755466+05:30	2026-11-15 10:14:50.755466+05:30
0fd12fda-18f1-48d9-ae87-29d153523b34	Limit Cat ce27	limit-cat-ce27	\N	\N	t	0	2026-11-15 10:14:50.852525+05:30	2026-11-15 10:14:50.852525+05:30
70fac41a-bdb9-4dbe-bfc1-5d944a24c222	Orders Cat 2d02	orders-cat-2d02	\N	\N	t	0	2026-11-15 10:14:51.555571+05:30	2026-11-15 10:14:51.555571+05:30
e07eaa40-0308-4f93-960f-610f90ec3a47	Stock Cat 983e	stock-cat-983e	\N	\N	t	0	2026-11-15 10:14:51.728581+05:30	2026-11-15 10:14:51.728581+05:30
21b4b069-025d-488f-9343-2997eb5e3a28	Rev Test Cat 8e81	rev-test-cat-8e81	\N	\N	t	0	2026-11-15 10:14:52.277315+05:30	2026-11-15 10:14:52.277315+05:30
b08d4e4a-4e19-424f-9b23-f4a325d61fca	Rev Cat 06c9	rev-cat-06c9	\N	\N	t	0	2026-11-15 10:14:52.407883+05:30	2026-11-15 10:14:52.407883+05:30
35877428-7d06-4cf9-bc16-335c55f7c275	Lehengas Cat 2585	lehengas-cat-2585	\N	\N	t	0	2026-11-15 10:29:53.65924+05:30	2026-11-15 10:29:53.65924+05:30
1d39d55b-3fbf-4fcd-a897-5848593f6f74	Kurti Collection aa29	kurti-collection-aa29	\N	\N	t	0	2026-11-15 10:29:53.877047+05:30	2026-11-15 10:29:53.877047+05:30
927d059f-9e8d-447f-b450-9c966fec7d93	Image Test Cat c624	image-test-cat-c624	\N	\N	t	0	2026-11-15 10:29:54.2184+05:30	2026-11-15 10:29:54.2184+05:30
d4716c88-7659-484b-8787-8d0b2e15fed9	Rejection Test Cat 01d3	rejection-test-cat-01d3	\N	\N	t	0	2026-11-15 10:29:54.495867+05:30	2026-11-15 10:29:54.495867+05:30
f826b9fc-b478-4bd8-8a89-71129305ceb6	Limit Cat f096	limit-cat-f096	\N	\N	t	0	2026-11-15 10:29:54.601458+05:30	2026-11-15 10:29:54.601458+05:30
1fec706f-d14b-4560-b0ed-3062aebd61c0	Orders Cat 268e	orders-cat-268e	\N	\N	t	0	2026-11-15 10:29:55.796078+05:30	2026-11-15 10:29:55.796078+05:30
6745f475-81b6-4de6-8a00-99f7a01c455e	Stock Cat ee7f	stock-cat-ee7f	\N	\N	t	0	2026-11-15 10:29:55.98596+05:30	2026-11-15 10:29:55.98596+05:30
3c228f25-f710-4f41-8c39-a01aa1f161aa	Rev Test Cat 19f2	rev-test-cat-19f2	\N	\N	t	0	2026-11-15 10:29:56.577301+05:30	2026-11-15 10:29:56.577301+05:30
1c790444-bf73-49db-9655-43ffa78fda3d	Rev Cat f397	rev-cat-f397	\N	\N	t	0	2026-11-15 10:29:56.680725+05:30	2026-11-15 10:29:56.680725+05:30
\.


--
-- Data for Name: delivery_rules; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.delivery_rules (id, name, min_order_amount, max_order_amount, charge, priority, is_active, created_at) FROM stdin;
\.


--
-- Data for Name: delivery_settings; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.delivery_settings (id, is_free_delivery_active, free_delivery_threshold, default_delivery_charge, updated_at) FROM stdin;
8ade6945-6750-4f65-83ad-54131ad7acb5	t	1500.00	50.00	2026-11-15 10:10:42.220203+05:30
\.


--
-- Data for Name: order_items; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.order_items (id, order_id, product_id, product_name_snapshot, unit_price_snapshot, quantity, line_total) FROM stdin;
37442f80-e0f2-4593-a27f-601dba0f7b6d	bbb45b77-b6be-464e-80ee-84b1ccb20b9b	c3141fac-b251-41ce-9df8-230a49a63647	Kanjeevaram Saree	2500.00	2	5000.00
908f2dbc-2b58-47a7-a04f-e2a14c12174f	0b98b276-39e5-4e77-a659-20de2f0ade2d	a2af9a33-3f59-48ff-8ab0-a1263d0ac1a4	Designer Anarkali	1200.00	2	2400.00
619acc7e-beb4-4def-a9aa-1122314057c1	a2b17648-ffd3-450e-a2a1-5dfb576835d6	a2af9a33-3f59-48ff-8ab0-a1263d0ac1a4	Designer Anarkali	1200.00	1	1200.00
7cb3b5c9-1867-4fd0-86f9-651736269e2d	90804940-f86e-4215-b1de-26e8bb30b3c4	617d364e-721b-4fde-8f53-2e77eb52f004	Kanjeevaram Saree	2500.00	2	5000.00
a144e037-331e-4386-b864-fbac909a36bd	bd8a58dc-dd91-4188-aed1-d94e9997a78c	9202455a-e5cf-4f53-9a6c-996db572f95d	Designer Anarkali	1200.00	2	2400.00
8262902d-0f8c-4f70-ad4c-dca9be2389f1	d2185ec8-78d3-427a-bb73-76e0dc854c0a	9202455a-e5cf-4f53-9a6c-996db572f95d	Designer Anarkali	1200.00	1	1200.00
fbac5b48-6e64-4b8a-969b-76604b0ae5ec	68b52f0f-2c58-4586-ad70-387394f3beb4	afebdf53-7a86-426c-bba9-aaf48b121bbb	Handloom Chanderi Saree	1800.00	1	1800.00
3e1bd17f-210b-4a14-bba5-c4976ddb57a2	68b427e1-6428-436b-be6d-3acd12b8bbf7	42385415-2211-47a1-9b50-dc1b1d8c23f2	Handloom Chanderi Saree	1800.00	1	1800.00
61f21cb8-55ec-44ea-b49b-eb47198b07f2	eb6264aa-490f-4031-b1c6-cdd385eb6da7	faf1c7e1-4922-4123-b831-f79999db5bfe	Kanjeevaram Saree	2500.00	2	5000.00
6a65cb51-afa3-4a95-b501-040b900d4414	ba59ad3d-ba1b-46b5-a10b-9217e7f56bc3	2a7f8a7b-66b0-44c0-ac79-d11f7f4f2a02	Designer Anarkali	1200.00	2	2400.00
3c493932-b765-4d47-b266-45cbb48a34cc	743fa268-2958-4657-adcc-aa2a9f546f45	2a7f8a7b-66b0-44c0-ac79-d11f7f4f2a02	Designer Anarkali	1200.00	1	1200.00
4e6d530f-5ead-42cc-bb4e-ddae6dbd3347	2eb271d6-6ef6-43f7-b056-c66beb01f62c	46d58e57-5df8-4649-85ec-79c7cd85b022	Handloom Chanderi Saree	1800.00	1	1800.00
c378b243-0cc1-4957-b7af-230b7c49ce2e	e78a27dd-14b3-408d-a2e8-e503834c1aa5	78b3945d-79e4-440f-a15f-c426071cac15	Kanjeevaram Saree	2500.00	2	5000.00
632cd35e-d729-47e5-8529-631115fc1056	696f8812-efa9-42e3-a93e-99ab6861928f	710d9bcb-6b8c-4c8b-9c53-492c0df2e86d	Designer Anarkali	1200.00	2	2400.00
0cf8ba50-a1fc-4b34-8d31-af5e42955422	8de0fc91-01c3-4ca6-9577-be8cfbd16cda	710d9bcb-6b8c-4c8b-9c53-492c0df2e86d	Designer Anarkali	1200.00	1	1200.00
a1238941-cee6-4348-8e08-4c7070345f60	d86d32a9-0db5-4e9b-99b3-fe2985a19674	000a5355-da52-4731-bd9d-80c24734f27c	Handloom Chanderi Saree	1800.00	1	1800.00
\.


--
-- Data for Name: order_status_history; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.order_status_history (id, order_id, old_status, new_status, changed_by_user_id, comment, created_at) FROM stdin;
cea38100-e27c-413f-a046-38d6818b5e24	bbb45b77-b6be-464e-80ee-84b1ccb20b9b	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:10:42.350233+05:30
f9b487a3-a45a-4ffd-9774-10423c60df18	0b98b276-39e5-4e77-a659-20de2f0ade2d	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:10:42.472207+05:30
15cd8a53-64c0-41bc-9226-b2e08e4f461d	0b98b276-39e5-4e77-a659-20de2f0ade2d	pending	cancelled	1daafa1a-445c-4384-be91-90fec39bb341	Order cancelled by customer.	2026-11-15 10:10:42.505023+05:30
f25b6aca-8f18-42f2-88d5-006daf175ddf	a2b17648-ffd3-450e-a2a1-5dfb576835d6	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:10:42.565694+05:30
7e104b80-e32f-4119-ae3c-010ac7742b42	a2b17648-ffd3-450e-a2a1-5dfb576835d6	pending	confirmed	ba487f6a-8977-472b-9ce5-bb32b22284e6	Order verified with customer.	2026-11-15 10:10:42.587513+05:30
f0798755-c1a4-45f1-9b67-b377c19521b9	a2b17648-ffd3-450e-a2a1-5dfb576835d6	confirmed	preparing	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to preparing by admin.	2026-11-15 10:10:42.63113+05:30
ad682ca9-e582-4234-8fe5-697d30eb2970	a2b17648-ffd3-450e-a2a1-5dfb576835d6	preparing	out_for_delivery	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to out_for_delivery by admin.	2026-11-15 10:10:42.664041+05:30
d97f6655-8975-4755-9882-048cea3b69a6	a2b17648-ffd3-450e-a2a1-5dfb576835d6	out_for_delivery	delivered	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to delivered by admin.	2026-11-15 10:10:42.703225+05:30
2fbfb1a6-7d2a-42bc-9532-7c6609db2c4b	90804940-f86e-4215-b1de-26e8bb30b3c4	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:13:46.547861+05:30
cd29ef27-98d9-4915-b002-79ed51e36ca1	bd8a58dc-dd91-4188-aed1-d94e9997a78c	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:13:46.702208+05:30
8762adf4-14d4-4bf1-a665-d2bb78b06c31	bd8a58dc-dd91-4188-aed1-d94e9997a78c	pending	cancelled	1daafa1a-445c-4384-be91-90fec39bb341	Order cancelled by customer.	2026-11-15 10:13:46.755377+05:30
6803a524-ce31-442e-aed6-095d586cd86d	d2185ec8-78d3-427a-bb73-76e0dc854c0a	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:13:46.828264+05:30
b0581cb9-dec7-4d56-a9af-2d5ad148aa34	d2185ec8-78d3-427a-bb73-76e0dc854c0a	pending	confirmed	ba487f6a-8977-472b-9ce5-bb32b22284e6	Order verified with customer.	2026-11-15 10:13:46.862773+05:30
4daea8a9-5ad8-46b2-b702-40549bc6484a	d2185ec8-78d3-427a-bb73-76e0dc854c0a	confirmed	preparing	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to preparing by admin.	2026-11-15 10:13:46.924085+05:30
88e8f559-4f96-40b8-98e4-3e7d722177b8	d2185ec8-78d3-427a-bb73-76e0dc854c0a	preparing	out_for_delivery	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to out_for_delivery by admin.	2026-11-15 10:13:46.966878+05:30
fd6956f6-1750-45fe-a691-ce074645ab33	d2185ec8-78d3-427a-bb73-76e0dc854c0a	out_for_delivery	delivered	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to delivered by admin.	2026-11-15 10:13:47.013572+05:30
4d969ea4-580c-4945-9239-9834377ffc6f	68b52f0f-2c58-4586-ad70-387394f3beb4	\N	pending	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Order placed by customer.	2026-11-15 10:13:47.691386+05:30
91e87de7-7284-46ed-944f-8057b915f0f2	68b52f0f-2c58-4586-ad70-387394f3beb4	pending	confirmed	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to confirmed by admin.	2026-11-15 10:13:47.737553+05:30
05ef8207-cf85-4aba-9a7e-7f5acc840953	68b52f0f-2c58-4586-ad70-387394f3beb4	confirmed	preparing	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to preparing by admin.	2026-11-15 10:13:47.787423+05:30
711ee42c-faa8-43d9-a79f-3c330d8284ff	68b52f0f-2c58-4586-ad70-387394f3beb4	preparing	out_for_delivery	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to out_for_delivery by admin.	2026-11-15 10:13:47.837923+05:30
f337538e-fb2d-4315-913a-dcc0225e6964	68b52f0f-2c58-4586-ad70-387394f3beb4	out_for_delivery	delivered	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to delivered by admin.	2026-11-15 10:13:47.876174+05:30
089adaee-fecc-4acd-8f8f-5cf645f481f7	68b427e1-6428-436b-be6d-3acd12b8bbf7	\N	pending	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Order placed by customer.	2026-11-15 10:14:22.036717+05:30
e79b0491-abb5-43ea-9a73-e2d144ee65d1	68b427e1-6428-436b-be6d-3acd12b8bbf7	pending	confirmed	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to confirmed by admin.	2026-11-15 10:14:22.122007+05:30
aa8b310d-543f-4ec0-8d4a-58ed39940f04	68b427e1-6428-436b-be6d-3acd12b8bbf7	confirmed	preparing	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to preparing by admin.	2026-11-15 10:14:22.212785+05:30
edb78213-90a0-4426-8a21-f43e23a020e0	68b427e1-6428-436b-be6d-3acd12b8bbf7	preparing	out_for_delivery	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to out_for_delivery by admin.	2026-11-15 10:14:22.298078+05:30
2f572627-67be-4c50-8215-a427ef9f3b9e	68b427e1-6428-436b-be6d-3acd12b8bbf7	out_for_delivery	delivered	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to delivered by admin.	2026-11-15 10:14:22.369452+05:30
8f53648b-d7ad-4c6d-93ae-3cd1e5cef8bf	eb6264aa-490f-4031-b1c6-cdd385eb6da7	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:14:51.65738+05:30
96f5ba63-85c1-4f18-b55a-db9ed83a2636	ba59ad3d-ba1b-46b5-a10b-9217e7f56bc3	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:14:51.819922+05:30
16e3baa6-d5e4-4961-8848-980b3ff79f9b	ba59ad3d-ba1b-46b5-a10b-9217e7f56bc3	pending	cancelled	1daafa1a-445c-4384-be91-90fec39bb341	Order cancelled by customer.	2026-11-15 10:14:51.885917+05:30
9ca85fa0-26aa-424f-8bcd-6b9e498b61a9	743fa268-2958-4657-adcc-aa2a9f546f45	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:14:51.957791+05:30
7efddadd-2327-49b7-aee9-2419d84fdf0c	743fa268-2958-4657-adcc-aa2a9f546f45	pending	confirmed	ba487f6a-8977-472b-9ce5-bb32b22284e6	Order verified with customer.	2026-11-15 10:14:52.001133+05:30
60bb7991-a847-486a-9af1-e3eea5a93287	743fa268-2958-4657-adcc-aa2a9f546f45	confirmed	preparing	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to preparing by admin.	2026-11-15 10:14:52.063372+05:30
ab006bc2-45f4-4ca0-824a-bfee5940dbf8	743fa268-2958-4657-adcc-aa2a9f546f45	preparing	out_for_delivery	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to out_for_delivery by admin.	2026-11-15 10:14:52.103682+05:30
d3f12ff3-4b97-4772-bfde-41c372c9d7c4	743fa268-2958-4657-adcc-aa2a9f546f45	out_for_delivery	delivered	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to delivered by admin.	2026-11-15 10:14:52.153633+05:30
53bcc4ef-8b1b-4277-91a0-2540f834c4e7	2eb271d6-6ef6-43f7-b056-c66beb01f62c	\N	pending	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Order placed by customer.	2026-11-15 10:14:52.506707+05:30
1b634759-d4f9-4fc0-b2a0-dc58398f9507	2eb271d6-6ef6-43f7-b056-c66beb01f62c	pending	confirmed	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to confirmed by admin.	2026-11-15 10:14:52.550963+05:30
cc8fd3bd-4ce8-4076-98df-1764b2fc0780	2eb271d6-6ef6-43f7-b056-c66beb01f62c	confirmed	preparing	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to preparing by admin.	2026-11-15 10:14:52.586695+05:30
73cde972-dc50-405e-90bb-4e98e02da127	2eb271d6-6ef6-43f7-b056-c66beb01f62c	preparing	out_for_delivery	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to out_for_delivery by admin.	2026-11-15 10:14:52.654745+05:30
25490938-1e4f-4148-beb4-873e1dfe8438	2eb271d6-6ef6-43f7-b056-c66beb01f62c	out_for_delivery	delivered	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to delivered by admin.	2026-11-15 10:14:52.711277+05:30
a9e95275-2acf-45b2-9964-0088e5ffcb62	e78a27dd-14b3-408d-a2e8-e503834c1aa5	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:29:55.900915+05:30
7d0a8909-0873-4c2a-a813-e6cbe646bc85	696f8812-efa9-42e3-a93e-99ab6861928f	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:29:56.093868+05:30
68e9b1b9-12f1-479c-8b5b-a3cb7ee4e88e	696f8812-efa9-42e3-a93e-99ab6861928f	pending	cancelled	1daafa1a-445c-4384-be91-90fec39bb341	Order cancelled by customer.	2026-11-15 10:29:56.164017+05:30
4288d082-8742-4c9b-acce-bb7bcdc433a8	8de0fc91-01c3-4ca6-9577-be8cfbd16cda	\N	pending	1daafa1a-445c-4384-be91-90fec39bb341	Order placed by customer.	2026-11-15 10:29:56.231404+05:30
6db80304-f5ed-439a-9d1d-293c158fde9d	8de0fc91-01c3-4ca6-9577-be8cfbd16cda	pending	confirmed	ba487f6a-8977-472b-9ce5-bb32b22284e6	Order verified with customer.	2026-11-15 10:29:56.279385+05:30
a6512913-1c13-45ea-9004-2bb9464e62fc	8de0fc91-01c3-4ca6-9577-be8cfbd16cda	confirmed	preparing	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to preparing by admin.	2026-11-15 10:29:56.347766+05:30
18073f30-8203-44df-a001-912f13aae57f	8de0fc91-01c3-4ca6-9577-be8cfbd16cda	preparing	out_for_delivery	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to out_for_delivery by admin.	2026-11-15 10:29:56.400352+05:30
4a622cac-a9ad-4ceb-9534-19d4ba30d708	8de0fc91-01c3-4ca6-9577-be8cfbd16cda	out_for_delivery	delivered	ba487f6a-8977-472b-9ce5-bb32b22284e6	Status changed to delivered by admin.	2026-11-15 10:29:56.446644+05:30
6d6c8aa1-d429-4770-badf-f8644bd4c333	d86d32a9-0db5-4e9b-99b3-fe2985a19674	\N	pending	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	Order placed by customer.	2026-11-15 10:29:56.778391+05:30
92ed93d7-bfc2-4a4e-b02b-7fb13523c880	d86d32a9-0db5-4e9b-99b3-fe2985a19674	pending	confirmed	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to confirmed by admin.	2026-11-15 10:29:56.828261+05:30
3e6c1aad-ff75-4733-b52e-33eb68ae8b81	d86d32a9-0db5-4e9b-99b3-fe2985a19674	confirmed	preparing	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to preparing by admin.	2026-11-15 10:29:56.878979+05:30
308fde8d-bcba-4a32-b3ad-4bff9f204918	d86d32a9-0db5-4e9b-99b3-fe2985a19674	preparing	out_for_delivery	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to out_for_delivery by admin.	2026-11-15 10:29:56.927612+05:30
b65d5da1-4225-412e-865c-a85ea58a2d71	d86d32a9-0db5-4e9b-99b3-fe2985a19674	out_for_delivery	delivered	a5cd818b-efbd-461c-bf1f-2ae6319c826e	Status changed to delivered by admin.	2026-11-15 10:29:56.972122+05:30
\.


--
-- Data for Name: orders; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.orders (id, order_number, customer_id, status, subtotal, delivery_charge, total, delivery_address_snapshot, note, created_at, updated_at) FROM stdin;
bbb45b77-b6be-464e-80ee-84b1ccb20b9b	ORD-20261115-40DE	1daafa1a-445c-4384-be91-90fec39bb341	pending	5000.00	0.00	5000.00	{"city": "Kolkata", "phone": "+91 9888877777", "state": "West Bengal", "street": "77 Park Street", "postal_code": "700016", "recipient_name": "Ananya Roy"}	Please gift wrap with golden ribbon.	2026-11-15 10:10:42.345417+05:30	2026-11-15 10:10:42.345417+05:30
0b98b276-39e5-4e77-a659-20de2f0ade2d	ORD-20261115-3AC7	1daafa1a-445c-4384-be91-90fec39bb341	cancelled	2400.00	0.00	2400.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:10:42.456519+05:30	2026-11-15 10:10:42.505023+05:30
a2b17648-ffd3-450e-a2a1-5dfb576835d6	ORD-20261115-DFD0	1daafa1a-445c-4384-be91-90fec39bb341	delivered	1200.00	50.00	1250.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:10:42.552292+05:30	2026-11-15 10:10:42.703225+05:30
90804940-f86e-4215-b1de-26e8bb30b3c4	ORD-20261115-B35A	1daafa1a-445c-4384-be91-90fec39bb341	pending	5000.00	0.00	5000.00	{"city": "Kolkata", "phone": "+91 9888877777", "state": "West Bengal", "street": "77 Park Street", "postal_code": "700016", "recipient_name": "Ananya Roy"}	Please gift wrap with golden ribbon.	2026-11-15 10:13:46.542891+05:30	2026-11-15 10:13:46.542891+05:30
bd8a58dc-dd91-4188-aed1-d94e9997a78c	ORD-20261115-3A3B	1daafa1a-445c-4384-be91-90fec39bb341	cancelled	2400.00	0.00	2400.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:13:46.699607+05:30	2026-11-15 10:13:46.755377+05:30
d2185ec8-78d3-427a-bb73-76e0dc854c0a	ORD-20261115-ACD8	1daafa1a-445c-4384-be91-90fec39bb341	delivered	1200.00	50.00	1250.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:13:46.817668+05:30	2026-11-15 10:13:47.005789+05:30
68b52f0f-2c58-4586-ad70-387394f3beb4	ORD-20261115-2E45	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	delivered	1800.00	0.00	1800.00	{"city": "Jaipur", "phone": "+91 9123456789", "state": "Rajasthan", "street": "12 Lake View Road", "postal_code": "302001", "recipient_name": "Kavita Sen"}	\N	2026-11-15 10:13:47.691386+05:30	2026-11-15 10:13:47.876174+05:30
68b427e1-6428-436b-be6d-3acd12b8bbf7	ORD-20261115-5777	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	delivered	1800.00	0.00	1800.00	{"city": "Jaipur", "phone": "+91 9123456789", "state": "Rajasthan", "street": "12 Lake View Road", "postal_code": "302001", "recipient_name": "Kavita Sen"}	\N	2026-11-15 10:14:22.021269+05:30	2026-11-15 10:14:22.367419+05:30
eb6264aa-490f-4031-b1c6-cdd385eb6da7	ORD-20261115-56D0	1daafa1a-445c-4384-be91-90fec39bb341	pending	5000.00	0.00	5000.00	{"city": "Kolkata", "phone": "+91 9888877777", "state": "West Bengal", "street": "77 Park Street", "postal_code": "700016", "recipient_name": "Ananya Roy"}	Please gift wrap with golden ribbon.	2026-11-15 10:14:51.649099+05:30	2026-11-15 10:14:51.649099+05:30
ba59ad3d-ba1b-46b5-a10b-9217e7f56bc3	ORD-20261115-BA55	1daafa1a-445c-4384-be91-90fec39bb341	cancelled	2400.00	0.00	2400.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:14:51.819922+05:30	2026-11-15 10:14:51.884558+05:30
743fa268-2958-4657-adcc-aa2a9f546f45	ORD-20261115-6526	1daafa1a-445c-4384-be91-90fec39bb341	delivered	1200.00	50.00	1250.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:14:51.954721+05:30	2026-11-15 10:14:52.152159+05:30
2eb271d6-6ef6-43f7-b056-c66beb01f62c	ORD-20261115-9701	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	delivered	1800.00	0.00	1800.00	{"city": "Jaipur", "phone": "+91 9123456789", "state": "Rajasthan", "street": "12 Lake View Road", "postal_code": "302001", "recipient_name": "Kavita Sen"}	\N	2026-11-15 10:14:52.503678+05:30	2026-11-15 10:14:52.711277+05:30
e78a27dd-14b3-408d-a2e8-e503834c1aa5	ORD-20261115-CB32	1daafa1a-445c-4384-be91-90fec39bb341	pending	5000.00	0.00	5000.00	{"city": "Kolkata", "phone": "+91 9888877777", "state": "West Bengal", "street": "77 Park Street", "postal_code": "700016", "recipient_name": "Ananya Roy"}	Please gift wrap with golden ribbon.	2026-11-15 10:29:55.900915+05:30	2026-11-15 10:29:55.900915+05:30
696f8812-efa9-42e3-a93e-99ab6861928f	ORD-20261115-CAB3	1daafa1a-445c-4384-be91-90fec39bb341	cancelled	2400.00	0.00	2400.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:29:56.08396+05:30	2026-11-15 10:29:56.147464+05:30
8de0fc91-01c3-4ca6-9577-be8cfbd16cda	ORD-20261115-98A1	1daafa1a-445c-4384-be91-90fec39bb341	delivered	1200.00	50.00	1250.00	{"city": "Ahmedabad", "phone": "+91 9777766666", "state": "Gujarat", "street": "10 Palace Road", "postal_code": "380001", "recipient_name": "Meera Patel"}	\N	2026-11-15 10:29:56.231404+05:30	2026-11-15 10:29:56.444174+05:30
d86d32a9-0db5-4e9b-99b3-fe2985a19674	ORD-20261115-D6FF	bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	delivered	1800.00	0.00	1800.00	{"city": "Jaipur", "phone": "+91 9123456789", "state": "Rajasthan", "street": "12 Lake View Road", "postal_code": "302001", "recipient_name": "Kavita Sen"}	\N	2026-11-15 10:29:56.778391+05:30	2026-11-15 10:29:56.972122+05:30
\.


--
-- Data for Name: product_images; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.product_images (id, product_id, cloudinary_url, cloudinary_public_id, cloudinary_asset_id, width, height, format, bytes_size, sort_order, is_primary, created_at) FROM stdin;
76f6d8bb-d58b-4100-81ec-acf7419c3f0e	46dd6a05-3201-420e-bfea-1f3baf12bcec	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:01:28.62874+05:30
b7e61805-58fd-40e6-aa73-d697c0991c75	b8e2a892-1060-4eb7-92e0-99d790a1491e	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:01:46.011819+05:30
12dbe05c-64b5-416a-a4fb-ef069fb40fde	f1b3e816-1b33-43a5-8222-d4b6741aa483	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:02:05.950007+05:30
8f608c4b-a7ea-4d02-93b0-9e066ae5f66e	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	0	t	2026-11-15 10:02:06.202358+05:30
173eb2ad-d4f6-497c-a1b0-276792019a3a	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	1	f	2026-11-15 10:02:06.218036+05:30
913ba37f-6e58-4137-a87e-c975116d5589	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	2	f	2026-11-15 10:02:06.249491+05:30
689e1199-9370-4b16-ac46-1f258ebfff05	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	3	f	2026-11-15 10:02:06.266271+05:30
2d98efc8-9daa-487c-9cdd-61382bb3df00	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	4	f	2026-11-15 10:02:06.283429+05:30
b8a769ab-64dd-4b07-97c5-9e8e4212413b	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	5	f	2026-11-15 10:02:06.297235+05:30
b158ca08-0714-4cd7-a35e-715ad3aa608c	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	6	f	2026-11-15 10:02:06.330371+05:30
574a9cc7-3fb3-4c2d-aed7-95466ec3988e	46077423-9da3-4301-86d0-fc78beeddc25	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	7	f	2026-11-15 10:02:06.350271+05:30
c13b5d50-d2b8-4de8-8701-8bd9d727521b	cdf13e71-85ed-4626-a0a5-0a0fa2dbc1f7	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:10:41.332874+05:30
48bd8569-09c8-43f0-a0a3-17b0038c4b8d	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	0	t	2026-11-15 10:10:41.635545+05:30
a47fa4e1-6450-47fe-938e-783a3eff5e58	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	1	f	2026-11-15 10:10:41.649188+05:30
ad70fc8d-c16e-41b1-8dd1-994c1b983a59	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	2	f	2026-11-15 10:10:41.68442+05:30
e6d4bf81-6194-4594-8216-b8ea79f35b49	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	3	f	2026-11-15 10:10:41.704598+05:30
c419d98f-b9ae-48e4-b631-8e139f0f91cc	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	4	f	2026-11-15 10:10:41.728838+05:30
0aab0542-4524-4479-937a-6cdcfa4f557e	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	5	f	2026-11-15 10:10:41.746682+05:30
cce36eb8-06fc-4345-aaad-39baec64aaaa	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	6	f	2026-11-15 10:10:41.7655+05:30
60fc6dd8-393e-46ec-a6a4-d43ea34846af	8bb49474-8f69-4b81-a9f1-0f35df39e0f6	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	7	f	2026-11-15 10:10:41.791119+05:30
4166575d-ef0b-4789-aff3-eb97c508bb56	4ccf035f-6ecd-40d1-9b1b-1bf50860200d	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:13:45.236086+05:30
3715557d-2409-4e46-8438-78ede1accd85	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	0	t	2026-11-15 10:13:45.607964+05:30
b7cf8161-6040-4b45-9eb2-0410765d16cc	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	1	f	2026-11-15 10:13:45.635807+05:30
da6484b8-900f-4186-9e65-f1729abf0b7d	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	2	f	2026-11-15 10:13:45.667532+05:30
3fe8dfbb-afe9-4ddf-a8e9-cd8d6e0612c6	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	3	f	2026-11-15 10:13:45.683218+05:30
a4b41de7-618d-4b04-afb1-b5a4dde33647	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	4	f	2026-11-15 10:13:45.717787+05:30
677f670c-2f99-444b-90be-d10998174fbd	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	5	f	2026-11-15 10:13:45.747421+05:30
58dda76f-008f-49ef-a331-e0f5c1d87d7f	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	6	f	2026-11-15 10:13:45.774963+05:30
70767855-9869-44cb-a552-2e4e0b29bdbd	fc5be87d-c87a-4561-9a7c-a72d8948bf6c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	7	f	2026-11-15 10:13:45.794665+05:30
44b1b258-987a-4396-8578-ada4c9a911d9	6203e6af-5069-4e7c-b960-02bb8df04f94	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:14:19.913564+05:30
34c27cc0-a7c4-4a97-86ad-473598a472d4	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	0	t	2026-11-15 10:14:20.362127+05:30
fa185f31-210b-4f7b-98d0-2270517ba42b	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	1	f	2026-11-15 10:14:20.393952+05:30
211b2079-e99c-4504-8543-99b2e03958b6	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	2	f	2026-11-15 10:14:20.430619+05:30
bd632944-28cf-4bb1-b238-30a81bb0059e	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	3	f	2026-11-15 10:14:20.463349+05:30
15a39d5e-e71d-43d1-89dd-6eb6e4cc7495	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	4	f	2026-11-15 10:14:20.497545+05:30
c980b6c3-a2ab-4196-871e-6c79ca24db72	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	5	f	2026-11-15 10:14:20.530306+05:30
012b0b51-14cf-45e3-ad93-d1effc501a67	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	6	f	2026-11-15 10:14:20.562489+05:30
65f29cd5-1393-4fb7-96b6-7abd9e5b75e0	7a9f76de-a53d-4f70-8e41-9e36964392ed	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	7	f	2026-11-15 10:14:20.580884+05:30
3c2ab1a8-cb02-4e4e-94a5-db9176ebf6a7	826eb0e2-096e-4c3d-94c5-60a9c1ce30d8	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:14:50.519531+05:30
57be6878-975d-46b7-882c-b9bcd52953c2	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	0	t	2026-11-15 10:14:50.924306+05:30
47068169-ef14-4812-9b81-c646b97f3a31	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	1	f	2026-11-15 10:14:50.953457+05:30
0d5f6d96-0adf-42c9-976f-a5f194329737	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	2	f	2026-11-15 10:14:50.972888+05:30
7ebf2c12-70ca-4890-9747-43ea03c3bb41	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	3	f	2026-11-15 10:14:51.004913+05:30
64721d05-8126-4932-828a-b4495b28ad68	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	4	f	2026-11-15 10:14:51.045256+05:30
95e82bc5-f918-4e7b-8b5a-3c65f76c9ca5	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	5	f	2026-11-15 10:14:51.070353+05:30
e4f53725-d828-4bce-951c-19a47d7d6e3d	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	6	f	2026-11-15 10:14:51.109507+05:30
31e1c08a-3cbd-4598-b123-d9ac0e1ec406	8a70a6a8-b203-4c7f-bb27-1d6bc488971c	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	7	f	2026-11-15 10:14:51.152401+05:30
c035e498-5742-41e7-9713-7d8a740cdfb5	491ec707-5033-4060-9175-b5448e3d958b	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample1	asset12345	800	1000	jpg	102400	0	t	2026-11-15 10:29:54.29269+05:30
b5573f98-46da-4145-9e3e-fb494c9ce678	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	0	t	2026-11-15 10:29:54.685885+05:30
ac2d5672-d627-41be-b1ff-b8007cf37ba2	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	1	f	2026-11-15 10:29:54.762193+05:30
dea669f5-3a31-4e36-804d-2a698d295747	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	2	f	2026-11-15 10:29:54.796946+05:30
6ed86470-a602-4adf-b7d8-7c2850436393	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	3	f	2026-11-15 10:29:54.828981+05:30
7190b02f-71b2-45ab-8951-d2400a555fff	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	4	f	2026-11-15 10:29:54.867382+05:30
de3ec3d7-1495-4e5e-a5e3-3cb1ffeb1b12	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	5	f	2026-11-15 10:29:55.151641+05:30
6de2d258-2731-46d2-b6f2-b95c38cbb06b	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	6	f	2026-11-15 10:29:55.215502+05:30
48efff28-73de-4619-b50c-38c52142a856	1b4a279f-8209-4ec7-af3f-d185cfb8e26a	https://res.cloudinary.com/demo/image/upload/sample.jpg	stitch_style/products/sample_limit	asset12345	800	1000	jpg	50000	7	f	2026-11-15 10:29:55.258556+05:30
\.


--
-- Data for Name: products; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.products (id, name, slug, description, price, category_id, is_available, stock_quantity, is_active, created_at, updated_at) FROM stdin;
31e4b0a5-c757-4e30-9794-1e7fe88ff1d7	Bridal Velvet Lehenga	bridal-velvet-lehenga	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	50d7689a-2493-4b20-a85d-af7cd476e9b1	t	5	t	2026-11-15 10:01:28.281292+05:30	2026-11-15 10:01:28.319826+05:30
595e0e20-7548-42a2-be97-6e8693bf755a	Cotton Casual Kurti	cotton-casual-kurti	Comfortable cotton	499.00	e72bd9d1-979a-41c1-9c5a-639dc8634ace	t	\N	t	2026-11-15 10:01:28.403516+05:30	2026-11-15 10:01:28.403516+05:30
5aa22959-baec-4843-8ebc-9cd024782f90	Embroidered Party Kurti	embroidered-party-kurti	Silk blend party wear	1299.00	e72bd9d1-979a-41c1-9c5a-639dc8634ace	t	\N	t	2026-11-15 10:01:28.438822+05:30	2026-11-15 10:01:28.438822+05:30
40de0a52-d581-47e1-854e-ebf57488fe55	Designer Anarkali Kurti	designer-anarkali-kurti	Floor length	2999.00	e72bd9d1-979a-41c1-9c5a-639dc8634ace	t	\N	t	2026-11-15 10:01:28.466122+05:30	2026-11-15 10:01:28.466122+05:30
46dd6a05-3201-420e-bfea-1f3baf12bcec	Saree Image Test	saree-image-test		999.00	cf2393cb-e99d-4cc7-907a-f5813c130879	t	\N	t	2026-11-15 10:01:28.598599+05:30	2026-11-15 10:01:28.598599+05:30
5e564c27-8ba8-4488-86ac-40dfd76e4e62	Rejection Prod	rejection-prod		999.00	ff5091d0-0bf0-441e-a120-220e6c800e6a	t	\N	t	2026-11-15 10:01:28.779602+05:30	2026-11-15 10:01:28.779602+05:30
7221d2ef-ce6e-4204-8dce-3be5ae7009f7	Bridal Velvet Lehenga	bridal-velvet-lehenga-1616fb	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	4512def2-8df1-4d97-9550-b75991781ee8	t	5	t	2026-11-15 10:01:45.590972+05:30	2026-11-15 10:01:45.623804+05:30
835a1bd2-34ec-47eb-9219-74a223dac9ea	Cotton Casual Kurti	cotton-casual-kurti-10a8c3	Comfortable cotton	499.00	abc4174e-5689-4aeb-9b45-a8a099db66ff	t	\N	t	2026-11-15 10:01:45.722726+05:30	2026-11-15 10:01:45.722726+05:30
8f1272a7-a5d1-4d3a-abee-cad9dbe0fb6c	Embroidered Party Kurti	embroidered-party-kurti-93809f	Silk blend party wear	1299.00	abc4174e-5689-4aeb-9b45-a8a099db66ff	t	\N	t	2026-11-15 10:01:45.750027+05:30	2026-11-15 10:01:45.750027+05:30
bb8fe9ea-2415-4e43-aca0-8eadf221cc89	Designer Anarkali Kurti	designer-anarkali-kurti-a6770c	Floor length	2999.00	abc4174e-5689-4aeb-9b45-a8a099db66ff	t	\N	t	2026-11-15 10:01:45.787776+05:30	2026-11-15 10:01:45.787776+05:30
b8e2a892-1060-4eb7-92e0-99d790a1491e	Saree Image Test	saree-image-test-c4da50		999.00	5a856a62-cbe9-4eff-81b2-380955216d0b	t	\N	t	2026-11-15 10:01:45.980013+05:30	2026-11-15 10:01:45.980013+05:30
be3eb306-a2aa-47b4-aa40-43fea8e8154d	Rejection Prod	rejection-prod-d58be3		999.00	0e512aa9-448a-41ba-8d3d-7bd7f149abff	t	\N	t	2026-11-15 10:01:46.168163+05:30	2026-11-15 10:01:46.168163+05:30
ec9b71b0-c497-4d80-89d1-98322b97423c	Bridal Velvet Lehenga	bridal-velvet-lehenga-361491	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	8a12194b-5c2c-435a-8b73-28998e532a1e	t	5	t	2026-11-15 10:02:05.593346+05:30	2026-11-15 10:02:05.633109+05:30
e4a5dbe4-876c-47eb-9976-7ce6aa0ddaf3	Cotton Casual Kurti	cotton-casual-kurti-40e860	Comfortable cotton	499.00	8ff3312e-ff22-4a8b-8d25-20f2be3c0917	t	\N	t	2026-11-15 10:02:05.720525+05:30	2026-11-15 10:02:05.720525+05:30
2a011b9b-33c4-415b-acdb-20441ab678dd	Embroidered Party Kurti	embroidered-party-kurti-b61b27	Silk blend party wear	1299.00	8ff3312e-ff22-4a8b-8d25-20f2be3c0917	t	\N	t	2026-11-15 10:02:05.751184+05:30	2026-11-15 10:02:05.751184+05:30
f6497541-550b-4da1-9797-875da0509301	Designer Anarkali Kurti	designer-anarkali-kurti-9a66fb	Floor length	2999.00	8ff3312e-ff22-4a8b-8d25-20f2be3c0917	t	\N	t	2026-11-15 10:02:05.786171+05:30	2026-11-15 10:02:05.786171+05:30
f1b3e816-1b33-43a5-8222-d4b6741aa483	Saree Image Test	saree-image-test-43e2f2		999.00	a9035475-ce06-4b9e-8a20-da7b7c28f95f	t	\N	t	2026-11-15 10:02:05.916643+05:30	2026-11-15 10:02:05.916643+05:30
76446fb5-9455-4007-ad71-63e00a12b241	Rejection Prod	rejection-prod-1538ef		999.00	6d029e3f-b360-4f80-91c2-c2f10d8efe2a	t	\N	t	2026-11-15 10:02:06.104446+05:30	2026-11-15 10:02:06.104446+05:30
46077423-9da3-4301-86d0-fc78beeddc25	Limit Prod	limit-prod		499.00	fa25b99d-8206-44aa-98e2-eb3f416aa2ec	t	\N	t	2026-11-15 10:02:06.169802+05:30	2026-11-15 10:02:06.169802+05:30
f4ac5bc6-0847-4f91-87ea-58ccd262b2d1	Bridal Velvet Lehenga	bridal-velvet-lehenga-96bf0f	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	4df83f25-abf9-49f6-ad3b-0e514535957a	t	5	t	2026-11-15 10:10:40.894517+05:30	2026-11-15 10:10:40.941781+05:30
3f7346cd-18be-492a-a8ee-7126fcaa6c07	Cotton Casual Kurti	cotton-casual-kurti-37817e	Comfortable cotton	499.00	906b7a64-265f-4391-966a-e9b588fbbce5	t	\N	t	2026-11-15 10:10:41.059126+05:30	2026-11-15 10:10:41.059126+05:30
d9fd933e-de63-416f-a32d-4e0f47ff40f5	Embroidered Party Kurti	embroidered-party-kurti-6e1856	Silk blend party wear	1299.00	906b7a64-265f-4391-966a-e9b588fbbce5	t	\N	t	2026-11-15 10:10:41.110724+05:30	2026-11-15 10:10:41.110724+05:30
2a75ca59-d7f0-4545-81f7-2bfb4b224d9e	Designer Anarkali Kurti	designer-anarkali-kurti-cc76d6	Floor length	2999.00	906b7a64-265f-4391-966a-e9b588fbbce5	t	\N	t	2026-11-15 10:10:41.160996+05:30	2026-11-15 10:10:41.160996+05:30
cdf13e71-85ed-4626-a0a5-0a0fa2dbc1f7	Saree Image Test	saree-image-test-b3db33		999.00	68034739-481a-4809-b429-f7ee7cf3326f	t	\N	t	2026-11-15 10:10:41.302751+05:30	2026-11-15 10:10:41.302751+05:30
ef655518-3733-43e3-9cb5-00f298ff97db	Rejection Prod	rejection-prod-2f3563		999.00	b950e82e-006c-4c95-938f-e406002ec080	t	\N	t	2026-11-15 10:10:41.478209+05:30	2026-11-15 10:10:41.478209+05:30
8bb49474-8f69-4b81-a9f1-0f35df39e0f6	Limit Prod	limit-prod-525ec0		499.00	f59c44e0-0942-42cd-89a0-d8175511f22f	t	\N	t	2026-11-15 10:10:41.617733+05:30	2026-11-15 10:10:41.617733+05:30
c3141fac-b251-41ce-9df8-230a49a63647	Kanjeevaram Saree	kanjeevaram-saree		2500.00	da17a607-4be3-4b8f-9b60-1eb125e56d17	t	8	t	2026-11-15 10:10:42.298118+05:30	2026-11-15 10:10:42.350233+05:30
6203e6af-5069-4e7c-b960-02bb8df04f94	Saree Image Test	saree-image-test-079d0e		999.00	3c88c48c-7051-4491-941e-c917413ebfca	t	\N	t	2026-11-15 10:14:19.86255+05:30	2026-11-15 10:14:19.86255+05:30
482a07dd-eccd-4674-91d4-818f27dc0f48	Rejection Prod	rejection-prod-60be2c		999.00	afc709b9-9ee1-4e96-8ea2-975446e0d8f5	t	\N	t	2026-11-15 10:14:20.200444+05:30	2026-11-15 10:14:20.200444+05:30
a2af9a33-3f59-48ff-8ab0-a1263d0ac1a4	Designer Anarkali	designer-anarkali		1200.00	6fe9e1f5-399c-480c-84d1-cfed4eaa6ed1	t	4	t	2026-11-15 10:10:42.424739+05:30	2026-11-15 10:10:42.552292+05:30
387f3bec-01a6-41b2-958c-bd54ff338ccb	Bridal Velvet Lehenga	bridal-velvet-lehenga-51a0c8	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	f94befc7-a185-4bed-972b-76f9b043a604	t	5	t	2026-11-15 10:13:44.786819+05:30	2026-11-15 10:13:44.818006+05:30
669f0904-3da0-4cdf-9180-66455e43c050	Cotton Casual Kurti	cotton-casual-kurti-a8a7c3	Comfortable cotton	499.00	98743ad6-c6d4-4c0d-9a20-4602624d9213	t	\N	t	2026-11-15 10:13:44.946217+05:30	2026-11-15 10:13:44.946217+05:30
7c32850b-4e6b-41e5-a15e-43fbf1c7f78a	Embroidered Party Kurti	embroidered-party-kurti-603550	Silk blend party wear	1299.00	98743ad6-c6d4-4c0d-9a20-4602624d9213	t	\N	t	2026-11-15 10:13:44.985606+05:30	2026-11-15 10:13:44.985606+05:30
a074df16-76e5-4aae-a114-1e40a190ba1d	Designer Anarkali Kurti	designer-anarkali-kurti-5d5645	Floor length	2999.00	98743ad6-c6d4-4c0d-9a20-4602624d9213	t	\N	t	2026-11-15 10:13:45.009002+05:30	2026-11-15 10:13:45.009002+05:30
4ccf035f-6ecd-40d1-9b1b-1bf50860200d	Saree Image Test	saree-image-test-407ba7		999.00	c1f0ab11-683e-447f-8fd3-92c8b7c43e2c	t	\N	t	2026-11-15 10:13:45.186612+05:30	2026-11-15 10:13:45.186612+05:30
13d8eb4f-5e03-4e00-87a3-c3b74b423582	Rejection Prod	rejection-prod-770047		999.00	09ebe6c1-5992-473c-ad54-9b91e697125e	t	\N	t	2026-11-15 10:13:45.424767+05:30	2026-11-15 10:13:45.424767+05:30
fc5be87d-c87a-4561-9a7c-a72d8948bf6c	Limit Prod	limit-prod-66d9ba		499.00	fffd1980-24ce-4c91-94b7-6131cca1317d	t	\N	t	2026-11-15 10:13:45.515705+05:30	2026-11-15 10:13:45.515705+05:30
617d364e-721b-4fde-8f53-2e77eb52f004	Kanjeevaram Saree	kanjeevaram-saree-f12dc1		2500.00	c5713b6a-44c0-4ae4-a9da-5f2f03f98d6c	t	8	t	2026-11-15 10:13:46.479126+05:30	2026-11-15 10:13:46.547861+05:30
9202455a-e5cf-4f53-9a6c-996db572f95d	Designer Anarkali	designer-anarkali-ef29e6		1200.00	da32effe-fd6f-4374-a319-fba88657fc03	t	4	t	2026-11-15 10:13:46.642939+05:30	2026-11-15 10:13:46.817668+05:30
ee0ee69c-bf3b-4e7d-9266-1f96621d40e1	Unpurchased Kurti	unpurchased-kurti		899.00	1882e2ae-479a-4684-97d6-1f62d1648fc7	t	\N	t	2026-11-15 10:13:47.511688+05:30	2026-11-15 10:13:47.511688+05:30
afebdf53-7a86-426c-bba9-aaf48b121bbb	Handloom Chanderi Saree	handloom-chanderi-saree		1800.00	5b3aca88-c964-4dcc-92fd-b1f5c5bae266	t	\N	t	2026-11-15 10:13:47.624079+05:30	2026-11-15 10:13:47.624079+05:30
f6054a74-8756-4b50-8861-dcb92b489879	Bridal Velvet Lehenga	bridal-velvet-lehenga-d42d1b	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	bedb0c8a-4969-4482-ad89-994e1370adc2	t	5	t	2026-11-15 10:14:19.368709+05:30	2026-11-15 10:14:19.414815+05:30
8daa2cec-5d75-4693-a9d2-633960ad8fc1	Cotton Casual Kurti	cotton-casual-kurti-dea943	Comfortable cotton	499.00	455b8fde-36a9-4b51-a7a3-df714ff9e62f	t	\N	t	2026-11-15 10:14:19.536147+05:30	2026-11-15 10:14:19.536147+05:30
6b370600-72f9-4da1-813a-172c9dd52724	Embroidered Party Kurti	embroidered-party-kurti-223b2b	Silk blend party wear	1299.00	455b8fde-36a9-4b51-a7a3-df714ff9e62f	t	\N	t	2026-11-15 10:14:19.585555+05:30	2026-11-15 10:14:19.585555+05:30
eaaa4ec4-7bb1-452f-bd6c-ab5ba9b16f0e	Designer Anarkali Kurti	designer-anarkali-kurti-d045e9	Floor length	2999.00	455b8fde-36a9-4b51-a7a3-df714ff9e62f	t	\N	t	2026-11-15 10:14:19.626769+05:30	2026-11-15 10:14:19.626769+05:30
7a9f76de-a53d-4f70-8e41-9e36964392ed	Limit Prod	limit-prod-fe2d88		499.00	1b996edc-2f17-4951-aa90-679ea599623f	t	\N	t	2026-11-15 10:14:20.312127+05:30	2026-11-15 10:14:20.312127+05:30
1d96eb4f-c312-4cba-a35c-9a28c9059cfe	Unpurchased Kurti	unpurchased-kurti-3a17f1		899.00	09155d29-0570-42df-a06a-2c12d04e64fc	t	\N	t	2026-11-15 10:14:21.722536+05:30	2026-11-15 10:14:21.722536+05:30
42385415-2211-47a1-9b50-dc1b1d8c23f2	Handloom Chanderi Saree	handloom-chanderi-saree-388882		1800.00	cfc314ef-cb7d-4527-b06f-04f672ddc453	t	\N	t	2026-11-15 10:14:21.904558+05:30	2026-11-15 10:14:21.904558+05:30
da07ebfa-90d0-4960-8bf5-59dff382df16	Bridal Velvet Lehenga	bridal-velvet-lehenga-6a4820	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	ee1e03d8-4616-4ff0-8181-ed0a763ab745	t	5	t	2026-11-15 10:14:50.006884+05:30	2026-11-15 10:14:50.053827+05:30
1d2c7ce3-52bb-4bdc-a819-38096037b949	Cotton Casual Kurti	cotton-casual-kurti-13e287	Comfortable cotton	499.00	0b589376-05fa-4962-8e59-f76a6dd9e6cc	t	\N	t	2026-11-15 10:14:50.193509+05:30	2026-11-15 10:14:50.193509+05:30
bec33bcb-9614-4915-8bb1-14e8d013d47e	Embroidered Party Kurti	embroidered-party-kurti-ab58ac	Silk blend party wear	1299.00	0b589376-05fa-4962-8e59-f76a6dd9e6cc	t	\N	t	2026-11-15 10:14:50.242759+05:30	2026-11-15 10:14:50.242759+05:30
fda8f060-c204-4a39-926b-79574fb1bc5f	Designer Anarkali Kurti	designer-anarkali-kurti-bc41ac	Floor length	2999.00	0b589376-05fa-4962-8e59-f76a6dd9e6cc	t	\N	t	2026-11-15 10:14:50.271163+05:30	2026-11-15 10:14:50.271163+05:30
826eb0e2-096e-4c3d-94c5-60a9c1ce30d8	Saree Image Test	saree-image-test-5769f0		999.00	9d1b626a-5ed6-494d-8d33-86ec2061c3f8	t	\N	t	2026-11-15 10:14:50.472144+05:30	2026-11-15 10:14:50.472144+05:30
f442dbe0-5ea8-466a-a496-d6d1cc14c365	Rejection Prod	rejection-prod-8df14e		999.00	ee832e73-df6e-41f0-992f-9239c69f3d48	t	\N	t	2026-11-15 10:14:50.786031+05:30	2026-11-15 10:14:50.786031+05:30
8a70a6a8-b203-4c7f-bb27-1d6bc488971c	Limit Prod	limit-prod-04f384		499.00	0fd12fda-18f1-48d9-ae87-29d153523b34	t	\N	t	2026-11-15 10:14:50.891188+05:30	2026-11-15 10:14:50.891188+05:30
faf1c7e1-4922-4123-b831-f79999db5bfe	Kanjeevaram Saree	kanjeevaram-saree-cb1dcc		2500.00	70fac41a-bdb9-4dbe-bfc1-5d944a24c222	t	8	t	2026-11-15 10:14:51.589604+05:30	2026-11-15 10:14:51.65738+05:30
2a7f8a7b-66b0-44c0-ac79-d11f7f4f2a02	Designer Anarkali	designer-anarkali-247478		1200.00	e07eaa40-0308-4f93-960f-610f90ec3a47	t	4	t	2026-11-15 10:14:51.759785+05:30	2026-11-15 10:14:51.956777+05:30
5ac25488-cb19-4282-9b73-45fba9dbe44f	Unpurchased Kurti	unpurchased-kurti-46bd31		899.00	21b4b069-025d-488f-9343-2997eb5e3a28	t	\N	t	2026-11-15 10:14:52.319193+05:30	2026-11-15 10:14:52.319193+05:30
46d58e57-5df8-4649-85ec-79c7cd85b022	Handloom Chanderi Saree	handloom-chanderi-saree-b62bea		1800.00	b08d4e4a-4e19-424f-9b23-f4a325d61fca	t	\N	t	2026-11-15 10:14:52.436402+05:30	2026-11-15 10:14:52.436402+05:30
6dbeaa38-6c5e-4773-befb-c5303bf0c97d	Bridal Velvet Lehenga	bridal-velvet-lehenga-fe3ef4	Royal velvet bridal lehenga with intricate zardozi embroidery.	2299.50	35877428-7d06-4cf9-bc16-335c55f7c275	t	5	t	2026-11-15 10:29:53.722823+05:30	2026-11-15 10:29:53.771524+05:30
5c6a821e-ff1b-4cbb-9c76-711cb75b00f0	Cotton Casual Kurti	cotton-casual-kurti-1d8e7d	Comfortable cotton	499.00	1d39d55b-3fbf-4fcd-a897-5848593f6f74	t	\N	t	2026-11-15 10:29:53.911926+05:30	2026-11-15 10:29:53.911926+05:30
b0ef7521-00ad-4ad5-be2b-6e190d7a4c06	Embroidered Party Kurti	embroidered-party-kurti-7ba405	Silk blend party wear	1299.00	1d39d55b-3fbf-4fcd-a897-5848593f6f74	t	\N	t	2026-11-15 10:29:53.962697+05:30	2026-11-15 10:29:53.962697+05:30
31c93636-0013-4ba9-b4d6-3c0a465a92f6	Designer Anarkali Kurti	designer-anarkali-kurti-3737e7	Floor length	2999.00	1d39d55b-3fbf-4fcd-a897-5848593f6f74	t	\N	t	2026-11-15 10:29:54.03378+05:30	2026-11-15 10:29:54.03378+05:30
491ec707-5033-4060-9175-b5448e3d958b	Saree Image Test	saree-image-test-b30854		999.00	927d059f-9e8d-447f-b450-9c966fec7d93	t	\N	t	2026-11-15 10:29:54.248579+05:30	2026-11-15 10:29:54.248579+05:30
a46796f2-202c-4d39-be82-17f25d3a8882	Rejection Prod	rejection-prod-fb2400		999.00	d4716c88-7659-484b-8787-8d0b2e15fed9	t	\N	t	2026-11-15 10:29:54.530582+05:30	2026-11-15 10:29:54.530582+05:30
1b4a279f-8209-4ec7-af3f-d185cfb8e26a	Limit Prod	limit-prod-d7c049		499.00	f826b9fc-b478-4bd8-8a89-71129305ceb6	t	\N	t	2026-11-15 10:29:54.641791+05:30	2026-11-15 10:29:54.641791+05:30
78b3945d-79e4-440f-a15f-c426071cac15	Kanjeevaram Saree	kanjeevaram-saree-ec525d		2500.00	1fec706f-d14b-4560-b0ed-3062aebd61c0	t	8	t	2026-11-15 10:29:55.823136+05:30	2026-11-15 10:29:55.900915+05:30
710d9bcb-6b8c-4c8b-9c53-492c0df2e86d	Designer Anarkali	designer-anarkali-70cab5		1200.00	6745f475-81b6-4de6-8a00-99f7a01c455e	t	4	t	2026-11-15 10:29:56.014753+05:30	2026-11-15 10:29:56.231404+05:30
0787aa12-95e0-417c-a9d4-ba264ec40101	Unpurchased Kurti	unpurchased-kurti-e63096		899.00	3c228f25-f710-4f41-8c39-a01aa1f161aa	t	\N	t	2026-11-15 10:29:56.607809+05:30	2026-11-15 10:29:56.607809+05:30
000a5355-da52-4731-bd9d-80c24734f27c	Handloom Chanderi Saree	handloom-chanderi-saree-72d95a		1800.00	1c790444-bf73-49db-9655-43ffa78fda3d	t	\N	t	2026-11-15 10:29:56.715868+05:30	2026-11-15 10:29:56.715868+05:30
\.


--
-- Data for Name: refresh_tokens; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.refresh_tokens (id, user_id, token_hash, family_id, expires_at, revoked_at, created_at) FROM stdin;
6e79b111-a9fe-4e94-a2bf-0d102ddaa5b8	c3cd4b05-fef0-48ad-ada3-5a95d8e66bf5	cc4f30d38962e4c915a3af4864800f1115e91b7ba299a1396cd3806011c893a6	5ab95c31-4896-4791-b4b1-4b62b86a6a9c	2026-12-15 09:54:19.708398+05:30	\N	2026-11-15 09:54:19.708398+05:30
fc0b0eb3-8fae-450b-82e2-7aa027fe445c	141cc95f-4668-442f-8cae-f9160cc3128f	117fac2d32a29e72ba6d517db8226432e190136ae2d0649c78927133c5a0d2c8	7994067e-eaa7-488a-bcd8-cae14778970b	2026-12-15 09:54:19.827387+05:30	\N	2026-11-15 09:54:19.840228+05:30
df16f4e0-c318-44de-a733-b7f5e7b701f5	1e5439f7-7052-4e3f-ac0a-ba14110af213	7c35aa965fee09b1e0ecae3a162e1ac20483bf878646a0fbe76bc559f93d97fd	f69a7f52-d522-4243-b8cb-ad9ebef07872	2026-12-15 09:54:19.956827+05:30	\N	2026-11-15 09:54:19.958145+05:30
2a474a7a-5d42-4ed8-8121-8797d2b3c439	ff9230c9-e08a-481c-81a5-c3e89ad73c51	6fd76915d63f6db98881e200f3689adcd05ea210de88ec09b67392b1aaadacb6	1b8c5b32-d9e1-454d-93c3-65761620e13a	2026-12-15 09:54:20.080559+05:30	\N	2026-11-15 09:54:20.080559+05:30
b61c023c-e041-4a85-baab-1c1a0eb32e76	ff9230c9-e08a-481c-81a5-c3e89ad73c51	bbcfc505ed7b4d388162def0d81a81fdc8b70526afebe9f8ce6d3ff3b516fd84	8d1b6c45-2969-43b9-b232-0b40e6411a7c	2026-12-15 09:54:20.199135+05:30	\N	2026-11-15 09:54:20.199135+05:30
80b4024e-9772-4d55-b44c-9cef79d9f87e	8200bc2c-0b13-4f95-99f2-89bcce887bed	0bade18537ab48126a9a584e549f0fcd1d2c9262688ee975b682b54d03a5508c	8b424da3-453b-4653-a8f9-452e4ee9fb07	2026-12-15 09:54:20.4241+05:30	\N	2026-11-15 09:54:20.4241+05:30
64801aed-cae4-459b-b782-2e74b9ce6811	2093d1cc-0005-475e-ad00-899ef27c0048	999c06dc0a2881746b4d501e92bd08ac70a35945eacf4b6d8a141b08df94cbce	33f0a237-8592-40b3-83a2-38aea25a8edd	2026-12-15 09:54:20.5616+05:30	\N	2026-11-15 09:54:20.5616+05:30
8b416535-08c4-4daa-8354-7afbfb371203	c8393000-ef90-4345-a676-5599c9517617	4324b8209eb07dfd845e1b3c03aca2ea6ab2f966155d37ce5ae37c6d8143c5c4	2bed459d-1124-4784-941d-fcd94ac1a8fb	2026-12-15 09:54:21.043439+05:30	\N	2026-11-15 09:54:21.043439+05:30
b9b5e623-6536-4209-b2be-9c97ce64329f	9600f15f-da63-4638-a3e2-43c865b62b19	c6fb447b7dc4d0997c0b80c6ab724119704c6ee9a213a7810edce9ec86b4017f	7079e558-e196-46d8-a40c-c3c8df325d4b	2026-12-15 09:54:21.319735+05:30	2026-11-15 09:54:21.323885+05:30	2026-11-15 09:54:21.319735+05:30
45718b4a-86ea-4f6a-8054-3a4c1e6fc6b3	9600f15f-da63-4638-a3e2-43c865b62b19	80fe43c78442e69fdc46627ceb4e44809b8ae94f2bec8e2dd9622e2ad116af29	7079e558-e196-46d8-a40c-c3c8df325d4b	2026-12-15 09:54:21.343069+05:30	2026-11-15 09:54:21.346905+05:30	2026-11-15 09:54:21.343069+05:30
40cb5fac-6c50-4798-b291-c260f582d589	dd368621-0708-4c22-a883-7bd81b093300	38530784f9da4143ac417f13a4e8d513e88f534b7e596f764a322ce1c32cc273	22f7b556-4358-4684-93eb-a1f2a20ae2f9	2026-12-15 09:54:21.492145+05:30	2026-11-15 09:54:21.492145+05:30	2026-11-15 09:54:21.492145+05:30
ea6a403c-e4b5-4844-a2da-796b1f317148	20ae0285-54bd-4578-9f36-ccf865d958d4	014363fceb317ea41c6adb1488026e36eaca3e8388d2b209875009547de02e6a	0f650b6e-9d60-4e35-80d4-4d0af56e56a4	2026-12-15 09:54:21.708342+05:30	2026-11-15 09:54:22.059541+05:30	2026-11-15 09:54:21.708342+05:30
723bd088-e0a3-4650-a0f6-c3a569dd9945	20ae0285-54bd-4578-9f36-ccf865d958d4	5d6ab3d4b14b69b2151d9e5e970ac93fc82dd2a054b69ce12842c0d699e81313	14896b38-5889-4de2-88b1-fe349aeee5dc	2026-12-15 09:54:22.306917+05:30	\N	2026-11-15 09:54:22.306917+05:30
00320cf1-5b33-43e9-b8a2-a71d52f4f542	bdeb367b-b0f6-403a-b878-defa8623fdb8	d49b9476d596dfb55fd124d071ddf92a269adadf6cbeb26e573ca83d0216467c	edf7286d-faef-4cb5-8227-f772263fe700	2026-12-15 09:54:22.428677+05:30	\N	2026-11-15 09:54:22.44098+05:30
f3ca0fed-fd5f-44c4-8b71-d350f07c1b3c	72fcf157-4076-4f4d-a3e6-58976eb9b419	8139bddc7d0847ae2fc6fa6cf783b53186ff208c49c46693974bb24a051d3f0a	213a5681-ceba-4961-87f3-d36f64c02513	2026-12-15 09:54:22.557046+05:30	\N	2026-11-15 09:54:22.557046+05:30
fe2082d2-53e1-4005-a871-5067521dd51a	0d0eb42d-bc0b-4f65-91da-66edb48eca04	6f3a271df2882d5d98745e0d67074cdd418acc9e4c2f9781f140d6e3d59a725a	9528bc95-e669-4899-9618-7736ef824121	2026-12-15 09:54:22.673657+05:30	\N	2026-11-15 09:54:22.673657+05:30
991eb576-2141-4702-854a-58df24a98987	5004e098-b897-48e8-8cc7-009cf9ca19c6	088d3a07dec46b087556558a3d6552fb390cab24de1f99da2a2b8a605594b219	5c138f36-2923-4171-a036-0f3a4b3df33b	2026-12-15 09:54:22.808437+05:30	\N	2026-11-15 09:54:22.808437+05:30
3bfeee4e-88d0-4a65-b707-91f8ff159beb	26336fd6-896f-4d4c-95a8-444b161ca10f	b0793bd6cf32e47da5de5483949833fd2b4dfa4c64363280cb5e323618854545	70be4ab8-d0e7-4538-87fc-245b19c151fa	2026-12-15 09:54:22.924198+05:30	\N	2026-11-15 09:54:22.933323+05:30
708a2d2a-3556-42c1-bbf9-bf51f766d6eb	3a4d1c3a-6a0e-4acf-82e1-f0aeeef41d94	013caba23336738c4cc3ac166a1a9a926c1687f089ab7d5a34f7971a6ac0850f	a8da3767-ca93-4799-8850-d5dae96198ac	2026-12-15 09:54:23.055685+05:30	\N	2026-11-15 09:54:23.05698+05:30
e8744f60-c2b2-4dcd-a75b-51ff30ce4fb5	93ae36a8-da23-4d91-8be1-ea7c6e50e050	e37f04ca3e1924a3bceef30d78d7b7afb425f37758ec0b1f5e69d096d1f2b75c	1861ceb4-8799-4576-a779-332e80f52d5a	2026-12-15 09:54:23.17565+05:30	\N	2026-11-15 09:54:23.17565+05:30
8b5f3981-1121-4b6d-a015-a70a6c732e1d	04460803-db30-445f-89d7-cbe4784f3dc1	fe20cb9b1b84d6defa43b663359de9bdf6acc8a7bac5edb381f0671b3e09e702	1b8ca583-0caf-4d0d-9cc8-79fa77667540	2026-12-15 09:54:23.303615+05:30	\N	2026-11-15 09:54:23.303615+05:30
135ca91a-c25b-49d9-9b95-8d06cdd08d7b	ad29a603-ab28-4f63-aa1a-67a1be05506e	a67e4e688fc4937f0c5053dc5ebd02a631e018b563fcec6794a84b3971e74a4c	830a4cfd-783f-4f46-8b7f-b0af68fad511	2026-12-15 09:54:23.423229+05:30	\N	2026-11-15 09:54:23.423229+05:30
6a7207c8-2a81-4082-923e-81e3fd7b407a	f8d89d4a-b1b3-44dc-9822-2fbbb464dc2d	a10f9b38aa710da1982d7afc117633a6e921feb059e784367ea5c9e836015e01	b78128d3-bd9b-4192-90ea-ea27cbd80576	2026-12-15 09:54:23.541826+05:30	\N	2026-11-15 09:54:23.541826+05:30
1e8af840-bb5d-48a1-b345-654ca8147fec	6873d825-618e-4d6e-8bcd-34872df28213	0ccd75b25b4338910ebd0b3d89c75de0acfce0c0d5d3c7342e1219512495a607	8b772624-df8a-4a5c-9e71-9d2d727c417b	2026-12-15 10:00:11.586296+05:30	\N	2026-11-15 10:00:11.586296+05:30
e9fd4395-6fe5-45ca-b294-85213298ba55	550b4021-def8-4016-9d46-0f1e3e5f6aed	9b991187c970470f184ad124df3760e551fcb9f190e628d7aea54b8c905026c9	6a77706c-97bb-41db-a945-addb214e333b	2026-12-15 10:00:11.733888+05:30	\N	2026-11-15 10:00:11.735894+05:30
03635cfb-4158-489d-91f6-733c11881dff	bcd95194-4ca9-4512-b1b1-def74138fed4	82c1d3feba418eeaa35e9b4275783544895e441ff9fabae0a8409841b02e33f5	061adecc-8223-4a57-b269-682ef8816872	2026-12-15 10:00:11.906279+05:30	\N	2026-11-15 10:00:11.906279+05:30
c5e4f6b2-d00c-4d36-9272-1a0c6a85ada4	502e9a1e-0b01-4baa-af15-6e2e1fa3d2f9	079edb10f7684870b81f88ded0fc4097c5854a9e3951a0cd901970a4843dfe36	79cfe274-7fa1-41e7-ab58-02564ee7b034	2026-12-15 10:00:12.043789+05:30	\N	2026-11-15 10:00:12.043789+05:30
417ecbae-97b0-487b-be87-83b1476df91a	502e9a1e-0b01-4baa-af15-6e2e1fa3d2f9	24466a7f27c64403180460281a563bec16e4c23b2ac0e386fb88b3346f3e9e2b	7dabeca5-2562-49ec-8f01-8a74dc123393	2026-12-15 10:00:12.164207+05:30	\N	2026-11-15 10:00:12.164207+05:30
43e8a701-06db-414b-a58a-cf7bd57d0134	8a799d11-1c99-44ff-b64e-f7154fae02c7	ccd1913d26df29e289cb453040474dea1831d7f353015e33c7b274795a680910	47149e57-5c4c-4796-ae31-38282fa80361	2026-12-15 10:00:12.39968+05:30	\N	2026-11-15 10:00:12.39968+05:30
2b5105cb-439a-4f6d-99d3-f3bf34577581	2bd95e45-2a32-4283-a184-4ddc9c22a2e4	e757f8d8841bcfde600a2a81ee2eef2accc4f620af94e6171b73758bbcfb19a6	4a53ba5c-519e-441c-89a6-5348545ee9bd	2026-12-15 10:00:12.521508+05:30	\N	2026-11-15 10:00:12.521508+05:30
e5e5d319-c03a-4bb0-bfca-afe4fafadab3	2d2d0f7b-16d0-4f1e-b5b2-d929aaaafc54	ceff848c9c2da6e425c172e4aa6d34b7af12e6ad09872f08ff1a67ebec4d1270	11e9f40d-f3a8-4930-8f4b-e7cf616f6875	2026-12-15 10:00:12.986031+05:30	\N	2026-11-15 10:00:12.986031+05:30
269fbab2-0449-4b5c-8b59-994c7ced821a	48e60617-008a-4546-8a36-00a82e154f49	020281836231b2de2a0642d7fe40b353881f987529dcaf85816696605b06632e	17ecbdf0-0dbd-479a-bb29-b97699722533	2026-12-15 10:00:13.272241+05:30	2026-11-15 10:00:13.288461+05:30	2026-11-15 10:00:13.272241+05:30
28de4671-7337-4fbf-8be9-29ec34eed4c1	48e60617-008a-4546-8a36-00a82e154f49	183469deea7f668e740f2c4daec41923d6f3838427630399feb5b2dbbb0eecb4	17ecbdf0-0dbd-479a-bb29-b97699722533	2026-12-15 10:00:13.288461+05:30	2026-11-15 10:00:13.305426+05:30	2026-11-15 10:00:13.288461+05:30
793c9ceb-dc0d-4e95-b2a5-9160d060e52d	d37e13c1-a446-46f3-80d4-dc296b1cb4ef	ca10b8c4cbc9527ee3b32f7945ef21f42af6d31cc3e213d675c00a4c8085bcb9	5ab2a319-8002-4f50-8f64-4178b0104b2a	2026-12-15 10:00:13.44112+05:30	2026-11-15 10:00:13.458632+05:30	2026-11-15 10:00:13.44112+05:30
09d5be48-22ec-4502-9cb0-2ac4a7f65348	1e0c5b4e-2472-4102-afd9-62ca8f1d8b2c	bba4c389afa2c2eeccd641282b08ad29ef043d3d5fc27245247e4af288920b7f	30c2fddf-5382-4fec-a0d8-53b9c63edc90	2026-12-15 10:00:13.588237+05:30	2026-11-15 10:00:13.921356+05:30	2026-11-15 10:00:13.588237+05:30
d0c9c00b-157c-4f7e-978f-29820c4a511a	1e0c5b4e-2472-4102-afd9-62ca8f1d8b2c	b2ad36dd50e6e5906885aef1a3c2c7dff17cfc3e474fbbaa1f2cc7284d132dc6	5c894ba7-764d-44bd-af1a-e5a858e7d219	2026-12-15 10:00:14.153566+05:30	\N	2026-11-15 10:00:14.154628+05:30
19727fce-510f-4055-bd04-6e1055c7fd3f	377bf974-8883-4010-9d5f-567ffd35a145	396dfe376dea839cff6d901bf8e2c60b1675648f3a08460a87e650bb88fcd55b	907786f2-962b-4b58-a19e-ce5af2936721	2026-12-15 10:00:14.278639+05:30	\N	2026-11-15 10:00:14.278639+05:30
768338ad-55b6-4283-ac63-bf6c8ca19a62	1b874abd-3af1-4caa-a8cb-942a38393ed4	6c413e14b33ebb8b4fc0f42c7f8fcc795ea6cd40e8cb31063208adaa4457d9bb	943e0589-7cb8-4281-b7bd-00663fd4ab95	2026-12-15 10:00:14.394523+05:30	\N	2026-11-15 10:00:14.394523+05:30
5bfcc176-d5f0-4717-8525-bc1b49da7832	e74f4abb-929b-443c-ab86-15555cc5f5e0	a9465fa5d8bf162afd95c45dadc1d9f88f74ff88ee3d515053a986e5c18b67b0	b8cb380d-2fbe-46c0-8d58-361b27a02dfb	2026-12-15 10:00:14.52276+05:30	\N	2026-11-15 10:00:14.52276+05:30
bed37d0b-ab98-4c22-837c-45455831e70f	ae9c4b22-528e-4f9b-b352-879da85c3e15	875fd6511728357fa3086c324871686d46f00dbf01b5b775bb38a852fdc63916	e7ce6825-77ad-4296-99b6-cbfacb5deb38	2026-12-15 10:00:14.639535+05:30	\N	2026-11-15 10:00:14.639535+05:30
081361c5-afb9-4af1-bc82-119f9212cf59	262c231c-3a87-43b3-998b-1dff96549ac2	31f16366496adaec6717302d1b6ec978803e3507cf79542b7f57081bc9a2daa6	8a2540d6-e97d-4a8e-8e73-8dfa0478537c	2026-12-15 10:00:14.751883+05:30	\N	2026-11-15 10:00:14.751883+05:30
a6893cbe-ae55-4bb6-8d9c-9355c517da9c	14f28ca3-83d8-4ed1-ad1c-3cc3e3da3165	d45c9df1d99ccfbc83c4463b0d2ad9d176f43b16e9a7a4f3b7196e13383d8df2	ec7750c9-6a1b-4044-90f0-c42bc6b87c61	2026-12-15 10:00:14.874952+05:30	\N	2026-11-15 10:00:14.874952+05:30
55977893-ea42-46fb-a4bc-5b01cf7a6644	4b4166dc-f5ac-47df-99bc-fa64d74e5ca0	4eec5641eca46020dab9e32b5f14964d62a411e69e22d8527b71855ad07a3135	268548a6-821c-471e-9950-4e0d414c3a7f	2026-12-15 10:00:14.987224+05:30	\N	2026-11-15 10:00:14.987224+05:30
422ebc2e-1302-42f4-afca-b005c713054b	238d650d-1595-432c-afae-25be8691fff2	6706443adf189ffb4304854563767cdaf6382caeca204af04614e2fd0f92caba	a2cf118a-2833-4e00-8574-667dd6616c65	2026-12-15 10:00:15.11084+05:30	\N	2026-11-15 10:00:15.11084+05:30
9046cf3b-f0d2-455b-9b01-0701f2bf0fda	f4c396c4-0b87-4949-be53-d63f6fe564e9	1ae3f497860295d3de53473f68dc7944b52e4767f88e422f3d97effa92acbd83	01f3accc-410b-443a-90fd-81c8b6ca65d9	2026-12-15 10:00:15.236382+05:30	\N	2026-11-15 10:00:15.236382+05:30
60d86a5a-5711-4a45-8ae4-2ddd6db61d79	26cc1977-151f-4400-8863-957e394923ec	c911037338d9d3f2a54cb900156c1bbcd91b0a842781d9805a66f280fbd3d289	13f0a3b1-f03f-4933-8593-cf86ccf74f03	2026-12-15 10:00:15.354124+05:30	\N	2026-11-15 10:00:15.354124+05:30
e96c9461-221a-49e9-a101-bc1bde58c8ff	e9a0c088-7d2b-46e5-9710-356855a22976	e0557c9afb9155fce889a30219decccdb66adf3797146f912c9056790f108267	d91be526-6ffd-43f5-a526-0b4987a4daec	2026-12-15 10:00:40.224471+05:30	\N	2026-11-15 10:00:40.224471+05:30
e01a435b-262c-413d-a2ec-0e4b1f319a0a	41aaa817-bd71-40d2-b022-aaab7f2e695d	5d7b2aa5e2efdcc10d47fa220312080a33a2dc03d2040ce0c1d9b2a3ba33938c	38cee23c-2ae5-405e-8742-5ecdc1e58de2	2026-12-15 10:00:40.345592+05:30	\N	2026-11-15 10:00:40.345592+05:30
58e3b38f-8c8f-4022-91d0-6bdc72cf9151	185f16b0-e330-4092-ae52-ae018b96b86b	2c6e5ae01182a28df95b56ee30720834e21fbe2fa772aebc0b260a2fc99072b1	a29b38ea-4b61-4763-8874-21169566ae64	2026-12-15 10:00:40.448622+05:30	\N	2026-11-15 10:00:40.448622+05:30
4aa38123-de8f-4249-8653-d006253555b1	1a46a28f-1509-40a0-a056-7169fbf3f5d8	30744744bcbf90c1a35e524fb9abb0bf6549a54903f4a2b3e74f3345197e7cb8	a999abb8-41c4-48cd-8c64-ffd748fdfefd	2026-12-15 10:00:40.567042+05:30	\N	2026-11-15 10:00:40.578323+05:30
d691ff58-f3c1-43f9-840f-c87a691dee37	1a46a28f-1509-40a0-a056-7169fbf3f5d8	681aa54c7ce0e25c234cf56a4262a0e9d2a26da19c7bde8b03470dbaf7dc5982	5f0642f8-de6b-4533-8cbe-cf70b3620e1d	2026-12-15 10:00:40.679184+05:30	\N	2026-11-15 10:00:40.679184+05:30
df9061d2-0669-4ee7-afe3-a9851e7bfc17	99e5b7c8-74a7-4a36-ada5-d9a92d9567f7	fc55b6fb713abc4ab78502adc1262e4fe7a5408335bebf275b9e75ef32d67681	aa12d04c-4ec2-45bb-940b-c1afe411e032	2026-12-15 10:00:40.908083+05:30	\N	2026-11-15 10:00:40.908083+05:30
48231daf-e5fe-4816-b22c-bd8cc68cc37e	215b4951-176a-49f3-9a68-082658b73c9c	23aea17612e5f6b6a5c1daa1c277d58c3cbc4079ddd184fa5631134b7f36c55c	5d420bde-10a7-422e-bd28-a95c9da2b84b	2026-12-15 10:00:41.046387+05:30	\N	2026-11-15 10:00:41.046387+05:30
3118c1b3-c3bb-4ad0-b563-780046a5b69c	e7c68e46-f316-4b25-a341-6629d8a7dae9	3429f15e9eeb0431fadbad7e06af07bfa5178eff12b5d4caf16cc4a91bef51a7	7cca5965-c91e-427d-9fcc-a083368eade6	2026-12-15 10:00:41.516498+05:30	\N	2026-11-15 10:00:41.516498+05:30
d728dbe6-2612-4fc7-be5b-2cffcea78755	f048a416-d623-42b4-9eb5-92d818938827	21e636cdf3f3aebf4d48ffd02fd3423bae5b195a726e6050807bf0b036d4190d	5b001732-40e3-4dd9-a799-dd9bcca9d0df	2026-12-15 10:00:41.830625+05:30	2026-11-15 10:00:41.855382+05:30	2026-11-15 10:00:41.831634+05:30
a1c3165c-f0b5-408f-b8fb-99d8ae3d174c	f048a416-d623-42b4-9eb5-92d818938827	12602c4f061b5ae8a79b190706b3c24386370687d5b24b033b74187f1e4ef762	5b001732-40e3-4dd9-a799-dd9bcca9d0df	2026-12-15 10:00:41.860926+05:30	2026-11-15 10:00:41.882171+05:30	2026-11-15 10:00:41.863057+05:30
32274aa2-3dc2-494e-a413-28b61e15eb2b	7db55207-7f39-4e27-8c94-18975e1f0910	fb6b3dc054fd9a8e0cc7d2cc2da7cceda5c1ecfc06b4c182d25343f19b75d8bc	b3fca9b4-3456-4a82-ab28-4129d582c480	2026-12-15 10:00:42.070872+05:30	2026-11-15 10:00:42.113883+05:30	2026-11-15 10:00:42.070872+05:30
98a8b2be-b137-46e1-8075-4ce228048503	a97b213e-894f-4784-8f61-2c693cee4439	5b23480115b55c2a946059762f83568d8f5605c1f8ea48371a24349ea772efd8	6afb178a-7fe5-46e6-b0a1-b668c84f58f3	2026-12-15 10:00:42.270051+05:30	2026-11-15 10:00:42.794533+05:30	2026-11-15 10:00:42.272685+05:30
9a703a0e-e7b8-4abd-a8b7-3831b7be957b	a97b213e-894f-4784-8f61-2c693cee4439	050cb8619f2bfab532f12f8b328a213611dc6baad5248cc6b4d58f6b0455ccb6	a99749f3-1fdd-4324-a884-004bbe828706	2026-12-15 10:00:43.140973+05:30	\N	2026-11-15 10:00:43.142984+05:30
d88c82eb-99c2-4056-9827-b57b4828542f	9cd6f9d0-998d-4f00-84de-bb3c9a784e98	2f5163dad0dc431887d3b31d336179c82140c46ee72c6ac1e83a43899fbb4240	5bc7910f-6f06-4dbc-902d-df097cd55092	2026-12-15 10:00:43.305427+05:30	\N	2026-11-15 10:00:43.306211+05:30
638fdce8-3883-45b5-bf84-61e9a7d020cf	be6dd55b-d74e-4e37-8149-ee6dc088620b	d12bdcf1fb0c8d28ddc077e572b3c3246e2cec33e4e940c49dd8747984a2ade5	4e5292b4-57d2-4070-b545-8dc57f123ab5	2026-12-15 10:00:43.457999+05:30	\N	2026-11-15 10:00:43.457999+05:30
da966994-9a2a-47b8-9cf8-8812eb8978a1	b0e03195-e258-4e9f-8678-521b8ddf5790	8664e2824b4070f56ade0a257b055a8a1ddb0bf5f8c35f0c0dff7ff3ee8605ef	6ba46481-744c-467e-93dc-c491dee79c4e	2026-12-15 10:00:43.598823+05:30	\N	2026-11-15 10:00:43.598823+05:30
fb6805ac-c3cd-4462-9329-e3f38933c555	151a6bc5-388c-486f-9f2e-df4657df1f9c	9229e835d37c07175f1be82a750d10aa474e7f9f532373d08fafd0a2f2aeca4f	cef5aed9-aae0-4cde-89bc-02ea376449c4	2026-12-15 10:00:43.74193+05:30	\N	2026-11-15 10:00:43.74193+05:30
3e687001-c85e-43b0-82da-0bbd06bfc3b2	47aa8f35-213c-4a8b-a374-537cbeff7682	508c201bede12e3d2e9f5d15e27dce8ccce777f64979dbe8cb22d126010ecfdd	79a08c58-d05b-4456-a527-538e3e0fddfa	2026-12-15 10:00:43.876949+05:30	\N	2026-11-15 10:00:43.876949+05:30
cb52d51c-8a8c-44d0-915e-a3b1bd162c0e	67746d8a-381e-4e4f-8f66-86bffe9024c4	a481be8f68a01d12b9e75a163dd8963332ba7d80f0a0f0f8e0b47e04713b1856	276fd3e3-5a01-4afc-be2d-9440f7cd658b	2026-12-15 10:00:44.01114+05:30	\N	2026-11-15 10:00:44.01114+05:30
13f5882d-a51f-478d-a78e-f7da1133cbaf	281b9bc1-da22-4b03-a5ca-eb7109b4d812	7aa3e0e5ce3898c021d2dee5f51adcffbbfb8e9c31bd123a1722e249a728e74f	9f04ce3b-952d-4371-b1d4-c9ca31a32eb6	2026-12-15 10:00:44.139726+05:30	\N	2026-11-15 10:00:44.143403+05:30
6264d293-978f-4276-b628-3781b6d42e24	1f04b5c0-6c55-449f-a5cd-731037ed8702	a2306d83428be296dd3ba9916893582b3233067bf15c98d6e4136502c63fd7ee	1c3c5816-c1af-4b2a-9019-afbe7d9d3370	2026-12-15 10:00:44.270473+05:30	\N	2026-11-15 10:00:44.270473+05:30
9edf0652-af7a-44ae-b81f-310ef26364df	a507ec3a-a007-4382-98e8-8517ba03b55e	a769f74c8c6241c27fd96b755585ddf2508c5efc26d714613f48eb36a0edd92e	20fb068c-4e4f-42b6-bc36-23c90b5b1587	2026-12-15 10:00:44.398194+05:30	\N	2026-11-15 10:00:44.398194+05:30
43eddd1e-bc50-45b5-be76-ba74c3154275	ee11b7c0-68b5-4ec1-8665-e9c8f4208e31	84f71d2fa9300e45447ac6ba5ed897eb854877ecc817f2a075a93ae713c865cc	1ec64832-f729-4238-bc99-31695178b1f9	2026-12-15 10:00:44.532263+05:30	\N	2026-11-15 10:00:44.532263+05:30
c0f62304-b887-47de-b24b-2b3a6dcbebb5	e2a14f67-914a-4999-8bc6-c38853183621	4313f722567faba334523e930d37b5ddf9667d64bdd47751b38aa0666c68c205	0cc2b06c-1ba4-4d38-a77c-f8ab9f5f241c	2026-12-15 10:01:00.202995+05:30	\N	2026-11-15 10:01:00.202995+05:30
4e1a5739-bc7e-474f-9663-bca06d656654	e504babc-66ae-4319-b045-533a8243b394	f068b0d0ce4792346e9352aa9e2babffac58af3aa073870e4c503393da0f7292	665eecfa-bb36-41ac-9894-4e49dc76692a	2026-12-15 10:01:00.337721+05:30	\N	2026-11-15 10:01:00.337721+05:30
42610722-dbbb-4be8-be05-e5b0cea36517	4d983bf1-5890-49d5-aff5-f7e8a849ed82	b62062304442c7fffe32e83e3fdb5b11f01bbed2c90d3fb0a16517a9057b5d07	5c24339d-c113-4494-99c4-2941951e8100	2026-12-15 10:01:00.44435+05:30	\N	2026-11-15 10:01:00.44435+05:30
8a9cbdcb-ac89-4ead-9afe-fab44a609191	4125bd46-1c85-40b2-9ce3-4778bf55c2ec	efb84c9ada06d7673377f3e0d4f714c78f1fb842892d9bdbeb48af2e53a9b613	18565c4f-60ab-4517-a85b-41c6c9358109	2026-12-15 10:01:00.578031+05:30	\N	2026-11-15 10:01:00.578031+05:30
27143ff9-7151-4e93-880c-e2a637e9784c	4125bd46-1c85-40b2-9ce3-4778bf55c2ec	acff2f75b13df1682b93c2ed49327471ba4b80c14563dc2169dd76ba40b45f0b	99122a73-321a-4a58-ba84-8ebfcdb2735c	2026-12-15 10:01:00.690104+05:30	\N	2026-11-15 10:01:00.690104+05:30
f129fc85-20bd-447f-a37f-ab06683455ed	1fc4703a-5359-464d-9fb0-ce65297ab663	6234ac926ee107d1a37e8f9ff306651b0410d77406847a2abf98238e844f39bf	29a38403-97ca-4509-a77b-f6039c303f6d	2026-12-15 10:01:00.916382+05:30	\N	2026-11-15 10:01:00.916382+05:30
393bd343-bd02-46be-bac0-7dd087d0292b	0cada2c3-313c-4abb-8909-642b5b54942a	6620f9496631e88f9ee4794c317b6bed2b155b9e046434b5cd4d9a6eb86afd25	1a8b6365-ba9f-4035-8534-a291d852008b	2026-12-15 10:01:01.043002+05:30	\N	2026-11-15 10:01:01.043002+05:30
2ffa24aa-e356-4bfa-a359-08134b4b05d2	d6d5a578-9512-405e-8de8-2eebe315b1af	2236d33bc450aba6d020f9fa0fe6581956ff13ae5abdda7a97b43396dbad012a	f7d1f109-5cb5-40c3-9d6b-40a5e16fcb9e	2026-12-15 10:01:01.533526+05:30	\N	2026-11-15 10:01:01.533526+05:30
17410e80-a0df-4db3-8900-e5b1c9ddb7c4	ebf58521-11e5-45e6-a4b9-0896daee3070	37992a6bbeba040e7d8302c24e629c4be4dcaf9484a680439df07c9adfc5e7c8	726f5d29-1f8a-460c-bdcc-efa85e5dee7e	2026-12-15 10:01:01.811352+05:30	2026-11-15 10:01:01.831097+05:30	2026-11-15 10:01:01.811352+05:30
7f1fdbd8-2ca0-4e3b-92bb-73ef2acfbfa4	ebf58521-11e5-45e6-a4b9-0896daee3070	add222f1517444e88ad92b32f76847ff71933f178c3f314a9ad1da7233dab539	726f5d29-1f8a-460c-bdcc-efa85e5dee7e	2026-12-15 10:01:01.831097+05:30	2026-11-15 10:01:01.845963+05:30	2026-11-15 10:01:01.831097+05:30
15af5f86-ecf9-4069-b7c7-0217e57f939e	ddaf36c0-3d08-4543-ae95-579278566cb7	2a4ff470ec1734ccdad4b20495fa4095da03c082959eb47f3bd71aede981569e	98e3c127-8988-4e67-b1bf-134293e17542	2026-12-15 10:01:01.974386+05:30	2026-11-15 10:01:01.989487+05:30	2026-11-15 10:01:01.974386+05:30
33aa1b33-dea5-403b-952f-f3dfd08db501	c13dd4fc-6319-4cbd-9f1f-985bfd36badb	5c726b311b72ca72553732048ef5f7a39e8673cbbe474962043d0e671a290fc9	f516d3fd-139f-4938-8b40-b40d036160ff	2026-12-15 10:01:02.125575+05:30	2026-11-15 10:01:02.541793+05:30	2026-11-15 10:01:02.125575+05:30
22e07dac-409b-4cce-9846-6069c6de19a9	c13dd4fc-6319-4cbd-9f1f-985bfd36badb	0efc0d4be40cba0f69b72f13e135081e3512c8556ed5e298c20bc1e4b3380ff7	2e5e8224-cd83-44c0-a7e9-2c2fc940398c	2026-12-15 10:01:02.772175+05:30	\N	2026-11-15 10:01:02.772175+05:30
ce8dcc4c-1e18-45f0-b1e8-f45c5a87192d	d25e6870-684d-4014-9455-c9ae839ddd74	9c286943d834785652d2b252433a2d408f36b5df3dc2f6086443b0ec7d5ff9be	23a258e9-8c1d-48c0-aec6-85072e079dca	2026-12-15 10:01:02.896952+05:30	\N	2026-11-15 10:01:02.896952+05:30
c8c7373b-30a1-4b89-98f4-a1a3de2bda66	e11441d3-141a-48fb-b458-8189aabaac54	07e2ec1bed69d62b95439a5ced2b8cb1b02c19de23912a939aa7b154d91b22a3	2471ef00-db15-4776-bf98-1675ed8eae80	2026-12-15 10:01:03.015975+05:30	\N	2026-11-15 10:01:03.015975+05:30
783d840a-3a1b-4f07-940f-9cb31b53cee3	a7cfeee7-58b0-445e-98d0-d095dd71037c	16b1f638a1a4efd973d4c9030888fe93d6d9c1e5ba6e40e9b6710b6e107b2d63	5cdc29a2-4e8d-4b65-9ac2-055f68044aff	2026-12-15 10:01:03.140702+05:30	\N	2026-11-15 10:01:03.140702+05:30
bae92fa0-570a-4a05-ad2a-c5de055e4871	6d979b57-a271-4295-9aca-bdc559572363	025e9b086edf10883f3b4c59f439279d13724497e58a809de70d46689b76bcda	7f9b6be2-57a1-4630-9fd0-dece339681d2	2026-12-15 10:01:03.25845+05:30	\N	2026-11-15 10:01:03.25845+05:30
909b14dc-b5e4-4175-a618-355d5cb9325e	aad4fec9-fa47-4499-89a1-ac85bfcbc147	8609a489e75466f7538449bd63084e1ed173c21f720467674d05e1e9e8a03859	16f720c0-9c2c-43fc-8a80-6ab9de46235f	2026-12-15 10:01:03.379117+05:30	\N	2026-11-15 10:01:03.379117+05:30
888b9eb5-d1a4-4101-9f22-584102db411b	04373638-22f3-46b4-9033-70715ee88a2d	8c590fbfcab0fdf9d9a52f32c7eaf785507d56f7e9c58868e1ace8450e3d9c9d	dfb83116-3d29-40d9-bb77-6cec519d3f8a	2026-12-15 10:01:03.506837+05:30	\N	2026-11-15 10:01:03.507848+05:30
958f9b20-98fb-49d8-a00f-cc6afa5e6518	c11024c3-4bac-47d5-b3cd-1ec3b3b3580d	9398d72c61580d8ed34f8a47fca7d3a9554fbfc039d079f926e75659f0ae47a6	92012210-17f4-41d8-974a-377929905eba	2026-12-15 10:01:03.621836+05:30	\N	2026-11-15 10:01:03.621836+05:30
1002e58b-881c-41be-9a9d-f74b735eafa7	9921156c-b913-4d05-9322-9d3c83a826dc	297ef5b434f6605c031bf7c9b0860313552a631b5859befef7b8405474a3964e	d3d0cdca-54a1-4584-ba5c-bcd8736bfe32	2026-12-15 10:01:03.74438+05:30	\N	2026-11-15 10:01:03.746813+05:30
600eb921-e474-4574-af27-31b36536950a	4de56ea6-0895-4a34-9d9d-75d176758eb6	afe9a8b0dea051ea8707657f7d3a899180f3c1d81a317d06e06326a22c0165ca	e64ea728-837c-48b7-9b7c-1b1167afe55a	2026-12-15 10:01:03.863072+05:30	\N	2026-11-15 10:01:03.863072+05:30
effbb59d-3712-4eca-8f50-454fedc3fd68	fc9baa5c-a489-4e87-980c-9696c8c30473	f54590d96c1d60b69f0f2ef883fde8882ebe5e5a6cc692d42bc8dc7715c409ca	f5c00de4-6c47-4ef2-8715-384aea16371a	2026-12-15 10:01:03.98022+05:30	\N	2026-11-15 10:01:03.98022+05:30
86f0635b-a079-4209-a27a-6fdc0841819b	e7f0ae1a-7624-4522-ab53-46401ce6dfed	ebe45628f567a3832c7a85e5425a63d7c95497aa6ec605ff306f60cfa75dfb43	175d3da2-dc65-4a88-998e-fdb39f7537d2	2026-12-15 10:01:23.5989+05:30	\N	2026-11-15 10:01:23.602191+05:30
ad46df3c-1e9f-4575-ae58-7672ab4cdea2	583c9f8a-0bf6-4e27-907b-a34a8cb4640b	9038f3d06e344e3fa38ada02b09674325b3d5dca6c91c07c390c795bbc8d8ab9	7a3733cb-5c15-474a-b06d-de7c62e0090d	2026-12-15 10:01:23.777457+05:30	\N	2026-11-15 10:01:23.779921+05:30
53640e11-3ec3-4c45-ae8a-1842cb33e06f	67670102-67a2-48f4-9360-ca765a435936	3d2b8388b1f68b1954ea09a533644b71d55599d9ec246ae99a96e9d6aaa73bc1	a0a22dff-419f-47f7-a6ff-17fd31a551ba	2026-12-15 10:01:23.908914+05:30	\N	2026-11-15 10:01:23.908914+05:30
5e810e39-3785-4e7f-bf1d-b69a9d3b45cb	8edfe372-8afd-45f0-9780-86b44ab97648	b0f7c3780ba6beae1befba6a266154651850ec38f857d9a9e001767c3e5022e4	71c601f4-6d16-423f-b01e-b1f5f5e5003c	2026-12-15 10:01:24.0512+05:30	\N	2026-11-15 10:01:24.0512+05:30
28f477dc-928b-4c9c-b7a0-6014ace5cdc1	8edfe372-8afd-45f0-9780-86b44ab97648	f9d6c8db87b9572b36cf387cbb1c1d74acaf3eb770b2dad6920cb9bf7418398e	58a4cbe1-35f1-4509-9ead-87a7e1f81c67	2026-12-15 10:01:24.189733+05:30	\N	2026-11-15 10:01:24.189733+05:30
4f309f09-8cad-4932-8812-08293bf2198a	6ca8b082-80f5-4780-a2de-0ddefa611ac8	0976d06704a1a4a78b78cfd490c4a98985d510cf14830c7b6c92165013ce9268	e4cb470d-e833-4408-a0bc-b1fef08fdaf3	2026-12-15 10:01:24.438907+05:30	\N	2026-11-15 10:01:24.44034+05:30
ffeb3101-6dd5-46c5-b125-a283ea3f4099	a9f8217e-07d8-494f-8ad0-2cac9d84e486	adcb38098957f4639a7b97e6e716163c9015d7a1d4830ad26443d6a8e4ed667f	1f47076f-0fd3-4cf1-89bf-4e664b14d016	2026-12-15 10:01:24.586576+05:30	\N	2026-11-15 10:01:24.586576+05:30
5bc98d83-9b6d-4edd-9b1d-e2107483ebb7	7316d1c9-d49e-4b34-9a7f-7de454268df0	e886b3ea3d23dedc33b48f45a1fdc768724fe5e0c89a21185f1804283cd46f88	e0eb3f14-b411-4adc-aa6b-3acc8a80ba10	2026-12-15 10:01:25.080156+05:30	\N	2026-11-15 10:01:25.080156+05:30
b146745c-0713-43e7-85d7-51224f9fbffd	e8064f2c-0b04-4801-b6c3-eb3b0708f5d7	181bf738b32e1ce1bddb988411e4c2f2797729ac7ca64ffc8e980cb2689a680f	3a7e8e4b-fa92-4020-898a-89bfa64709c0	2026-12-15 10:01:25.375233+05:30	2026-11-15 10:01:25.391363+05:30	2026-11-15 10:01:25.375233+05:30
d05f411e-1959-42f9-9e57-5f728d521b20	e8064f2c-0b04-4801-b6c3-eb3b0708f5d7	12f4906b6c4f6ca4763f7ff926cd5d9fb6917943ada4e376279192d6d52354aa	3a7e8e4b-fa92-4020-898a-89bfa64709c0	2026-12-15 10:01:25.391363+05:30	2026-11-15 10:01:25.413629+05:30	2026-11-15 10:01:25.391363+05:30
2e1b8026-6bbb-44ae-b642-d3be1ade603b	75dcf2de-ad3d-4fce-a75c-498175704e55	864a6b9302f7884f21fe350edb812583f3bb2a293d9329f3e516dca26745d6bf	da40f82b-e83a-485e-af45-45e76a3493b8	2026-12-15 10:01:25.551359+05:30	2026-11-15 10:01:25.569345+05:30	2026-11-15 10:01:25.551359+05:30
9c26834d-1300-4c3e-9673-6dfb0d341d30	f81bc565-e9c7-429c-b49e-108a6a98cc05	32f6b30b17faed744aee67f9ef8fe52454d5843f7be8553b101c7bfa34027b6c	affd3f64-fd2c-475c-aa1e-03ddd9ddc81a	2026-12-15 10:01:25.709723+05:30	2026-11-15 10:01:26.07228+05:30	2026-11-15 10:01:25.709723+05:30
763a2281-dadf-4889-8771-eaa5bb6e5be3	f81bc565-e9c7-429c-b49e-108a6a98cc05	c8c8f83c516b638b595f5fe5cbe01379c89dcee936b7c77fb997f41e4cac74a5	1b594566-a080-4435-bad7-27a98b7734d9	2026-12-15 10:01:26.314507+05:30	\N	2026-11-15 10:01:26.314507+05:30
e56249f4-fe1b-4889-a150-1d1ef9050122	f2fe6bfb-72ba-43a8-9c40-6f43cecbe13f	fbd31a6fb64f24b8d1f0dcea299effb2ec5e8f568ca44f7cab9dd96b85f4e2f8	c20ded72-79f7-4262-b00d-61a8ac788146	2026-12-15 10:01:26.446327+05:30	\N	2026-11-15 10:01:26.446327+05:30
ec82918f-313d-45cb-bbe8-6489bbbd5981	2c150299-c5d9-4e1b-8a0a-d081332f9c21	ef5081ad2314836244812ca9322d2089280c9389a59c02fa7c9f65cabdd4a1b2	f5265f8a-7845-44c8-b429-f83f66a3645d	2026-12-15 10:01:26.583846+05:30	\N	2026-11-15 10:01:26.591334+05:30
385dfb6f-6677-481e-bfa1-a4d5f4203322	f646e0e5-1603-48c6-bb7f-4a9dcefedf37	ca079894eafdb31907bb8edea7dfe8fd00bde89e27599a2b62d77b02a727f5a8	79ef74e3-3496-45e4-8def-5408ec60c68e	2026-12-15 10:01:26.717405+05:30	\N	2026-11-15 10:01:26.717405+05:30
bec3a4e6-f641-40f8-9cf5-b8287ff04031	2c9cf861-5062-4019-ac6c-261c75099f55	9bfc62aa4b6dfe88321bd4e3e06e7c052bb8decc679270b78ead0c12161b75cd	abddf654-99a3-42ce-b8b5-2af8786d5ce0	2026-12-15 10:01:26.850589+05:30	\N	2026-11-15 10:01:26.850589+05:30
541d4bcc-4527-4425-bc6d-a3fecef626fe	63a50ec0-3dc0-4152-bce4-8f94eca3ac7b	e6e7559c768bbbf5d54a05cbc41b6ebf2fbedd8f76bf2d89dbb5d8331c1bb498	7675e76c-68be-40a0-beee-5c4db6fbefb2	2026-12-15 10:01:26.981087+05:30	\N	2026-11-15 10:01:26.981087+05:30
09fc4ebd-b1b2-4b80-addf-692d6a072833	1fec3817-3674-44b9-9255-6a50f36502d0	a206615691270da5b8434364f2ebf64061495adf8a265f439e63deda9d3c6ac7	7f3452aa-8ed9-4b30-9e6d-4b5489c5fed1	2026-12-15 10:01:27.108659+05:30	\N	2026-11-15 10:01:27.108659+05:30
524b5a84-b1f7-43f6-9fae-6144c359bcf8	9913e92a-b23e-4236-895a-f4eee650f8cf	fa94f14685edd96508fbde23b082bd7b31532f3b72aa31febb9b1906269b1c7f	1e13d668-2e66-4fb9-87a9-0b3a192d00c6	2026-12-15 10:01:27.236975+05:30	\N	2026-11-15 10:01:27.240696+05:30
090a051e-ee21-4536-9e50-2154a91f637a	6594c43d-4659-4d81-aeba-2651510e46ed	15edd807d8f7ea22d0ce11ade1b29875bcb50ad2a908ebf3003d5157184f76c4	799db6b3-f6d9-40fb-bacb-cec99f515f77	2026-12-15 10:01:27.365501+05:30	\N	2026-11-15 10:01:27.365501+05:30
14b3641e-ba18-4f6e-833d-a0da3b1b8a7d	07d6bb11-d9a9-44d3-9ac1-1d4968a40764	d4c05d89b8b08a5f69b9fbf8c164a853d0764c180838aeebea2ac2161db38512	22cec832-f03b-48cf-8750-9e46b9f85e52	2026-12-15 10:01:27.488382+05:30	\N	2026-11-15 10:01:27.488382+05:30
f471ca8f-73ca-492f-9ed5-2e7c5e1dbe4b	48beffe8-853b-4aba-8979-741e7e35b0f5	9ffdb4ceb45ccc2033622b471acf11275078a9bc8b5db1fafed424024099393e	faf4c67d-5552-4512-ba6c-71c836835d5f	2026-12-15 10:01:27.613523+05:30	\N	2026-11-15 10:01:27.613523+05:30
fddab465-8626-40c3-8e7a-0a873a39122d	1633297c-1aae-42cc-bba2-b1e200130fdf	1f8f298e1214c9cbb54429d89d8d98821762fb52dcb9c9eca4918cbaf786431a	226e98d3-1510-48d5-90f9-c8a76fcb1a8a	2026-12-15 10:01:41.61887+05:30	\N	2026-11-15 10:01:41.61887+05:30
b37ccef4-31ae-4056-9da4-925f59a3dcff	0446e56d-ea56-4287-a7be-0240565421e8	1dc0ef87cc630f3299344bc3b31b3b0c51b28dd0e6ad92a6c764279909bd7e42	ace0bff2-a897-4af5-8b76-3f3be95f4cef	2026-12-15 10:01:41.728399+05:30	\N	2026-11-15 10:01:41.728399+05:30
346e8ad2-7ac8-426c-a235-73807353c2d8	58ad0164-900e-4b47-950d-e48e7391bc32	4b355ca5024cba4fa49abd3725828b80cbd4f8267422334a9946d55e28120990	2811c92b-d6d6-402e-9b05-7734e9a21736	2026-12-15 10:01:41.83909+05:30	\N	2026-11-15 10:01:41.841861+05:30
fbd870b1-2e46-477a-a589-cc7bd8e55cfb	6b88d33a-7147-4d80-b11e-fe750c78844f	a3354c174269bfb141fdd27d8e8f339da9adfbd64f48f188365246c62997b763	17cc0a5d-2141-44b2-af8c-70871d379c9a	2026-12-15 10:01:41.948275+05:30	\N	2026-11-15 10:01:41.948275+05:30
c563cc70-3064-4483-878f-d619c3fe2a68	6b88d33a-7147-4d80-b11e-fe750c78844f	eab52a83efb3b9a77b66e223362a399a43666a0c17fad26277c8605a777d29a1	2a0266b7-32a3-41f1-9c5a-b2eb9c0d6a22	2026-12-15 10:01:42.066356+05:30	\N	2026-11-15 10:01:42.067366+05:30
e4e409fb-37aa-4761-bf35-970cec5cc163	889c30ea-4b38-4953-9192-1c4b296e94e1	2a0e751c77a6e68619361e2d4840b248ef5e11e4270eba3c76fb1dd76f0b6f53	3c9683c2-7d5b-4f44-8c7d-9b18ff412c5f	2026-12-15 10:01:42.292041+05:30	\N	2026-11-15 10:01:42.292041+05:30
8ffa47dd-7757-42f9-b3e1-11c13d3f4bc7	0aa2d43a-f381-4b59-b6a5-5164321b0d1c	e7d56c54aff831ceafba08a3eaba5731549334c426f7a94a68938cc73094d451	b37af459-0aac-40d0-aabb-3e53b751e351	2026-12-15 10:01:42.428741+05:30	\N	2026-11-15 10:01:42.429749+05:30
97fb2d33-e1da-44b3-ba15-0b19691b5944	59aac385-2bd5-4288-96c6-61dca077ae01	32a9ea894f9b0f5f0d247d241dbc28ffa5189145223713ca9b8a609520362b83	87bdbeb0-ce66-40fe-8623-83c1b1848c73	2026-12-15 10:01:42.89106+05:30	\N	2026-11-15 10:01:42.89106+05:30
60e41b2c-13bf-4b76-8e95-841b63921457	8fac1804-a606-431a-b93a-69442b5fb34c	69f1be91d170177e6f3d76cf212545b997d22f561070216544e57c4583229265	3db35248-95fb-45cb-8e6a-413c8c67c971	2026-12-15 10:01:43.157821+05:30	2026-11-15 10:01:43.185151+05:30	2026-11-15 10:01:43.157821+05:30
bd3a4e29-1fda-422c-b6c7-548740c5d38f	8fac1804-a606-431a-b93a-69442b5fb34c	ea3ba2e2b87a938e5f8c406897bdb27648208d711053361f4893699cf4ce4b93	3db35248-95fb-45cb-8e6a-413c8c67c971	2026-12-15 10:01:43.186286+05:30	2026-11-15 10:01:43.204004+05:30	2026-11-15 10:01:43.186286+05:30
10a361ae-04b0-41e4-9dc1-b266d05af3ad	12fe8a03-d6f8-4551-a791-60b6f5e74a78	79a1312468c10710ab4a490209a6be54d23342eead92932cd523a6590eb1f19a	f372e276-44d9-44bd-86b4-525e70180878	2026-12-15 10:01:43.342062+05:30	2026-11-15 10:01:43.358196+05:30	2026-11-15 10:01:43.342062+05:30
c28b1e23-5d83-4088-b46c-e35040b05880	bb77d7d5-360c-4bd6-a03f-4854de775f06	5d5c8add2779b6d4ec729681d3ceb2a43d665bfda4370d425c9cf8b698d7f08b	7e3233a0-45a1-4a38-b759-3d1922673268	2026-12-15 10:01:43.493736+05:30	2026-11-15 10:01:43.829096+05:30	2026-11-15 10:01:43.493736+05:30
4f6ea949-c849-4c19-873c-9b8a2f2df689	bb77d7d5-360c-4bd6-a03f-4854de775f06	45b80fa4d25bf68ae203d5d60c67750c5c006b4901f418a0135cf9c885a5455c	7b4c7356-d6a4-43bf-9bf6-4324af232756	2026-12-15 10:01:44.058047+05:30	\N	2026-11-15 10:01:44.058047+05:30
95837ed4-dda6-486d-bd4b-f5ecf79dba6a	53ad667b-e168-44ae-915a-fd3f71188b74	90876fb0e7776bbdffc126fecbcfcc3452399a9961d9b8c7bd9b3f8645d40ecb	9752ecc4-9f90-4b8d-8901-e9168cbf1401	2026-12-15 10:01:44.177444+05:30	\N	2026-11-15 10:01:44.177444+05:30
0e4229dc-41ae-4f75-8a50-3f722f247447	23a353c9-4a91-436f-8a36-1aca3a29c754	6263492c2243903189b8572a3a54796f6631778a209eddf1afbcf35139be31fd	0c7cd12c-06d1-4091-b373-86ba03dde085	2026-12-15 10:01:44.299251+05:30	\N	2026-11-15 10:01:44.299251+05:30
25fe1ac7-15f0-4913-9540-90610a005bee	37dd9580-4d3a-4003-a9c3-0bd1401232ec	c10340608d2030e59581b13686936ac362faf653bac5587a9a80e50da21c5317	ba77c365-012e-43a4-9131-4458e2e2bcf0	2026-12-15 10:01:44.410125+05:30	\N	2026-11-15 10:01:44.410125+05:30
7aef7123-d0cc-4fcc-934c-90ff5777cb49	fa1e6759-9896-46e5-a8d2-996a41595ffe	b3485f8aaaf084db7ea2feb53764d1d34147323562bc27ce424a994a3fc38808	d16a4821-8013-4d78-adcd-d4996ef8619f	2026-12-15 10:01:44.541057+05:30	\N	2026-11-15 10:01:44.541057+05:30
82acdd89-cf11-4b44-8831-b2d0de684906	789c9ef4-c858-494d-ac41-e2db9d1ff46b	e19bc3ff42746ed06f5f4b609b8ad8eb5732273ba20a16163d5767e9c63d3117	53e25275-67e2-40d9-aa71-3085a3144687	2026-12-15 10:01:44.657299+05:30	\N	2026-11-15 10:01:44.657299+05:30
aac98249-b4b1-4baf-b728-d27e575a9fbe	ce1bff2e-ce08-4baa-9ec3-6a0115fa3c1a	c973ac5f531d5ac3c833c6152ba55e2b7764a2b1a908007f76597f7cb8acacd0	a94c5fd2-c3b6-41be-b3da-17bd4908a2d3	2026-12-15 10:01:44.766134+05:30	\N	2026-11-15 10:01:44.766134+05:30
02f612fe-1b42-4cc0-b30d-06d9c2d099a4	be69e842-27ae-4147-8612-d8d1c900c312	f94a7e5285fe1da6006adb3583421023a56fd8ed1fcb9ce8e9f5960f8e0b5ca9	f7925579-dde3-404d-833d-98e157b7abc5	2026-12-15 10:01:44.895105+05:30	\N	2026-11-15 10:01:44.895105+05:30
b66b1af7-f89d-4a23-bc6b-66bd4740cc3e	940b5b41-7baa-47d3-b8ae-a1b7b8f5d65b	a94361eb4f2c74b920a5debc5f3af9baa128ebea422b1dbb87288b6dbb995fd9	334a9b7a-4e64-4c2e-bf96-d13cea37c877	2026-12-15 10:01:45.006741+05:30	\N	2026-11-15 10:01:45.006741+05:30
df399de2-2fc5-49ea-b067-f80cb9c56129	e21e9a02-a0aa-45eb-a6be-a13f379bcd5e	b4546cee042703881ead79ed39894463891dce75928a70d395d1025fbfe99256	6b5e3c68-a312-4dda-a9ad-d9ff5c29d632	2026-12-15 10:01:45.142303+05:30	\N	2026-11-15 10:01:45.143313+05:30
a44850c5-428e-4a74-95ed-c4e33e8e114e	d6bbb5b9-0116-43fc-9b68-390e72651c2f	bc9308e2b136f77734532d4de61f41eba17a4e3d343ca00413611f04674202f0	414bb0fd-ca14-4808-a8a7-93709a52806e	2026-12-15 10:01:45.261106+05:30	\N	2026-11-15 10:01:45.261106+05:30
ef389774-5fd6-4604-b60c-cac5bf8e9e62	592ddcc6-3db3-4cea-a2c7-fe36ac21ac72	f67400fa2448699bf25700db90afa0fba0870801fb5c93943bbb0d042f506c7a	36bcb2a9-8e87-48f6-a87e-5b88d51e4fec	2026-12-15 10:02:01.548508+05:30	\N	2026-11-15 10:02:01.551075+05:30
fa9b99e0-c883-433d-b8b6-67c461924407	1aad5a0a-5134-4cb4-ba61-55e9d4b6e5f2	c7c04d48b1bc6cf0cc6d8cfb5a0961c6bff4a2e27b48db58636350859495d353	87919c6a-5f79-40ea-815b-bba03d049ea7	2026-12-15 10:02:01.671845+05:30	\N	2026-11-15 10:02:01.671845+05:30
7c2dcd70-f351-4764-beca-c919b3dce499	69b718f5-6dea-4362-99a6-6788d2bc026a	c50f76614606f73a71b402ec42809f78237d18cd7e01fae1bb9d74979e991796	a4dd4c83-64d8-493f-907d-c7e80036d9a4	2026-12-15 10:02:01.789247+05:30	\N	2026-11-15 10:02:01.789247+05:30
b8ac8261-94dd-4ad6-8ce6-10ce19a7f363	2cadd76a-df00-4205-ba74-0de1c1d38f70	89dde8cb83f82954369a1ebd38735db0fb8577966647be601ed27b76dd8a5455	3a9a102e-379a-4e34-95ee-6aa074745158	2026-12-15 10:02:01.912481+05:30	\N	2026-11-15 10:02:01.912481+05:30
72616138-0637-488c-99c4-a49ef4da6e1c	2cadd76a-df00-4205-ba74-0de1c1d38f70	e9a2c49cfb34fffebbec1082539763639f24448f2fa619957750866283cc3b1f	a292c2f1-5edd-4bb9-a6f5-0c1ca9c122ba	2026-12-15 10:02:02.03731+05:30	\N	2026-11-15 10:02:02.03731+05:30
f32701d3-3124-4f23-9056-adbc22e72928	0c4fe5b5-ad08-4b80-b502-4de4186ee956	74bb6bc0be622a9dfee9c63340c10c47f1db28faee08c5765b0e9401895e5600	60b9cc44-db1c-4c6f-82cb-4e3be3ca1e5e	2026-12-15 10:02:02.258865+05:30	\N	2026-11-15 10:02:02.258865+05:30
1b7ef3c2-009b-4891-9e7d-bb5e03369c99	379947d4-6464-449b-913e-ffd9dea90868	a3c355ef2cf552525e0432effaad25ba7af4cbea083a966ba56e11b65311581f	dec535e9-91c3-44fe-9114-6806f39fe652	2026-12-15 10:02:02.388837+05:30	\N	2026-11-15 10:02:02.388837+05:30
d78e073c-08c9-41cd-a480-bfb9cbeb09dc	8dee790e-6bc4-4c34-964f-e7b7289b1ce8	381169c76235930bb81faa89953427571926e1c004364156bdeda8746b27fda9	f940bf17-99ff-4f03-afc2-2d3a80d674ff	2026-12-15 10:02:02.885064+05:30	\N	2026-11-15 10:02:02.885064+05:30
6cf416bf-7922-4060-8046-9fcc1821163f	169f2677-be9c-4eb7-abb8-5fc8e24f39cd	896ff6866728bfa1bb70ca0cfa8916a936442e5e6c27413a9df7ff6b639cfb13	4398cb5f-76c2-4881-9129-708bfe79f790	2026-12-15 10:02:03.163901+05:30	2026-11-15 10:02:03.18448+05:30	2026-11-15 10:02:03.163901+05:30
2e44c656-5843-4641-9e21-98f25c7a4996	169f2677-be9c-4eb7-abb8-5fc8e24f39cd	b6b5254b7b37037f569b26812c376474908a1fa6ff15bcbfcdba32becce4d1f0	4398cb5f-76c2-4881-9129-708bfe79f790	2026-12-15 10:02:03.18448+05:30	2026-11-15 10:02:03.195655+05:30	2026-11-15 10:02:03.18448+05:30
33f9dc88-5ec3-4c71-8800-443e814be063	f905dfb1-ccbb-44e9-82f9-72f31c2866db	2a510d66615566c537f800be6cd64d7f1ca0fae0a9b1dd3540c6b6b460934ad4	82f2452c-3646-4bf0-9369-de44e898857e	2026-12-15 10:02:03.337865+05:30	2026-11-15 10:02:03.354657+05:30	2026-11-15 10:02:03.337865+05:30
2c2fe7d3-552a-47f0-b572-e46553845274	646ed346-259a-4485-940b-fba63be9e718	eb58de7a78274ff183f31243ce9392f08e214be0d726e3ba6929adb4cf531fd7	1032012d-3cfd-42e6-99e6-394a4d89d99f	2026-12-15 10:02:03.484825+05:30	2026-11-15 10:02:03.834215+05:30	2026-11-15 10:02:03.484825+05:30
73fb0125-7b44-4102-9c78-1532b417b4c5	646ed346-259a-4485-940b-fba63be9e718	8725975a5a7d64d1ad1cb2de1ae36ca2a5311287e0f8cfd253cc6138ce01ef91	6af9af29-a59a-4f32-a0ad-406647ce7724	2026-12-15 10:02:04.05346+05:30	\N	2026-11-15 10:02:04.05346+05:30
483a0e2b-78f5-4a3a-be0e-196f087e28ec	69d398bb-e9d2-4def-b63b-d2377853b0ea	6da0de831ff00a19730fd85c6010f550e5fda2c4d9bf61a588ee27ea31e62379	344a8b90-a650-4805-af2a-2906bab1e79d	2026-12-15 10:02:04.179549+05:30	\N	2026-11-15 10:02:04.182757+05:30
b71c5118-970d-4a82-b4b3-4a4f559b0891	e4cc5105-a27d-41a7-9274-a80e679b7fab	a4aa652da269ccdaac44733d6b42d7b8cf97617e598748d25fa65b90f5644b62	154fe1e2-665d-41bf-9d9c-43723bfb601c	2026-12-15 10:02:04.30162+05:30	\N	2026-11-15 10:02:04.30162+05:30
1060963e-f3e5-4e9b-b0cb-90933abbdae2	6642567d-ff40-4c4f-8d6a-d6cc00639ffb	d72c679bc2dfd78cfd48902bce89ced43c66905770e7b9f35e60236dfa975d0f	b5bb1204-1220-4c48-9ef8-b758eeb5c58f	2026-12-15 10:02:04.420901+05:30	\N	2026-11-15 10:02:04.421909+05:30
649d19b9-e0a7-4366-83a4-d533a8605b89	875fa499-a4cb-4ee3-b1b5-df520b038671	e7c56c00df5ea07f61dcdd3042ca9fad3bdc2cff1340040edab1e8d92b0e9488	9105a6ed-337b-47db-aa2f-f34296858ba1	2026-12-15 10:02:04.529356+05:30	\N	2026-11-15 10:02:04.529356+05:30
681e311a-fedb-4eed-b89b-c15dfdb8341c	10a0ad73-eae4-4ac3-9e80-c2d68eb7fc6d	fe89c74c6e33176a8bf762028a369a02f608547ea0712851fee0d19e1607df3f	fb1c9658-c45d-450f-921c-6d9bf0a2283a	2026-12-15 10:02:04.661823+05:30	\N	2026-11-15 10:02:04.661823+05:30
d6bac2ad-b40f-4e0b-95ef-921073c028d0	69a180aa-8203-4b86-a7b8-1264bccce630	acddae0d0c55def6bb24cf37f5b8b21bf7598d4363b64b05b01f981c337c7747	7be02cdc-ca48-4ddd-b759-3daa98d754da	2026-12-15 10:02:04.785775+05:30	\N	2026-11-15 10:02:04.785775+05:30
b85594ab-f8df-44ce-9c89-391673961f05	f1506810-d03a-4863-901e-3ca88a1bd6c1	5327d3a8540bb74953013ee9a4b70b3cdff5ec0690de7884a16022d1aeb216bb	a1e22320-18ab-4305-a253-1926d285a1cf	2026-12-15 10:02:04.905811+05:30	\N	2026-11-15 10:02:04.905811+05:30
e79cb6aa-c747-403a-88a7-cb84d44f7e62	1ee0fe3c-e202-4db7-bce0-fddd22a34b74	9576cdc68d6213363bb10ed519b04fadd82966a0846654ca56f7ec9e8ea8919b	c5998ad4-a19e-46f2-8cb0-ff4964dde8bb	2026-12-15 10:02:05.026364+05:30	\N	2026-11-15 10:02:05.026364+05:30
8a046af3-d8f2-4844-9fe7-89f3126148b4	48ab97c2-af38-4516-8d66-35594e442a6a	e62455df9049007a9fd476f49b47dc9b8760a3016eba9037a4c056cf6dacb0e3	49711e11-f9cd-470f-89f8-e3a8ec980a63	2026-12-15 10:02:05.138021+05:30	\N	2026-11-15 10:02:05.138021+05:30
d352b9ed-91c6-4b24-ba38-fd8a73178e4f	21f04dc1-0e5c-4cf4-8660-aa6b8276eea1	2c59502f163b9c1cd20a50d433c7790d8ad831a0d3e4ac38b587b0b9d217e0b2	83d2fb22-53e8-48da-92de-c8146667c9f1	2026-12-15 10:02:05.264328+05:30	\N	2026-11-15 10:02:05.264328+05:30
f6e4f9f9-db26-4a9b-a5b1-25ac79390659	a7d9306c-2df4-4864-8348-4d49c9fb1d59	f16a21bb091989cec6a1e7ee74a452801bd6c03d39d14573c2858f912b25398e	16474604-4c31-472d-b3dc-f9d4d2223dc7	2026-12-15 10:10:35.746454+05:30	\N	2026-11-15 10:10:35.749481+05:30
e879d0db-8c19-499b-86d2-d39097d2b254	fbf4449c-99e3-4013-b7d7-266f5501eefc	96aa44b29125afbe6c23ddd7e4e028a1678d26828abda755743d207ea23d31f9	a5fd5238-d8c5-4241-94b8-322dc23b1cab	2026-12-15 10:10:36.11329+05:30	\N	2026-11-15 10:10:36.114323+05:30
409bd8e4-db85-436c-8639-5d5f35dc555e	f998fdac-8549-4788-b9b0-44d3bf2438ad	f1a48f596a58752418e39b35eafc2c2dc1eb903250eb936feb31d25d654c574d	256a37ff-49b9-42b0-a396-b50d38657073	2026-12-15 10:10:36.244619+05:30	\N	2026-11-15 10:10:36.244619+05:30
02114abf-a2b6-4ade-93b2-9446e82509df	a183fb22-91e4-47ff-838f-8e18448d2ca4	d09fc7bcaac06782baa49b6560960a3fa78d7286d0556651834b9b942269d44d	622fb525-312e-42e4-a4c4-21953defb6e2	2026-12-15 10:10:36.403732+05:30	\N	2026-11-15 10:10:36.40473+05:30
7fe0b9e1-5130-46b9-b4ee-e6842d980cbe	a183fb22-91e4-47ff-838f-8e18448d2ca4	1c218884d16ca9fb9b944361b5299e7704024ca86ad6db2b4864de2bfa45174e	bb942112-6baf-4c03-b8b5-61eb57d3db8e	2026-12-15 10:10:36.538779+05:30	\N	2026-11-15 10:10:36.539911+05:30
4eb39d4b-e6b1-4628-a744-2bfd54401e96	142e458e-f53b-4a44-9b32-3256242126cb	24eb380d6f0d72a4e998a8dafadff71ea251f80807114409bf9f439bcc024b27	d52422ef-a8c6-49af-bfa0-4210a289725d	2026-12-15 10:10:36.802275+05:30	\N	2026-11-15 10:10:36.803273+05:30
a4dabaad-afb8-4296-ac02-8add9c9d318f	5d7cb32e-595a-49a2-8781-3f4e8eb1bd8c	f0d5b8b5ccf4496b90f3bd89858f9f64067fdba2053549c2f54bb9594f3428ed	887be685-b1e2-42e1-993d-440fe32360c8	2026-12-15 10:10:36.959175+05:30	\N	2026-11-15 10:10:36.959175+05:30
86ca5c0d-db32-4cfa-9525-9f748db02305	36b6cd20-6c92-4169-9f28-701a177a0673	eb3aa712afca0b44729fda0ac37b34cb00ca4f7ba854641c659c9955d645f937	59bebd23-11c1-446f-a4e0-474395717771	2026-12-15 10:10:37.423264+05:30	\N	2026-11-15 10:10:37.423264+05:30
fe94bf97-5d3d-4f21-9e10-7ddbfc982691	8a48231c-4436-43e3-b36f-143c2cad4236	7afff1bcd0b50bff2c6d5b1a4078411d816a395feeaecc73db997d62a442a331	6fef6ebd-65de-41f6-bb25-7ec498da5d92	2026-12-15 10:10:37.716065+05:30	2026-11-15 10:10:37.723544+05:30	2026-11-15 10:10:37.716065+05:30
7cbc5c1c-ff55-4083-9ad6-44327be32988	8a48231c-4436-43e3-b36f-143c2cad4236	54122c2d7c14c02e1afd6b9acbbbd53d7738dd8803310244ecbf8a0406003c3f	6fef6ebd-65de-41f6-bb25-7ec498da5d92	2026-12-15 10:10:37.738381+05:30	2026-11-15 10:10:37.751669+05:30	2026-11-15 10:10:37.739588+05:30
5f30ea62-c2eb-45c9-8652-87cbf50a517f	a32eceae-a5b1-43c6-8600-73d14f3a4cad	5f299b3f2a3be28a6a39da93d474beee43ba631845d33ac2788bde81bd2a8542	3686b0a4-2009-485b-b759-1aadf49c5d30	2026-12-15 10:10:37.873694+05:30	2026-11-15 10:10:37.898783+05:30	2026-11-15 10:10:37.873694+05:30
154ef4f3-90ca-47c9-b297-829fe4f736c1	6c30590b-7122-4c93-8d4b-04afc4b4d936	47bc22490eddf6b0cd804cfb711832d7fd563575ae8a0254910f186805bc29e1	61158f37-c471-44bd-a3a9-abac5b83c36b	2026-12-15 10:10:38.040544+05:30	2026-11-15 10:10:38.694076+05:30	2026-11-15 10:10:38.041557+05:30
2fc38c5c-4751-4ef9-82b8-32ccfe8a77e1	6c30590b-7122-4c93-8d4b-04afc4b4d936	4f66a56c9f5e6f7ccf69560508264b13c13c280bb4fb46ac2fc6fa055c272dda	7b00dfe2-9857-44cb-9037-c48c453bb8bb	2026-12-15 10:10:38.963965+05:30	\N	2026-11-15 10:10:38.963965+05:30
bf506039-c68d-431b-8620-926e57e7cc53	f20c63ad-8b9d-48c6-b803-c8c670cfb0ca	69cab1dfed10947fb5b1a3f1c5ba4e41970727f4a2ecb4488c08ef74517f5623	23a10158-213c-4a4e-949c-d72b74d5d683	2026-12-15 10:10:39.110435+05:30	\N	2026-11-15 10:10:39.110435+05:30
82215b97-a3f0-4cda-a821-7d2a366f8901	fa24d0c3-c7da-41b3-a5a1-6f979a6b7cd8	59a9138a0446fec5300a396ac0002cc0aadf3e9c4c9f69af4a9d0c89f856bc12	3aaf365e-a8d3-4d54-8d4c-055e6fbfa321	2026-12-15 10:10:39.269745+05:30	\N	2026-11-15 10:10:39.270294+05:30
d31f876a-0c1e-421b-b622-044feb1fdb04	900f3b32-87d9-468f-bb2a-b60a9b6ae5da	9189b7a1d4f49f85be4b0c2b4484c73fb28c4bdd883056b68068549ad78ef41d	fcea83ac-ef2c-44ac-849d-a7a4f18de66a	2026-12-15 10:10:39.610935+05:30	\N	2026-11-15 10:10:39.611941+05:30
2061001e-484a-4e29-8b2b-a72c2111eb02	be1f2c4c-0abc-4a84-9e96-263d6796c296	91eb599941bbe5ab0c25188136864b445f8bc47530d14600f09c3faf11092760	23f3bbb3-0074-46a8-ba4b-6e32ad454856	2026-12-15 10:10:39.743801+05:30	\N	2026-11-15 10:10:39.744843+05:30
db7c11f2-c2a5-497f-91ec-2179d09989f2	3019fd4e-56bb-4598-a790-7047090e1b6b	de003d96ecfd0eb707264d8d33665ed4f27ffcc7e09fa31f34a865ddeb918db7	09619b25-f077-4614-96b8-5d0145c4b77f	2026-12-15 10:10:39.866793+05:30	\N	2026-11-15 10:10:39.866793+05:30
8ff037e1-ae59-400f-8c9b-77bc0b80ffcc	a8736da7-d2e4-49cb-a846-ad1b1529f6c1	49850a1ec333c0be46333e8ce3effcc2b2d6b0d4d60e50952de284636fc1a0e1	0cb3e6e7-03d4-4cfa-abab-32402db78b4d	2026-12-15 10:10:39.993597+05:30	\N	2026-11-15 10:10:39.994606+05:30
5e5cb086-8516-4e86-8b9c-2f61b2c66c25	f77397c8-4c39-4bdd-aff9-6ddb30e01f97	540deb6774248638a54038e96157ee5dbd91611055c77b10b450388ec254fd5f	af9411a2-cfb4-4c1e-a631-7f09a57c5d01	2026-12-15 10:10:40.118091+05:30	\N	2026-11-15 10:10:40.118091+05:30
dd4a49ad-76a0-43a5-9e7a-fd6d3a7bd5ec	55a6d008-6dfa-4832-8cdf-d5eb861c9573	7824bf95fb5a98f83e450a619c044aed7d4f5f3adb1f5a993531c2d2343f92f2	58933db4-e43c-4ea8-93ce-0785af8655ad	2026-12-15 10:10:40.247095+05:30	\N	2026-11-15 10:10:40.248343+05:30
9866a380-e126-4e35-ae56-20da01741db7	040a27dd-b211-4699-b345-14b80a17d2da	a03350046ac9e7c54f682c766f6cf4a0250411db2443e36d0a322c0f4bfc30da	276929d8-e2ce-4715-a41d-bc5092ba69c0	2026-12-15 10:10:40.379504+05:30	\N	2026-11-15 10:10:40.380712+05:30
6a807173-8767-4c70-8ccf-68767efb67a4	d9f7bbba-a0e6-4cbf-84a6-5e5f7852186d	72860c8c5049a0380f7b64c8cdc119a4339985718e3b171ef5cb9931e469ebf8	4a915906-b4e1-406c-82bb-f8747fbf0c8a	2026-12-15 10:10:40.510403+05:30	\N	2026-11-15 10:10:40.511401+05:30
9ea074ea-3323-4b66-bb92-6d56901e5f10	fb72adfb-b1df-4975-bf69-17749f6a5a7d	0873933be4233bd922e847c30f17daf6719a1218edba5396a83d676a85a5a3e5	6381b2fa-d438-41dd-9f09-860bade7b653	2026-12-15 10:13:39.510774+05:30	\N	2026-11-15 10:13:39.511817+05:30
d657e1bf-4090-4b61-bc83-a699916c76ae	6b4bdc06-0b33-41ea-a350-296e4760faae	b5ee540868055c621cacb9f9ae5fdc804dacc582e4f9283e6fc0e3b79adba784	0b41fd56-9525-4057-a9fd-bfc2f5d2b32b	2026-12-15 10:13:39.643409+05:30	\N	2026-11-15 10:13:39.643409+05:30
6b85e4c3-0eb3-4f26-9a92-4c48d1ea9cd8	e168363d-219a-484e-9d77-c7047e059126	f76c799a9785d6d7485fb5ca89e61b5e41e83e70786fd5253a036c483f748d75	fcc96d76-9f3e-40ce-aff1-d81e69252a8b	2026-12-15 10:13:39.767664+05:30	\N	2026-11-15 10:13:39.767664+05:30
6d5bf14a-5433-46aa-9c5d-d83bfbf080d5	af13f86e-3087-4697-b3b3-3d0f17c202fe	dc2095fba8258fe7f013075e76feea0fc9432dd634c283786c444425212e7352	d74265ea-5d7e-4b12-a4a8-6f662548f0d7	2026-12-15 10:13:39.916294+05:30	\N	2026-11-15 10:13:39.916294+05:30
076ef562-e17f-4129-9fe0-28228c9ccf41	af13f86e-3087-4697-b3b3-3d0f17c202fe	e99f2104ea13d9911c3c1cf7fbfd7b429c63eba93fad57af2e50317cd571ad44	a74dea4e-0455-4a11-b3a2-df859e6b75fb	2026-12-15 10:13:40.060911+05:30	\N	2026-11-15 10:13:40.060911+05:30
8d2856d4-b1dd-44e9-b78a-9a4ccf775eba	dac0f509-e838-4f0f-ae78-47f5652e6734	ec6ea875ad1c51b632dd438dc710af2f80e2908b4733ab2d6034573b58af9039	12fb7f7a-77e8-4cd5-b03f-cb526ab9a987	2026-12-15 10:13:40.345362+05:30	\N	2026-11-15 10:13:40.345362+05:30
74e2a8df-22b2-4e8b-bc63-e8401b21cd9b	7958f017-31dd-4ec4-884b-03acac10c012	bcd0d7d1587626fbc94fb1868ad9097dbce573d86358319398daedb8caec448b	42c08e0b-4117-4389-a8a7-c4327be83026	2026-12-15 10:13:40.510275+05:30	\N	2026-11-15 10:13:40.510275+05:30
9e926d9a-7d22-46dc-957d-1dfa25f6e716	9d3970e8-b975-4a7a-889b-12200c47be3b	d531ee8691da67068c78257263d301f8aa272fb5cceb3276e98e97c7e09b7c1b	e2dde631-59d3-43cb-9e6e-52687363f8a7	2026-12-15 10:13:41.106756+05:30	\N	2026-11-15 10:13:41.106756+05:30
0388abaa-e784-4c8d-ae44-f24269d99b71	e266a19c-667d-4557-9196-c43eae1b1040	14af18a53de13023baeb64ffd5b90b3c42972ab5deaaa057abbd43dea71293d9	03c6e2a8-8687-46fc-bcd6-646e18d490f2	2026-12-15 10:13:41.467319+05:30	2026-11-15 10:13:41.493361+05:30	2026-11-15 10:13:41.468331+05:30
2dfeb84e-b463-40e5-a9b5-edcade4d706c	e266a19c-667d-4557-9196-c43eae1b1040	9d56c14a5415c24ce545f3e42c1c129d4b5f89a94fae0b5512d8440fdc39aead	03c6e2a8-8687-46fc-bcd6-646e18d490f2	2026-12-15 10:13:41.498646+05:30	2026-11-15 10:13:41.512002+05:30	2026-11-15 10:13:41.498646+05:30
343900ce-651b-4908-a846-2dd62cc0112f	0ff0556b-8248-4455-8073-4e1765c3d677	00b2fb9a579859fadf98fd149cc44ce0de776fa3378c3fa6b4e35f9c3483df5f	8dc40f4d-3d16-4606-8849-62c52151ab61	2026-12-15 10:13:41.694923+05:30	2026-11-15 10:13:41.710913+05:30	2026-11-15 10:13:41.694923+05:30
ddcbe7dd-ffe3-4ef5-8f44-1a1b98bda1d7	9ea7696d-2838-4e4c-8921-877232c31ae7	c7fb9dc51a95e0edf7d97960ec912509c3b2a385feb5bede0469fea2371d9498	9c92a8f6-e6f6-41fb-a360-74073456c999	2026-12-15 10:13:41.899061+05:30	2026-11-15 10:13:42.418305+05:30	2026-11-15 10:13:41.899061+05:30
9b1b2904-4be3-42e8-b70d-8c79cd52db3f	9ea7696d-2838-4e4c-8921-877232c31ae7	b7fed7a9566155c092f65a8b731e12d5a9d7fb2bd57b5b79d6ced37467ddc42b	0a21567b-14c1-4e45-ba05-9c2c86635b03	2026-12-15 10:13:42.742853+05:30	\N	2026-11-15 10:13:42.742853+05:30
fd63a21a-b1d3-4fac-bcb8-9e8d566fc50e	91c28447-9824-46ef-80c6-24ae27acbaee	211f4aa8d670f8828b73f8cc0fa94771d3db36e82dc792d2d3b8a35e5edb490e	3ab4c6ce-a6c3-4523-ae76-250b49a63a62	2026-12-15 10:13:42.913046+05:30	\N	2026-11-15 10:13:42.913046+05:30
d67f3a71-36bb-4c8d-8848-624b939ed0f1	6158010b-2859-47c9-8a8b-2f9a68e19970	779003c3428c95a0e9b9f4b07ea1031ca13238b9d3d1af7da334b34d677a9627	2dffc4e4-25a5-4c10-b82c-e180bd3a832c	2026-12-15 10:13:43.064527+05:30	\N	2026-11-15 10:13:43.064527+05:30
610df680-e807-4366-9bb2-7dd94637ff64	c71080b7-aa9f-4ca8-abbf-8190032c5004	f6c0da903ceb439b617a3792175a9a212ff758f3507dfcfd7fe19127035d30ee	a7a7fc89-45dc-4f79-88aa-edfa3565bd7c	2026-12-15 10:13:43.220784+05:30	\N	2026-11-15 10:13:43.220784+05:30
df5fdb08-b8c1-47bc-8876-106fc31cdb8c	28dd8fc5-3542-4c1f-8310-3e2355819f3b	dfea86ac22c2d96a3d95f7ed7e9973b5e9b48ae91112fea8c09ebfcb8dedd143	bef87385-f3a7-4d23-9fe6-88007ed71d8c	2026-12-15 10:13:43.374632+05:30	\N	2026-11-15 10:13:43.375689+05:30
9a7adc72-205d-41ab-8685-42163b99f31b	c3185614-5c4d-422b-9f8c-e3256d1a89eb	3a13cc551eb9f256bef545240f359ae339bf943da6b928840ee559b2f9866773	8dd6d7c2-7c80-4123-8b86-2fd79bb7a6f2	2026-12-15 10:13:43.537612+05:30	\N	2026-11-15 10:13:43.537612+05:30
465b371d-3f32-4afc-84a7-7a95fd82046e	d46883a0-f5c2-45c8-832a-e60146576fd7	082d0b221d2cd5ec8d0f3033a3d7ede4ee6605350255c762ccbaa26264254867	5487bca9-280d-44c6-9cd3-ae16be50ea8d	2026-12-15 10:13:43.705404+05:30	\N	2026-11-15 10:13:43.705404+05:30
524132c7-8194-4c76-8a06-75d2e480957c	f10701c9-c7a7-43b4-8a9c-7284a0ac0671	c1547dcc938bfaee6158f408124aebe9d28fae6bead97fac91455d6cf8863650	3279baae-ad27-4325-89d0-9a85ed3a3e11	2026-12-15 10:13:43.857883+05:30	\N	2026-11-15 10:13:43.857883+05:30
97554f7c-1135-42d8-ad7b-bc421dcd714b	55da96ea-7dcb-4e92-94c9-c31678caf1b1	c3ec090876e925afbe05818feb5a392aef8fb8b18116300b7f29844ec918f167	71171ac0-fee0-434e-92e0-1956d178c7b6	2026-12-15 10:13:44.031697+05:30	\N	2026-11-15 10:13:44.031697+05:30
338d488a-0c1d-4c21-aded-1d73fea806c0	6a2dffff-c4ef-4a1a-9f46-3929603ab9f2	b8f264a1f86f0f9242ad45eebfc64787d4f77ce164a19900ec87c454d7817293	6765229c-46ec-4dd2-83e0-b0fc3fe4c830	2026-12-15 10:13:44.198149+05:30	\N	2026-11-15 10:13:44.200671+05:30
c0b6320e-fc5f-4331-8ca1-cd33a1e89026	99b96be9-200e-4997-9013-a9b64a279738	ae7e63ba612c75817222241b011fbc9e58b3fb6211211298f785fca915d2d402	65dbf8ed-664d-4f0c-ac94-08b114645bd3	2026-12-15 10:13:44.359004+05:30	\N	2026-11-15 10:13:44.359004+05:30
469777c6-7609-462c-83d1-9b5597d750d5	40e8a082-4ff3-4b59-b6f6-80054cb6004a	dfa8c7cd2c60f0ecb42732e9154e18618a5d4a97d9e2239409143b8af3157dea	bb0d08ec-b9f5-4ee8-8c6a-35458685a949	2026-12-15 10:14:13.882945+05:30	\N	2026-11-15 10:14:13.88881+05:30
72f0b203-c33d-46f2-95f6-8937f25a770a	62bce4be-70f7-4ba6-ab46-fe6639cb7c0c	71b1aa5c2a9fb313a99a93e7e71611471279f1c718a9e7ed16e6f21718055c97	dc85eb4b-4ebd-4c8c-bd71-ba9f7496ac0d	2026-12-15 10:14:14.042678+05:30	\N	2026-11-15 10:14:14.043211+05:30
fdc3d8a7-a1fc-4d69-974a-fd7ff3bb5c98	6319caae-9617-45b4-a559-2e6cee39cce4	2f78c912fb29464b72b6782a2a6ce786d592f11db8c14bd407e377044661a8f0	bbb01151-7ac3-4eea-8c5d-81784d3fa486	2026-12-15 10:14:14.32075+05:30	\N	2026-11-15 10:14:14.32075+05:30
d1ed2a48-d82d-440c-8528-822a75a35e8a	b7140cf3-69fb-4a48-9a42-0efe42e3bc58	88569018893a206065d817694f73e306a2ee79e4818bbc827ee91e7e410e3047	4c46860a-8bf3-414b-955a-552076027892	2026-12-15 10:14:14.490708+05:30	\N	2026-11-15 10:14:14.490708+05:30
e30e3c87-76ba-4cad-9b11-3587adf9c248	b7140cf3-69fb-4a48-9a42-0efe42e3bc58	4b7238dd912d1aee4d757cc031a3287a7c8f862044d2110ff137d504bde0f7ef	e9c3e60c-5c9f-495e-ac54-730aaf506e86	2026-12-15 10:14:14.64382+05:30	\N	2026-11-15 10:14:14.64382+05:30
a155d12f-140c-4fa9-bc50-5aa60480ac4b	c205dc72-02a1-43d9-b1e4-47037ca44d57	aa3b5be5785fa7ae5a558b0fe94b8c0d37caea6cdd5f78223b1578b70ec6b83e	c7359623-5378-4432-9090-440475e3eaa0	2026-12-15 10:14:14.943744+05:30	\N	2026-11-15 10:14:14.943744+05:30
2fcd3ece-a306-454a-a647-b67fab4122e0	fca802ad-5f4d-4bfa-a338-f37cfa951936	8a5b9b8aa551d3d30f650d37e86b835cefe6cca411963096980c25c6ceaf6f00	d0ef802e-b193-465b-9565-8e958fe5d47a	2026-12-15 10:14:15.183781+05:30	\N	2026-11-15 10:14:15.184996+05:30
bd2dfc85-946c-4db5-92df-f099a07b06aa	45b303de-74ac-4594-b56b-42762430554f	9b166313753333c282892fe97761a7805737709c873d87c31b800bc8be46dc9b	13cb70e0-3e7d-4b6b-b7db-4eb4a6e3cdd2	2026-12-15 10:14:15.765832+05:30	\N	2026-11-15 10:14:15.765832+05:30
53c94d39-f63c-4a93-a5c0-251aae6cb09b	97ad8c73-e604-47e6-9fea-bab1de86fe6a	9c86e0dbebd4e339c61a140a77f5348bb5b8ae865323889f103732428c7aaca1	872c1b84-7e5f-40f4-92a7-aa5a5dadc8e8	2026-12-15 10:14:16.166833+05:30	2026-11-15 10:14:16.198376+05:30	2026-11-15 10:14:16.17285+05:30
a0e8762d-d8dc-4d92-a10a-accf1f23fb58	97ad8c73-e604-47e6-9fea-bab1de86fe6a	4d36d6658fb534cd36d368b60e5fee9696c4c2def42c6d2cf195257ffa575056	872c1b84-7e5f-40f4-92a7-aa5a5dadc8e8	2026-12-15 10:14:16.200371+05:30	2026-11-15 10:14:16.223322+05:30	2026-11-15 10:14:16.204388+05:30
055d9762-87c4-45e8-9c04-58afc20f9f2b	76fcd6c5-d97b-4151-9b42-5bf45166238e	e901c7e640b010a037e005b3e1956757981d4f70c476d5114145efc892fb6a45	64a5706a-4430-4a9a-beae-ebe0de770d58	2026-12-15 10:14:16.406224+05:30	2026-11-15 10:14:16.415083+05:30	2026-11-15 10:14:16.406224+05:30
0716ab57-bb5b-4247-adb0-ec712428b165	4912744b-7641-494c-98b8-0a806517f294	20d2e61f5c1051b7694fd0c861326b3563c1209e5a13bb730627f42bf7247124	9fc1b267-4b1d-4d9f-9b90-f4d2b88712e3	2026-12-15 10:14:16.596583+05:30	2026-11-15 10:14:17.045484+05:30	2026-11-15 10:14:16.596583+05:30
35c69d6a-f849-4696-a92a-245f5f601931	4912744b-7641-494c-98b8-0a806517f294	840a104fac0abc72c46d30a63944e290ba76397a649b3b176202b69fc80a7616	4473800c-2a07-4b15-943f-00f83faba373	2026-12-15 10:14:17.322279+05:30	\N	2026-11-15 10:14:17.322279+05:30
242f67cc-05fe-4c8b-ac01-ee674f13716f	cc06d8b8-de68-4232-95da-1393dd016a21	d10a74fde84a6abea3e0cfbedf3517a01bdcc1cd7fc385e1904a0240574aeb8f	7e238289-8a7f-47ce-96f5-a325f3c095a0	2026-12-15 10:14:17.468204+05:30	\N	2026-11-15 10:14:17.468204+05:30
4398b4ae-1b66-46d4-b0fb-c73b560068ba	966bc9e7-f2b0-415c-bcc2-2a33d6f3933e	819b3117ce6ed63832d146f8c879b036ed9782dbb9d4417c3236914a52d618ba	2406820e-52cd-44df-818d-9bcc5260a296	2026-12-15 10:14:17.615005+05:30	\N	2026-11-15 10:14:17.615005+05:30
489a7e21-bec5-415c-b9ab-3af1f922229b	920fea38-9162-452d-a4c5-d84e99e04469	e7e3774da048b98e4d97a98458d8cfb784e6a54799487b78477168fb9a693ee4	bdd68bb7-5d25-4f9f-929a-6b302d456f8f	2026-12-15 10:14:17.771745+05:30	\N	2026-11-15 10:14:17.771745+05:30
163832f1-30ba-49ac-b7c6-ecec9968742c	64ad93c0-b465-47dc-b5c1-77c32a691aa6	16264c1e3b81c0a5ff28c0cae564a61692e071d3bcddc71c9904b1863b4a51d7	7927fc25-938b-4a77-80fd-58173d0d14ce	2026-12-15 10:14:17.968097+05:30	\N	2026-11-15 10:14:17.975122+05:30
9b224e35-c3fc-4b05-b85d-7a269961f476	a7234ea4-0c80-4b89-99e3-65a81d7ba785	e82e9c6aebce3b5a48c0904d4497ace711fed383dff207b535e00ded14710bdc	b226d7e5-d747-4a7b-9087-a3f7a5baa6f3	2026-12-15 10:14:18.148482+05:30	\N	2026-11-15 10:14:18.148482+05:30
3e8e3587-5459-4043-89b6-b1e5143408a2	8ad8cd75-f852-4ac4-b829-aaed729838a9	3f3984616700bedfd3b8fca39025dca9f94ce22c8c36842e96654e77cb810f62	ae9fdae7-ef96-42e8-9ba5-bd32a17ed93c	2026-12-15 10:14:18.317526+05:30	\N	2026-11-15 10:14:18.317526+05:30
31e898a1-fc52-4b47-a424-25408aab23cc	67ac7719-e28e-425d-a2a3-d90ac1ddb5fa	b91268b687a05728e43ff479c16701dd98d9db80bae7a86323d0469069ddfb0a	b5032385-1a53-4421-adf5-81c86259a6fc	2026-12-15 10:14:18.471256+05:30	\N	2026-11-15 10:14:18.471256+05:30
cdfc0fd5-f59d-4a58-99b2-918b44e8ee7d	a0d1c040-8d97-437c-867f-014b13ce7f37	59d1884f4470b69b48a67cfd23aa85b1cf87f30e4e7c9faa9fa6fb820e231925	d2216fe8-0af3-4894-a2e6-aad3c789ebbc	2026-12-15 10:14:18.621882+05:30	\N	2026-11-15 10:14:18.621882+05:30
a80cd284-c7a1-4661-af58-cc87c101d70f	80c52a2a-e213-4d3c-9ec4-7914c6176c3e	6937fbcdb71cc53120f74b0dc2dc0ad6107c81ce2355316c3d3a56c7afea1dd4	88d4f3b4-b367-42ff-a36e-409bf60435f1	2026-12-15 10:14:18.775751+05:30	\N	2026-11-15 10:14:18.775751+05:30
b25c7363-2e48-445b-b356-d0407f0af899	fe8a3a1f-9206-4b8e-92ee-28f5a466e965	b80ea29d2ad2990168867bdc4dc12338fe2ad623de38d17d645a516d961bb2b9	cc451da0-e041-4845-9692-5691dc48112b	2026-12-15 10:14:18.943414+05:30	\N	2026-11-15 10:14:18.943758+05:30
d53d7a27-d325-487c-84f4-dc9cdef8d686	5a298b8f-5343-456e-bf6d-7c2d50f5dbf7	61c9f000199553384883fe654b620e4056b3cc9309a265f11e1459c18b251846	cf7a327c-2716-4ef8-84a3-55fa745fe2f3	2026-12-15 10:14:44.492848+05:30	\N	2026-11-15 10:14:44.492848+05:30
83dafec6-2742-47cf-aa8f-0cbc998fa61a	efcfe59c-f6dd-4cae-b3e9-c7d1b7df84e1	0643c6d04776cd25f260aee229776a31323ce2323976f36ccd839d9e8cd44e8c	5df2bd57-832d-492b-bc03-c7cf02431fd4	2026-12-15 10:14:44.639067+05:30	\N	2026-11-15 10:14:44.6401+05:30
f164b308-3d2e-4f66-8309-d594a37ffcdf	1b11680b-8a45-493e-bd22-31b3e23efb9e	0ccc07b52061209d91c4a2716299e175182bb5b9978734b10c1e478e2295a4f6	84de205d-17f9-4401-b4d2-d62274595b75	2026-12-15 10:14:44.772514+05:30	\N	2026-11-15 10:14:44.772514+05:30
052f2db4-e683-43d6-b148-8288b5bda66a	f22fa7ec-1992-442a-8a0b-db3ce7aaa607	e0e4f37bd4e38ca2742fb88c76c026f2b2b7ca9cc78356204ce4c737ef967dc3	059733b8-f1d2-417a-8e3a-d919e4b1097d	2026-12-15 10:14:44.92473+05:30	\N	2026-11-15 10:14:44.92473+05:30
a513a04b-6c97-4bbb-956e-79a2eead6b89	f22fa7ec-1992-442a-8a0b-db3ce7aaa607	82208facaa598e06f1608aeeaf3062630db637afd45d69f9fdf5b08d8deae69c	2a84e8d2-9858-41d8-b608-057115cea1ca	2026-12-15 10:14:45.059974+05:30	\N	2026-11-15 10:14:45.059974+05:30
ca5bd99a-3956-4042-9474-13b18d32c76f	063b07b3-4ee8-42f6-a7fe-2e1044f43c03	c6369c85a4755bca291592a1a610eed5c083e42615ab30eea5d01095c1a7733d	7b9dcc34-62bc-4ac6-8e74-6edad1c1b8dc	2026-12-15 10:14:45.439392+05:30	\N	2026-11-15 10:14:45.439392+05:30
53ae6c1f-4809-4134-9b27-be85816a3b57	c519c08f-adfe-4301-9411-99fa4e752784	8cf5371727ab888e5ba72ebe2bc8c08162718d222d9ef4316abd062f48fb8520	acfeb3b4-7f85-4b58-88c7-aa8924acdf75	2026-12-15 10:14:45.609184+05:30	\N	2026-11-15 10:14:45.614851+05:30
de1a6d4a-d8cf-42ee-a248-cded77a3f81a	60224df6-72b3-4297-82bc-a70eb9b8dfec	945cf9152322325596cef54df2e3ffff523cf33d8e9e598cd563ab4d6fbda3fd	f1362927-a76a-466d-9be4-c160dad6f9ff	2026-12-15 10:14:46.172169+05:30	\N	2026-11-15 10:14:46.172169+05:30
bbfa0ab4-077a-4270-b358-ae2019b99c88	8b41741b-ae73-48a1-b2f6-099c92184111	690e672cb39dc2b1e245726ef3582d0ec2dd2e4a68782176ea316e23421a971d	8de047b6-d0b3-4563-8810-a64fe35504eb	2026-12-15 10:14:46.555463+05:30	2026-11-15 10:14:46.57937+05:30	2026-11-15 10:14:46.555463+05:30
e0ef3872-3ac9-4380-b889-8a4643894a4f	8b41741b-ae73-48a1-b2f6-099c92184111	24a3518c93891512cc3df1ada0fff0fc89bf758bdbe49739b8fb322083da4c41	8de047b6-d0b3-4563-8810-a64fe35504eb	2026-12-15 10:14:46.582975+05:30	2026-11-15 10:14:46.603003+05:30	2026-11-15 10:14:46.582975+05:30
c8bcb5b9-c194-4d0f-9e97-5b3ce9f167cb	3b2098d7-56e6-48d1-ab55-aad04c1662b9	c9c43be49a5a49169b4e57b66475691b14526a869c4c1c9cd52c7765f1efc933	b5468746-5795-402f-a282-b4e8031b663b	2026-12-15 10:14:46.771579+05:30	2026-11-15 10:14:46.793109+05:30	2026-11-15 10:14:46.771579+05:30
35140c07-b102-4b67-9d8a-5e364e2d17ac	b9d3f611-9539-4205-b471-14201c5f5a9d	db8b582c46eb3c03182696803efa2021cf9f2dea0b9909ecf8a30cc59fba60b4	9b05972f-14b1-4fdb-9997-5b94c486746c	2026-12-15 10:14:46.95519+05:30	2026-11-15 10:14:47.395336+05:30	2026-11-15 10:14:46.95519+05:30
a89ca433-fd4c-4f2b-a6af-f26fb2cc80cd	b9d3f611-9539-4205-b471-14201c5f5a9d	c8aa1ed3cc0c362aaa1faaff83116e2e6fd41ffa7bb9fb8ea239fe23f864255f	9e64a078-8968-4f65-aa44-a79a84732bb6	2026-12-15 10:14:47.670372+05:30	\N	2026-11-15 10:14:47.670372+05:30
53ec4932-af20-42bb-bde6-5f0767fcb9ab	a76f062f-1437-4009-82e0-f8027e4210ac	2d961380adf1d4be6b248c4f769d31e38c2014e7797dc2736131f3c2ab3d0e6f	128fafe1-85da-4cce-a2bd-e231ab765005	2026-12-15 10:14:47.826161+05:30	\N	2026-11-15 10:14:47.826161+05:30
c8165fb6-7e3e-489f-bd5c-5d49194205af	7d429a53-084f-4278-a9fa-6bf97f9b2242	5893402d9df1f18626306700d2b74b44e1bb5e53e2d2caa66b2b76b5f4f597ab	82543150-564b-4e78-a86c-325a6f94a54d	2026-12-15 10:14:47.980522+05:30	\N	2026-11-15 10:14:47.980522+05:30
289807de-b489-4398-81ee-7b11c4c804c5	43c8ed99-30b6-419a-94e3-7255012aafa4	8dec5d8e28c8e7987ec059e8675cc29d31b850b2326b569166120e1318e0fbd4	5f23ef32-0189-4cbd-90de-6d2ccde7e93e	2026-12-15 10:14:48.145619+05:30	\N	2026-11-15 10:14:48.146617+05:30
f0849ab0-4915-4f71-a192-6bd68b5bb394	fb188179-7c4d-4b80-8f88-345042174c60	2a487cc6c7ac789462a6edf9d3ac5c926dae9510e0e8138171fd1228b5e14d3f	a85a783d-d2d9-474f-b56b-f795e38f5ee3	2026-12-15 10:14:48.355372+05:30	\N	2026-11-15 10:14:48.357383+05:30
25fa4f17-ce7b-4ae2-9b41-b449821e84f7	45f8232a-f992-49fc-b8e0-277b1a2dec21	aaa864f2ed8bb27e33900ede349a9406fcc08a9f2dde78c808bed2de4560b8d7	4cc22615-12d1-4abd-87cc-c39b6c0ffaea	2026-12-15 10:14:48.58567+05:30	\N	2026-11-15 10:14:48.587681+05:30
92182094-3dbc-4867-a547-09aa5261ad23	ef9df25b-9a86-4559-9f42-48b410a4fc49	53fa3d3865918ef6e17d155ce0ad328db71ba7901a6b3cc83b6281deafff262c	eed83470-3c15-4235-b240-58436a2cfdf1	2026-12-15 10:14:48.771314+05:30	\N	2026-11-15 10:14:48.771314+05:30
8cf48380-d799-4f9b-b8df-de7741760582	d493499a-43ad-411d-a0e6-fefa6fb25f83	723536d4db92b91b0758c89f07c7c728a42cfbbcb32fcde462b9aa642e0cbe54	79652d29-a9f5-47de-aa83-551993d6acd8	2026-12-15 10:14:48.967484+05:30	\N	2026-11-15 10:14:48.967484+05:30
5224ac98-a66c-4bb4-be79-86d91dd0e977	33923beb-3ae1-4789-b035-5b2b146c63e9	472aab610f3a1bda2e65d6affb8d40f4a73284b7ca37bf66bb661a28a77f3d5e	684dba1c-e43e-425d-8f5c-03b916526d37	2026-12-15 10:14:49.169059+05:30	\N	2026-11-15 10:14:49.170193+05:30
a2b0153f-a0a7-4cd5-b850-57d6f85c66e5	e5758ca4-3f39-40c9-9ce1-f3db23e0312c	a9945a599c3082db372770ede878345ff2adbb734a5578cb45a9372eb8fc58dd	6d68dc65-95a2-4d67-872f-9944d6d80aeb	2026-12-15 10:14:49.353221+05:30	\N	2026-11-15 10:14:49.353221+05:30
dc011796-11bd-4328-95bf-b3d9ac277880	e849a903-d79e-4a1f-b969-17d1d0ffd0a5	2b740cf2de7f494990b8ee326b7de478587dd704828c419da705b584cd938c09	ca60c535-81cd-4976-a810-46fdc625e0f0	2026-12-15 10:14:49.529188+05:30	\N	2026-11-15 10:14:49.529188+05:30
d614b107-8e53-44b9-8aef-c1bce7810a6e	34e7a7da-b44b-4467-a7bd-0d222f434eac	a742b52955939d71aaabc7faa7b1fa566cd1d4820dff67ac57d4626a0c464013	26a11671-8c66-4d86-adb2-4ba763610508	2026-12-15 10:29:46.968235+05:30	\N	2026-11-15 10:29:46.968235+05:30
4b0ef1d6-79e6-472b-8f32-5903468ea4f3	01db5886-49f4-47f0-8a02-c7096378fbc9	38577cf5a7ae0065acc4a936f7be8fc9caea22287b6cd29ca921fb95c4485fde	f3bdb320-7fe2-4412-9cf6-3bc868877405	2026-12-15 10:29:47.110044+05:30	\N	2026-11-15 10:29:47.110044+05:30
d605a1fb-09d8-4104-b1cf-dc0adb02ae7b	a3b659d0-f06c-44ac-a900-c2c19d52adce	bdfb9e52d4f27c576c8749cd1dda6ae0ce227d5f4b902955a1cf656e8fce8fe8	113b11e7-4041-4ec4-9b7e-67d44f1bcb1c	2026-12-15 10:29:47.348173+05:30	\N	2026-11-15 10:29:47.348173+05:30
269fe8ab-3b4c-4743-9885-c4687e6867e2	c0af8f1f-626c-4c92-80b1-068ee1985b63	f7cee8214477985ce278925c1b35948a83e9127bdf7f425f1ede0a3064c55ea4	49f53af0-1491-4315-838d-d15a845fd11c	2026-12-15 10:29:47.510561+05:30	\N	2026-11-15 10:29:47.510561+05:30
c1dc9057-dc2c-491e-9a20-148f066b531d	c0af8f1f-626c-4c92-80b1-068ee1985b63	50fbcb95c1fb3710b6375d396ab5b9c87c5abbb9426394d34e3fc30889166fab	0f6e8301-307a-460d-9463-68e3c79566fb	2026-12-15 10:29:47.648034+05:30	\N	2026-11-15 10:29:47.648034+05:30
164a4582-0ee8-4091-a0ad-1b3eb467028f	8403286e-0972-4b60-a972-b0f490238d65	c020c9871cc8b8ace7053c22192493fc9254f4999b2e8bf751848d66a3f81958	a1cbf3fb-3fc8-45ec-b444-075ba3bf0c04	2026-12-15 10:29:47.930713+05:30	\N	2026-11-15 10:29:47.930713+05:30
e3c51838-445f-4f68-bdbf-e30368868c69	2e8f579e-cf82-4bb6-b3b3-8cd7373c9783	a820bee90339a958ee5acaf4fe7e54d36926cc7da2b094c0065d0bca75168839	3ed32419-7cf5-4c51-8fb2-70aae72c3eb8	2026-12-15 10:29:48.106777+05:30	\N	2026-11-15 10:29:48.108527+05:30
59ab2933-3549-4646-84fd-0f34455a2b5c	b090c6a9-cc45-424c-85cd-23f623fd7f08	0a7e3d88b493c52fbbb656c60d1336b1fbce53041701cb58ced8f109084bf250	80030d30-b94e-45cf-ad74-b6db976946f6	2026-12-15 10:29:48.873989+05:30	\N	2026-11-15 10:29:48.880087+05:30
515234bc-0725-49a0-bbe7-b0bf2310cc64	91b328b2-e6f1-4d2e-a00d-794b26a45808	eadd8afb233b2fe2412b7946382dce1d5ea247b6a127b98bf26c21913dedf374	6e2bd267-2dde-4725-a84a-9dac3a75cc10	2026-12-15 10:29:49.357452+05:30	2026-11-15 10:29:49.384353+05:30	2026-11-15 10:29:49.357452+05:30
096cb23a-dcbd-4f24-8c7f-35900472425e	91b328b2-e6f1-4d2e-a00d-794b26a45808	81b3ebbcfbc6303cc39cfc9a3b2f8daf249f89a23a223d35946296bd4227e021	6e2bd267-2dde-4725-a84a-9dac3a75cc10	2026-12-15 10:29:49.398039+05:30	2026-11-15 10:29:49.419572+05:30	2026-11-15 10:29:49.398898+05:30
1a44353d-7a71-4e23-924f-c0099836ab2b	4c294885-a375-48f9-96ec-6538f2032bff	2e2894e5f2a91e96ebc42afdb7a1f664a1e667ccafd09bf5aa889cfccdc29e10	8dd1836d-7a4b-4dae-a214-0cb8d3577b99	2026-12-15 10:29:49.646741+05:30	2026-11-15 10:29:49.673144+05:30	2026-11-15 10:29:49.646741+05:30
b3617ffa-3c65-44b5-9dc2-3c9c4892032b	0a2bae51-cb61-4140-97bf-eef598e3cceb	606884e94b15a74208e4e7ea1a45f1a5867c16836496bebef09d2daf378c84a4	6b1a25ad-fe14-4a10-beb2-6e8d5c1b1269	2026-12-15 10:29:49.908231+05:30	2026-11-15 10:29:50.513853+05:30	2026-11-15 10:29:49.90923+05:30
43d18ab3-ec46-4c5c-8bfb-ff6ab1c7986a	0a2bae51-cb61-4140-97bf-eef598e3cceb	08e3b90111a6c307794e4b3e518abcadeeea9f8bfa49589dc24b24391a68d827	6ca9f2e9-050e-4134-ad2c-9c97413bb3f5	2026-12-15 10:29:50.920054+05:30	\N	2026-11-15 10:29:50.922061+05:30
480cd081-1bab-44ae-b703-be685a6e1b31	48fa2700-435b-44eb-8d66-28ea8fa26e29	f6e52b26167f2505e04777a0561cc407246151948f546e1469f960d4930aecdc	a9e05135-4f28-48be-9241-2f1dbc0bdd1d	2026-12-15 10:29:51.133666+05:30	\N	2026-11-15 10:29:51.133666+05:30
b6e98377-98d8-4685-8c8d-57ba52ca7ffe	ec3951c4-6668-4f2a-bef8-caff51a3ed87	50db0c9fa026d155a3063b23702fad03083e6f04a4c0099586f41ec1367a87ab	984146e8-005a-46c3-acb4-a35c969ccffe	2026-12-15 10:29:51.349949+05:30	\N	2026-11-15 10:29:51.353269+05:30
311ac659-b1ba-4b24-96b8-19b0b24fffa8	20d0f6a2-b9f5-4e47-ae60-346a03befcde	dc739932f54de0cf2c46d258df37c4e9141f8f475941cc69aaaad8e2f596f527	418495c4-bcf1-4990-bd88-6da1b04b12e8	2026-12-15 10:29:51.573233+05:30	\N	2026-11-15 10:29:51.573233+05:30
47be2b5d-7fc5-48a3-adb7-e82a3576aea8	41bf8470-0bbd-4e5a-9b27-83d211f6994d	71590f374fa679085be4caf79fbc560caefc913bb685b506e787cfc75608ef61	a185f39b-ca8c-4c6b-aed1-e608135b10d9	2026-12-15 10:29:51.806848+05:30	\N	2026-11-15 10:29:51.807846+05:30
5eea2716-daeb-4ddb-9792-dafd1fc2fded	554c125e-f63f-4a54-abc2-6a7728c7d929	91afb3b8a1609f4120d6f21642066c3bd567f7f11c272b42026646bda5d68168	14ff4e18-eb23-46f5-8653-5822cdd9a93f	2026-12-15 10:29:51.997077+05:30	\N	2026-11-15 10:29:51.997077+05:30
634fd834-4aea-4ccf-b7d4-151c4eae79ae	e7460005-4dfe-4f26-921d-021788b0d43d	b5c79cda15ee115bd597ee35d16daa08764e8b3aa4ba2757351d09ba2456ce60	5d593153-beb6-4017-9ff9-cdb0959ddbcf	2026-12-15 10:29:52.185014+05:30	\N	2026-11-15 10:29:52.185014+05:30
d00f983a-a27b-4136-95f6-75c9d281dd17	59ba0e40-9fda-48f8-bb8a-1ef48c3187e5	e0fd4ca4b3a4ee8d00b78a61ab0fc54e9655f16b7de3d904c7a4ace362ee16f8	9c9d609e-5b09-45a5-bb07-aae3c51ccf15	2026-12-15 10:29:52.445557+05:30	\N	2026-11-15 10:29:52.447087+05:30
dfef71b9-abc1-464c-9ac4-be925e8dd23c	98b4e5e4-54da-442b-841a-df54c43ef188	6c028865d771985bcd082e0229e9ecb4e08d811b7623eae25ff8c3facd2332d2	f88d554f-2357-4480-8fd7-7f2616fbc663	2026-12-15 10:29:52.649655+05:30	\N	2026-11-15 10:29:52.650205+05:30
7b981562-0188-4a4b-834a-f78fcfa1ec43	dd002523-ad7b-409d-ae65-a5e9eed41c53	38697082f4ac6cc7871d386710308e21d3d7224c3eaaa01f7edbd807624f6fb2	edec3abd-82dc-481f-9d7b-cd34b81cd89f	2026-12-15 10:29:52.921242+05:30	\N	2026-11-15 10:29:52.923102+05:30
60e1da8d-4ca9-46d4-9dbf-a3e86fe5f2b9	35fd05a8-03a7-46ad-8439-02e918dfcbd8	312075f0657e1f9fc21e6a07f578731de8a7e133f1b43c54bd7f3caa47d47268	feb40856-0ad6-4f43-93d1-a849b295a8ea	2026-12-15 10:29:53.171496+05:30	\N	2026-11-15 10:29:53.175166+05:30
\.


--
-- Data for Name: reviews; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.reviews (id, product_id, customer_id, rating, comment, is_visible, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: stitch_admin
--

COPY public.users (id, email, password_hash, full_name, phone, role, is_active, created_at, updated_at) FROM stdin;
0bf76e78-4b36-450f-aebb-87873bf2636a	admin@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$ZfqiJj52Cvcrucn3xppoGw$vRTQgKHzQ5k20Wbzh5OM6WDUjSyKqKVjOl9Ky+VfzJY	Master Admin	\N	admin	t	2026-11-15 09:53:11.81367+05:30	2026-11-15 09:53:11.81367+05:30
c3cd4b05-fef0-48ad-ada3-5a95d8e66bf5	cust_a47f9f94@example.com	$argon2id$v=19$m=65536,t=3,p=4$wuz6VKgm8yKY2/8247Hwyg$88L95lnntZnwch5XbKf2qIYDr/AlSLhPgaMDtDS04aM	Test Customer	+919876543210	customer	t	2026-11-15 09:54:19.708398+05:30	2026-11-15 09:54:19.708398+05:30
141cc95f-4668-442f-8cae-f9160cc3128f	hashcheck_c5493f1d@example.com	$argon2id$v=19$m=65536,t=3,p=4$NxWSw4yGECySn5fGpCmqQw$YjrtUD76b9qnwT16/VPprc9ex489n53Am1GVVCisJ+I	Hash Checker	\N	customer	t	2026-11-15 09:54:19.827387+05:30	2026-11-15 09:54:19.827387+05:30
1e5439f7-7052-4e3f-ac0a-ba14110af213	dup_daf03d70@example.com	$argon2id$v=19$m=65536,t=3,p=4$aGhSimsEaSetagZYQknm2Q$UI1RpQkf2UA/g7PlJgWjP3mDPXL3gyxhnKpFRd4ucSc	Duplicate User	\N	customer	t	2026-11-15 09:54:19.945315+05:30	2026-11-15 09:54:19.945315+05:30
ff9230c9-e08a-481c-81a5-c3e89ad73c51	login_cust_63ba0845@example.com	$argon2id$v=19$m=65536,t=3,p=4$MPHgIcq1et2eAIExWG9C4g$ZMUohN7pvqjIPNHifBzmYXAbLtRZ1xg1ae0yV1JkW1I	Customer Login Test	\N	customer	t	2026-11-15 09:54:20.080559+05:30	2026-11-15 09:54:20.080559+05:30
8200bc2c-0b13-4f95-99f2-89bcce887bed	admin_faa21f12@example.com	$argon2id$v=19$m=65536,t=3,p=4$03/xgOaNnluZNMk3z18rUQ$FzoayVpgY/ZhtqUjwnou+rsLrhX57hTNjN3CXohMWm8	Admin User	\N	admin	t	2026-11-15 09:54:20.311796+05:30	2026-11-15 09:54:20.311796+05:30
2093d1cc-0005-475e-ad00-899ef27c0048	existing_4aeedd84@example.com	$argon2id$v=19$m=65536,t=3,p=4$mH0hTv6cX67mBOBjz889VQ$K+74Xn92jKTEUbhgZtAq/ysA/84Wno5a8AVHPU5AD48	Existing	\N	customer	t	2026-11-15 09:54:20.55977+05:30	2026-11-15 09:54:20.55977+05:30
b371f44f-f108-4e96-a5cb-07efa27457f6	inactive_8d6d0afc@example.com	$argon2id$v=19$m=65536,t=3,p=4$5NHM4zhXumiMeMlE/UHFbQ$TEoxwFL6revjkrHOpQpGslNnxgxR6jS+ZJ/iCkjppb0	Inactive User	\N	customer	f	2026-11-15 09:54:20.790862+05:30	2026-11-15 09:54:20.790862+05:30
c8393000-ef90-4345-a676-5599c9517617	cust_block_174aa803@example.com	$argon2id$v=19$m=65536,t=3,p=4$+kbpvblUI2lxEpA9fuu89g$hsrSdGpIx84DKhi0a2Q495sYFUrzXketbpKIUrHCbzw	Blocked Customer	\N	customer	t	2026-11-15 09:54:21.041001+05:30	2026-11-15 09:54:21.041001+05:30
c276f22d-ee28-4bd2-a6b2-670df33ea743	admin_allow_f1d0ff78@example.com	$argon2id$v=19$m=65536,t=3,p=4$sc4Gt08vlo6xAVL7MjD/mg$8k+iYMf2/qICbGpd0E4j4ZFGhcYO/2+PbdXsS7MZSVI	Allowed Admin	\N	admin	t	2026-11-15 09:54:21.173885+05:30	2026-11-15 09:54:21.173885+05:30
9600f15f-da63-4638-a3e2-43c865b62b19	reuse_cfab485f@example.com	$argon2id$v=19$m=65536,t=3,p=4$FS4bSTqOW80hJyBQSBXT9w$xSdrU2+hAl+ViT+43g4gwkd1VM00toLr5tsrExFsw5Q	Reuse Test	\N	customer	t	2026-11-15 09:54:21.317732+05:30	2026-11-15 09:54:21.317732+05:30
dd368621-0708-4c22-a883-7bd81b093300	logout_53896494@example.com	$argon2id$v=19$m=65536,t=3,p=4$ZnL1e+cn4OD/dopOH4t5og$ygluVl1M8SlbpZ/wmFXKH3ygtA5/8P0DDwxW/WcEGYM	Logout Test	\N	customer	t	2026-11-15 09:54:21.488939+05:30	2026-11-15 09:54:21.488939+05:30
20ae0285-54bd-4578-9f36-ccf865d958d4	chg_pwd_888e776b@example.com	$argon2id$v=19$m=65536,t=3,p=4$EESrZk61XTrajwpz7FwcPg$xgEE4u91mKywcXxdzQAsaGFt2mLEa9IPT1fiKStWbY8	Change Password Test	\N	customer	t	2026-11-15 09:54:21.696694+05:30	2026-11-15 09:54:22.059541+05:30
bdeb367b-b0f6-403a-b878-defa8623fdb8	rate_0_24fea2@example.com	$argon2id$v=19$m=65536,t=3,p=4$nYAKRDVTYeMsa8FxZRpzmw$AClGGHL8zU7XrgKXnHltR2eClI2JXeDDAWHJULeqtvw	Rate Limit Test	\N	customer	t	2026-11-15 09:54:22.428677+05:30	2026-11-15 09:54:22.428677+05:30
72fcf157-4076-4f4d-a3e6-58976eb9b419	rate_1_2cdb91@example.com	$argon2id$v=19$m=65536,t=3,p=4$L/pCIaP+FFLY07LTke7M+g$Tk7jmKkQ9VSsuj6RRliz4LpnVxxbS12aBTzRw/3Y9n8	Rate Limit Test	\N	customer	t	2026-11-15 09:54:22.557046+05:30	2026-11-15 09:54:22.557046+05:30
0d0eb42d-bc0b-4f65-91da-66edb48eca04	rate_2_227c9e@example.com	$argon2id$v=19$m=65536,t=3,p=4$ocebl6sg7M13/qnFawyO+Q$/9qnT21lJFtz4H8KiEzC9ez7KySndmcCXQSa435EIcs	Rate Limit Test	\N	customer	t	2026-11-15 09:54:22.673657+05:30	2026-11-15 09:54:22.673657+05:30
5004e098-b897-48e8-8cc7-009cf9ca19c6	rate_3_bfbdb9@example.com	$argon2id$v=19$m=65536,t=3,p=4$laHw3VW4ubmbNTLgK0+AjQ$5N9x812RUm4gs9Jappzd4SfB+t3RJ4urYI7K8duzlD8	Rate Limit Test	\N	customer	t	2026-11-15 09:54:22.806705+05:30	2026-11-15 09:54:22.806705+05:30
26336fd6-896f-4d4c-95a8-444b161ca10f	rate_4_48713b@example.com	$argon2id$v=19$m=65536,t=3,p=4$4RQfaJWIfiV01wddzTgldw$Shm57nEXAP6APxX3+M7GAfD0HSYoj7XKdCVahbOkWO8	Rate Limit Test	\N	customer	t	2026-11-15 09:54:22.924198+05:30	2026-11-15 09:54:22.924198+05:30
3a4d1c3a-6a0e-4acf-82e1-f0aeeef41d94	rate_5_bf9481@example.com	$argon2id$v=19$m=65536,t=3,p=4$EukJ5GttY6QnIe27cJw2sw$lsb1BdGxDi06uDdv14wix8QAdF0U7ixCZPU7GbZ6SbQ	Rate Limit Test	\N	customer	t	2026-11-15 09:54:23.052764+05:30	2026-11-15 09:54:23.052764+05:30
93ae36a8-da23-4d91-8be1-ea7c6e50e050	rate_6_3fd03a@example.com	$argon2id$v=19$m=65536,t=3,p=4$BY6MtNGfJSn736KUoq53Dg$0S9jj46+O3YKfRw34HWwDxoZNXi7YdnIU4yXwaLKTHs	Rate Limit Test	\N	customer	t	2026-11-15 09:54:23.17565+05:30	2026-11-15 09:54:23.17565+05:30
04460803-db30-445f-89d7-cbe4784f3dc1	rate_7_a2e400@example.com	$argon2id$v=19$m=65536,t=3,p=4$+cBTw9WV5dDeMb0mN3+eUA$bAqdMxiodoC8drMKgm+ddCLQ4pjyROm8VY/MwjL2jsM	Rate Limit Test	\N	customer	t	2026-11-15 09:54:23.290118+05:30	2026-11-15 09:54:23.290118+05:30
ad29a603-ab28-4f63-aa1a-67a1be05506e	rate_8_9af8be@example.com	$argon2id$v=19$m=65536,t=3,p=4$YDjHcnTxTou9rDtL6avJMQ$OjA6pP++EV99sERbMzch+ZfmmXGXIWKpAMigBbA3Wm4	Rate Limit Test	\N	customer	t	2026-11-15 09:54:23.423229+05:30	2026-11-15 09:54:23.423229+05:30
f8d89d4a-b1b3-44dc-9822-2fbbb464dc2d	rate_9_d3e27e@example.com	$argon2id$v=19$m=65536,t=3,p=4$b5R5iB7yPyTDpJUP9QFBLg$WWHfi/6sa59OSxf9OZ3f5+pIZiRTaZXIjINUWHU3Ec8	Rate Limit Test	\N	customer	t	2026-11-15 09:54:23.541826+05:30	2026-11-15 09:54:23.541826+05:30
6873d825-618e-4d6e-8bcd-34872df28213	cust_326dbe2b@example.com	$argon2id$v=19$m=65536,t=3,p=4$0tmlSDdlJCzJJzvw2A0k/w$jplnzsoViUKxE5kRrzJgYIxkFDDOXXryaNMtNZfONTU	Test Customer	+919876543210	customer	t	2026-11-15 10:00:11.586296+05:30	2026-11-15 10:00:11.586296+05:30
550b4021-def8-4016-9d46-0f1e3e5f6aed	hashcheck_888a492c@example.com	$argon2id$v=19$m=65536,t=3,p=4$hwJURX66yz/fEdtSAnZvYw$vuaiGUznKj7z3xvQeDMZcb99B7eKLRUCNQJPI124u+k	Hash Checker	\N	customer	t	2026-11-15 10:00:11.731881+05:30	2026-11-15 10:00:11.731881+05:30
bcd95194-4ca9-4512-b1b1-def74138fed4	dup_33559801@example.com	$argon2id$v=19$m=65536,t=3,p=4$rBGgkL6Mg0qJ2qCpyg1HRw$ytMXWADyhOqAR6UfjPP6KhmJBlmPuwGuQizje9HRXhI	Duplicate User	\N	customer	t	2026-11-15 10:00:11.904272+05:30	2026-11-15 10:00:11.904272+05:30
502e9a1e-0b01-4baa-af15-6e2e1fa3d2f9	login_cust_e4095bb6@example.com	$argon2id$v=19$m=65536,t=3,p=4$xl5jPa7nF+xo5WzRWSFCBw$CNZx7KCRC0o3vr/cWp6YW00/lrx58T81xDKIPkcb5CA	Customer Login Test	\N	customer	t	2026-11-15 10:00:12.043789+05:30	2026-11-15 10:00:12.043789+05:30
8a799d11-1c99-44ff-b64e-f7154fae02c7	admin_a35fd2dc@example.com	$argon2id$v=19$m=65536,t=3,p=4$6GArVtau2cfRrqj1qn9N6g$zyQdXQwGA39TyetHm8uX8Q3YRExsSeln3KCWniSy9wQ	Admin User	\N	admin	t	2026-11-15 10:00:12.27819+05:30	2026-11-15 10:00:12.27819+05:30
2bd95e45-2a32-4283-a184-4ddc9c22a2e4	existing_e69cae02@example.com	$argon2id$v=19$m=65536,t=3,p=4$w/0aBTc4mYGvdnl5qZioVQ$xQScBjR8cZwJBy4d6HEsF49BaXgu5KBKAAYNNAZ3aUM	Existing	\N	customer	t	2026-11-15 10:00:12.521508+05:30	2026-11-15 10:00:12.521508+05:30
e5aa733b-fa1a-441b-86b7-e67062b00e48	inactive_c15a4f04@example.com	$argon2id$v=19$m=65536,t=3,p=4$vQOkF0nB58JSfg/DfjtaQw$RBpMh9ZdWvXjMRhU7DUoWNbvjCyoznus5EYBHqHt854	Inactive User	\N	customer	f	2026-11-15 10:00:12.75938+05:30	2026-11-15 10:00:12.75938+05:30
2d2d0f7b-16d0-4f1e-b5b2-d929aaaafc54	cust_block_f8e10602@example.com	$argon2id$v=19$m=65536,t=3,p=4$lqUaL24U0ig+Ffgd5NWyNA$oSZKg7545EiAQE/4mEzdnxHJXwGY4b31I04S9M0TOAA	Blocked Customer	\N	customer	t	2026-11-15 10:00:12.986031+05:30	2026-11-15 10:00:12.986031+05:30
faaa383f-cb9b-41cb-8c49-6e05826aaea7	admin_allow_e2565b8a@example.com	$argon2id$v=19$m=65536,t=3,p=4$SLqP8oqcZZ0ClVEuZceIvw$GOSZyV5y5nDjwyZlsGArj1OzQ8uVaZ1y49A8gIAfaYA	Allowed Admin	\N	admin	t	2026-11-15 10:00:13.126165+05:30	2026-11-15 10:00:13.126165+05:30
48e60617-008a-4546-8a36-00a82e154f49	reuse_fb8bbb5f@example.com	$argon2id$v=19$m=65536,t=3,p=4$QJn1m1gRyIP0tuSOCYjQvw$c8nxca8rt3UUpiIr6sq3gcHjisQt0g47RjHM7vOxGB0	Reuse Test	\N	customer	t	2026-11-15 10:00:13.272241+05:30	2026-11-15 10:00:13.272241+05:30
d37e13c1-a446-46f3-80d4-dc296b1cb4ef	logout_9124bf13@example.com	$argon2id$v=19$m=65536,t=3,p=4$lsOe8HiB7h7mU4QdWA9xhQ$7S9zacQN1Rcf9gbYPePh445NJGeytzC86ryzFgbfxv0	Logout Test	\N	customer	t	2026-11-15 10:00:13.44112+05:30	2026-11-15 10:00:13.44112+05:30
1e0c5b4e-2472-4102-afd9-62ca8f1d8b2c	chg_pwd_6ba50ed2@example.com	$argon2id$v=19$m=65536,t=3,p=4$eZX9zm0le/OazuFveckzSA$sk+OPqnJVui0RuZyZFt1FnxRYRXV0Wg944KE9fPvxQ8	Change Password Test	\N	customer	t	2026-11-15 10:00:13.588237+05:30	2026-11-15 10:00:13.917601+05:30
377bf974-8883-4010-9d5f-567ffd35a145	rate_0_052f5a@example.com	$argon2id$v=19$m=65536,t=3,p=4$xmCAHWC7CJG1/3T7onKM7A$8Q1pm62y+6jAf1JsiU6c6KWtzxVpRqT0RdEf+rs8F1Q	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.27231+05:30	2026-11-15 10:00:14.27231+05:30
1b874abd-3af1-4caa-a8cb-942a38393ed4	rate_1_79bfd4@example.com	$argon2id$v=19$m=65536,t=3,p=4$QJonhvDKZbZ/BEs1uEoe4g$GX4HpJjldL34LLaYpfOuMSSoM8+iLdy+rF1zlGUr83A	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.394523+05:30	2026-11-15 10:00:14.394523+05:30
e74f4abb-929b-443c-ab86-15555cc5f5e0	rate_2_4f1d39@example.com	$argon2id$v=19$m=65536,t=3,p=4$8WAr/ObOAIqarKgWprj2uw$mNp8HQCnd6oubnvm9BDoEeavuepC5YMX1SabiqWUQsk	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.52066+05:30	2026-11-15 10:00:14.52066+05:30
ae9c4b22-528e-4f9b-b352-879da85c3e15	rate_3_d0056d@example.com	$argon2id$v=19$m=65536,t=3,p=4$9C3UlA62ZovoRlShxkr8jw$S1Bj4qL1JMsPxVEUmleYnhxY7pK+l/R1quh4AREaE84	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.639535+05:30	2026-11-15 10:00:14.639535+05:30
262c231c-3a87-43b3-998b-1dff96549ac2	rate_4_edbd63@example.com	$argon2id$v=19$m=65536,t=3,p=4$aCYCt8QtsSSHA98QdmXlxA$XNlhAnh/xLej6wzvR7UY6+e9asQBw9UNp5mTs4DR+Po	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.751883+05:30	2026-11-15 10:00:14.751883+05:30
14f28ca3-83d8-4ed1-ad1c-3cc3e3da3165	rate_5_58e622@example.com	$argon2id$v=19$m=65536,t=3,p=4$MVoMWs5zgMf/XO1oz8oCvA$vMUlIvxuzUaLZTOWk2c6XXX/7p4pipjcsQOCLrPWAkE	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.874952+05:30	2026-11-15 10:00:14.874952+05:30
4b4166dc-f5ac-47df-99bc-fa64d74e5ca0	rate_6_29fe4f@example.com	$argon2id$v=19$m=65536,t=3,p=4$kB/1yIM8GSwGP6IsaI1rDg$kWin2kOdZ2WpezFMXTfjVwTdGsWVVKQ10Rkkpzs5Jvk	Rate Limit Test	\N	customer	t	2026-11-15 10:00:14.987224+05:30	2026-11-15 10:00:14.987224+05:30
238d650d-1595-432c-afae-25be8691fff2	rate_7_265d8f@example.com	$argon2id$v=19$m=65536,t=3,p=4$hY159OMM1wZOcLgKXhpqwA$3P6pO6TU+xefWRbmYixJeaAi683VH/dWsuZnQ1UDj84	Rate Limit Test	\N	customer	t	2026-11-15 10:00:15.11084+05:30	2026-11-15 10:00:15.11084+05:30
f4c396c4-0b87-4949-be53-d63f6fe564e9	rate_8_9d9732@example.com	$argon2id$v=19$m=65536,t=3,p=4$jL5ngKbaMW4NTbwFTqG0xA$lkV3UYsM3jTlL4aoSttRAnmvWeo6bdoF2foydXri/Ds	Rate Limit Test	\N	customer	t	2026-11-15 10:00:15.230971+05:30	2026-11-15 10:00:15.230971+05:30
26cc1977-151f-4400-8863-957e394923ec	rate_9_539084@example.com	$argon2id$v=19$m=65536,t=3,p=4$f9z4wYuo48aML/xT2zJoEA$zrm4kL+yiXB+qWXlaJhOZRGmdvofIkQYYrCe/PF4rWU	Rate Limit Test	\N	customer	t	2026-11-15 10:00:15.352313+05:30	2026-11-15 10:00:15.352313+05:30
e9a0c088-7d2b-46e5-9710-356855a22976	cust_0ecfc89d@example.com	$argon2id$v=19$m=65536,t=3,p=4$TkzCAX7qSrXSe/Rl/MoTLg$6nuBDfcG5K8hZRdl7QgSsVWFTe8u69PsH5kYzTP4ag8	Test Customer	+919876543210	customer	t	2026-11-15 10:00:40.224471+05:30	2026-11-15 10:00:40.224471+05:30
41aaa817-bd71-40d2-b022-aaab7f2e695d	hashcheck_be3c3f7d@example.com	$argon2id$v=19$m=65536,t=3,p=4$Qa8Me7QaSbmB12+IVjQmFw$H/b1yJhMzI1G4DbbGQknB75NVscdsAfYMTEEMj/O8v0	Hash Checker	\N	customer	t	2026-11-15 10:00:40.343176+05:30	2026-11-15 10:00:40.343176+05:30
185f16b0-e330-4092-ae52-ae018b96b86b	dup_f8b650b6@example.com	$argon2id$v=19$m=65536,t=3,p=4$oH+VkF6eUcrWPQnuuKd2DQ$Qf1lxNYWoJqBoIj/jd7jBDQtx/Ut4JB6bRwS4jEulKs	Duplicate User	\N	customer	t	2026-11-15 10:00:40.448622+05:30	2026-11-15 10:00:40.448622+05:30
1a46a28f-1509-40a0-a056-7169fbf3f5d8	login_cust_ccbd7d71@example.com	$argon2id$v=19$m=65536,t=3,p=4$KBVZySYAUguy0TJ9B5TDzQ$U31Hrw3/Bbj33vS7+BW01aM/+SSypZzvQaRifBOQ25U	Customer Login Test	\N	customer	t	2026-11-15 10:00:40.567042+05:30	2026-11-15 10:00:40.567042+05:30
99e5b7c8-74a7-4a36-ada5-d9a92d9567f7	admin_41434e25@example.com	$argon2id$v=19$m=65536,t=3,p=4$bIwqC9vhgxzaFyZfbtp3mA$XDFqS4wi9JgD2bQ6eBgsxvCSEnvVsynXyPIDL0RM9uo	Admin User	\N	admin	t	2026-11-15 10:00:40.794363+05:30	2026-11-15 10:00:40.794363+05:30
215b4951-176a-49f3-9a68-082658b73c9c	existing_0ad9ad4c@example.com	$argon2id$v=19$m=65536,t=3,p=4$zAroc+fXcdt0h+wqo9M37A$oUXYsuU5ECHnleFUKbpVUWBEHaB1UHvOtL6S3luUuWU	Existing	\N	customer	t	2026-11-15 10:00:41.0438+05:30	2026-11-15 10:00:41.0438+05:30
fbbfea56-164b-4b78-9d2a-89daaf9d9597	inactive_b7ab9c66@example.com	$argon2id$v=19$m=65536,t=3,p=4$Wogo7qtiHYHPD+vZjDA+Xg$h+vUx7xf1YejuLY+ptCUAQojMkgY2L6SZCu4hFR3jWM	Inactive User	\N	customer	f	2026-11-15 10:00:41.279381+05:30	2026-11-15 10:00:41.279381+05:30
e7c68e46-f316-4b25-a341-6629d8a7dae9	cust_block_01118274@example.com	$argon2id$v=19$m=65536,t=3,p=4$zM3gUGz3HfAWvq+I/oHFzw$NoiUf+ZGBQiDa5/wPYRNswPsdGVUH1hOOxU8qXiRKYA	Blocked Customer	\N	customer	t	2026-11-15 10:00:41.512978+05:30	2026-11-15 10:00:41.512978+05:30
494c04c3-d785-4721-bf53-fe26ec35e17e	admin_allow_f73c8f56@example.com	$argon2id$v=19$m=65536,t=3,p=4$S2kfdRtLyeAMjVau+MKBQA$sqKPq9nwR8uk15OaaLuaZIuz9CzxefDx/aavKOztyaM	Allowed Admin	\N	admin	t	2026-11-15 10:00:41.662936+05:30	2026-11-15 10:00:41.662936+05:30
f048a416-d623-42b4-9eb5-92d818938827	reuse_36c2da14@example.com	$argon2id$v=19$m=65536,t=3,p=4$PtGgwgDYm4hKx74atxs58A$yw9iPKsC8XWxw1vhoj5BIux5sr/77qEvIf3JZdenqSo	Reuse Test	\N	customer	t	2026-11-15 10:00:41.828108+05:30	2026-11-15 10:00:41.828108+05:30
7db55207-7f39-4e27-8c94-18975e1f0910	logout_2008c115@example.com	$argon2id$v=19$m=65536,t=3,p=4$yFGto7SGDmBQ05//hTfPGg$id4+EfQcStttbD5Sjr8WM/eJVzasEf9TqmN1x654J6Y	Logout Test	\N	customer	t	2026-11-15 10:00:42.064076+05:30	2026-11-15 10:00:42.064076+05:30
a97b213e-894f-4784-8f61-2c693cee4439	chg_pwd_f690de18@example.com	$argon2id$v=19$m=65536,t=3,p=4$5msn9ruLR4PEA0Na4iLHeA$Zw6fH1BqnPip4NBmUxC3Nad2A8RCPZuHcEi5MaMvGNM	Change Password Test	\N	customer	t	2026-11-15 10:00:42.270051+05:30	2026-11-15 10:00:42.786091+05:30
9cd6f9d0-998d-4f00-84de-bb3c9a784e98	rate_0_f4ecb6@example.com	$argon2id$v=19$m=65536,t=3,p=4$YYG4CJmZLeL6Nk8XA52z6w$Nr+1W/6Ds/rNlvc1VTirhnrxaZb0DD2WenoeY8UTLI0	Rate Limit Test	\N	customer	t	2026-11-15 10:00:43.299238+05:30	2026-11-15 10:00:43.299238+05:30
be6dd55b-d74e-4e37-8149-ee6dc088620b	rate_1_0b682e@example.com	$argon2id$v=19$m=65536,t=3,p=4$BcdLEuvYV7UQ3s1LHE3+oQ$/uDDHznLAXZ5lLRW4yNHp/npnXUdBnnUmCK3URGEDBA	Rate Limit Test	\N	customer	t	2026-11-15 10:00:43.455992+05:30	2026-11-15 10:00:43.455992+05:30
b0e03195-e258-4e9f-8678-521b8ddf5790	rate_2_bf6b98@example.com	$argon2id$v=19$m=65536,t=3,p=4$7mavZL87CNt7Gc9a8xBhyQ$jvfael9ebZ6a4bmrpMExcVS7Wv3FwFT7kT6L64bDef4	Rate Limit Test	\N	customer	t	2026-11-15 10:00:43.598823+05:30	2026-11-15 10:00:43.598823+05:30
151a6bc5-388c-486f-9f2e-df4657df1f9c	rate_3_a4c804@example.com	$argon2id$v=19$m=65536,t=3,p=4$tVIuWsFbGFtWWmKk8kkIMw$LusrNFBRp/qqDpM0KolddiP9HUmp2CyGuVECcE67DSg	Rate Limit Test	\N	customer	t	2026-11-15 10:00:43.728898+05:30	2026-11-15 10:00:43.728898+05:30
47aa8f35-213c-4a8b-a374-537cbeff7682	rate_4_895687@example.com	$argon2id$v=19$m=65536,t=3,p=4$4wF6rMlUi8xpXKwFO4b0hQ$G3vyUUuKkzXBQTjUEvYNXNEU+AxGd6cbA+Fa/4hx1wA	Rate Limit Test	\N	customer	t	2026-11-15 10:00:43.876949+05:30	2026-11-15 10:00:43.876949+05:30
67746d8a-381e-4e4f-8f66-86bffe9024c4	rate_5_0d267e@example.com	$argon2id$v=19$m=65536,t=3,p=4$MA4fhFvPgKzjjViX8GOFQg$3fE7njyivy5OaPHUpPlurve7qyEMUlOY8Qcw11wiN1g	Rate Limit Test	\N	customer	t	2026-11-15 10:00:43.997228+05:30	2026-11-15 10:00:43.997228+05:30
281b9bc1-da22-4b03-a5ca-eb7109b4d812	rate_6_0da251@example.com	$argon2id$v=19$m=65536,t=3,p=4$5001GU+b+eiFYXnhSFzeew$1jZRqzIt36UE5hVfhwl0y6gdc61KaxFE07TY/o9nZJw	Rate Limit Test	\N	customer	t	2026-11-15 10:00:44.139726+05:30	2026-11-15 10:00:44.139726+05:30
1f04b5c0-6c55-449f-a5cd-731037ed8702	rate_7_3699d6@example.com	$argon2id$v=19$m=65536,t=3,p=4$bGsyT4fASVBdMgkQfuz2zw$4B3NdcL+i6Q8c8a9iL4S05SgGfH6su69u9Z/xTIbNe8	Rate Limit Test	\N	customer	t	2026-11-15 10:00:44.270473+05:30	2026-11-15 10:00:44.270473+05:30
a507ec3a-a007-4382-98e8-8517ba03b55e	rate_8_5d2048@example.com	$argon2id$v=19$m=65536,t=3,p=4$pBAffA5BTaPFjLJmEOO9Fg$mgwyryPhg8vVkB1Up2KRsvNVx56R2JZ9JJ65XshpvKg	Rate Limit Test	\N	customer	t	2026-11-15 10:00:44.398194+05:30	2026-11-15 10:00:44.398194+05:30
ee11b7c0-68b5-4ec1-8665-e9c8f4208e31	rate_9_09c89c@example.com	$argon2id$v=19$m=65536,t=3,p=4$PFDKC63wlMoHOkPVjq5qmw$epkwN9dPY/YOKhH6R3XZ1RSnU0w1ikcFjCl2VFxCqdM	Rate Limit Test	\N	customer	t	2026-11-15 10:00:44.530727+05:30	2026-11-15 10:00:44.530727+05:30
37ee37f3-560e-43ff-b12f-3f875eb3d5d5	catalog_admin@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$jldb4VEod4G1oNbm6PPCww$lEt3CY7PPwb+l5MejYjkpuSv05AoEz3BC8Koes/cDQs	Catalog Admin	\N	admin	t	2026-11-15 10:00:44.687425+05:30	2026-11-15 10:00:44.687425+05:30
92ee43f4-1af4-471f-92ae-416667ad7dcd	catalog_customer@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$aqtF08/eljzTsaFbkBgxHQ$sHBMqvnMa+BXoDCMl97gy8LJRGxSgY3xkK5p+Uzofjw	Catalog Customer	\N	customer	t	2026-11-15 10:00:45.218354+05:30	2026-11-15 10:00:45.218354+05:30
e2a14f67-914a-4999-8bc6-c38853183621	cust_ccad1784@example.com	$argon2id$v=19$m=65536,t=3,p=4$Nad+3fsx/8q80V27IRebiA$1HRS8TnjiyVJl0qX9TCm2ECLElQFBp2FcN9NnKG1BkU	Test Customer	+919876543210	customer	t	2026-11-15 10:01:00.202995+05:30	2026-11-15 10:01:00.202995+05:30
e504babc-66ae-4319-b045-533a8243b394	hashcheck_05a1e6d2@example.com	$argon2id$v=19$m=65536,t=3,p=4$16gUFMNREkKL2QqJFNGRAw$8iuaQdNULe61gQo9dSO/E+cMby2mm4GxMpcmXR7y6Bs	Hash Checker	\N	customer	t	2026-11-15 10:01:00.329665+05:30	2026-11-15 10:01:00.329665+05:30
4d983bf1-5890-49d5-aff5-f7e8a849ed82	dup_7a90cf9d@example.com	$argon2id$v=19$m=65536,t=3,p=4$dbfhnFZI+uO3UqyZjs1A1w$w10bux8EVEHFHHCixGzmEFMvREBuK5AMEbpNQqL0lNI	Duplicate User	\N	customer	t	2026-11-15 10:01:00.44435+05:30	2026-11-15 10:01:00.44435+05:30
4125bd46-1c85-40b2-9ce3-4778bf55c2ec	login_cust_916dc84f@example.com	$argon2id$v=19$m=65536,t=3,p=4$rMbF/a4mONL9czGJS6PtyA$+OcjIRPXAUS+zcrjIbMyxK5HUvDKt2GEQ2SXLOTLWQE	Customer Login Test	\N	customer	t	2026-11-15 10:01:00.578031+05:30	2026-11-15 10:01:00.578031+05:30
1fc4703a-5359-464d-9fb0-ce65297ab663	admin_93abe70e@example.com	$argon2id$v=19$m=65536,t=3,p=4$DE6ODHncjOARxxL531Fgig$++8m6mf8T8q/yhHl5NGLtvNqDbeQ+ZVdIWausspB37w	Admin User	\N	admin	t	2026-11-15 10:01:00.789129+05:30	2026-11-15 10:01:00.789129+05:30
0cada2c3-313c-4abb-8909-642b5b54942a	existing_a9a65b1b@example.com	$argon2id$v=19$m=65536,t=3,p=4$cWBS1WyQijCqZdNuROZAqA$YQJgX1exwCSWQZ7lD3vja/6Z/YiDDiRRAiOQFDYAa60	Existing	\N	customer	t	2026-11-15 10:01:01.043002+05:30	2026-11-15 10:01:01.043002+05:30
eceb0c5b-4e1c-4e10-acf9-3494c109ee4e	inactive_204cb604@example.com	$argon2id$v=19$m=65536,t=3,p=4$mNeL6huJHzT3xHRzmqrl+g$i0jfq3S0uMPBcce9GweQKeJmh5kz8olARE6j3/19h+U	Inactive User	\N	customer	f	2026-11-15 10:01:01.288861+05:30	2026-11-15 10:01:01.288861+05:30
d6d5a578-9512-405e-8de8-2eebe315b1af	cust_block_ba7a6072@example.com	$argon2id$v=19$m=65536,t=3,p=4$3QYZWByKBVOnmIURVfE6Sw$uRhaq65Ymk1AaURS3D55NRvTt+1T8sCxW2i/bsq+DP8	Blocked Customer	\N	customer	t	2026-11-15 10:01:01.522619+05:30	2026-11-15 10:01:01.522619+05:30
58dcc960-5aaf-4727-9c49-44f9b6959312	admin_allow_e23aa13b@example.com	$argon2id$v=19$m=65536,t=3,p=4$cmfWG/S08O90pAflDjrhVQ$NUGWyGjOOjrcXR3wx1HAbpovl8HKfBD7zVaf/edj/j4	Allowed Admin	\N	admin	t	2026-11-15 10:01:01.668302+05:30	2026-11-15 10:01:01.668302+05:30
ebf58521-11e5-45e6-a4b9-0896daee3070	reuse_4eada0f2@example.com	$argon2id$v=19$m=65536,t=3,p=4$b2KN1002cpbqsG1zzkvChw$D2Cqg89xXQO52klc8iq0Cr2rVhSpDwM/l19oFIj/fRM	Reuse Test	\N	customer	t	2026-11-15 10:01:01.809348+05:30	2026-11-15 10:01:01.809348+05:30
ddaf36c0-3d08-4543-ae95-579278566cb7	logout_ac8e1cfc@example.com	$argon2id$v=19$m=65536,t=3,p=4$8bv1FOyQC9XyRqsDaYvwjA$ST8Iy/h/i89hrOPu1InShyaQI+ANC/+j6QH/ZzGXq6w	Logout Test	\N	customer	t	2026-11-15 10:01:01.974386+05:30	2026-11-15 10:01:01.974386+05:30
c13dd4fc-6319-4cbd-9f1f-985bfd36badb	chg_pwd_db722883@example.com	$argon2id$v=19$m=65536,t=3,p=4$O3eODP1TIQkDqcn+2EoJXQ$RdBUmiyCFzrz/LpuYI6Gh9HnN2pNVx4ZMw52cnUa5Aw	Change Password Test	\N	customer	t	2026-11-15 10:01:02.125575+05:30	2026-11-15 10:01:02.538758+05:30
d25e6870-684d-4014-9455-c9ae839ddd74	rate_0_7cae01@example.com	$argon2id$v=19$m=65536,t=3,p=4$x6aT2gxhqvf1Gj09O5BTyA$MUsD3LNgZXfwpPEcSFn+J+Y0c038WNeUJZxBG2FU6pk	Rate Limit Test	\N	customer	t	2026-11-15 10:01:02.896952+05:30	2026-11-15 10:01:02.896952+05:30
e11441d3-141a-48fb-b458-8189aabaac54	rate_1_93a32b@example.com	$argon2id$v=19$m=65536,t=3,p=4$GPtjJtl9zM2Mv6EOf9ft+w$kALkKSm/sfxNCCkcllZL4replDEU+7l/GUA8FP1ce0E	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.015975+05:30	2026-11-15 10:01:03.015975+05:30
a7cfeee7-58b0-445e-98d0-d095dd71037c	rate_2_3d6e6e@example.com	$argon2id$v=19$m=65536,t=3,p=4$dEC1C5yI3LgilH0+Mhp+vA$+He4c3MaP9YKFhbvFVvyL4G/GUyoQQGDn2HJn2acpIY	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.140702+05:30	2026-11-15 10:01:03.140702+05:30
6d979b57-a271-4295-9aca-bdc559572363	rate_3_d20c60@example.com	$argon2id$v=19$m=65536,t=3,p=4$yjXBcPdfNk1qCPy9/PDS9A$XWO68LKXIdb/p8bR/Vvcx0qCALdbYPQ5jy6BtQfR0So	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.25845+05:30	2026-11-15 10:01:03.25845+05:30
aad4fec9-fa47-4499-89a1-ac85bfcbc147	rate_4_a9fa5d@example.com	$argon2id$v=19$m=65536,t=3,p=4$NX/kvw9iIsh3w5Vt2DoGVg$T58y/M+/Z0RibJbQC15t3sh2eHzwe2cZcESCKlwsmS4	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.379117+05:30	2026-11-15 10:01:03.379117+05:30
04373638-22f3-46b4-9033-70715ee88a2d	rate_5_5aa883@example.com	$argon2id$v=19$m=65536,t=3,p=4$DnSYAQwI36f/zwnvoy21eg$K/bqkethc3PHk5uKXhrVySWzC2IsVKRb+on0iVbI0NI	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.504405+05:30	2026-11-15 10:01:03.504405+05:30
c11024c3-4bac-47d5-b3cd-1ec3b3b3580d	rate_6_a167bd@example.com	$argon2id$v=19$m=65536,t=3,p=4$cx7iAtm4wEWLeJVCnE4sBA$V+MMZXNxGKiUqHTvNfBWwtARUZjwpNnF9YpdZCtlFRg	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.621836+05:30	2026-11-15 10:01:03.621836+05:30
9921156c-b913-4d05-9322-9d3c83a826dc	rate_7_83d54b@example.com	$argon2id$v=19$m=65536,t=3,p=4$4L/v1VtPCfHRC6vahh720w$EDRWQlSbsGeCu79TmHSjeZLSyUxUOXk8hcl5jnhS9ls	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.74438+05:30	2026-11-15 10:01:03.74438+05:30
4de56ea6-0895-4a34-9d9d-75d176758eb6	rate_8_c99e95@example.com	$argon2id$v=19$m=65536,t=3,p=4$hW2+VgmSqRoZvwGlf+yCrw$BIWzVw/OC/6teSCZE69QGnBdBkpIKq7dS1DbafvLJrg	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.863072+05:30	2026-11-15 10:01:03.863072+05:30
fc9baa5c-a489-4e87-980c-9696c8c30473	rate_9_3f17e6@example.com	$argon2id$v=19$m=65536,t=3,p=4$KDnIduPaBEIKxzmOv0yDWA$SBgoFe07DAJ4NixzgOlxtu31zgYuSuLQND41V3lfL+4	Rate Limit Test	\N	customer	t	2026-11-15 10:01:03.98022+05:30	2026-11-15 10:01:03.98022+05:30
e7f0ae1a-7624-4522-ab53-46401ce6dfed	cust_4aff2abe@example.com	$argon2id$v=19$m=65536,t=3,p=4$jTF1S8Qschhc5Ry0p2yNDQ$Rh7r7fdUdPhN7hunVfYuD5JuhdGK9BA+KbnP+iFjrtA	Test Customer	+919876543210	customer	t	2026-11-15 10:01:23.594658+05:30	2026-11-15 10:01:23.594658+05:30
583c9f8a-0bf6-4e27-907b-a34a8cb4640b	hashcheck_561a78e2@example.com	$argon2id$v=19$m=65536,t=3,p=4$JaIOC8le2DZ7RPlGZ9K3lQ$rVbRQoFOg8GDLHHViGvdc9Op524XwDLJIqePvyG3lfE	Hash Checker	\N	customer	t	2026-11-15 10:01:23.775451+05:30	2026-11-15 10:01:23.775451+05:30
67670102-67a2-48f4-9360-ca765a435936	dup_b52263fc@example.com	$argon2id$v=19$m=65536,t=3,p=4$VHQj4XyrtgBGOwx06+cctA$6pN00Gp4jsBdkWAhqvxlo2YK2JuF/7CDIY+8fY6g5fc	Duplicate User	\N	customer	t	2026-11-15 10:01:23.908914+05:30	2026-11-15 10:01:23.908914+05:30
8edfe372-8afd-45f0-9780-86b44ab97648	login_cust_8a2806b0@example.com	$argon2id$v=19$m=65536,t=3,p=4$xRBVBT7g4SNIFpBAmYLcag$IMTp3Mr09xyhpiyXYpHgkYW6aPHt4Z7NYXj9CBGnvCc	Customer Login Test	\N	customer	t	2026-11-15 10:01:24.0512+05:30	2026-11-15 10:01:24.0512+05:30
6ca8b082-80f5-4780-a2de-0ddefa611ac8	admin_960e775d@example.com	$argon2id$v=19$m=65536,t=3,p=4$FYc3MO214YtBgUHft/Al6A$IeKePaa9yHY230tv1XeaE5GNuVbPmkueUp4CRe2QBbE	Admin User	\N	admin	t	2026-11-15 10:01:24.311612+05:30	2026-11-15 10:01:24.311612+05:30
a9f8217e-07d8-494f-8ad0-2cac9d84e486	existing_61fec1e0@example.com	$argon2id$v=19$m=65536,t=3,p=4$umWtIBZdIRfjb3uG4HAD/A$V9x3Dg397uIjsSHssqtFLNeI+NOh8doEhT8OHK4TaRA	Existing	\N	customer	t	2026-11-15 10:01:24.586576+05:30	2026-11-15 10:01:24.586576+05:30
2dabd0ed-1a34-49e5-9968-8ae613d6e95d	inactive_af4c84f9@example.com	$argon2id$v=19$m=65536,t=3,p=4$nbfmmFMSoL4RLZhTJEauWg$UEeyqzLZR6/OgG27qUK5LfheqnRkSNIT7bQlohM2yTk	Inactive User	\N	customer	f	2026-11-15 10:01:24.837557+05:30	2026-11-15 10:01:24.837557+05:30
7316d1c9-d49e-4b34-9a7f-7de454268df0	cust_block_7abe796f@example.com	$argon2id$v=19$m=65536,t=3,p=4$pocaBrHot2emfXtNZbU7cw$IlJ1lfz/d6X+Q9l8DBYQOesSx++lU//xGa13kpiTLH8	Blocked Customer	\N	customer	t	2026-11-15 10:01:25.080156+05:30	2026-11-15 10:01:25.080156+05:30
6e093b53-1ba9-442a-95ce-551c703c4872	admin_allow_6dad7109@example.com	$argon2id$v=19$m=65536,t=3,p=4$+tmBWLUjffkrBP2rtdBW3w$2XMG868Aq7kuuggPQddXoA8xudOf1tb8PwFawppA5fg	Allowed Admin	\N	admin	t	2026-11-15 10:01:25.218807+05:30	2026-11-15 10:01:25.218807+05:30
e8064f2c-0b04-4801-b6c3-eb3b0708f5d7	reuse_e502ebbd@example.com	$argon2id$v=19$m=65536,t=3,p=4$oFTNYWy9n3/ZOA7ORuLL5A$nglZZdGzqaQOgOBQsEFb7I6O8gKkTjnAAY/egCNYNy4	Reuse Test	\N	customer	t	2026-11-15 10:01:25.3682+05:30	2026-11-15 10:01:25.3682+05:30
75dcf2de-ad3d-4fce-a75c-498175704e55	logout_65e74ad0@example.com	$argon2id$v=19$m=65536,t=3,p=4$i+xNH/NZ5mkRCJqAkZKeBg$a03eEL62giG+n/JhSQzy4jq4lz2ylw/fxgEsGCf0zNs	Logout Test	\N	customer	t	2026-11-15 10:01:25.551359+05:30	2026-11-15 10:01:25.551359+05:30
f81bc565-e9c7-429c-b49e-108a6a98cc05	chg_pwd_22cbbd50@example.com	$argon2id$v=19$m=65536,t=3,p=4$SXaRCFLNUdp8IjpRqD6xmw$dTFug5+IJ9wNUPyqaaAbjIijJazbyAQ2QoXl3Bhs334	Change Password Test	\N	customer	t	2026-11-15 10:01:25.709723+05:30	2026-11-15 10:01:26.065936+05:30
f2fe6bfb-72ba-43a8-9c40-6f43cecbe13f	rate_0_588d1f@example.com	$argon2id$v=19$m=65536,t=3,p=4$fsSX29022Yz157YtqoSXRw$YkWzzyj1ghShlA72O81hlM8RDVHqQk6hB33KKxgM5FA	Rate Limit Test	\N	customer	t	2026-11-15 10:01:26.446327+05:30	2026-11-15 10:01:26.446327+05:30
2c150299-c5d9-4e1b-8a0a-d081332f9c21	rate_1_459d73@example.com	$argon2id$v=19$m=65536,t=3,p=4$ajH/Nrh9mzFuUVz9hkFQMw$RUFKEsmLhIgU79bkubEyrjEnIxkahFAWT0cG8l7X2DY	Rate Limit Test	\N	customer	t	2026-11-15 10:01:26.583846+05:30	2026-11-15 10:01:26.583846+05:30
f646e0e5-1603-48c6-bb7f-4a9dcefedf37	rate_2_095340@example.com	$argon2id$v=19$m=65536,t=3,p=4$3v9TKYC99prVYMCHQ+EuUA$Y0hETbxmR1YJ6A7izZW0b1G2bEVqwA437/6ct/oswpo	Rate Limit Test	\N	customer	t	2026-11-15 10:01:26.717405+05:30	2026-11-15 10:01:26.717405+05:30
2c9cf861-5062-4019-ac6c-261c75099f55	rate_3_0ba3b9@example.com	$argon2id$v=19$m=65536,t=3,p=4$IMkKC05c7+jV/hkcO7aNFg$xjh8H3leZncQgF2RKIAgY0R4IVmcNXQa40f22B0owok	Rate Limit Test	\N	customer	t	2026-11-15 10:01:26.847237+05:30	2026-11-15 10:01:26.847237+05:30
63a50ec0-3dc0-4152-bce4-8f94eca3ac7b	rate_4_4d4e5b@example.com	$argon2id$v=19$m=65536,t=3,p=4$NuiYB/XvarShV9F8Jv1wag$EXFFijZort9mfHX0jGZ8G9gB0kfAiR/mTEOhpv6iVVk	Rate Limit Test	\N	customer	t	2026-11-15 10:01:26.9673+05:30	2026-11-15 10:01:26.9673+05:30
1fec3817-3674-44b9-9255-6a50f36502d0	rate_5_0d8c73@example.com	$argon2id$v=19$m=65536,t=3,p=4$p85J2I8Qp7OpGfEI9FRwxg$PQu0qYTrKMC/NBu98gKnuovfgWzHy3FQ4b6XfTGKCCQ	Rate Limit Test	\N	customer	t	2026-11-15 10:01:27.106655+05:30	2026-11-15 10:01:27.106655+05:30
9913e92a-b23e-4236-895a-f4eee650f8cf	rate_6_46de54@example.com	$argon2id$v=19$m=65536,t=3,p=4$spqG2qkm3QmLMo3uVg85iA$QYEwPyODYlXHuVHPeVUUGkXW8R3+bm8nWYeRrHd9FN4	Rate Limit Test	\N	customer	t	2026-11-15 10:01:27.236975+05:30	2026-11-15 10:01:27.236975+05:30
6594c43d-4659-4d81-aeba-2651510e46ed	rate_7_968549@example.com	$argon2id$v=19$m=65536,t=3,p=4$ay3srLNM3PSQHvQQAoXWxA$IrpgROPrn+VkJNE0Rx6MlTa7TueOn6nksYvxoxsgw5s	Rate Limit Test	\N	customer	t	2026-11-15 10:01:27.365501+05:30	2026-11-15 10:01:27.365501+05:30
07d6bb11-d9a9-44d3-9ac1-1d4968a40764	rate_8_5ba9c3@example.com	$argon2id$v=19$m=65536,t=3,p=4$qnxcldfmZnjVlmhK2UY6pQ$X6AUznY2q9gi+bn7YLwwb+HaLTrdX1puj01TF64qPGU	Rate Limit Test	\N	customer	t	2026-11-15 10:01:27.488382+05:30	2026-11-15 10:01:27.488382+05:30
48beffe8-853b-4aba-8979-741e7e35b0f5	rate_9_3af434@example.com	$argon2id$v=19$m=65536,t=3,p=4$477mO9FD1zQ3/viHnrEUfA$d5faZRbsrojO/M240VXdIYncebMfa/eb499ZPmq5pJk	Rate Limit Test	\N	customer	t	2026-11-15 10:01:27.613523+05:30	2026-11-15 10:01:27.613523+05:30
1633297c-1aae-42cc-bba2-b1e200130fdf	cust_efc76a54@example.com	$argon2id$v=19$m=65536,t=3,p=4$KYvntOmQ1W/+Jbh+vwCsAg$sua9XE+rXBhTHCyVmqGAVofzRsguisf2WkXaVA9keU8	Test Customer	+919876543210	customer	t	2026-11-15 10:01:41.609639+05:30	2026-11-15 10:01:41.609639+05:30
0446e56d-ea56-4287-a7be-0240565421e8	hashcheck_16d35e7c@example.com	$argon2id$v=19$m=65536,t=3,p=4$v6zIAR3T8banNGBnyDkBtQ$o/LEUv5eHGRC4k05Q7jTC5yYBN7i/eAjyPrNghFGGlY	Hash Checker	\N	customer	t	2026-11-15 10:01:41.728399+05:30	2026-11-15 10:01:41.728399+05:30
58ad0164-900e-4b47-950d-e48e7391bc32	dup_93e2f990@example.com	$argon2id$v=19$m=65536,t=3,p=4$Eh4IxIJA13jNTkcwbCKo4Q$Ib0demaVHVl/poyRBtlWUbzodOCgGXsKTsrwtQ0UH5E	Duplicate User	\N	customer	t	2026-11-15 10:01:41.83909+05:30	2026-11-15 10:01:41.83909+05:30
6b88d33a-7147-4d80-b11e-fe750c78844f	login_cust_451154a3@example.com	$argon2id$v=19$m=65536,t=3,p=4$xdTcZfH5VQJaWNctoUmFjA$M7luE/muca0ymAmcG9XipKGs77OJm/JZgrRBsSJ4r5Y	Customer Login Test	\N	customer	t	2026-11-15 10:01:41.948275+05:30	2026-11-15 10:01:41.948275+05:30
889c30ea-4b38-4953-9192-1c4b296e94e1	admin_2307f4dc@example.com	$argon2id$v=19$m=65536,t=3,p=4$Fxl76vJz2qH59kMmZSCbPw$HDl+TwbS58G0YAK8duDte7ZI9GMXQeVHTGc5C5/ztH4	Admin User	\N	admin	t	2026-11-15 10:01:42.171498+05:30	2026-11-15 10:01:42.171498+05:30
0aa2d43a-f381-4b59-b6a5-5164321b0d1c	existing_8dd94372@example.com	$argon2id$v=19$m=65536,t=3,p=4$4WrFF5h47jRkkLZDttCw4A$r5COGLI2Wwn2RyVpAnrS8p6J/VGdsfX8JoVCerFybvc	Existing	\N	customer	t	2026-11-15 10:01:42.426516+05:30	2026-11-15 10:01:42.426516+05:30
0f46bd30-dc7d-40f1-a86a-c388f0d00acb	inactive_679adc40@example.com	$argon2id$v=19$m=65536,t=3,p=4$CHQ3hziz6TAjq+E4jFUDOA$b0nFg+4qPRawJ8vHwpSLf7P2rNpTjlJ5gyRdRj8kwcc	Inactive User	\N	customer	f	2026-11-15 10:01:42.653697+05:30	2026-11-15 10:01:42.653697+05:30
59aac385-2bd5-4288-96c6-61dca077ae01	cust_block_0c6f3584@example.com	$argon2id$v=19$m=65536,t=3,p=4$8J98Y48NKu++YGfggneCKQ$aB6LCqBwkZwLjZ6I/tUfEk8jyZ2Q1vWTaggWLrDhOLI	Blocked Customer	\N	customer	t	2026-11-15 10:01:42.887135+05:30	2026-11-15 10:01:42.887135+05:30
439fae78-4e37-4b91-9347-4c8c625a5dac	admin_allow_537a44df@example.com	$argon2id$v=19$m=65536,t=3,p=4$HCYFQ0/ozjFurW7AdYE8zw$f9YExptf9HUuL5w1JQ3onrdg+BI+RaqdzSB2giYf1R0	Allowed Admin	\N	admin	t	2026-11-15 10:01:43.013654+05:30	2026-11-15 10:01:43.013654+05:30
8fac1804-a606-431a-b93a-69442b5fb34c	reuse_a4b9b663@example.com	$argon2id$v=19$m=65536,t=3,p=4$FDAhmZwNK+H9UMY99/asOA$b9qLD8Hsc23h1ipVeDahzGeuUd2hui5CcmRz84BBWZE	Reuse Test	\N	customer	t	2026-11-15 10:01:43.157821+05:30	2026-11-15 10:01:43.157821+05:30
12fe8a03-d6f8-4551-a791-60b6f5e74a78	logout_45a7424f@example.com	$argon2id$v=19$m=65536,t=3,p=4$2jd0oU6Wu7DuhXJRQ6/wpA$sYmgR9Lw7gDQC7blyUwB37ptEfxaffmovKWSZbSGPPY	Logout Test	\N	customer	t	2026-11-15 10:01:43.342062+05:30	2026-11-15 10:01:43.342062+05:30
bb77d7d5-360c-4bd6-a03f-4854de775f06	chg_pwd_2101cf8d@example.com	$argon2id$v=19$m=65536,t=3,p=4$nVGTDNnZ+joVJPt7fOaijw$UB1tcIQL1dIPqn8rTvHBtovX0M/uCgduI+V1ddddDfo	Change Password Test	\N	customer	t	2026-11-15 10:01:43.491663+05:30	2026-11-15 10:01:43.829096+05:30
53ad667b-e168-44ae-915a-fd3f71188b74	rate_0_35af22@example.com	$argon2id$v=19$m=65536,t=3,p=4$PPXqdsL8BWVyIZ+SM+3iJQ$eJZY57uqa113zJ5AdBcruudlrPNRU7nntx7op8IDZhY	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.177444+05:30	2026-11-15 10:01:44.177444+05:30
23a353c9-4a91-436f-8a36-1aca3a29c754	rate_1_076790@example.com	$argon2id$v=19$m=65536,t=3,p=4$WAbRFabFsWtufoWag67mxQ$QIz8v93hQbqXhMcWBklKGmjBD7vUtqA1dvA1szAbUc0	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.299251+05:30	2026-11-15 10:01:44.299251+05:30
37dd9580-4d3a-4003-a9c3-0bd1401232ec	rate_2_fa78d8@example.com	$argon2id$v=19$m=65536,t=3,p=4$rmrShyyd5F28qU0T9mNS4A$BVxh6T5l6hWivB8I0gcLHl21MYEdTjlVuoL0XRGyjmA	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.410125+05:30	2026-11-15 10:01:44.410125+05:30
fa1e6759-9896-46e5-a8d2-996a41595ffe	rate_3_a02f45@example.com	$argon2id$v=19$m=65536,t=3,p=4$tb5RTillbJo2mTAa1t2Rkg$X2+tnONB4s3rZs50iDGpq54IIC3yf8XUMS/Q3kF6Jp8	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.529393+05:30	2026-11-15 10:01:44.529393+05:30
789c9ef4-c858-494d-ac41-e2db9d1ff46b	rate_4_522ad7@example.com	$argon2id$v=19$m=65536,t=3,p=4$0bpbDajZB+1r9p1yZXheTg$4nmm6yoSdU1Lb5mKGGP55nSsowGg5ifiiwKPtkENQhI	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.657299+05:30	2026-11-15 10:01:44.657299+05:30
ce1bff2e-ce08-4baa-9ec3-6a0115fa3c1a	rate_5_68e66a@example.com	$argon2id$v=19$m=65536,t=3,p=4$c1+CGEmMdTQbglFdj5ehKg$6GaSSqLHehYdSJJGGpBuJMYwidFqhuOXEy0BA4xMzBY	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.766134+05:30	2026-11-15 10:01:44.766134+05:30
be69e842-27ae-4147-8612-d8d1c900c312	rate_6_cd0edd@example.com	$argon2id$v=19$m=65536,t=3,p=4$0ZbtDnj1OqnwUuJgWGy7Yw$nAhb9GckbcBEoHCDl2ddPhYnBcpM20PmS46yJxyU1kk	Rate Limit Test	\N	customer	t	2026-11-15 10:01:44.895105+05:30	2026-11-15 10:01:44.895105+05:30
940b5b41-7baa-47d3-b8ae-a1b7b8f5d65b	rate_7_25b993@example.com	$argon2id$v=19$m=65536,t=3,p=4$zEj40zvbkIss1ilLKiJ9Fw$88xH/DGgoLh32piczyIvM132hu0EZ1KltcFgZHFBRBs	Rate Limit Test	\N	customer	t	2026-11-15 10:01:45.006741+05:30	2026-11-15 10:01:45.006741+05:30
e21e9a02-a0aa-45eb-a6be-a13f379bcd5e	rate_8_494f24@example.com	$argon2id$v=19$m=65536,t=3,p=4$anmaISO+S2w4nAY7gbL/jw$HES9VyXhm3wqeeHkkKg/1CHYWqmiUd1yYufMth/4gvU	Rate Limit Test	\N	customer	t	2026-11-15 10:01:45.140267+05:30	2026-11-15 10:01:45.140267+05:30
d6bbb5b9-0116-43fc-9b68-390e72651c2f	rate_9_3d5c24@example.com	$argon2id$v=19$m=65536,t=3,p=4$ZJC/V7sX90/PXBZuezB7Zw$gK+8LSTWKK+7eomfGL79nV3CsBGkd1Oq+akTVR75bMU	Rate Limit Test	\N	customer	t	2026-11-15 10:01:45.261106+05:30	2026-11-15 10:01:45.261106+05:30
592ddcc6-3db3-4cea-a2c7-fe36ac21ac72	cust_78ee378e@example.com	$argon2id$v=19$m=65536,t=3,p=4$lxS4m9TUki2/LBYTLOdG/g$YGQjjLfH1OvFgB63QMsatYZLl7te0ihbkkYyX7YyVBg	Test Customer	+919876543210	customer	t	2026-11-15 10:02:01.546504+05:30	2026-11-15 10:02:01.546504+05:30
1aad5a0a-5134-4cb4-ba61-55e9d4b6e5f2	hashcheck_2c851759@example.com	$argon2id$v=19$m=65536,t=3,p=4$/SxvP5hJLBRXWqxFJimjBQ$BGxA9K5sYDQl2izzSroyh+jgYJ9UrkVn2IK1SWPhzd0	Hash Checker	\N	customer	t	2026-11-15 10:02:01.670632+05:30	2026-11-15 10:02:01.670632+05:30
69b718f5-6dea-4362-99a6-6788d2bc026a	dup_e7250b7c@example.com	$argon2id$v=19$m=65536,t=3,p=4$2xhWhDqD7o3XlX0YVk5L/g$gxct6FGMRVLWpvFEXc67LouEBd9C1EIgG2NGogdhXhU	Duplicate User	\N	customer	t	2026-11-15 10:02:01.787244+05:30	2026-11-15 10:02:01.787244+05:30
2cadd76a-df00-4205-ba74-0de1c1d38f70	login_cust_d999fbb6@example.com	$argon2id$v=19$m=65536,t=3,p=4$EkSI9HcmEqpEBM2zK44Bng$kHYwdvNGvw7NwZrD3BDo3rEZbyvactNaMhjGnDb8PbQ	Customer Login Test	\N	customer	t	2026-11-15 10:02:01.905747+05:30	2026-11-15 10:02:01.905747+05:30
0c4fe5b5-ad08-4b80-b502-4de4186ee956	admin_6e5e3164@example.com	$argon2id$v=19$m=65536,t=3,p=4$8dbaRAPg+v6WAJztbmlIKw$PPw0l1usMPDZngeSsBLi8nOn4bjCNFrXGC+U/0QFdZs	Admin User	\N	admin	t	2026-11-15 10:02:02.147897+05:30	2026-11-15 10:02:02.147897+05:30
379947d4-6464-449b-913e-ffd9dea90868	existing_2038fb65@example.com	$argon2id$v=19$m=65536,t=3,p=4$UaMXq/n9+zJhka+wY09qDA$Efbke4oAn56kaGvSWVLW+EQQzQQvDDKCKPojhNigviw	Existing	\N	customer	t	2026-11-15 10:02:02.388837+05:30	2026-11-15 10:02:02.388837+05:30
69aacd2c-cdca-43ff-a582-eb1e5fa9b54d	inactive_be8690ff@example.com	$argon2id$v=19$m=65536,t=3,p=4$KmanpUOAy2ZwQ+ioMm6OAg$p+VuPd0zHrK9GxK8Jm1Sk32hBL4UbY9Lvbj42T0KChw	Inactive User	\N	customer	f	2026-11-15 10:02:02.639178+05:30	2026-11-15 10:02:02.639178+05:30
8dee790e-6bc4-4c34-964f-e7b7289b1ce8	cust_block_886f2fd1@example.com	$argon2id$v=19$m=65536,t=3,p=4$C65D26OdJ8ha/N6hrJTjOw$++PtZBVx6XUwDX40Hvm8rM0H2mi/d2dtEwWhYsw6jTc	Blocked Customer	\N	customer	t	2026-11-15 10:02:02.871363+05:30	2026-11-15 10:02:02.871363+05:30
35717add-ea5d-4a31-99ba-c315d21509bd	admin_allow_5e9b13a7@example.com	$argon2id$v=19$m=65536,t=3,p=4$b6IuHo8aicwQ5gtkfG3myg$4lxQZHiUgkIE1HDHW1Hg6d8pV+qpdQqUuKPr7J6lDlk	Allowed Admin	\N	admin	t	2026-11-15 10:02:03.021443+05:30	2026-11-15 10:02:03.021443+05:30
169f2677-be9c-4eb7-abb8-5fc8e24f39cd	reuse_855be8ee@example.com	$argon2id$v=19$m=65536,t=3,p=4$OEs7niOEaIyfscXmflRdaQ$ajTI76dbaUVf+Fe5XylYpSYkSxHPlufrPpQ2pOFT7Vs	Reuse Test	\N	customer	t	2026-11-15 10:02:03.149871+05:30	2026-11-15 10:02:03.149871+05:30
f905dfb1-ccbb-44e9-82f9-72f31c2866db	logout_8a35ad15@example.com	$argon2id$v=19$m=65536,t=3,p=4$zT9sxsv5ALd57IwZP03Yhg$1nWAARj0U+/Kf+CM5vklvAGRRvRR8MyYQCcl2iqlxno	Logout Test	\N	customer	t	2026-11-15 10:02:03.337865+05:30	2026-11-15 10:02:03.337865+05:30
646ed346-259a-4485-940b-fba63be9e718	chg_pwd_85fd46e2@example.com	$argon2id$v=19$m=65536,t=3,p=4$C8nf4kp1cvPftp5j9URtVg$LrJoPDiYiH17D3+geD9r2Y1VL34cb1LLUynMv9K0mmo	Change Password Test	\N	customer	t	2026-11-15 10:02:03.484825+05:30	2026-11-15 10:02:03.817605+05:30
69d398bb-e9d2-4def-b63b-d2377853b0ea	rate_0_df35d9@example.com	$argon2id$v=19$m=65536,t=3,p=4$BtiyEifwwOUxbQcHCAvjzQ$uK7ZfoLdKf2jRbbG8MH4hgmuqu/6eG4DW9y2iJwx6l4	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.179549+05:30	2026-11-15 10:02:04.179549+05:30
e4cc5105-a27d-41a7-9274-a80e679b7fab	rate_1_f11e24@example.com	$argon2id$v=19$m=65536,t=3,p=4$ANnkyGUADVkTeVIf5Mv7Kg$G97DW1lRj7n+myV3exOH8g3Mud8VuSY05od9ISKZeR8	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.298011+05:30	2026-11-15 10:02:04.298011+05:30
6642567d-ff40-4c4f-8d6a-d6cc00639ffb	rate_2_bb1b90@example.com	$argon2id$v=19$m=65536,t=3,p=4$sKLMsHnAkj9CG398UIxVfQ$0jPHAY1L6E/OvTXuJSRvqS28W3aIvTw4NOh2yXQ8N+Y	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.419379+05:30	2026-11-15 10:02:04.419379+05:30
875fa499-a4cb-4ee3-b1b5-df520b038671	rate_3_6e126d@example.com	$argon2id$v=19$m=65536,t=3,p=4$7SWz1QmMwF5y8vhevrOYzw$CumxCslgOxPdcUN1i1G6fPrcYxzKx8ZUPnjUiPnupwI	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.529356+05:30	2026-11-15 10:02:04.529356+05:30
10a0ad73-eae4-4ac3-9e80-c2d68eb7fc6d	rate_4_cfbb0d@example.com	$argon2id$v=19$m=65536,t=3,p=4$nPr3OR1cwsGYajjCMelygA$4UmV4VD08cbSulICa5WitA68c1qA92Y0EvFrYNKm0bM	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.661823+05:30	2026-11-15 10:02:04.661823+05:30
69a180aa-8203-4b86-a7b8-1264bccce630	rate_5_83f6b1@example.com	$argon2id$v=19$m=65536,t=3,p=4$OcF45HQhcKLOiWJVpR8xhg$fN2Hq/Azo/FjrKFvW613Ez/vfebUXTsRszoRhmAfe84	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.782659+05:30	2026-11-15 10:02:04.782659+05:30
f1506810-d03a-4863-901e-3ca88a1bd6c1	rate_6_4ae8dc@example.com	$argon2id$v=19$m=65536,t=3,p=4$z7rAPEGnzkzh0QIQybar1g$C85ifI72Qr/aBZxvU+v8yb+AkObH5ftXubisZ4vKIyU	Rate Limit Test	\N	customer	t	2026-11-15 10:02:04.900792+05:30	2026-11-15 10:02:04.900792+05:30
1ee0fe3c-e202-4db7-bce0-fddd22a34b74	rate_7_8bf246@example.com	$argon2id$v=19$m=65536,t=3,p=4$bYTniVYhfC2EhchupwXK3Q$Ns6qA2lB2SY1C6FPtnLqugVFg+9uCLQUOB8rk838uf0	Rate Limit Test	\N	customer	t	2026-11-15 10:02:05.010656+05:30	2026-11-15 10:02:05.010656+05:30
48ab97c2-af38-4516-8d66-35594e442a6a	rate_8_c50f3f@example.com	$argon2id$v=19$m=65536,t=3,p=4$rNS+xpLrI3N2gLaGlcZyxg$KFSGkX/q/G2+DHrZvQNDmMJUXfe8DCMNI3hbm0zP5yQ	Rate Limit Test	\N	customer	t	2026-11-15 10:02:05.138021+05:30	2026-11-15 10:02:05.138021+05:30
21f04dc1-0e5c-4cf4-8660-aa6b8276eea1	rate_9_bf13f3@example.com	$argon2id$v=19$m=65536,t=3,p=4$PIhf98UBtz5XleEIhOnbyQ$eAHgNYqmwg04dnLQ4CNFTwztZg/YtORQiEFO2ijlGOs	Rate Limit Test	\N	customer	t	2026-11-15 10:02:05.264328+05:30	2026-11-15 10:02:05.264328+05:30
a7d9306c-2df4-4864-8348-4d49c9fb1d59	cust_72c17866@example.com	$argon2id$v=19$m=65536,t=3,p=4$r5/kudxwunGtPsK4j5LfFw$V0YPOjn9Y5Kfl1ybxNj+5jBQecy4R3zJNUL8iAovclU	Test Customer	+919876543210	customer	t	2026-11-15 10:10:35.743132+05:30	2026-11-15 10:10:35.743132+05:30
fbf4449c-99e3-4013-b7d7-266f5501eefc	hashcheck_747f6448@example.com	$argon2id$v=19$m=65536,t=3,p=4$82gEJcaE7GPhJAFXM2oNyQ$dwO8EjF0C9JPP2Gr0OpxdyDH/RR3BU/PyUy1PibKCDA	Hash Checker	\N	customer	t	2026-11-15 10:10:36.11127+05:30	2026-11-15 10:10:36.11127+05:30
f998fdac-8549-4788-b9b0-44d3bf2438ad	dup_36040ec6@example.com	$argon2id$v=19$m=65536,t=3,p=4$vfxPL5um3/t8NFyGdAyJFQ$7BERPmnGLaOs4kZL44EzgeutOQa4A5tMKRzONYzxDEg	Duplicate User	\N	customer	t	2026-11-15 10:10:36.244619+05:30	2026-11-15 10:10:36.244619+05:30
a183fb22-91e4-47ff-838f-8e18448d2ca4	login_cust_f133c3e4@example.com	$argon2id$v=19$m=65536,t=3,p=4$glUEUOB0stiwgda9Xsa97Q$LpZenOd+T9pGJmoUiv7yLtQblvQdcrogsI16g6sdEw4	Customer Login Test	\N	customer	t	2026-11-15 10:10:36.401728+05:30	2026-11-15 10:10:36.401728+05:30
142e458e-f53b-4a44-9b32-3256242126cb	admin_f247223a@example.com	$argon2id$v=19$m=65536,t=3,p=4$hjj24nzxXkP7Hq/ozB5wKQ$LlCEfCQSP8OJVQflE8aiNw8UKZuy2MfOY1Yet4Gch/M	Admin User	\N	admin	t	2026-11-15 10:10:36.671027+05:30	2026-11-15 10:10:36.671027+05:30
5d7cb32e-595a-49a2-8781-3f4e8eb1bd8c	existing_30b0b034@example.com	$argon2id$v=19$m=65536,t=3,p=4$JGuQJ6R6zdRO/n6MrpDyig$lqfhzWKRSwSTxPlEoy1y7jOdfsmis0hY9Yj6azPQYrg	Existing	\N	customer	t	2026-11-15 10:10:36.95594+05:30	2026-11-15 10:10:36.95594+05:30
c695aa41-ee45-4d21-9d3d-212909e19322	inactive_5ea96159@example.com	$argon2id$v=19$m=65536,t=3,p=4$sZVZGMsJJ8wHW8zKRLC35w$NRJKeNBrFTum9q5HDgv7bdC2Ov4aRf1D30lY/AQvfcQ	Inactive User	\N	customer	f	2026-11-15 10:10:37.190922+05:30	2026-11-15 10:10:37.190922+05:30
36b6cd20-6c92-4169-9f28-701a177a0673	cust_block_7a0d30f4@example.com	$argon2id$v=19$m=65536,t=3,p=4$TE8Wu5JoYCzs2eHgrRgtSw$eMA8nWq8ZbOqYH+1/1z8oHFY1sOMBahOOuqywA2tmoI	Blocked Customer	\N	customer	t	2026-11-15 10:10:37.423264+05:30	2026-11-15 10:10:37.423264+05:30
e1d79c0a-7eb8-4a88-994c-9c6edb59f38d	admin_allow_392a685b@example.com	$argon2id$v=19$m=65536,t=3,p=4$W3Lx++enZwSnNResgh50uA$AEimsL23YlKcWLL9qgP0Su3R3Zq+qbwITMyVc+170zs	Allowed Admin	\N	admin	t	2026-11-15 10:10:37.571938+05:30	2026-11-15 10:10:37.571938+05:30
8a48231c-4436-43e3-b36f-143c2cad4236	reuse_fb2085d5@example.com	$argon2id$v=19$m=65536,t=3,p=4$uUAQ1uxF4xAENJImdvbeSg$eqvagyEOFGZMpYr9wZMj2KPjeVmnKoHbxqMY6PHw78A	Reuse Test	\N	customer	t	2026-11-15 10:10:37.714053+05:30	2026-11-15 10:10:37.714053+05:30
a32eceae-a5b1-43c6-8600-73d14f3a4cad	logout_3c9fe69d@example.com	$argon2id$v=19$m=65536,t=3,p=4$JK90is43Y06iv9fe1Ek73g$uqijWhrpNzjFji+HINEQQBWIwUoh20XtJBNSCQ5N1nQ	Logout Test	\N	customer	t	2026-11-15 10:10:37.873694+05:30	2026-11-15 10:10:37.873694+05:30
6c30590b-7122-4c93-8d4b-04afc4b4d936	chg_pwd_30fcb620@example.com	$argon2id$v=19$m=65536,t=3,p=4$OtVDF+b2Vg1oIZImVIfFAA$GwMWj7rZPUyFf3EBBId9MJAy5uMMEixUMy4QgBy18uQ	Change Password Test	\N	customer	t	2026-11-15 10:10:38.038555+05:30	2026-11-15 10:10:38.673516+05:30
f20c63ad-8b9d-48c6-b803-c8c670cfb0ca	rate_0_1aa3e5@example.com	$argon2id$v=19$m=65536,t=3,p=4$oZAr+52TJ8DrsmFNRXRZ7w$GqjHjGiovqAHgLzrPIX99d1TkX4Fh7BD5QRut8dWUKs	Rate Limit Test	\N	customer	t	2026-11-15 10:10:39.107438+05:30	2026-11-15 10:10:39.107438+05:30
fa24d0c3-c7da-41b3-a5a1-6f979a6b7cd8	rate_1_2eccc7@example.com	$argon2id$v=19$m=65536,t=3,p=4$hR3jJVUYnZ3SkNHHcHNpaw$WYgXcsLP7Y9DcdPEaQKGm3r2IUT2cTur7PqBQW7pI6U	Rate Limit Test	\N	customer	t	2026-11-15 10:10:39.267099+05:30	2026-11-15 10:10:39.267099+05:30
900f3b32-87d9-468f-bb2a-b60a9b6ae5da	rate_2_73f4f7@example.com	$argon2id$v=19$m=65536,t=3,p=4$pPf5VmZCYK4+XG9kNh8HWQ$5QnmT5trKUKAtEcCDesEtvA23Ey91Zriz7nDCS8gl7E	Rate Limit Test	\N	customer	t	2026-11-15 10:10:39.608917+05:30	2026-11-15 10:10:39.608917+05:30
be1f2c4c-0abc-4a84-9e96-263d6796c296	rate_3_9e3328@example.com	$argon2id$v=19$m=65536,t=3,p=4$3hE8lZQ1yjtiKi9gX0x5tg$JSTbWmAZLvHMCvMZBjdv1g5hh6fr700NW/5TIEkFk9Q	Rate Limit Test	\N	customer	t	2026-11-15 10:10:39.741808+05:30	2026-11-15 10:10:39.741808+05:30
3019fd4e-56bb-4598-a790-7047090e1b6b	rate_4_6cb56c@example.com	$argon2id$v=19$m=65536,t=3,p=4$yMjk9ueTdd8FPCEXyzu3WQ$A5sT9EVMzWcsNedoT6DF781lJaI9/K0X2gmSULz1qzg	Rate Limit Test	\N	customer	t	2026-11-15 10:10:39.86433+05:30	2026-11-15 10:10:39.86433+05:30
a8736da7-d2e4-49cb-a846-ad1b1529f6c1	rate_5_896b1e@example.com	$argon2id$v=19$m=65536,t=3,p=4$n9cyYEaINgucNHEFt5wvvg$rfjz33Li2VorGkv+5pgFRkVKeDRjIDXXvF4gYmv3uaU	Rate Limit Test	\N	customer	t	2026-11-15 10:10:39.990583+05:30	2026-11-15 10:10:39.990583+05:30
f77397c8-4c39-4bdd-aff9-6ddb30e01f97	rate_6_d0e70a@example.com	$argon2id$v=19$m=65536,t=3,p=4$qGRebgUwa4/bpXdLWvdo4g$8WeUXx0e2xOX7YUBRjpQZm/2Wi3ctIKm3xFYx5iavJk	Rate Limit Test	\N	customer	t	2026-11-15 10:10:40.11604+05:30	2026-11-15 10:10:40.11604+05:30
55a6d008-6dfa-4832-8cdf-d5eb861c9573	rate_7_0dfbfd@example.com	$argon2id$v=19$m=65536,t=3,p=4$AwtDRLL5nczdpN+32BIPCg$U/JC2oCmJNxQq8ExRctLPqOBAbuyiiCYCUG+O88I184	Rate Limit Test	\N	customer	t	2026-11-15 10:10:40.24507+05:30	2026-11-15 10:10:40.24507+05:30
040a27dd-b211-4699-b345-14b80a17d2da	rate_8_293ede@example.com	$argon2id$v=19$m=65536,t=3,p=4$hARHjsqXkJjnWM+ZZmAZBA$q84YSJfT/6NCSsOCUahyjtJaPQ36h9/mDqPPxe1NkSw	Rate Limit Test	\N	customer	t	2026-11-15 10:10:40.378508+05:30	2026-11-15 10:10:40.378508+05:30
d9f7bbba-a0e6-4cbf-84a6-5e5f7852186d	rate_9_ebb73c@example.com	$argon2id$v=19$m=65536,t=3,p=4$I7K8BxZdPQdIPPHQnx7KDA$os77KFeLrcU8qx8n5VFFlmrykl+YbKeQNWcQPD4yrl8	Rate Limit Test	\N	customer	t	2026-11-15 10:10:40.508409+05:30	2026-11-15 10:10:40.508409+05:30
1daafa1a-445c-4384-be91-90fec39bb341	orders_customer@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$2wXaLNPfx2kv8e45IQk7MA$FI7/1bbxm6Zrk+5/wIhkcTmn4Ra+vS+Q4qpi2frVsF8	Orders Customer	\N	customer	t	2026-11-15 10:10:41.979246+05:30	2026-11-15 10:10:41.979246+05:30
ba487f6a-8977-472b-9ce5-bb32b22284e6	orders_admin@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$vwrNj9FgU67osdPhaoTt/w$MY63VoVCVwkNtTAwNeskEL6HssaUa3yeOHsrOsbMwjY	Orders Admin	\N	admin	t	2026-11-15 10:10:42.188406+05:30	2026-11-15 10:10:42.188406+05:30
fb72adfb-b1df-4975-bf69-17749f6a5a7d	cust_6b7a46ad@example.com	$argon2id$v=19$m=65536,t=3,p=4$0fvqRiWzGDhhrZc/eqW8Tw$AR0hX9KXgN8KychoZs3FGaUYbGVD5EDjMJa5CfnR7fQ	Test Customer	+919876543210	customer	t	2026-11-15 10:13:39.506325+05:30	2026-11-15 10:13:39.506325+05:30
6b4bdc06-0b33-41ea-a350-296e4760faae	hashcheck_684fce1b@example.com	$argon2id$v=19$m=65536,t=3,p=4$mv89/6eHqjnZheP2smVpgw$oqrNkQ9LS9cn1RZgd5UliSUUWE4rxBahpTTE5ghbLTs	Hash Checker	\N	customer	t	2026-11-15 10:13:39.642348+05:30	2026-11-15 10:13:39.642348+05:30
e168363d-219a-484e-9d77-c7047e059126	dup_4b3f3ed2@example.com	$argon2id$v=19$m=65536,t=3,p=4$YZS/UmLj2KxYPGFT9KrM1Q$/UHhNeSItBMvnmODHm4aFrwMXhSokuL4LUgQSAf394s	Duplicate User	\N	customer	t	2026-11-15 10:13:39.767664+05:30	2026-11-15 10:13:39.767664+05:30
af13f86e-3087-4697-b3b3-3d0f17c202fe	login_cust_5f24a87e@example.com	$argon2id$v=19$m=65536,t=3,p=4$EtCjV0cVlxlMG2wPtkfXwA$dd/b/wJjRaNKlgJo2+aaggy3eHwrVP74YMkkAAi5zt8	Customer Login Test	\N	customer	t	2026-11-15 10:13:39.916294+05:30	2026-11-15 10:13:39.916294+05:30
dac0f509-e838-4f0f-ae78-47f5652e6734	admin_41a25153@example.com	$argon2id$v=19$m=65536,t=3,p=4$ygxDjyYud1qT4KrnyN35Og$OxLJymSsFDtwqAfygzsJkBLCOiPhYRkvId7X1Z32fzc	Admin User	\N	admin	t	2026-11-15 10:13:40.194958+05:30	2026-11-15 10:13:40.194958+05:30
7958f017-31dd-4ec4-884b-03acac10c012	existing_10eae1a7@example.com	$argon2id$v=19$m=65536,t=3,p=4$XSY7fSIdf/fgQr1iPU+Dyg$xa35CcHoKCQCasuGCpXk5UtF7L3ir0yAc3KDpUG+h6Q	Existing	\N	customer	t	2026-11-15 10:13:40.510275+05:30	2026-11-15 10:13:40.510275+05:30
a912e2fd-bf6c-4d85-b035-22ea4e084e00	inactive_7c4be7ad@example.com	$argon2id$v=19$m=65536,t=3,p=4$ApEFKTxxZ0TJpHTGteq3vw$xtNfAe0GXTlCK0YGyhCsQobIRt1XhiBpEnV8obzChWE	Inactive User	\N	customer	f	2026-11-15 10:13:40.808856+05:30	2026-11-15 10:13:40.808856+05:30
9d3970e8-b975-4a7a-889b-12200c47be3b	cust_block_5c66d84a@example.com	$argon2id$v=19$m=65536,t=3,p=4$Wn5xwj5u3lMbnI2mnMHaJA$8XM9PgsO+E0ix9HWVCbtSPEstOnLH0BtFBouu+jqVJs	Blocked Customer	\N	customer	t	2026-11-15 10:13:41.1037+05:30	2026-11-15 10:13:41.1037+05:30
3264134d-d9db-4f80-b677-f28b083d8bef	admin_allow_1dc79a8d@example.com	$argon2id$v=19$m=65536,t=3,p=4$/6SLXUMVPX3MabZDkhHgQQ$rIzSXFcTdSeoN9k8d4K62DC0L9NTA3hK9hf3PKpzmOo	Allowed Admin	\N	admin	t	2026-11-15 10:13:41.297142+05:30	2026-11-15 10:13:41.297142+05:30
e266a19c-667d-4557-9196-c43eae1b1040	reuse_7bb78dc8@example.com	$argon2id$v=19$m=65536,t=3,p=4$aspoDWzdZIwyOxBEa91gYA$3/rFirhR61biR0NwnVdVCwGTS/cA30zUEdy/flj2c3w	Reuse Test	\N	customer	t	2026-11-15 10:13:41.465282+05:30	2026-11-15 10:13:41.465282+05:30
0ff0556b-8248-4455-8073-4e1765c3d677	logout_3bf4c90a@example.com	$argon2id$v=19$m=65536,t=3,p=4$VYTmUXZzbytM//ajo/UqYA$Ss/xatClgt/CAgb0IIoIzq3O+94DyTEkikGs6HOg/bs	Logout Test	\N	customer	t	2026-11-15 10:13:41.693184+05:30	2026-11-15 10:13:41.693184+05:30
9ea7696d-2838-4e4c-8921-877232c31ae7	chg_pwd_5c1cb407@example.com	$argon2id$v=19$m=65536,t=3,p=4$oamROFqhDJGHAtktcYZe6w$t+tM5LBidWbaopqt8SymvGjsFnScMiqTGpPRKEXr630	Change Password Test	\N	customer	t	2026-11-15 10:13:41.899061+05:30	2026-11-15 10:13:42.404656+05:30
91c28447-9824-46ef-80c6-24ae27acbaee	rate_0_ccd6d2@example.com	$argon2id$v=19$m=65536,t=3,p=4$pJaqtQyLBkjNpPxN2dMbhQ$+4bl9mk8GVZ9Jc27BWAmSk/9lp3jwxtVnsgOxCHtlRc	Rate Limit Test	\N	customer	t	2026-11-15 10:13:42.910877+05:30	2026-11-15 10:13:42.910877+05:30
6158010b-2859-47c9-8a8b-2f9a68e19970	rate_1_c90b10@example.com	$argon2id$v=19$m=65536,t=3,p=4$hdox7v1HLt7SyUq3yxF6bA$rEDixaDtamjWtbRiibcG5epGCxxEGyoGisohDS2+ljE	Rate Limit Test	\N	customer	t	2026-11-15 10:13:43.064527+05:30	2026-11-15 10:13:43.064527+05:30
c71080b7-aa9f-4ca8-abbf-8190032c5004	rate_2_277746@example.com	$argon2id$v=19$m=65536,t=3,p=4$LID9GMcClTnsfgnptZTTPQ$dMC4WzcmuZB+9p+LQshvYeK/KQj7uBsBzn3Gi0zy9WE	Rate Limit Test	\N	customer	t	2026-11-15 10:13:43.220784+05:30	2026-11-15 10:13:43.220784+05:30
28dd8fc5-3542-4c1f-8310-3e2355819f3b	rate_3_7cefb5@example.com	$argon2id$v=19$m=65536,t=3,p=4$9alwEnEcS59UIDSEXfvgTA$Xz9UKtwcqHuMmKLqRIBd5sNLVYwfXqlvg6TDWfoExjU	Rate Limit Test	\N	customer	t	2026-11-15 10:13:43.37153+05:30	2026-11-15 10:13:43.37153+05:30
c3185614-5c4d-422b-9f8c-e3256d1a89eb	rate_4_04c142@example.com	$argon2id$v=19$m=65536,t=3,p=4$gzTbMARgo+4phCL/dlofWw$y0lVWVjXJ2BMW03TTlokDmI8NaE9RJ4XdojatIITmVk	Rate Limit Test	\N	customer	t	2026-11-15 10:13:43.526352+05:30	2026-11-15 10:13:43.526352+05:30
d46883a0-f5c2-45c8-832a-e60146576fd7	rate_5_3d8484@example.com	$argon2id$v=19$m=65536,t=3,p=4$uz0X6iEEcHRs4qq1xyY8Jw$TN+x9MN+/p6JffPa8a3nwtdEyM+cuNg5STH75hHbVKs	Rate Limit Test	\N	customer	t	2026-11-15 10:13:43.703372+05:30	2026-11-15 10:13:43.703372+05:30
f10701c9-c7a7-43b4-8a9c-7284a0ac0671	rate_6_a43a0f@example.com	$argon2id$v=19$m=65536,t=3,p=4$FezQN+0gd+Mt9EoxcO3Baw$x+hnCyiuKO6B2UNimncRwfqmFD5X8MHOpnVwlXKEN8Y	Rate Limit Test	\N	customer	t	2026-11-15 10:13:43.857883+05:30	2026-11-15 10:13:43.857883+05:30
55da96ea-7dcb-4e92-94c9-c31678caf1b1	rate_7_a34bd9@example.com	$argon2id$v=19$m=65536,t=3,p=4$G/AYsNu/LgcXzNKplsD71g$Gfiw1nd1a2XaWPsTJvwPCllHNdbklDqUh3cOM2cdhuE	Rate Limit Test	\N	customer	t	2026-11-15 10:13:44.0301+05:30	2026-11-15 10:13:44.0301+05:30
6a2dffff-c4ef-4a1a-9f46-3929603ab9f2	rate_8_12b8e1@example.com	$argon2id$v=19$m=65536,t=3,p=4$B+QMP18soBahY1K1QwXCwA$W/ipPa1LlxfV850m0/MsaSLoZDP0rKNrRWqOHYGjBFY	Rate Limit Test	\N	customer	t	2026-11-15 10:13:44.196656+05:30	2026-11-15 10:13:44.196656+05:30
99b96be9-200e-4997-9013-a9b64a279738	rate_9_995d64@example.com	$argon2id$v=19$m=65536,t=3,p=4$f7gYvGCWtkFuyAuiMRAXOA$1MMF7eAnPpI5hrwSckTA2AdBx2DoASkwXemWs8honW4	Rate Limit Test	\N	customer	t	2026-11-15 10:13:44.359004+05:30	2026-11-15 10:13:44.359004+05:30
bbe4f946-e2f1-4ffe-ad03-d59dd61f549a	reviews_customer@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$L0iXc3ugkdljbFPnW288jw$jzjqdSdCf2tnIi12NQb/bVmTm9Mq/DnWCC8VDwBZvo8	Reviews Customer	\N	customer	t	2026-11-15 10:13:47.288463+05:30	2026-11-15 10:13:47.288463+05:30
a5cd818b-efbd-461c-bf1f-2ae6319c826e	reviews_admin@stitchstyle.com	$argon2id$v=19$m=65536,t=3,p=4$pscRAHfrzB4CYU9ZwVElhw$MPnCy4/DKtTcFXl68PInY+4xqCr5UsPreGcg+Kyssc8	Reviews Admin	\N	admin	t	2026-11-15 10:13:47.458322+05:30	2026-11-15 10:13:47.458322+05:30
40e8a082-4ff3-4b59-b6f6-80054cb6004a	cust_6d4d4db9@example.com	$argon2id$v=19$m=65536,t=3,p=4$8PNRc/RiOa+OUfiexvx4+g$C/OJT5PtKuc1ye/ejti2qbsyGI380gzSgVd2rQn8wIQ	Test Customer	+919876543210	customer	t	2026-11-15 10:14:13.882945+05:30	2026-11-15 10:14:13.882945+05:30
62bce4be-70f7-4ba6-ab46-fe6639cb7c0c	hashcheck_48fa40c2@example.com	$argon2id$v=19$m=65536,t=3,p=4$gC+Cp18+mux6fE9KsmYZrA$LzYIL/FZ1RsLhXpROGf1L2EO44Jo3JDYCkJTavjMpbc	Hash Checker	\N	customer	t	2026-11-15 10:14:14.039357+05:30	2026-11-15 10:14:14.039357+05:30
6319caae-9617-45b4-a559-2e6cee39cce4	dup_ad31b544@example.com	$argon2id$v=19$m=65536,t=3,p=4$U+FlJVx4rbB3qMIs384U3w$viYSCgyXfQKT4np5pkc+ZcKIKsOYa8QqgbBloynf6TI	Duplicate User	\N	customer	t	2026-11-15 10:14:14.32075+05:30	2026-11-15 10:14:14.32075+05:30
b7140cf3-69fb-4a48-9a42-0efe42e3bc58	login_cust_e1a046e9@example.com	$argon2id$v=19$m=65536,t=3,p=4$RxGQ+wdF8G/Gda+FWoB2Nw$4L+1bQBhklG92BqR7siB+ibjjSZBxes/FkePCS1tEgY	Customer Login Test	\N	customer	t	2026-11-15 10:14:14.4897+05:30	2026-11-15 10:14:14.4897+05:30
c205dc72-02a1-43d9-b1e4-47037ca44d57	admin_8fa33ead@example.com	$argon2id$v=19$m=65536,t=3,p=4$DEDFcON7/BsGFnfiIPAcVA$8zPyey25/GIar2up0dE/2H2hRXFG6/sLJVnt2BoUud8	Admin User	\N	admin	t	2026-11-15 10:14:14.786784+05:30	2026-11-15 10:14:14.786784+05:30
fca802ad-5f4d-4bfa-a338-f37cfa951936	existing_c66a93e9@example.com	$argon2id$v=19$m=65536,t=3,p=4$lPuEM1Qgz69Q1/RDqT7TYQ$ueOruC1vnk4lsvCBTnOjIrIkVn1kCP0QXnGCD0oalLk	Existing	\N	customer	t	2026-11-15 10:14:15.180853+05:30	2026-11-15 10:14:15.180853+05:30
13d8f9bd-c445-4fea-bb8c-2a1568d6e7c4	inactive_64ab4ed7@example.com	$argon2id$v=19$m=65536,t=3,p=4$9xQ6BX6tnI6DbrURNXxE9A$xiyKheMwP9nl8xfaK638Nf8kXVvF1IsMa3kQq0g4nFI	Inactive User	\N	customer	f	2026-11-15 10:14:15.464798+05:30	2026-11-15 10:14:15.464798+05:30
45b303de-74ac-4594-b56b-42762430554f	cust_block_54e551e1@example.com	$argon2id$v=19$m=65536,t=3,p=4$a1jgjsDqhXmv3Af0gmGzOA$PCqzB1ACCRSRu1G5rujPzptiCj4BskoTE2HGSrFzefs	Blocked Customer	\N	customer	t	2026-11-15 10:14:15.765832+05:30	2026-11-15 10:14:15.765832+05:30
b0b8506c-2cf2-47d1-b940-a1af84237286	admin_allow_2f947980@example.com	$argon2id$v=19$m=65536,t=3,p=4$E1K8m5Iat5GvnqExkj761Q$ZZGRYV3XYsmpmGB14OCJUpPRhP2F71WmC4U3jTiXQko	Allowed Admin	\N	admin	t	2026-11-15 10:14:15.98455+05:30	2026-11-15 10:14:15.98455+05:30
97ad8c73-e604-47e6-9fea-bab1de86fe6a	reuse_2fe2aab0@example.com	$argon2id$v=19$m=65536,t=3,p=4$1dTSEkedO6ZJU9iMCVlqyg$owPtGTFcP6B9RmRsRMnzv1BpSSIPG2XK+kHEIHZFwy0	Reuse Test	\N	customer	t	2026-11-15 10:14:16.166833+05:30	2026-11-15 10:14:16.166833+05:30
76fcd6c5-d97b-4151-9b42-5bf45166238e	logout_0767b178@example.com	$argon2id$v=19$m=65536,t=3,p=4$2K77U91N4T4K80L7g91bJw$jVZkB/XXtEj/02k+hhtMZ5bpnQfOF1X9PurwUQD+uRM	Logout Test	\N	customer	t	2026-11-15 10:14:16.39918+05:30	2026-11-15 10:14:16.39918+05:30
4912744b-7641-494c-98b8-0a806517f294	chg_pwd_5a3c449b@example.com	$argon2id$v=19$m=65536,t=3,p=4$y5fFpUTIIrKE8fFYjljUoA$quvD+VomHlKXHBr/uzxwgWD3kFmWUcEyyDviW2wjd1U	Change Password Test	\N	customer	t	2026-11-15 10:14:16.596583+05:30	2026-11-15 10:14:17.0321+05:30
cc06d8b8-de68-4232-95da-1393dd016a21	rate_0_c2cc18@example.com	$argon2id$v=19$m=65536,t=3,p=4$32A6kSXfZoHXBIofxyxltQ$CqP7U1q4gJtfIlpK6tbyYRplpRQXp0jwgd6AoqagswI	Rate Limit Test	\N	customer	t	2026-11-15 10:14:17.463379+05:30	2026-11-15 10:14:17.463379+05:30
966bc9e7-f2b0-415c-bcc2-2a33d6f3933e	rate_1_c9566d@example.com	$argon2id$v=19$m=65536,t=3,p=4$epukjSqBoBAo7uwdBuOMEA$MAYiHqyRcT7YTMvvj8B5RA0Dzk00QV/aXuLOoBKiNIw	Rate Limit Test	\N	customer	t	2026-11-15 10:14:17.615005+05:30	2026-11-15 10:14:17.615005+05:30
920fea38-9162-452d-a4c5-d84e99e04469	rate_2_4b6fe9@example.com	$argon2id$v=19$m=65536,t=3,p=4$fASkSREfpiSUC/MwIpUjXQ$G0FaQ/zJdMfSmmMZocWs+G36F2RYdqu7nWMoSr1hq8w	Rate Limit Test	\N	customer	t	2026-11-15 10:14:17.771745+05:30	2026-11-15 10:14:17.771745+05:30
64ad93c0-b465-47dc-b5c1-77c32a691aa6	rate_3_d00d36@example.com	$argon2id$v=19$m=65536,t=3,p=4$xOw4kSSdg9H5QznHfkeLKA$mXBs4DEWTIQm4F2R9m+AQDWfPaaBpJ53BfWlpqot094	Rate Limit Test	\N	customer	t	2026-11-15 10:14:17.968097+05:30	2026-11-15 10:14:17.968097+05:30
a7234ea4-0c80-4b89-99e3-65a81d7ba785	rate_4_b62f45@example.com	$argon2id$v=19$m=65536,t=3,p=4$aZYAWBM2aJcp463/ATkelQ$LEl3dNAv1ajjFjpdSU82SbMG5lP7FOsBXu1ZJ6j3Y4A	Rate Limit Test	\N	customer	t	2026-11-15 10:14:18.143911+05:30	2026-11-15 10:14:18.143911+05:30
8ad8cd75-f852-4ac4-b829-aaed729838a9	rate_5_e2bce6@example.com	$argon2id$v=19$m=65536,t=3,p=4$IVMlbTYeH98esl9MgV58SA$uOvfXeL3nn0ENQ5SAKBBLjqMoKhSyyWHb4C46CSAw/E	Rate Limit Test	\N	customer	t	2026-11-15 10:14:18.31291+05:30	2026-11-15 10:14:18.31291+05:30
67ac7719-e28e-425d-a2a3-d90ac1ddb5fa	rate_6_c83f5f@example.com	$argon2id$v=19$m=65536,t=3,p=4$Zu8Ap4OELtuqcbX1JHXqaA$T+JSSXVg2fDqEhDjyW+TjYj241d10UimfbCuTSdIPKw	Rate Limit Test	\N	customer	t	2026-11-15 10:14:18.466394+05:30	2026-11-15 10:14:18.466394+05:30
a0d1c040-8d97-437c-867f-014b13ce7f37	rate_7_88b42d@example.com	$argon2id$v=19$m=65536,t=3,p=4$bHiLFg27npeMYsrHyIFMIw$vyUJsIv40onrLVPzhLf1k6PAQ6okEDjqVYTyJ8aEnaY	Rate Limit Test	\N	customer	t	2026-11-15 10:14:18.621882+05:30	2026-11-15 10:14:18.621882+05:30
80c52a2a-e213-4d3c-9ec4-7914c6176c3e	rate_8_028b88@example.com	$argon2id$v=19$m=65536,t=3,p=4$nQx2NwHqtjOe60pQSkxMVw$FvDa6maJQYm/xi5vhNpde2BQWIeJVr+NYx7s8td4ErY	Rate Limit Test	\N	customer	t	2026-11-15 10:14:18.775751+05:30	2026-11-15 10:14:18.775751+05:30
fe8a3a1f-9206-4b8e-92ee-28f5a466e965	rate_9_0dc9c0@example.com	$argon2id$v=19$m=65536,t=3,p=4$w3HtnxXk/ERMvwTNpAhiVQ$oc/QvXs57rw5jqciXuIe0d1ije+gE7hYXYrMvx+HDnk	Rate Limit Test	\N	customer	t	2026-11-15 10:14:18.939989+05:30	2026-11-15 10:14:18.939989+05:30
5a298b8f-5343-456e-bf6d-7c2d50f5dbf7	cust_66c99f64@example.com	$argon2id$v=19$m=65536,t=3,p=4$goqa3FyYCGsgHmSDQvDKog$/xsjgcKlVBp9X9shD6uRZk7YDw8lkDLFGJxklQyN6fM	Test Customer	+919876543210	customer	t	2026-11-15 10:14:44.488698+05:30	2026-11-15 10:14:44.488698+05:30
efcfe59c-f6dd-4cae-b3e9-c7d1b7df84e1	hashcheck_bdce68b8@example.com	$argon2id$v=19$m=65536,t=3,p=4$vqhs2NDWtWQJNkHz3QA2Aw$DTKRmur/BsQ593bXXRKUmyCJoirHV1Wx9t8QR8ExtNk	Hash Checker	\N	customer	t	2026-11-15 10:14:44.637009+05:30	2026-11-15 10:14:44.637009+05:30
1b11680b-8a45-493e-bd22-31b3e23efb9e	dup_2e3a92c6@example.com	$argon2id$v=19$m=65536,t=3,p=4$/S1hye8RQI+ucNcfE20rSQ$YvjdeCB41DUY8MTS6nUVqVEngvQpNInBJ1Iu2yNV8O4	Duplicate User	\N	customer	t	2026-11-15 10:14:44.772514+05:30	2026-11-15 10:14:44.772514+05:30
f22fa7ec-1992-442a-8a0b-db3ce7aaa607	login_cust_cd9ee9d6@example.com	$argon2id$v=19$m=65536,t=3,p=4$lMNjV4dvXp4lnefPlFGHfw$MwgwNROI8Tsmce1pzBjHAybacv2ww030nPrqf4TD17M	Customer Login Test	\N	customer	t	2026-11-15 10:14:44.920222+05:30	2026-11-15 10:14:44.920222+05:30
063b07b3-4ee8-42f6-a7fe-2e1044f43c03	admin_db032d3a@example.com	$argon2id$v=19$m=65536,t=3,p=4$gJBvU8q1sOjU1KNL6l3eKQ$BDpRSzDyyDALsxMWxTTLQ254U7jVSYoe/M1W7wrM9NM	Admin User	\N	admin	t	2026-11-15 10:14:45.288923+05:30	2026-11-15 10:14:45.288923+05:30
c519c08f-adfe-4301-9411-99fa4e752784	existing_5d47d6b8@example.com	$argon2id$v=19$m=65536,t=3,p=4$IaD/63Ob3LAIBopKxDkn0w$u1EYVC1eSRQFgSjxc+CdTV6gRZi3UoEAITl/934oqI8	Existing	\N	customer	t	2026-11-15 10:14:45.609184+05:30	2026-11-15 10:14:45.609184+05:30
a60918b2-c17d-459d-a306-d046e73f95a8	inactive_b0bcd158@example.com	$argon2id$v=19$m=65536,t=3,p=4$JdYQr5OfgaXSme2MRV5E5w$KpylBBQl7OdSvaOE6wTkyQVRWncPkvtiZAyhn13a8dg	Inactive User	\N	customer	f	2026-11-15 10:14:45.898461+05:30	2026-11-15 10:14:45.898461+05:30
60224df6-72b3-4297-82bc-a70eb9b8dfec	cust_block_5ac97cac@example.com	$argon2id$v=19$m=65536,t=3,p=4$IQdsx9zeBCAoqPrMW0wsIw$17bANfnhqm74WjxcvnMIqcBxvY3sWdJJOOMSFTwuc9s	Blocked Customer	\N	customer	t	2026-11-15 10:14:46.172169+05:30	2026-11-15 10:14:46.172169+05:30
73c29983-5c6c-47f7-9165-fb42e3740803	admin_allow_f5fb95cd@example.com	$argon2id$v=19$m=65536,t=3,p=4$MQvuKGZlYP42vulHabLQVg$iKA/K1pSMgJYpkq95me5owFj+hU7KuHzZsJhXmFQe2o	Allowed Admin	\N	admin	t	2026-11-15 10:14:46.37981+05:30	2026-11-15 10:14:46.37981+05:30
8b41741b-ae73-48a1-b2f6-099c92184111	reuse_d4c65b80@example.com	$argon2id$v=19$m=65536,t=3,p=4$nJCLovhv39Ot4CDR5N8Yiw$2Ry/ZT0lWSQjgomPVVkJ1qXPm78oE4e5tn0IxeVZTg0	Reuse Test	\N	customer	t	2026-11-15 10:14:46.552966+05:30	2026-11-15 10:14:46.552966+05:30
3b2098d7-56e6-48d1-ab55-aad04c1662b9	logout_1ac2c1ce@example.com	$argon2id$v=19$m=65536,t=3,p=4$YZcKGLibXU2f+28j8Y0wUw$YUUUmCsjb+TgYivgmkz9bxmb3Npm4v9GVgfS9BuYXFQ	Logout Test	\N	customer	t	2026-11-15 10:14:46.771579+05:30	2026-11-15 10:14:46.771579+05:30
b9d3f611-9539-4205-b471-14201c5f5a9d	chg_pwd_06da95f7@example.com	$argon2id$v=19$m=65536,t=3,p=4$2Lb6xF6QHp25DqLRN8bJsw$PCCmU0t4Cw9gPmz0ItcLZzojLC4OChO/mRA+NBGfpyg	Change Password Test	\N	customer	t	2026-11-15 10:14:46.95519+05:30	2026-11-15 10:14:47.386063+05:30
a76f062f-1437-4009-82e0-f8027e4210ac	rate_0_ce626d@example.com	$argon2id$v=19$m=65536,t=3,p=4$o8FRkNND7/7SH2IGw89DEw$alP/26FC0HdLMIfTwpiUi6vQD4j/XcHpXv8DY+5rnEM	Rate Limit Test	\N	customer	t	2026-11-15 10:14:47.824153+05:30	2026-11-15 10:14:47.824153+05:30
7d429a53-084f-4278-a9fa-6bf97f9b2242	rate_1_beded4@example.com	$argon2id$v=19$m=65536,t=3,p=4$tZe7CbHGEXBn2CstIgr9rA$nyUhD8MM+JtSVoXw7BlhZcaHqepdlaNkWPz+c957eC8	Rate Limit Test	\N	customer	t	2026-11-15 10:14:47.975823+05:30	2026-11-15 10:14:47.975823+05:30
43c8ed99-30b6-419a-94e3-7255012aafa4	rate_2_3eb581@example.com	$argon2id$v=19$m=65536,t=3,p=4$BgLoC24F8fZHR0hqL5UJwg$REr8/z8x07LhslBiEhI8Ol77Z2uvvh/CDqjSF8GgLLk	Rate Limit Test	\N	customer	t	2026-11-15 10:14:48.142627+05:30	2026-11-15 10:14:48.142627+05:30
fb188179-7c4d-4b80-8f88-345042174c60	rate_3_83f745@example.com	$argon2id$v=19$m=65536,t=3,p=4$Mhl41iGk6wPS1il/llD9jw$7jW/CCkVU9/DPwIkUwYk3DXj0021/tssAiNDM88movI	Rate Limit Test	\N	customer	t	2026-11-15 10:14:48.348687+05:30	2026-11-15 10:14:48.348687+05:30
45f8232a-f992-49fc-b8e0-277b1a2dec21	rate_4_b926b0@example.com	$argon2id$v=19$m=65536,t=3,p=4$UUHFHfYgbIPLE+Ztquhi3g$RJnIXRDiYVbPMoH5LhMjdFGSQI/Vh2K5dAJYTnMan5Q	Rate Limit Test	\N	customer	t	2026-11-15 10:14:48.576356+05:30	2026-11-15 10:14:48.576356+05:30
ef9df25b-9a86-4559-9f42-48b410a4fc49	rate_5_82eff6@example.com	$argon2id$v=19$m=65536,t=3,p=4$RLz63dA25PwvSmAQmxXcLg$yY6ks9L4BAJRnWw4/zIwS1peqlYBHjldYEvuJIZBef8	Rate Limit Test	\N	customer	t	2026-11-15 10:14:48.771314+05:30	2026-11-15 10:14:48.771314+05:30
d493499a-43ad-411d-a0e6-fefa6fb25f83	rate_6_31f518@example.com	$argon2id$v=19$m=65536,t=3,p=4$9FWTzkD2KShc6pnUEmTWqg$UhFiN/byJHh3GGwFvusGYnBiEMFpa2AE3GVdVv2tABQ	Rate Limit Test	\N	customer	t	2026-11-15 10:14:48.963726+05:30	2026-11-15 10:14:48.963726+05:30
33923beb-3ae1-4789-b035-5b2b146c63e9	rate_7_6a69b6@example.com	$argon2id$v=19$m=65536,t=3,p=4$ONenX36RSdTaOXjtkR1YQA$1T2DcJ/pzEzp/FfmRm2AMc4SWSN46/B2ZaP3C2R0aAQ	Rate Limit Test	\N	customer	t	2026-11-15 10:14:49.163786+05:30	2026-11-15 10:14:49.163786+05:30
e5758ca4-3f39-40c9-9ce1-f3db23e0312c	rate_8_f9e041@example.com	$argon2id$v=19$m=65536,t=3,p=4$e1HfYyEC6CMcDg5CCotqrA$d6uICUvZjPTiec7mTES3Zn7nKFGnI+ZoEhJD+qA2zYw	Rate Limit Test	\N	customer	t	2026-11-15 10:14:49.353221+05:30	2026-11-15 10:14:49.353221+05:30
e849a903-d79e-4a1f-b969-17d1d0ffd0a5	rate_9_aae516@example.com	$argon2id$v=19$m=65536,t=3,p=4$UHGHfarT98RfyAwwit9yxw$oq5zODe51Q9FcRnYU38iStgCBPtGNl4nKpLPDUMarr8	Rate Limit Test	\N	customer	t	2026-11-15 10:14:49.525811+05:30	2026-11-15 10:14:49.525811+05:30
34e7a7da-b44b-4467-a7bd-0d222f434eac	cust_6d629551@example.com	$argon2id$v=19$m=65536,t=3,p=4$CrjvfmDUnvbiYiS73n2oyg$HeyanIa/v2JaAzf4hw/l1CKV61PfFQiA38D0jQDDrPA	Test Customer	+919876543210	customer	t	2026-11-15 10:29:46.965521+05:30	2026-11-15 10:29:46.965521+05:30
01db5886-49f4-47f0-8a02-c7096378fbc9	hashcheck_1c5383f6@example.com	$argon2id$v=19$m=65536,t=3,p=4$CUruwEK8Y83981zGnhfbUg$gl2C/BG5P0T+tHKPxg7t35CqZjp0elMEPJFuy5HE+B8	Hash Checker	\N	customer	t	2026-11-15 10:29:47.110044+05:30	2026-11-15 10:29:47.110044+05:30
a3b659d0-f06c-44ac-a900-c2c19d52adce	dup_bd20cf73@example.com	$argon2id$v=19$m=65536,t=3,p=4$0+BBOBgkb4acE5599sGQ7g$UkSnUpBzu6FEcnUitXVOsQYN1M3hkhoPFPwRhD3/ows	Duplicate User	\N	customer	t	2026-11-15 10:29:47.348173+05:30	2026-11-15 10:29:47.348173+05:30
c0af8f1f-626c-4c92-80b1-068ee1985b63	login_cust_1d6c4430@example.com	$argon2id$v=19$m=65536,t=3,p=4$mtoIWWETNp01I6BVZ7W0rg$LkGsjh5wxxrftv2AoNzES11XRexQ9nEI2BA/3OF4oxo	Customer Login Test	\N	customer	t	2026-11-15 10:29:47.499554+05:30	2026-11-15 10:29:47.499554+05:30
8403286e-0972-4b60-a972-b0f490238d65	admin_d6a00337@example.com	$argon2id$v=19$m=65536,t=3,p=4$G5UPRfODTE9KHnIBJwS0nA$W3G8JgpEiZ+FRGbUuMxPdjzLHLH2BAWKJYk3hTrLdyA	Admin User	\N	admin	t	2026-11-15 10:29:47.789624+05:30	2026-11-15 10:29:47.789624+05:30
2e8f579e-cf82-4bb6-b3b3-8cd7373c9783	existing_c71a8f4f@example.com	$argon2id$v=19$m=65536,t=3,p=4$E0xt/4tpa0dH2HGfs7YoEQ$Ayn8inigeoLqeLG3QT2R9AyZ11T/uJ9bCXtNRFg1wkQ	Existing	\N	customer	t	2026-11-15 10:29:48.104766+05:30	2026-11-15 10:29:48.104766+05:30
91c52549-5d36-4651-b008-3b31adecc6e3	inactive_9e1ead95@example.com	$argon2id$v=19$m=65536,t=3,p=4$3rYWFWBLyP/cPGd2fMCknQ$f6+FQOtol8yVUL38vltTrl8MkXIdALQiUMO9Q5/IKLQ	Inactive User	\N	customer	f	2026-11-15 10:29:48.457656+05:30	2026-11-15 10:29:48.457656+05:30
b090c6a9-cc45-424c-85cd-23f623fd7f08	cust_block_0999aad6@example.com	$argon2id$v=19$m=65536,t=3,p=4$cMqyE5+Amh2DaFH6Bk7SSw$xhdzmriEcWDky1Fv65oZ62YDMia29iDNN5sfMD41YNU	Blocked Customer	\N	customer	t	2026-11-15 10:29:48.873989+05:30	2026-11-15 10:29:48.873989+05:30
a52e0602-2eb6-4069-8f05-030129083d26	admin_allow_5d38fc62@example.com	$argon2id$v=19$m=65536,t=3,p=4$nW57qbJlIhBFcoQ691bnug$U7PorYeeZ3aOqhPZ3Myuisqu+l53D6m2Qxvnj2wm20Q	Allowed Admin	\N	admin	t	2026-11-15 10:29:49.133799+05:30	2026-11-15 10:29:49.133799+05:30
91b328b2-e6f1-4d2e-a00d-794b26a45808	reuse_16c1fd69@example.com	$argon2id$v=19$m=65536,t=3,p=4$KYFRnFzQMOh5u79qr0bdCw$RalJzhDm7h+BRbMon7OVkfwww3J2PGxLMhyA4cnyJJw	Reuse Test	\N	customer	t	2026-11-15 10:29:49.356374+05:30	2026-11-15 10:29:49.356374+05:30
4c294885-a375-48f9-96ec-6538f2032bff	logout_56561022@example.com	$argon2id$v=19$m=65536,t=3,p=4$am8vB05kLu+qJPL2uGddgA$j0D/+9o/FpBhNQsXlJ9nFAVrT0A3A43Bzx08E5+PKGo	Logout Test	\N	customer	t	2026-11-15 10:29:49.642349+05:30	2026-11-15 10:29:49.642349+05:30
0a2bae51-cb61-4140-97bf-eef598e3cceb	chg_pwd_5760350b@example.com	$argon2id$v=19$m=65536,t=3,p=4$gIrVymLB7H75ZIwOXNowRA$RVIg59i/rdSgIXsXMeTKRdlg/hw/Dim5yXHLEj0F1Vs	Change Password Test	\N	customer	t	2026-11-15 10:29:49.904894+05:30	2026-11-15 10:29:50.50121+05:30
48fa2700-435b-44eb-8d66-28ea8fa26e29	rate_0_293a0f@example.com	$argon2id$v=19$m=65536,t=3,p=4$NPefnzUXV2IdokvxbxFLag$tZ4rn1D4UbWEK/bulfAYTxWSkzzAoemVXxRep8+4b4M	Rate Limit Test	\N	customer	t	2026-11-15 10:29:51.133666+05:30	2026-11-15 10:29:51.133666+05:30
ec3951c4-6668-4f2a-bef8-caff51a3ed87	rate_1_673f1a@example.com	$argon2id$v=19$m=65536,t=3,p=4$MjZMf9QwL5Zd4PvEr+litg$DKVmXZqLy436SnNC2uN/JFJEsa6AKxIiEguTu1JhRqM	Rate Limit Test	\N	customer	t	2026-11-15 10:29:51.348389+05:30	2026-11-15 10:29:51.348389+05:30
20d0f6a2-b9f5-4e47-ae60-346a03befcde	rate_2_400f9c@example.com	$argon2id$v=19$m=65536,t=3,p=4$QIzrOxQsCoNEqpiwltU+bg$At3vYHBbR7PwgOzjitdPKIuJX6uaGH/8qMrO2IAGOOo	Rate Limit Test	\N	customer	t	2026-11-15 10:29:51.571228+05:30	2026-11-15 10:29:51.571228+05:30
41bf8470-0bbd-4e5a-9b27-83d211f6994d	rate_3_1addb1@example.com	$argon2id$v=19$m=65536,t=3,p=4$bOsWLPaEOSD5SRH9IMfG6A$Lj2jBllupvkzBisJxkxKyq0Yzkt3aKXUSk4qu5j6RYo	Rate Limit Test	\N	customer	t	2026-11-15 10:29:51.803797+05:30	2026-11-15 10:29:51.803797+05:30
554c125e-f63f-4a54-abc2-6a7728c7d929	rate_4_41ec0e@example.com	$argon2id$v=19$m=65536,t=3,p=4$wt/wtftH93YCOWeh2grieQ$DmODzGNq01sSwpD9UyYkVHBCJShsk9zugqzJXMcNJ18	Rate Limit Test	\N	customer	t	2026-11-15 10:29:51.989272+05:30	2026-11-15 10:29:51.989272+05:30
e7460005-4dfe-4f26-921d-021788b0d43d	rate_5_b2b719@example.com	$argon2id$v=19$m=65536,t=3,p=4$/3GN+HzhEl0Zsk0w+ULMjw$jRBSZpi72Ju1lY+5LUXPEET7vdcmgkJtzUZrIK62/EA	Rate Limit Test	\N	customer	t	2026-11-15 10:29:52.185014+05:30	2026-11-15 10:29:52.185014+05:30
59ba0e40-9fda-48f8-bb8a-1ef48c3187e5	rate_6_0db1cb@example.com	$argon2id$v=19$m=65536,t=3,p=4$1PObpZ/yCsRXjvr6BabfaA$6prpA1gCnBL0d8+AxL0zOpp1H0SDdzdUiPV0SIEHvts	Rate Limit Test	\N	customer	t	2026-11-15 10:29:52.440151+05:30	2026-11-15 10:29:52.440151+05:30
98b4e5e4-54da-442b-841a-df54c43ef188	rate_7_9123ff@example.com	$argon2id$v=19$m=65536,t=3,p=4$9wuRdG1dVDxUKyf4DHcZDw$AFMHsoY2tX8lfKE/H+ygDtaYFTyVL6qXZFdpLts+5Jo	Rate Limit Test	\N	customer	t	2026-11-15 10:29:52.645459+05:30	2026-11-15 10:29:52.645459+05:30
dd002523-ad7b-409d-ae65-a5e9eed41c53	rate_8_f20a74@example.com	$argon2id$v=19$m=65536,t=3,p=4$ypoLYdL/I3RDWkf8StacoA$AB2P74GjU+z6MoJSHPdvAH4FmfPjae3pD4IsTGPcBkA	Rate Limit Test	\N	customer	t	2026-11-15 10:29:52.914553+05:30	2026-11-15 10:29:52.914553+05:30
35fd05a8-03a7-46ad-8439-02e918dfcbd8	rate_9_d963d2@example.com	$argon2id$v=19$m=65536,t=3,p=4$pJwrIWJrABeNphoGs0JOLw$qSo8aUP0L3pZo6huTZj4WrHDICPugrcNVkQwA9dx5AU	Rate Limit Test	\N	customer	t	2026-11-15 10:29:53.169484+05:30	2026-11-15 10:29:53.169484+05:30
\.


--
-- Name: addresses addresses_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_pkey PRIMARY KEY (id);


--
-- Name: alembic_version alembic_version_pkc; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.alembic_version
    ADD CONSTRAINT alembic_version_pkc PRIMARY KEY (version_num);


--
-- Name: categories categories_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.categories
    ADD CONSTRAINT categories_pkey PRIMARY KEY (id);


--
-- Name: delivery_rules delivery_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.delivery_rules
    ADD CONSTRAINT delivery_rules_pkey PRIMARY KEY (id);


--
-- Name: delivery_settings delivery_settings_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.delivery_settings
    ADD CONSTRAINT delivery_settings_pkey PRIMARY KEY (id);


--
-- Name: order_items order_items_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_pkey PRIMARY KEY (id);


--
-- Name: order_status_history order_status_history_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_pkey PRIMARY KEY (id);


--
-- Name: orders orders_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_pkey PRIMARY KEY (id);


--
-- Name: product_images product_images_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (id);


--
-- Name: refresh_tokens refresh_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_pkey PRIMARY KEY (id);


--
-- Name: reviews reviews_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_pkey PRIMARY KEY (id);


--
-- Name: reviews uq_product_customer_review; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT uq_product_customer_review UNIQUE (product_id, customer_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: idx_addresses_customer_default; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX idx_addresses_customer_default ON public.addresses USING btree (customer_id, is_default);


--
-- Name: idx_orders_customer_created; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX idx_orders_customer_created ON public.orders USING btree (customer_id, created_at);


--
-- Name: idx_product_images_product_primary; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX idx_product_images_product_primary ON public.product_images USING btree (product_id, is_primary);


--
-- Name: idx_products_category_active; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX idx_products_category_active ON public.products USING btree (category_id, is_active, is_available);


--
-- Name: idx_products_price; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX idx_products_price ON public.products USING btree (price);


--
-- Name: idx_reviews_product_visible; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX idx_reviews_product_visible ON public.reviews USING btree (product_id, is_visible);


--
-- Name: ix_addresses_customer_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_addresses_customer_id ON public.addresses USING btree (customer_id);


--
-- Name: ix_categories_is_active; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_categories_is_active ON public.categories USING btree (is_active);


--
-- Name: ix_categories_name; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_categories_name ON public.categories USING btree (name);


--
-- Name: ix_categories_slug; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_categories_slug ON public.categories USING btree (slug);


--
-- Name: ix_order_items_order_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_order_items_order_id ON public.order_items USING btree (order_id);


--
-- Name: ix_order_items_product_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_order_items_product_id ON public.order_items USING btree (product_id);


--
-- Name: ix_order_status_history_order_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_order_status_history_order_id ON public.order_status_history USING btree (order_id);


--
-- Name: ix_orders_created_at; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_orders_created_at ON public.orders USING btree (created_at);


--
-- Name: ix_orders_customer_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_orders_customer_id ON public.orders USING btree (customer_id);


--
-- Name: ix_orders_order_number; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_orders_order_number ON public.orders USING btree (order_number);


--
-- Name: ix_orders_status; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_orders_status ON public.orders USING btree (status);


--
-- Name: ix_product_images_cloudinary_public_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_product_images_cloudinary_public_id ON public.product_images USING btree (cloudinary_public_id);


--
-- Name: ix_product_images_is_primary; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_product_images_is_primary ON public.product_images USING btree (is_primary);


--
-- Name: ix_product_images_product_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_product_images_product_id ON public.product_images USING btree (product_id);


--
-- Name: ix_products_category_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_products_category_id ON public.products USING btree (category_id);


--
-- Name: ix_products_created_at; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_products_created_at ON public.products USING btree (created_at);


--
-- Name: ix_products_is_active; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_products_is_active ON public.products USING btree (is_active);


--
-- Name: ix_products_is_available; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_products_is_available ON public.products USING btree (is_available);


--
-- Name: ix_products_name; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_products_name ON public.products USING btree (name);


--
-- Name: ix_products_slug; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_products_slug ON public.products USING btree (slug);


--
-- Name: ix_refresh_tokens_expires_at; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_refresh_tokens_expires_at ON public.refresh_tokens USING btree (expires_at);


--
-- Name: ix_refresh_tokens_family_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_refresh_tokens_family_id ON public.refresh_tokens USING btree (family_id);


--
-- Name: ix_refresh_tokens_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_refresh_tokens_id ON public.refresh_tokens USING btree (id);


--
-- Name: ix_refresh_tokens_token_hash; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_refresh_tokens_token_hash ON public.refresh_tokens USING btree (token_hash);


--
-- Name: ix_refresh_tokens_user_expires; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_refresh_tokens_user_expires ON public.refresh_tokens USING btree (user_id, expires_at);


--
-- Name: ix_refresh_tokens_user_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_refresh_tokens_user_id ON public.refresh_tokens USING btree (user_id);


--
-- Name: ix_reviews_created_at; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_reviews_created_at ON public.reviews USING btree (created_at);


--
-- Name: ix_reviews_customer_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_reviews_customer_id ON public.reviews USING btree (customer_id);


--
-- Name: ix_reviews_is_visible; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_reviews_is_visible ON public.reviews USING btree (is_visible);


--
-- Name: ix_reviews_product_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_reviews_product_id ON public.reviews USING btree (product_id);


--
-- Name: ix_users_email; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_users_email ON public.users USING btree (email);


--
-- Name: ix_users_email_lower; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE UNIQUE INDEX ix_users_email_lower ON public.users USING btree (lower((email)::text));


--
-- Name: ix_users_id; Type: INDEX; Schema: public; Owner: stitch_admin
--

CREATE INDEX ix_users_id ON public.users USING btree (id);


--
-- Name: addresses addresses_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.addresses
    ADD CONSTRAINT addresses_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: order_items order_items_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.order_items
    ADD CONSTRAINT order_items_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE RESTRICT;


--
-- Name: order_status_history order_status_history_changed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_changed_by_user_id_fkey FOREIGN KEY (changed_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: order_status_history order_status_history_order_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.order_status_history
    ADD CONSTRAINT order_status_history_order_id_fkey FOREIGN KEY (order_id) REFERENCES public.orders(id) ON DELETE CASCADE;


--
-- Name: orders orders_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.orders
    ADD CONSTRAINT orders_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- Name: product_images product_images_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.product_images
    ADD CONSTRAINT product_images_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- Name: products products_category_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.categories(id) ON DELETE RESTRICT;


--
-- Name: refresh_tokens refresh_tokens_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.refresh_tokens
    ADD CONSTRAINT refresh_tokens_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_customer_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_customer_id_fkey FOREIGN KEY (customer_id) REFERENCES public.users(id) ON DELETE CASCADE;


--
-- Name: reviews reviews_product_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: stitch_admin
--

ALTER TABLE ONLY public.reviews
    ADD CONSTRAINT reviews_product_id_fkey FOREIGN KEY (product_id) REFERENCES public.products(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

\unrestrict zVILCGffbMTjSxr6EOHDbQzfZclhREDa0kxifXRumpAEIKIufqqYGPdBLidmIzW

