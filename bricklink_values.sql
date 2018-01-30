--
-- PostgreSQL database dump
--

-- Dumped from database version 10.1
-- Dumped by pg_dump version 10.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET search_path = public, pg_catalog;

--
-- Data for Name: bricklink_values; Type: TABLE DATA; Schema: public; Owner: kevinpersonal
--

COPY bricklink_values (id, retrieved_at, complete_set_new_listings_count, complete_set_new_avg_price, complete_set_new_median_price, complete_set_new_high_price, complete_set_new_low_price, complete_set_used_listings_count, complete_set_used_avg_price, complete_set_used_median_price, complete_set_used_high_price, complete_set_used_low_price, complete_set_completed_listing_new_listings_count, complete_set_completed_listing_new_avg_price, complete_set_completed_listing_new_median_price, complete_set_completed_listing_new_high_price, complete_set_completed_listing_new_low_price, complete_set_completed_listing_used_listings_count, complete_set_completed_listing_used_avg_price, complete_set_completed_listing_used_median_price, complete_set_completed_listing_used_high_price, complete_set_completed_listing_used_low_price, part_out_value_last_six_months_used, part_out_value_last_six_months_new, part_out_value_current_used, part_out_value_current_new, most_recent, lego_set_id, created_at, updated_at) FROM stdin;
3976	2018-01-26 03:24:20.307695	68	25.870000000000001	23.6900000000000013	31.870000000000001	20.4200000000000017	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1225	2018-01-26 03:24:20.310083	2018-01-26 03:24:20.310083
3960	2018-01-26 03:24:12.133164	137	32.1799999999999997	31.2300000000000004	49.5499999999999972	25.5899999999999999	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1214	2018-01-26 03:24:12.134838	2018-01-26 03:24:12.134838
3961	2018-01-26 03:24:12.213613	131	10.8000000000000007	10.4000000000000004	18	9.21000000000000085	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1212	2018-01-26 03:24:12.216192	2018-01-26 03:24:12.216192
3987	2018-01-26 03:24:27.089954	52	33.1000000000000014	31.2300000000000004	39.990000000000002	19.620000000000001	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1238	2018-01-26 03:24:27.092224	2018-01-26 03:24:27.092224
3962	2018-01-26 03:24:13.649046	131	21.0199999999999996	19.8299999999999983	27.4100000000000001	16.3200000000000003	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1216	2018-01-26 03:24:13.651417	2018-01-26 03:24:13.651417
3977	2018-01-26 03:24:20.529758	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1231	2018-01-26 03:24:20.532415	2018-01-26 03:24:20.532415
3963	2018-01-26 03:24:13.647455	101	54.4200000000000017	52.0499999999999972	75	44.0200000000000031	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1215	2018-01-26 03:24:13.65353	2018-01-26 03:24:13.65353
3964	2018-01-26 03:24:13.654521	223	9.23000000000000043	9.21000000000000085	16.1000000000000014	6.50999999999999979	0	\N	\N	\N	\N	5	6.42999999999999972	6.42999999999999972	6.42999999999999972	6.41000000000000014	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1218	2018-01-26 03:24:13.656996	2018-01-26 03:24:13.656996
3965	2018-01-26 03:24:14.057351	156	20.629999999999999	20.4699999999999989	27.4100000000000001	16.3200000000000003	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1217	2018-01-26 03:24:14.063749	2018-01-26 03:24:14.063749
3954	2018-01-26 03:24:10.279206	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1209	2018-01-26 03:24:10.51785	2018-01-26 03:24:10.51785
3957	2018-01-26 03:24:10.283738	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1208	2018-01-26 03:24:10.522048	2018-01-26 03:24:10.522048
3956	2018-01-26 03:24:10.469448	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1210	2018-01-26 03:24:10.520775	2018-01-26 03:24:10.520775
3955	2018-01-26 03:24:09.656415	141	214.090000000000003	183.389999999999986	458.45999999999998	176.52000000000001	0	\N	\N	\N	\N	19	184.409999999999997	191.159999999999997	200.710000000000008	167.990000000000009	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1207	2018-01-26 03:24:10.519372	2018-01-26 03:24:10.519372
3958	2018-01-26 03:24:11.911375	152	5.84999999999999964	5.20000000000000018	12.8000000000000007	5.00999999999999979	0	\N	\N	\N	\N	1	8.58000000000000007	8.58000000000000007	8.58000000000000007	8.58000000000000007	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1211	2018-01-26 03:24:11.913582	2018-01-26 03:24:11.913582
3959	2018-01-26 03:24:12.114837	115	21.0599999999999987	20.8099999999999987	28	18.4200000000000017	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1213	2018-01-26 03:24:12.116903	2018-01-26 03:24:12.116903
3978	2018-01-26 03:24:20.81903	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1232	2018-01-26 03:24:20.820985	2018-01-26 03:24:20.820985
3966	2018-01-26 03:24:15.186862	88	20.6700000000000017	19.8299999999999983	25.8500000000000014	16.3200000000000003	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1221	2018-01-26 03:24:15.188718	2018-01-26 03:24:15.188718
3967	2018-01-26 03:24:15.189154	122	10.25	9.91000000000000014	13.2200000000000006	8.13000000000000078	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1220	2018-01-26 03:24:15.191513	2018-01-26 03:24:15.191513
3968	2018-01-26 03:24:16.720676	90	28.2899999999999991	26.0199999999999996	37.1599999999999966	20.4200000000000017	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1219	2018-01-26 03:24:16.722372	2018-01-26 03:24:16.722372
3979	2018-01-26 03:24:21.96394	100	5.03000000000000025	5.05999999999999961	6.37000000000000011	3.24000000000000021	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1234	2018-01-26 03:24:21.965453	2018-01-26 03:24:21.965453
3969	2018-01-26 03:24:16.74477	89	20.8399999999999999	20.1600000000000001	25.8500000000000014	16.3200000000000003	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1223	2018-01-26 03:24:16.746443	2018-01-26 03:24:16.746443
3970	2018-01-26 03:24:16.927826	78	33.2199999999999989	30.7100000000000009	40	24.5199999999999996	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1224	2018-01-26 03:24:16.929608	2018-01-26 03:24:16.929608
3994	2018-01-26 03:24:28.92205	57	22.8399999999999999	22.370000000000001	28.6900000000000013	16.3200000000000003	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1247	2018-01-26 03:24:28.925566	2018-01-26 03:24:28.925566
3971	2018-01-26 03:24:17.754811	113	10.4700000000000006	10.2300000000000004	19	8.13000000000000078	0	\N	\N	\N	\N	1	8.02999999999999936	8.02999999999999936	8.02999999999999936	8.02999999999999936	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1222	2018-01-26 03:24:17.75791	2018-01-26 03:24:17.75791
3980	2018-01-26 03:24:22.249774	57	10.4600000000000009	10.4000000000000004	12.6099999999999994	6.50999999999999979	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1233	2018-01-26 03:24:22.251792	2018-01-26 03:24:22.251792
3972	2018-01-26 03:24:18.06176	62	22.870000000000001	20.4699999999999989	37.1599999999999966	17.3999999999999986	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1226	2018-01-26 03:24:18.063646	2018-01-26 03:24:18.063646
3973	2018-01-26 03:24:18.582847	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1227	2018-01-26 03:24:18.584576	2018-01-26 03:24:18.584576
3974	2018-01-26 03:24:19.287575	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1228	2018-01-26 03:24:19.289465	2018-01-26 03:24:19.289465
3981	2018-01-26 03:24:23.363788	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1230	2018-01-26 03:24:23.366032	2018-01-26 03:24:23.366032
3975	2018-01-26 03:24:19.376801	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1229	2018-01-26 03:24:19.378476	2018-01-26 03:24:19.378476
3988	2018-01-26 03:24:27.267134	54	34.490000000000002	38	39.990000000000002	24.5199999999999996	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1242	2018-01-26 03:24:27.269531	2018-01-26 03:24:27.269531
3989	2018-01-26 03:24:27.267937	94	24.1400000000000006	25	30.9200000000000017	13.0999999999999996	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1241	2018-01-26 03:24:27.271584	2018-01-26 03:24:27.271584
3982	2018-01-26 03:24:23.479878	59	21.5599999999999987	20.8099999999999987	26.4400000000000013	13.0999999999999996	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1236	2018-01-26 03:24:23.48201	2018-01-26 03:24:23.48201
3983	2018-01-26 03:24:23.580653	53	17.3999999999999986	15.8200000000000003	25	9.78999999999999915	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1237	2018-01-26 03:24:23.582678	2018-01-26 03:24:23.582678
3984	2018-01-26 03:24:24.916357	88	5.16999999999999993	5.01999999999999957	6.37000000000000011	3.24000000000000021	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1235	2018-01-26 03:24:24.918068	2018-01-26 03:24:24.918068
3990	2018-01-26 03:24:27.4794	60	70.8299999999999983	74.2800000000000011	82.2399999999999949	48.0700000000000003	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1243	2018-01-26 03:24:27.481303	2018-01-26 03:24:27.481303
3985	2018-01-26 03:24:25.231226	67	51.2999999999999972	48.2299999999999969	61.8299999999999983	34.4200000000000017	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1239	2018-01-26 03:24:25.233091	2018-01-26 03:24:25.233091
3986	2018-01-26 03:24:25.73259	46	25	22.5199999999999996	39.1300000000000026	16.3399999999999999	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1240	2018-01-26 03:24:25.734224	2018-01-26 03:24:25.734224
3999	2018-01-26 03:24:31.568619	104	19.6799999999999997	20	30.9600000000000009	15.3499999999999996	1	14.9900000000000002	14.9900000000000002	14.9900000000000002	14.9900000000000002	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1253	2018-01-26 03:24:31.570584	2018-01-26 03:24:31.570584
3991	2018-01-26 03:24:28.511882	50	11.4600000000000009	12.5	18.5199999999999996	8.13000000000000078	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1244	2018-01-26 03:24:28.513734	2018-01-26 03:24:28.513734
3992	2018-01-26 03:24:28.704176	59	30.3099999999999987	34.3100000000000023	37.1099999999999994	20.4200000000000017	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1245	2018-01-26 03:24:28.706911	2018-01-26 03:24:28.706911
3996	2018-01-26 03:24:30.04619	53	33.8699999999999974	32.5499999999999972	41.7199999999999989	24.5199999999999996	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1248	2018-01-26 03:24:30.048854	2018-01-26 03:24:30.048854
3993	2018-01-26 03:24:28.710186	47	34.7199999999999989	37.1599999999999966	42.5900000000000034	24.5199999999999996	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1246	2018-01-26 03:24:28.712568	2018-01-26 03:24:28.712568
3995	2018-01-26 03:24:30.044444	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1250	2018-01-26 03:24:30.047121	2018-01-26 03:24:30.047121
3997	2018-01-26 03:24:30.049771	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1249	2018-01-26 03:24:30.052641	2018-01-26 03:24:30.052641
4004	2018-01-26 03:24:33.469216	36	65.9300000000000068	73.9500000000000028	73.9500000000000028	37.990000000000002	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1258	2018-01-26 03:24:33.474826	2018-01-26 03:24:33.474826
3998	2018-01-26 03:24:30.241313	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1251	2018-01-26 03:24:30.243091	2018-01-26 03:24:30.243091
4003	2018-01-26 03:24:32.898938	87	25.4100000000000001	25	37.1599999999999966	20.4699999999999989	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1256	2018-01-26 03:24:32.900753	2018-01-26 03:24:32.900753
4000	2018-01-26 03:24:31.875841	104	19.7399999999999984	20	30.9600000000000009	15.3499999999999996	1	14.9900000000000002	14.9900000000000002	14.9900000000000002	14.9900000000000002	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1254	2018-01-26 03:24:31.879865	2018-01-26 03:24:31.879865
4001	2018-01-26 03:24:31.876353	76	25.7699999999999996	25	37.1599999999999966	20.4699999999999989	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1255	2018-01-26 03:24:31.881234	2018-01-26 03:24:31.881234
4002	2018-01-26 03:24:31.876632	137	61.2100000000000009	54.259999999999998	99.1099999999999994	48.4299999999999997	0	\N	\N	\N	\N	22	53.9099999999999966	53.9099999999999966	53.9099999999999966	53.9099999999999966	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1252	2018-01-26 03:24:31.883199	2018-01-26 03:24:31.883199
4005	2018-01-26 03:24:33.470666	44	80.2399999999999949	90.4699999999999989	105.310000000000002	54.8800000000000026	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1259	2018-01-26 03:24:33.481398	2018-01-26 03:24:33.481398
4006	2018-01-26 03:24:33.61863	58	51.509999999999998	51	57.7000000000000028	41.6400000000000006	0	\N	\N	\N	\N	0	\N	\N	\N	\N	0	\N	\N	\N	\N	\N	\N	\N	\N	t	1257	2018-01-26 03:24:33.62108	2018-01-26 03:24:33.62108
\.


--
-- Name: bricklink_values_id_seq; Type: SEQUENCE SET; Schema: public; Owner: kevinpersonal
--

SELECT pg_catalog.setval('bricklink_values_id_seq', 4006, true);


--
-- PostgreSQL database dump complete
--
