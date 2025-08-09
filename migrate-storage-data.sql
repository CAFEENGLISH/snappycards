-- STORAGE DATA MIGRATION SCRIPT
-- Generated: 2025-08-07T21:46:42.519Z
-- Source: ycxqxdhaxehspypqbnpi
-- Target: aeijlzokobuqcyznljvn

-- =============================================
-- STORAGE BUCKETS MIGRATION
-- =============================================

-- Create bucket: media
INSERT INTO storage.buckets (
  id, name, owner, public, avif_autodetection, file_size_limit, allowed_mime_types, created_at, updated_at
) VALUES (
  'media',
  'media',
  NULL,
  true,
  false,
  NULL,
  NULL,
  '2025-08-01 14:15:13.571133+00',
  '2025-08-01 14:15:13.571133+00'
) ON CONFLICT (id) DO NOTHING;

-- =============================================
-- STORAGE OBJECTS MIGRATION
-- =============================================

-- Objects for bucket: media (44 objects)
-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'bccf393b-3890-4af8-b49a-414534c3a18f',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 14:24:36.167845+00',
  '2025-08-01 14:24:36.167845+00',
  '2025-08-01 14:24:36.167845+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T14:24:37.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059274124_rsngpgsh86.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '9cf0d587-677c-4d20-a331-43c97d28d3d0',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059274124_rsngpgsh86.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 14:41:14.703899+00',
  '2025-08-01 14:41:14.703899+00',
  '2025-08-01 14:41:14.703899+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T14:41:15.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059833333_xufyxa7wr59.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '7f03d5c0-fb5a-4c56-aa87-31afe5137486',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059833333_xufyxa7wr59.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 14:50:33.892509+00',
  '2025-08-01 14:50:33.892509+00',
  '2025-08-01 14:50:33.892509+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T14:50:34.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754060396778_6pbj9admg3.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '66a3c9a6-2903-43e0-9357-1de6ea981e57',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754060396778_6pbj9admg3.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 14:59:57.314206+00',
  '2025-08-01 14:59:57.314206+00',
  '2025-08-01 14:59:57.314206+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T14:59:58.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_1rtayuayo9g.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '00be9e1d-7df3-4806-ade6-40d3342093fb',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_1rtayuayo9g.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 15:23:46.907186+00',
  '2025-08-01 15:23:46.907186+00',
  '2025-08-01 15:23:46.907186+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T15:23:47.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_x4hy0q16c1.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '7cf6255f-b9a2-4130-bff2-212f24e309dc',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_x4hy0q16c1.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 15:23:46.868763+00',
  '2025-08-01 15:23:46.868763+00',
  '2025-08-01 15:23:46.868763+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T15:23:47.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281219_hg669on57u5.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '141f686b-2162-46be-98a1-38e383e31845',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281219_hg669on57u5.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 15:48:01.837094+00',
  '2025-08-01 15:48:01.837094+00',
  '2025-08-01 15:48:01.837094+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T15:48:02.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281220_2gprfoihenf.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '77aa2a90-0e05-4477-bed3-4902a27d49b9',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281220_2gprfoihenf.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 15:48:01.847393+00',
  '2025-08-01 15:48:01.847393+00',
  '2025-08-01 15:48:01.847393+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-01T15:48:02.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_1dm8ruxy0t5.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '6faf46e8-e157-4fcc-bdd7-85a526bd4a3d',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_1dm8ruxy0t5.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 15:59:22.696319+00',
  '2025-08-03 15:59:22.696319+00',
  '2025-08-03 15:59:22.696319+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-03T15:59:23.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_kyl98gf7z8.jpeg
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '8112ffd8-28f9-4f6a-ba5c-12b60dcb8974',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_kyl98gf7z8.jpeg',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 15:59:22.683785+00',
  '2025-08-03 15:59:22.683785+00',
  '2025-08-03 15:59:22.683785+00',
  '{"eTag":"\"cbe9a40c9e4d9e8e591e04e8a2e9eacf\"","size":155174,"mimetype":"image/jpeg","cacheControl":"max-age=3600","lastModified":"2025-08-03T15:59:23.000Z","contentLength":155174,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754068707678_wiz0dsl0a1.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'b09b3ede-67df-4a5a-842f-6326b93cf785',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754068707678_wiz0dsl0a1.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:18:28.260286+00',
  '2025-08-01 17:18:28.260286+00',
  '2025-08-01 17:18:28.260286+00',
  '{"eTag":"\"3ed3babd8b6a52b768fee4714d5f5d61\"","size":230462,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:18:29.000Z","contentLength":230462,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754069851062_opc98k7pmni.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'e7138afa-35fc-4c2b-8e6e-37f97a9a15d7',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754069851062_opc98k7pmni.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:37:32.095232+00',
  '2025-08-01 17:37:32.095232+00',
  '2025-08-01 17:37:32.095232+00',
  '{"eTag":"\"4b268e8fc75417546bb151b311f2d2f6\"","size":1391886,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:37:32.000Z","contentLength":1391886,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070134534_h3klxvkio0i.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '35f5b617-4481-4766-a2fa-1336adb960b6',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070134534_h3klxvkio0i.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:42:15.606421+00',
  '2025-08-01 17:42:15.606421+00',
  '2025-08-01 17:42:15.606421+00',
  '{"eTag":"\"9333985ee23d2978876c0ffb0a0f5843\"","size":1430225,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:42:16.000Z","contentLength":1430225,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070376408_ifvvsune63r.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '0e833d89-3048-4cca-85fc-1778c5de299c',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070376408_ifvvsune63r.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:46:16.844218+00',
  '2025-08-01 17:46:16.844218+00',
  '2025-08-01 17:46:16.844218+00',
  '{"eTag":"\"c41a2601445070f3b2d22b503ecf1f0f\"","size":64891,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:46:17.000Z","contentLength":64891,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070406486_1a0o4c0ya56.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '1ad178e7-8d02-4066-aabc-c48949e55132',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070406486_1a0o4c0ya56.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:46:47.450846+00',
  '2025-08-01 17:46:47.450846+00',
  '2025-08-01 17:46:47.450846+00',
  '{"eTag":"\"91e0c91d6b52f2d6ab82eb8a731f645c\"","size":1347272,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:46:48.000Z","contentLength":1347272,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070689049_ykaa09anqy.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'b6f9b4fa-9442-4f50-a474-0f0d51abae22',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070689049_ykaa09anqy.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:51:29.81476+00',
  '2025-08-01 17:51:29.81476+00',
  '2025-08-01 17:51:29.81476+00',
  '{"eTag":"\"5528bef8f89c6c41936ec1dfa997d5b0\"","size":560891,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:51:30.000Z","contentLength":560891,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070718585_flkco5ynm9g.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '2c3c7742-fc03-4ec6-94d3-cae321a90e1f',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070718585_flkco5ynm9g.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:51:59.5802+00',
  '2025-08-01 17:51:59.5802+00',
  '2025-08-01 17:51:59.5802+00',
  '{"eTag":"\"81ddfa7cdc7b30cb4860a5577b320134\"","size":1361112,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:52:00.000Z","contentLength":1361112,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071133208_yx5tj4evbrs.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '52165783-f4de-4532-9ad4-601043f8cf7c',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071133208_yx5tj4evbrs.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 17:58:54.283563+00',
  '2025-08-01 17:58:54.283563+00',
  '2025-08-01 17:58:54.283563+00',
  '{"eTag":"\"ed25bc917bcc94de3691f29d0201746f\"","size":1368076,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T17:58:55.000Z","contentLength":1368076,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071381516_5jywcqpkr22.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '38295f39-9f96-4a83-8962-46a7db2472d0',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071381516_5jywcqpkr22.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 18:03:02.247575+00',
  '2025-08-01 18:03:02.247575+00',
  '2025-08-01 18:03:02.247575+00',
  '{"eTag":"\"c28c8856069ff3658e250cc1052807b8\"","size":817869,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T18:03:03.000Z","contentLength":817869,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754073360276_qp22w0onij.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'aa0de215-6f72-4f98-81fa-55a670ff3745',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754073360276_qp22w0onij.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-01 18:36:01.489717+00',
  '2025-08-01 18:36:01.489717+00',
  '2025-08-01 18:36:01.489717+00',
  '{"eTag":"\"5721820167873dac1510f941b1c3519b\"","size":1538204,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-01T18:36:02.000Z","contentLength":1538204,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136177271_cwug6mm34ad.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '5b95ebf8-6af2-4c4f-a56f-b75245b287e2',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136177271_cwug6mm34ad.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-02 12:02:58.288702+00',
  '2025-08-02 12:02:58.288702+00',
  '2025-08-02 12:02:58.288702+00',
  '{"eTag":"\"39e6d06a1df1fab2b8b1636e3ab84036\"","size":1367000,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-02T12:02:59.000Z","contentLength":1367000,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136724885_1a4y03jhpdt.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '4e9203dc-ae0c-4f73-8dd5-511eac46adcc',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136724885_1a4y03jhpdt.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-02 12:12:05.661845+00',
  '2025-08-02 12:12:05.661845+00',
  '2025-08-02 12:12:05.661845+00',
  '{"eTag":"\"14183f5102c0ef9c0beeecb0d601e15a\"","size":868173,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-02T12:12:06.000Z","contentLength":868173,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136964687_pj775ro9hd.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'a342151e-532f-4730-8f3e-aa6a9c4eccd9',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136964687_pj775ro9hd.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-02 12:16:05.477044+00',
  '2025-08-02 12:16:05.477044+00',
  '2025-08-02 12:16:05.477044+00',
  '{"eTag":"\"20782c8de32c7cce25a62036026fd047\"","size":909103,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-02T12:16:06.000Z","contentLength":909103,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754247996774_5d4rxhjx5e7.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '50a1b817-ca9b-4514-8d6a-7c15f93640ab',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754247996774_5d4rxhjx5e7.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:06:37.525371+00',
  '2025-08-03 19:06:37.525371+00',
  '2025-08-03 19:06:37.525371+00',
  '{"eTag":"\"790592ce63b289ee1fd83e06e4bfc54f\"","size":770833,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:06:38.000Z","contentLength":770833,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248251778_9y86aadumf6.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '59d4ce35-cc22-43c4-b53c-b3b630af835b',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248251778_9y86aadumf6.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:10:52.508207+00',
  '2025-08-03 19:10:52.508207+00',
  '2025-08-03 19:10:52.508207+00',
  '{"eTag":"\"e97f10c40fb549dfc8adb36d2c4d116b\"","size":728121,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:10:53.000Z","contentLength":728121,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248275148_48t909nkqh2.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '28bfbf21-8f8f-43b9-a896-d4b9d19f5dcb',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248275148_48t909nkqh2.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:11:15.853611+00',
  '2025-08-03 19:11:15.853611+00',
  '2025-08-03 19:11:15.853611+00',
  '{"eTag":"\"e97f10c40fb549dfc8adb36d2c4d116b\"","size":728121,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:11:16.000Z","contentLength":728121,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248421365_r7zxeev7pb.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '4e47b723-029d-40cb-903e-4b015116ea81',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248421365_r7zxeev7pb.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:13:42.920818+00',
  '2025-08-03 19:13:42.920818+00',
  '2025-08-03 19:13:42.920818+00',
  '{"eTag":"\"18d35e12660b37c0bfe531ef7f71c4ac\"","size":4269404,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:13:43.000Z","contentLength":4269404,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248445574_koawtzfjva9.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '22afc7f7-d3d2-4831-b15a-57ed42dcad78',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248445574_koawtzfjva9.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:14:06.28748+00',
  '2025-08-03 19:14:06.28748+00',
  '2025-08-03 19:14:06.28748+00',
  '{"eTag":"\"3cf32c3ef8f828710e52eb910b794b9a\"","size":756667,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:14:07.000Z","contentLength":756667,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248632778_z3w5u7xrmj.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '68b5cc17-ae1f-4363-b8f4-9ce2ab418b7f',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248632778_z3w5u7xrmj.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:17:13.526246+00',
  '2025-08-03 19:17:13.526246+00',
  '2025-08-03 19:17:13.526246+00',
  '{"eTag":"\"c6aa408fcb3601ca2e859a890a26c312\"","size":782999,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:17:14.000Z","contentLength":782999,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249298507_7m1dj6f26vs.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'e08072ff-7fb7-4b4b-812a-3e32e3011795',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249298507_7m1dj6f26vs.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:28:19.268581+00',
  '2025-08-03 19:28:19.268581+00',
  '2025-08-03 19:28:19.268581+00',
  '{"eTag":"\"faac5e38ec9334db523ea8d4613ba211\"","size":747133,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:28:20.000Z","contentLength":747133,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249823648_wumfimc5jxs.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '383a08b2-88f0-41fa-963e-76608f7747b5',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249823648_wumfimc5jxs.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:37:04.606907+00',
  '2025-08-03 19:37:04.606907+00',
  '2025-08-03 19:37:04.606907+00',
  '{"eTag":"\"655f0d1cf0132aafe98285335eb6cf3e\"","size":1726773,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:37:05.000Z","contentLength":1726773,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249873696_c0nil6jdxlb.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '747be234-17c4-444f-84aa-79abe06a46e5',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249873696_c0nil6jdxlb.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:37:54.299387+00',
  '2025-08-03 19:37:54.299387+00',
  '2025-08-03 19:37:54.299387+00',
  '{"eTag":"\"1292e983b8084abdae47913f7983a88e\"","size":277243,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:37:55.000Z","contentLength":277243,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250045571_kj8luwryyu7.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'e805ab45-bdfc-47c7-9b9e-eced5b51b78d',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250045571_kj8luwryyu7.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:40:46.079232+00',
  '2025-08-03 19:40:46.079232+00',
  '2025-08-03 19:40:46.079232+00',
  '{"eTag":"\"1292e983b8084abdae47913f7983a88e\"","size":277243,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:40:46.000Z","contentLength":277243,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250058447_2hi8bpooiml.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '8f1f956d-19ac-480c-869c-3027dc9d1712',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250058447_2hi8bpooiml.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:40:58.987262+00',
  '2025-08-03 19:40:58.987262+00',
  '2025-08-03 19:40:58.987262+00',
  '{"eTag":"\"1292e983b8084abdae47913f7983a88e\"","size":277243,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:40:59.000Z","contentLength":277243,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250181414_pda0fn9nmsd.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '91b00af0-fbc1-408d-b7cb-7bd2441753e8',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250181414_pda0fn9nmsd.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:43:01.997426+00',
  '2025-08-03 19:43:01.997426+00',
  '2025-08-03 19:43:01.997426+00',
  '{"eTag":"\"1292e983b8084abdae47913f7983a88e\"","size":277243,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:43:02.000Z","contentLength":277243,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250349221_0ooapzq6yp29.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '0af60075-48ee-41fe-92d3-6ee42f1679a9',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250349221_0ooapzq6yp29.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:45:49.962695+00',
  '2025-08-03 19:45:49.962695+00',
  '2025-08-03 19:45:49.962695+00',
  '{"eTag":"\"e78c91c2c5f1f5ded5a32d0db247458e\"","size":781720,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:45:50.000Z","contentLength":781720,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250536179_pp565enayi9.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '4106fe9d-7be2-4530-8246-1a7ee90175a1',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250536179_pp565enayi9.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:48:57.079726+00',
  '2025-08-03 19:48:57.079726+00',
  '2025-08-03 19:48:57.079726+00',
  '{"eTag":"\"a545a23a8da7e9a84f943ecfb7b02b03\"","size":1077942,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:48:57.000Z","contentLength":1077942,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250555947_dqvhb1u1roj.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '38284921-486e-4f68-8912-70ce7f45bb03',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250555947_dqvhb1u1roj.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:49:16.75786+00',
  '2025-08-03 19:49:16.75786+00',
  '2025-08-03 19:49:16.75786+00',
  '{"eTag":"\"a545a23a8da7e9a84f943ecfb7b02b03\"","size":1077942,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:49:17.000Z","contentLength":1077942,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250815489_66e22ityenb.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'd982a951-0bd7-4fa0-bb20-3e62cb4d5eef',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250815489_66e22ityenb.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:53:36.063488+00',
  '2025-08-03 19:53:36.063488+00',
  '2025-08-03 19:53:36.063488+00',
  '{"eTag":"\"adf794904c63b556d4c24a391dac9fd2\"","size":168259,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:53:36.000Z","contentLength":168259,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250986922_8o62ncfj2a.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '0375f1ae-bb09-478e-9709-c56c25fcd03c',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250986922_8o62ncfj2a.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 19:56:28.031021+00',
  '2025-08-03 19:56:28.031021+00',
  '2025-08-03 19:56:28.031021+00',
  '{"eTag":"\"314c6f3ebc523176bf6f5fdb61fc9027\"","size":1847992,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T19:56:28.000Z","contentLength":1847992,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251233083_wmfdp0jq0xl.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '74455c7b-acd4-4175-94b4-91abd8ac4ac4',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251233083_wmfdp0jq0xl.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 20:00:34.011485+00',
  '2025-08-03 20:00:34.011485+00',
  '2025-08-03 20:00:34.011485+00',
  '{"eTag":"\"89a112d1add351da2f6f8bed3e23245c\"","size":1449454,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T20:00:34.000Z","contentLength":1449454,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251494059_hy3edd4dq9r.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'b500d648-b9eb-42f5-85e0-0e0a806a0da1',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251494059_hy3edd4dq9r.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 20:04:55.068666+00',
  '2025-08-03 20:04:55.068666+00',
  '2025-08-03 20:04:55.068666+00',
  '{"eTag":"\"b905404e0a0d125433af484be0fac243\"","size":1544772,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T20:04:55.000Z","contentLength":1544772,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251549080_2td6nmjosdo.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  'ab866ad2-c9f2-4562-81db-32c57f076ace',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251549080_2td6nmjosdo.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 20:05:50.09483+00',
  '2025-08-03 20:05:50.09483+00',
  '2025-08-03 20:05:50.09483+00',
  '{"eTag":"\"6ab41b20429f74abbcee29f0bb64ee11\"","size":1710115,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T20:05:50.000Z","contentLength":1710115,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;

