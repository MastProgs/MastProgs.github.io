'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';
const RESOURCES = {
  "assets/AssetManifest.json": "5af843b394517310d4a942998131c4a9",
"assets/assets/fonts/HangeulNuriB.ttf": "9d7bc0920edaedefbf3753feb912b0a5",
"assets/assets/fonts/HangeulNuriR.ttf": "237e36a33874614aaf1c98f351c02388",
"assets/assets/fonts/NanumGothic-Bold.ttf": "4fa4ea43222779743fc8cd4b4835d04e",
"assets/assets/fonts/NanumGothic-ExtraBold.ttf": "4b1b824d86d866cb8245accebe324b62",
"assets/assets/fonts/NanumGothic-Regular.ttf": "3cbe9257e888255cb2dad0d8a80a7759",
"assets/assets/fonts/NanumMyeongjo-Bold.ttf": "5ea37dfbbfbd9fb13421ffc6032f150a",
"assets/assets/fonts/NanumMyeongjo-ExtraBold.ttf": "bf37d995db642e86d6d45f2388e00a9b",
"assets/assets/fonts/NanumMyeongjo-Regular.ttf": "efdc1f63c31b3c0acc07777c2c2d8b38",
"assets/assets/fonts/NotoSansKR-Black.otf": "05c077164c27fa722dcafe63ed38355e",
"assets/assets/fonts/NotoSansKR-Bold.otf": "e2406ff1791c401bc93e73d9e44e6d2b",
"assets/assets/fonts/NotoSansKR-Light.otf": "e914a10a1bd0088fb8f743fc7569749f",
"assets/assets/fonts/NotoSansKR-Medium.otf": "32666ae307200b0bcab5553590672bb1",
"assets/assets/fonts/NotoSansKR-Regular.otf": "210989664066c01d8ffdbdf56bb773cd",
"assets/assets/fonts/NotoSansKR-Thin.otf": "277434d967d5f33b857fc3f2dbaff15b",
"assets/assets/fonts/TmonMonsori.ttf": "0266b60888b0995b5ddb28136e58d844",
"assets/assets/fonts/TmonTium.ttf": "5050b23709b772bfa48328d40edd21f5",
"assets/assets/fonts/YouandiModernTR.ttf": "5814f36151c600ba04601cd2e3aa915c",
"assets/assets/images/airforce.png": "003eae995002dc0c0873a1a0445f78cf",
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
"assets/FontManifest.json": "beaeab6ed48f4b31cfcea6918e4321b9",
"assets/fonts/MaterialIcons-Regular.otf": "e7069dfd19b331be16bed984668fe080",
"assets/NOTICES": "bf6f9782fb6ae8684a3d88fee4a0e664",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "6d342eb68f170c97609e9da345464e5e",
"canvaskit/canvaskit.js": "97937cb4c2c2073c968525a3e08c86a3",
"canvaskit/canvaskit.wasm": "3de12d898ec208a5f31362cc00f09b9e",
"canvaskit/profiling/canvaskit.js": "c21852696bc1cc82e8894d851c01921a",
"canvaskit/profiling/canvaskit.wasm": "371bc4e204443b0d5e774d64a046eb99",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter.js": "1cfe996e845b3a8a33f57607e8b09ee4",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"index.html": "61713e354bf8f62e6b48e035f89de761",
"/": "61713e354bf8f62e6b48e035f89de761",
"main.dart.js": "6fe3bb369ad69332e3acd9bdcfd675d6",
"manifest.json": "4533fc5525fe0215b57ac7dc49fb9023",
"version.json": "808df6b521b1d1b3246e699773327b3f"
};

// The application shell files that are downloaded before a service worker can
// start.
const CORE = [
  "main.dart.js",
"index.html",
"assets/AssetManifest.json",
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
