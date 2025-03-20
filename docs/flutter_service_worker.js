'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "660602d704b42eaa9e5cb7955baa8c4a",
"assets/AssetManifest.bin.json": "5303d1eb86f897fabcc1b0ec0bad342a",
"assets/AssetManifest.json": "a3cdeb29952f338b8516a0abac674b41",
"assets/assets/fonts/NotoSansKR-Regular.otf": "210989664066c01d8ffdbdf56bb773cd",
"assets/assets/fonts/YouandiModernTR.ttf": "5814f36151c600ba04601cd2e3aa915c",
"assets/assets/images/airforce.png": "c004e39efcdaa9e25b8aa34de9e50ddd",
"assets/assets/images/aleph.jpg": "65aed74a5a5e4bb3052f984262eebb80",
"assets/assets/images/aleph.png": "21b402950ce967dfd4f8200d0694b83d",
"assets/assets/images/auto_trading.png": "674ee62cf83f200bfd983e392032e2db",
"assets/assets/images/aws.png": "fe81e439bda3a5f7b5e22ccb453097d2",
"assets/assets/images/AWSgameliftFlexmatch.png": "172e08b9926bde333535e365c40cf3a3",
"assets/assets/images/azure.png": "0f2ce8652a47c55b4e0c5c3f3d7f8ab1",
"assets/assets/images/centos.jpg": "6ba2c896a50f3e86c1f3f8bede9a3987",
"assets/assets/images/cloudflare.png": "4a20196f4c2ade07c0a496168ec37536",
"assets/assets/images/company_nexon_moai.png": "a446b41519774f0acaa2ce8052190a21",
"assets/assets/images/company_traha.jpg": "94d99007b7bdbd02836dcb39f33a164d",
"assets/assets/images/company_traha2.jpg": "3e2cd4e8d926ef7d3f7cd0dd06121908",
"assets/assets/images/company_traha3.png": "bbeffbad02b2d96c1d5bdc78a832af7f",
"assets/assets/images/company_unreal.png": "aa597db8d1385a2c4af6af2d25db7397",
"assets/assets/images/cpp.png": "6f1fa38c5906f4a06bf5e131c3753c83",
"assets/assets/images/cpppp.png": "d60a0eedee77639031e2e5201791a7f7",
"assets/assets/images/docker.png": "652c1777bd14500d88f111771ea0c15f",
"assets/assets/images/electron.png": "772f38c1f6579634fa90806c37ea5dde",
"assets/assets/images/firebase.png": "83d1f24f90d135133ea1b04ac924e708",
"assets/assets/images/fishing_tornado.png": "3429271d8b6432e27a9a5b3c7a9ea73c",
"assets/assets/images/flutter.png": "fba7a39b3edd134cfea563aa154324d5",
"assets/assets/images/freestyle.png": "1530d9b48464db3b3186e4ddc43c5c8e",
"assets/assets/images/freestyle_1.jpg": "a460b6541fa57f10707f21b84b849fb8",
"assets/assets/images/git.png": "86b5acf4bd826bfcaf30b21cc2496a55",
"assets/assets/images/github.png": "c5b8b6f77f5255befb6c460d7355a7ee",
"assets/assets/images/github_actions.png": "7673903cb2dda142d151eae5a5b6cb34",
"assets/assets/images/go.png": "2cae236ba3d4f8ae10f53b35f78a3df2",
"assets/assets/images/gunsl.png": "544079be38109cf0d825b3f35275d8b2",
"assets/assets/images/gunslinger_stratos.png": "52c9a96ee793c0c01bad6106cfbd4bee",
"assets/assets/images/hb.png": "b7b70c45ebf2d122c74a3188e3bbcf08",
"assets/assets/images/hnbit2.png": "986196d448e0da5ada4a0709e2706fb1",
"assets/assets/images/jenkins.png": "aede8398e254865d343ab4ad4aaa791b",
"assets/assets/images/joycity.jpg": "15bef3e4568fb667840d00eb681557d0",
"assets/assets/images/joycity.png": "e05852d0f4ac0ce26fefd08267ee8370",
"assets/assets/images/js.png": "032f185de0300a695936325e755fd479",
"assets/assets/images/jy.jpg": "b97f4552c72552eb2266c337e0f37c06",
"assets/assets/images/kookmin.png": "494e458e00ffb4b10283bf43a2adb391",
"assets/assets/images/kpu.png": "888c93a1584f82cb2152f6393494500a",
"assets/assets/images/kubernetes.png": "ad8aec58d107e51e93de9b9ca2589bbe",
"assets/assets/images/linux.png": "6577a3317ed4f7ea60fa7ef7b913a6f6",
"assets/assets/images/LogServerArchi.png": "201285679f11f75bfa996d01dd2adb94",
"assets/assets/images/moai.jpg": "1d1a2357baf0ed3edfd4c07ecfe69f43",
"assets/assets/images/moai.png": "eec8fc8565a7ad865a4c2166f996a216",
"assets/assets/images/mongo.png": "fbe277537308adf105b20d605797d0cf",
"assets/assets/images/mongodb.png": "2018d7e9c1f5bdf28baadd15744c02b2",
"assets/assets/images/mssql.png": "4baec0c002c0b9eaec6ec32c7a0d22f8",
"assets/assets/images/myface.png": "81d95ee7b02f8d6bc40d0e09601970c2",
"assets/assets/images/myface2.png": "eff71b5a23e3ec4c590cbc83b48ffdeb",
"assets/assets/images/myface3.png": "79499e8c5a2401eaa5d0c64aa41526bc",
"assets/assets/images/mysql.png": "fc8a59fa3fe1c45d86d1d61756dab55a",
"assets/assets/images/nallary.png": "2763a25f8078733d374ff98778f0339f",
"assets/assets/images/naverpost.png": "ab7b0e970c15163b77100d1688e613fb",
"assets/assets/images/naver_cloud_platform.png": "64c8912b5ee881ca712208053250d590",
"assets/assets/images/people.png": "99f6bac3964c4ececb93ade0a000c752",
"assets/assets/images/process_achv1.png": "011196832df7f42203b7082d87758f7a",
"assets/assets/images/process_achv2.png": "f998f26e1b87afe312b1881accb8114d",
"assets/assets/images/process_memorialstone1.png": "395fd43d9640b28772168a9ad3c93c5e",
"assets/assets/images/process_memorialstone2.png": "28f3cd7f77867fe044e2eaa26b7886ed",
"assets/assets/images/process_subloader.png": "24139327dc46905b69036abd8aad7f31",
"assets/assets/images/python.png": "e50787dda83696abe3a3980d51d21664",
"assets/assets/images/redduck.png": "fa7dc1373f9fd6d729c44a9bd8fed4ad",
"assets/assets/images/redis.png": "0f45f24309ad2e7080db196190ea9f36",
"assets/assets/images/richpocket.png": "d903d5ce3eaab28ee2e5abfd374dc05e",
"assets/assets/images/sign.png": "fd4f33c176adf92aa0f674ac47b08238",
"assets/assets/images/sign2.png": "8b3d05e926e8bafae685cf476be30f99",
"assets/assets/images/sql.png": "2d8cae88f2c64a2c83126bc2b703fb0a",
"assets/assets/images/square.png": "621010b92775d2494e69aec35bedb7f5",
"assets/assets/images/steam.png": "ac76eb94e4ea7381aa66641a1a8201af",
"assets/assets/images/stockmaster-flowchart.png": "3caf33e9a34d62689e9a25c6ddb7908b",
"assets/assets/images/svn.png": "abcfdf26ff385ed88ea41766600b0cb8",
"assets/assets/images/traha_play.webp": "a515b5e26d561bbbf42cd675444ab7d7",
"assets/assets/images/traha_title.webp": "7255d412c3cc7f3fae33df6c02ced0f3",
"assets/assets/images/ts.png": "3c8f914875eb708de5bb2452d3c7239d",
"assets/assets/images/tuk.png": "09b082a15125b450e51e2268f1e81a42",
"assets/assets/images/unreal.png": "a842416919fdefca1a1ffa7aac84a940",
"assets/assets/images/UwpStressTool.png": "13cb1a23e4f25a921be9830c6a05e5fe",
"assets/assets/images/vs.png": "9e11182e2802c6e809ed822fb1d4d79b",
"assets/assets/images/vsc.png": "30c6da1a360c0c4a234d2ceca34e6424",
"assets/assets/images/vue.png": "e7763556920c2bce359c7dceea44c8a8",
"assets/assets/images/wemade.png": "0db1d92ab38c4eba157eed557408933e",
"assets/assets/images/windows.png": "7aa20a9822a7d9480837a2dd04a5ad50",
"assets/FontManifest.json": "178c650448c71c02d3fbe9aaac7bfd9c",
"assets/fonts/MaterialIcons-Regular.otf": "2fcc37e7140b2235521755e8eb0e0284",
"assets/NOTICES": "62e010b027fd2faa314f20a5efc31d37",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "e986ebe42ef785b27164c36a9abc7818",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "66177750aff65a66cb07bb44b8c6422b",
"canvaskit/canvaskit.js.symbols": "48c83a2ce573d9692e8d970e288d75f7",
"canvaskit/canvaskit.wasm": "1f237a213d7370cf95f443d896176460",
"canvaskit/chromium/canvaskit.js": "671c6b4f8fcc199dcc551c7bb125f239",
"canvaskit/chromium/canvaskit.js.symbols": "a012ed99ccba193cf96bb2643003f6fc",
"canvaskit/chromium/canvaskit.wasm": "b1ac05b29c127d86df4bcfbf50dd902a",
"canvaskit/skwasm.js": "694fda5704053957c2594de355805228",
"canvaskit/skwasm.js.symbols": "262f4827a1317abb59d71d6c587a93e2",
"canvaskit/skwasm.wasm": "9f0c0c02b82a910d12ce0543ec130e60",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "f393d3c16b631f36852323de8e583132",
"flutter_bootstrap.js": "c6c5c4e28c3918a10a5419871ca8ab78",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "b61639734ec23fdd3d545808f12be7be",
"/": "b61639734ec23fdd3d545808f12be7be",
"main.dart.js": "a7ed7f0889edbd6ed38aed5be306ea2c",
"manifest.json": "e343c1a254e8a8177b8c86c03dc44770",
"version.json": "7426b39c6f6fda47f9c3ed532ff33ff3"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
