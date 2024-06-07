'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"canvaskit/skwasm.worker.js": "bfb704a6c714a75da9ef320991e88b03",
"canvaskit/skwasm.js": "f17a293d422e2c0b3a04962e68236cc2",
"canvaskit/canvaskit.wasm": "f312edac4fb4c74852dc1a4f069ab100",
"canvaskit/canvaskit.js.symbols": "07c19b69fa5f53224712e8471c00344d",
"canvaskit/skwasm.js.symbols": "ab140650f4d351b74f4e6bca3e8dd0e0",
"canvaskit/skwasm.wasm": "7fe5c39ff8466de52fbb0c66473abbe3",
"canvaskit/canvaskit.js": "5fda3f1af7d6433d53b24083e2219fa0",
"canvaskit/chromium/canvaskit.wasm": "f9074e52c7e9c770f1130c6ed9e2677f",
"canvaskit/chromium/canvaskit.js.symbols": "100d192729121969872b80009e47a5b7",
"canvaskit/chromium/canvaskit.js": "87325e67bf77a9b483250e1fb1b54677",
"icons/Icon-maskable-192.png": "c457ef57daa1d16f64b27b786ec2ea3c",
"icons/Icon-maskable-512.png": "301a7604d45b3e739efc881eb04896ea",
"icons/Icon-512.png": "96e752610906ba2a93c65f8abe1645f1",
"icons/Icon-192.png": "ac9a721a12bbc803b44f645561ecb1e1",
"manifest.json": "e4239af77c8e0ac120f56899b42feb79",
"favicon.png": "5dcef449791fa27946b3d35ad8803796",
"flutter_bootstrap.js": "422ea73cc301871a8a3ea2985aa8de83",
"version.json": "cfd0ed5cd78953745eaeb36b161965d4",
"index.html": "06ae4a3839afccab67ee84613f776d06",
"/": "06ae4a3839afccab67ee84613f776d06",
"main.dart.js": "1b9cbf0250c216270a0b2777e7026f91",
"assets/AssetManifest.json": "5fb3c216c374e361e9119f043db95481",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "89ed8f4e49bcdfc0b5bfc9b24591e347",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin.json": "b051f0fb5330247cde6f59683fb099cb",
"assets/fonts/MaterialIcons-Regular.otf": "b13936835799e8501386b072250437bf",
"assets/assets/leaderboard/badges/go.png": "727a3c30b5f34931eadb8957faff6474",
"assets/assets/leaderboard/badges/badges.kra~": "0db7728a8d9206db77bdd5f2df2463f0",
"assets/assets/leaderboard/badges/st%2520cloud%2520mvp%2520badge.png": "a74cf9bc22e7a8813fd109ce28697f8e",
"assets/assets/leaderboard/badges/sheets.png": "50454feaad634b0ef924699b893d9c1c",
"assets/assets/leaderboard/badges/gopher.png": "a52fa4f17f74cdef6a95b07adae8f87d",
"assets/assets/leaderboard/badges/badges.kra": "182d4e414d27803c405704832c767f95",
"assets/assets/leaderboard/badges/2nd%2520place%2520badge.png": "42c7fcf43036b9fa829d2c3d6f1403f0",
"assets/assets/leaderboard/badges/java.png": "74e943d82452f81f6a0bb0b51ac6785d",
"assets/assets/leaderboard/badges/3rd%2520place%2520badge.png": "a11d8df1bdcdecd0032faf5eacccb331",
"assets/assets/leaderboard/badges/1st%2520place%2520badge.png": "eae122d025f75e3600996c176b905ad5",
"assets/assets/accolades/goat.png": "6ef9f309b38f4fe341c242354e244577",
"assets/assets/accolades/gearEye.png": "a16942d8ae554941e7ede791ea5d8a47",
"assets/assets/accolades/note.png": "c70e1bb68bedad6a686f568af0400018",
"assets/assets/accolades/ryanMcgoff.png": "9a43bccedd568292dafc8d6f910df1f3",
"assets/assets/extras/naz.png": "6bdfff96eeb3cb1f37e66594a9a23968",
"assets/assets/extras/rudy.png": "751c76b15963d0b0a4371c3c09e32bba",
"assets/assets/hof/7312.png": "da05ea44cd924751cdcdc3557f0fc134",
"assets/assets/hof/mike.png": "ab5be3942b57d752db677d80857eb82b",
"assets/assets/hof/tag.png": "ba968e5ac3b2d6f475dc25bd789f0c5a",
"assets/NOTICES": "0239bc051b99a303a8812832bec0de84",
"assets/AssetManifest.bin": "697bdcf3721549ad193809e5cafa01df",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"flutter.js": "383e55f7f3cce5be08fcf1f3881f585c"};
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
