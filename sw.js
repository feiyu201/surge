const cacheName = 'surge-shell';
const urlsToCache = [
  '/index.html?v=3',
  '/surge.sh?v=3',
  '/404.html?v=3',
];

// 安装 Service Worker
self.addEventListener('install', (event) => {
  console.log('Service Worker installed');

  // 预缓存文件
  event.waitUntil(
    caches.open(cacheName).then((cache) => {
      return cache.addAll(urlsToCache);
    })
  );
});

// 激活 Service Worker
self.addEventListener('activate', (event) => {
  console.log('Service Worker activated');

  // 删除旧缓存
  event.waitUntil(
    caches.keys().then((keyList) => {
      return Promise.all(keyList.map((key) => {
        if (key !== cacheName) {
          return caches.delete(key);
        }
      }));
    })
  );
});

// 拦截网络请求并返回缓存内容
self.addEventListener('fetch', (event) => {
  const request = event.request;
  const url = new URL(request.url);
  if (url.origin === 'https://api.vvhan.com' || url.origin === 'https://cn.bing.com') {
    event.respondWith(
      caches.match(request).then((response) => {
        if (response) {
          return response;
        }
        return fetch(request).then((response) => {
          const clonedResponse = response.clone();
          caches.open(cacheName).then((cache) => {
            cache.put(request, clonedResponse);
          });
          return response;
        });
      })
    );
  } else {
    event.respondWith(
      caches.match(request).then((response) => {
        if (response) {
          return response;
        } else {
          return fetch(request);
        }
      })
    );
  }
});
