(function (Browser) {
  "use strict";

  let pubpeer = null;

  function initMessaging() {
    safari.self.addEventListener('message', ({ name }) => {
      if (name === 'addPubPeerMarks' && pubpeer) {
        pubpeer.init();
      } else if (name === 'removePubPeerMarks') {
        pubpeer.removeElements(['div.pp_comm', 'p.pp_articles']);
      }
    })
    top.window.pubpeerMessageListenerInitialized = true;
  }

  function isSameOrigin() {
    return Boolean(Object.keys(top.window.location).length) && top.window === window;
  }

  if (isSameOrigin()) {
    top.window.document.addEventListener("DOMContentLoaded", function (event) {
      pubpeer = new PubPeer(Browser);
      safari.extension.dispatchMessage("pageLoaded");
    }, false);

    if (!top.window.pubpeerMessageListenerInitialized) {
      initMessaging();
    }
  }
})(Browser);
