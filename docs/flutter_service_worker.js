'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"assets/AssetManifest.bin": "7a69d0cf5121fb73db6349b107f737b6",
"assets/AssetManifest.bin.json": "8b175969178ef188ed03cc37057ab751",
"assets/AssetManifest.json": "b189cfa8b8a77ecfb5c62135ff2d915b",
"assets/assets/fonts/NotoSansKR-Regular.otf": "210989664066c01d8ffdbdf56bb773cd",
"assets/assets/fonts/YouandiModernTR.ttf": "5814f36151c600ba04601cd2e3aa915c",
"assets/assets/images/airforce.png": "003eae995002dc0c0873a1a0445f78cf",
"assets/assets/images/aleph.jpg": "65aed74a5a5e4bb3052f984262eebb80",
"assets/assets/images/auto_trading.png": "674ee62cf83f200bfd983e392032e2db",
"assets/assets/images/aws.png": "cda74aa1531b6a618be4254fe603f6ae",
"assets/assets/images/AWSgameliftFlexmatch.png": "172e08b9926bde333535e365c40cf3a3",
"assets/assets/images/azure.jpg": "58d3f4abc44e6de163191fb536dc49ac",
"assets/assets/images/centos.jpg": "6ba2c896a50f3e86c1f3f8bede9a3987",
"assets/assets/images/company_nexon_moai.png": "a446b41519774f0acaa2ce8052190a21",
"assets/assets/images/company_traha.jpg": "94d99007b7bdbd02836dcb39f33a164d",
"assets/assets/images/company_traha2.jpg": "3e2cd4e8d926ef7d3f7cd0dd06121908",
"assets/assets/images/company_traha3.png": "bbeffbad02b2d96c1d5bdc78a832af7f",
"assets/assets/images/company_unreal.png": "aa597db8d1385a2c4af6af2d25db7397",
"assets/assets/images/cpp.png": "7ed65b4994628e2f913979e0f9f46d1b",
"assets/assets/images/cpppp.png": "c3abc4c018d0a270101c4403344ddd45",
"assets/assets/images/electron.png": "b1f221c678cbb4a9ff11b468af3b3e50",
"assets/assets/images/flutter.png": "0b5a2f8d3f4d173805affaf9f84f6c87",
"assets/assets/images/freestyle.png": "1530d9b48464db3b3186e4ddc43c5c8e",
"assets/assets/images/freestyle_1.jpg": "a460b6541fa57f10707f21b84b849fb8",
"assets/assets/images/github.png": "c5b8b6f77f5255befb6c460d7355a7ee",
"assets/assets/images/golang.jpg": "b25b6cd95a69c1016bd475e41e893d33",
"assets/assets/images/gunsl.png": "544079be38109cf0d825b3f35275d8b2",
"assets/assets/images/gunslinger_stratos.png": "52c9a96ee793c0c01bad6106cfbd4bee",
"assets/assets/images/hb.png": "6a94d24d6b2e3a9a8857a27548c79cf5",
"assets/assets/images/hnbit2.png": "986196d448e0da5ada4a0709e2706fb1",
"assets/assets/images/joycity.jpg": "15bef3e4568fb667840d00eb681557d0",
"assets/assets/images/js.png": "0e4fdce8ac22e09688c580e5bc4dcd7d",
"assets/assets/images/jy.jpg": "b97f4552c72552eb2266c337e0f37c06",
"assets/assets/images/kookmin.png": "e1cd9d252dc3ce43d216654d31fd6020",
"assets/assets/images/kpu.png": "888c93a1584f82cb2152f6393494500a",
"assets/assets/images/linux.png": "210bdcb542a9b5d2e5ed8c6b20ade706",
"assets/assets/images/logo.svg": "07d1e22e8cddd99a53037dc510221b7b",
"assets/assets/images/LogServerArchi.png": "201285679f11f75bfa996d01dd2adb94",
"assets/assets/images/moai.jpg": "1d1a2357baf0ed3edfd4c07ecfe69f43",
"assets/assets/images/mongo.png": "fbe277537308adf105b20d605797d0cf",
"assets/assets/images/mssql.png": "10ecabd2611bc8e3774d5ab18a64a9b4",
"assets/assets/images/myface.png": "81d95ee7b02f8d6bc40d0e09601970c2",
"assets/assets/images/myface2.png": "eff71b5a23e3ec4c590cbc83b48ffdeb",
"assets/assets/images/mysql.png": "569126d3a6496ec292a6707fea79a24b",
"assets/assets/images/naverpost.png": "ab7b0e970c15163b77100d1688e613fb",
"assets/assets/images/people.png": "99f6bac3964c4ececb93ade0a000c752",
"assets/assets/images/process_achv1.png": "011196832df7f42203b7082d87758f7a",
"assets/assets/images/process_achv2.png": "f998f26e1b87afe312b1881accb8114d",
"assets/assets/images/process_memorialstone1.png": "395fd43d9640b28772168a9ad3c93c5e",
"assets/assets/images/process_memorialstone2.png": "28f3cd7f77867fe044e2eaa26b7886ed",
"assets/assets/images/process_subloader.png": "24139327dc46905b69036abd8aad7f31",
"assets/assets/images/python.png": "dc199ecc9e90e4bc7e9ed9b31e3c2b5f",
"assets/assets/images/redis.jpg": "74336f92ee3077d9f244b34cc729b520",
"assets/assets/images/sign.png": "fd4f33c176adf92aa0f674ac47b08238",
"assets/assets/images/sign2.png": "8b3d05e926e8bafae685cf476be30f99",
"assets/assets/images/sql.png": "2d8cae88f2c64a2c83126bc2b703fb0a",
"assets/assets/images/square.png": "621010b92775d2494e69aec35bedb7f5",
"assets/assets/images/steam.png": "ac76eb94e4ea7381aa66641a1a8201af",
"assets/assets/images/svn.png": "930d4a6c2055d97e9f3e8956fb7951b1",
"assets/assets/images/traha_play.webp": "a515b5e26d561bbbf42cd675444ab7d7",
"assets/assets/images/traha_title.webp": "7255d412c3cc7f3fae33df6c02ced0f3",
"assets/assets/images/tuk.jpg": "54cd5934805bd34a6c758e6b02d06f8d",
"assets/assets/images/typescript.png": "8656e839fa33def4d00520fc84194a98",
"assets/assets/images/ueicon.png": "1ef82ff1445cea832a52c14e9c096a02",
"assets/assets/images/UwpStressTool.png": "13cb1a23e4f25a921be9830c6a05e5fe",
"assets/assets/images/vs.png": "5c915cf002d759fe5e4a1a9570cb5186",
"assets/assets/images/vsc.png": "a78dfa30bc7f1e6e652284bdd386d0d6",
"assets/assets/images/vue.png": "82b9c7a5a3f405032b1db71a25f67021",
"assets/assets/images/wemade.png": "5b4a03288f4c6be7af40e2bcb6f9efee",
"assets/assets/images/windows.png": "7d9ea06334332db14c702272280c893a",
"assets/FontManifest.json": "178c650448c71c02d3fbe9aaac7bfd9c",
"assets/fonts/MaterialIcons-Regular.otf": "9d2d304bb56596d68833f9e4bcf601e4",
"assets/NOTICES": "40dabde0810ab64703fad66be87d56c4",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "89ed8f4e49bcdfc0b5bfc9b24591e347",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"canvaskit/canvaskit.js": "c86fbd9e7b17accae76e5ad116583dc4",
"canvaskit/canvaskit.js.symbols": "38cba9233b92472a36ff011dc21c2c9f",
"canvaskit/canvaskit.wasm": "3d2a2d663e8c5111ac61a46367f751ac",
"canvaskit/chromium/canvaskit.js": "43787ac5098c648979c27c13c6f804c3",
"canvaskit/chromium/canvaskit.js.symbols": "4525682ef039faeb11f24f37436dca06",
"canvaskit/chromium/canvaskit.wasm": "f5934e694f12929ed56a671617acd254",
"canvaskit/profiling/canvaskit.js": "c21852696bc1cc82e8894d851c01921a",
"canvaskit/profiling/canvaskit.wasm": "371bc4e204443b0d5e774d64a046eb99",
"canvaskit/skwasm.js": "445e9e400085faead4493be2224d95aa",
"canvaskit/skwasm.js.symbols": "741d50ffba71f89345996b0aa8426af8",
"canvaskit/skwasm.wasm": "e42815763c5d05bba43f9d0337fa7d84",
"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "c71a09214cb6f5f8996a531350400a9a",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "f6685823975cbbb798eeb539988fe6cf",
"/": "f6685823975cbbb798eeb539988fe6cf",
"main.dart.js": "7b6293a083bbec44862f11ce32c0062d",
"manifest.json": "4533fc5525fe0215b57ac7dc49fb9023",
"version.json": "808df6b521b1d1b3246e699773327b3f"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
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