-- Object: 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251892207_fny3ryxm15c.png
INSERT INTO storage.objects (
  id, bucket_id, name, owner, created_at, updated_at, last_accessed_at, metadata
) VALUES (
  '0ea537ab-f05a-4db3-a17e-4a604361a651',
  'media',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251892207_fny3ryxm15c.png',
  '6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4',
  '2025-08-03 20:11:33.252525+00',
  '2025-08-03 20:11:33.252525+00',
  '2025-08-03 20:11:33.252525+00',
  '{"eTag":"\"64446be1b68689779baeb3c9fee92d23\"","size":1512213,"mimetype":"image/png","cacheControl":"max-age=3600","lastModified":"2025-08-03T20:11:34.000Z","contentLength":1512213,"httpStatusCode":200}'::jsonb
) ON CONFLICT (id) DO NOTHING;


-- =============================================
-- FILE DATA COPYING INSTRUCTIONS
-- =============================================

-- IMPORTANT: After running this SQL script, you need to copy the actual file data.
-- This can be done using:
-- 1. Supabase CLI storage commands
-- 2. Storage API calls
-- 3. Manual download/upload process

-- Files to copy by bucket:
-- Bucket 'media': 44 files
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754058275584_l0my16tnvb.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059274124_rsngpgsh86.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754059833333_xufyxa7wr59.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754060396778_6pbj9admg3.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_1rtayuayo9g.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754061826309_x4hy0q16c1.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281219_hg669on57u5.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754063281220_2gprfoihenf.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_1dm8ruxy0t5.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/1754236762140_kyl98gf7z8.jpeg
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754068707678_wiz0dsl0a1.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754069851062_opc98k7pmni.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070134534_h3klxvkio0i.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070376408_ifvvsune63r.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070406486_1a0o4c0ya56.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070689049_ykaa09anqy.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754070718585_flkco5ynm9g.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071133208_yx5tj4evbrs.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754071381516_5jywcqpkr22.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754073360276_qp22w0onij.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136177271_cwug6mm34ad.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136724885_1a4y03jhpdt.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754136964687_pj775ro9hd.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754247996774_5d4rxhjx5e7.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248251778_9y86aadumf6.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248275148_48t909nkqh2.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248421365_r7zxeev7pb.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248445574_koawtzfjva9.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754248632778_z3w5u7xrmj.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249298507_7m1dj6f26vs.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249823648_wumfimc5jxs.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754249873696_c0nil6jdxlb.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250045571_kj8luwryyu7.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250058447_2hi8bpooiml.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250181414_pda0fn9nmsd.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250349221_0ooapzq6yp29.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250536179_pp565enayi9.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250555947_dqvhb1u1roj.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250815489_66e22ityenb.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754250986922_8o62ncfj2a.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251233083_wmfdp0jq0xl.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251494059_hy3edd4dq9r.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251549080_2td6nmjosdo.png
--   - 6ab21c8b-43d1-46ac-b28c-fae0f89dd7d4/cards/clipboard_1754251892207_fny3ryxm15c.png

-- =============================================
-- VERIFICATION QUERIES
-- =============================================

-- Check bucket count
SELECT COUNT(*) as bucket_count FROM storage.buckets;

-- Check objects count by bucket
SELECT b.name as bucket_name, COUNT(o.id) as object_count
FROM storage.buckets b
LEFT JOIN storage.objects o ON b.id = o.bucket_id
GROUP BY b.name
ORDER BY b.name;

