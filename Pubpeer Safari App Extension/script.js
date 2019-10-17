///////////////////////////////////////////////////////////
// - sanitizer.js - //
///////////////////////////////////////////////////////////

/* globals define, module */

/**
 * A simple library to help you escape HTML using template strings.
 *
 * It's the counterpart to our eslint "no-unsafe-innerhtml" plugin that helps us
 * avoid unsafe coding practices.
 * A full write-up of the Hows and Whys are documented
 * for developers at
 *  https://developer.mozilla.org/en-US/Firefox_OS/Security/Security_Automation
 * with additional background information and design docs at
 *  https://wiki.mozilla.org/User:Fbraun/Gaia/SafeinnerHTMLRoadmap
 *
 */
(function (root, factory) {
  'use strict';
  if (typeof define === 'function' && define.amd) {
    define(factory);
  } else if (typeof exports === 'object') {
    module.exports = factory();
  } else {
    root.Sanitizer = factory();
  }
}(this, function () {
  'use strict';

  var Sanitizer = {
    _entity: /[&<>"'/]/g,

    _entities: {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      '\'': '&apos;',
      '/': '&#x2F;'
    },

    getEntity: function (s) {
      return Sanitizer._entities[s];
    },

    /**
     * Escapes HTML for all values in a tagged template string.
     */
    escapeHTML: function (strings, ...values) {
      var result = '';

      for (var i = 0; i < strings.length; i++) {
        result += strings[i];
        if (i < values.length) {
          result += String(values[i]).replace(Sanitizer._entity,
            Sanitizer.getEntity);
        }
      }

      return result;
    },
    /**
     * Escapes HTML and returns a wrapped object to be used during DOM insertion
     */
    createSafeHTML: function (strings, ...values) {
      var escaped = Sanitizer.escapeHTML(strings, ...values);
      return {
        __html: escaped,
        toString: function () {
          return '[object WrappedHTMLObject]';
        },
        info: 'This is a wrapped HTML object. See https://developer.mozilla.or' +
          'g/en-US/Firefox_OS/Security/Security_Automation for more.'
      };
    },
    /**
     * Unwrap safe HTML created by createSafeHTML or a custom replacement that
     * underwent security review.
     */
    unwrapSafeHTML: function (...htmlObjects) {
      var markupList = htmlObjects.map(function (obj) {
        return obj.__html;
      });
      return markupList.join('');
    }
  };

  return Sanitizer;

}));

///////////////////////////////////////////////////////////
// - pubpeer.js - //
///////////////////////////////////////////////////////////

var Browser = (function () {
  'use strict';

  if (typeof navigator === 'undefined' || !navigator) {
    return null;
  }

  var userAgentString = navigator.userAgent;

  var browsers = [
    ['Edge', /Edge\/([0-9\._]+)/],
    ['Chrome', /(?!Chrom.*OPR)Chrom(?:e|ium)\/([0-9\.]+)(:?\s|$)/],
    ['Firefox', /Firefox\/([0-9\.]+)(?:\s|$)/],
    ['Safari', /Version\/([0-9\._]+).*Safari/]
  ];

  return browsers.map(function (rule) {
    if (rule[1].test(userAgentString)) {
      var match = rule[1].exec(userAgentString);
      var version = match && match[1].split(/[._]/).slice(0, 3);

      if (version && version.length < 3) {
        Array.prototype.push.apply(version, (version.length == 1) ? [0, 0] : [0]);
      }

      return {
        name: rule[0],
        version: version.join('.')
      };
    }
  }).filter(Boolean).shift();
})();

Element.prototype.parents = function (selector) {
  'use strict';
  var parents = [],
    element = this,
    hasSelector = selector !== undefined;

  while (element = element.parentElement) {
    if (element.nodeType !== Node.ELEMENT_NODE) {
      continue;
    }
    if (!hasSelector || element.matches(selector)) {
      parents.push(element);
    }
  }

  return parents;
};

(function (Browser) {
  'use strict';
  var
    url = "https://pubpeer.com",
    address = `${url}/v3/publications?devkey=PubMed${Browser.name}`,
    utm = `?utm_source=${Browser.name}&utm_medium=BrowserExtension&utm_campaign=${Browser.name}`,
    articleTitles = [],
    pageDOIs = [];

  function getPageDOIs() {
    pageDOIs = document.body.innerHTML.match(/\b(10[.][0-9]{4,}(?:[.][0-9]+)*\/(?:(?!["&\'<>])\S)+)\b/gi) || [];
  }

  function addPubPeerMarks() {
    informExtensionInstalled();

    if (pageNeedsPubPeerLinks()) {
      addPubPeerLinks();
    }
  }

  function unique(array) {
    return [... new Set(array)];
  }

  function contains(selector, text) {
    var elements = document.querySelectorAll(selector);
    return [].filter.call(elements, function (element) {
      return RegExp(text).test(element.textContent);
    });
  }

  function informExtensionInstalled() {
    localStorage.setItem('pubpeer-extension', true);
  }

  function pageNeedsPubPeerLinks() {
    return unique(pageDOIs).length > 0 && window.location.hostname.indexOf('pubpeer') === -1
  }

  function addPubPeerLinks() {
    let request = new XMLHttpRequest();
    request.open('POST', address, true);
    request.setRequestHeader("Content-Type", "application/json;charset=UTF-8");

    request.onload = function () {
      if (request.status >= 200 && request.status < 400) {
        let responseText = JSON.parse(request.responseText);
        if (!responseText) {
          return;
        }
        responseText.feedbacks.forEach(function (publication) {
          appendPublicationDetails(publication);
        });
        addTopBar();
      }
    };

    request.send(JSON.stringify({
      dois: unique(pageDOIs),
      version: '0.3.2',
      browser: Browser.name
    }));
  }

  function isDOMElement (obj) {
    return !!(obj && obj.nodeType === 1);
  }

  function onAfterAddingTopBar () {
    if (location.hostname === 'www.cell.com') {
      const headerElement = document.querySelector('header.header.base.fixed');
      const mainContent = document.querySelector('main.content');
      const articleElement = document.querySelector('p.pp_articles');
      if (isDOMElement(headerElement) && isDOMElement(mainContent) && isDOMElement(articleElement)) {
        headerElement.style.top = '35px';
        mainContent.style.paddingTop = '117px';
        articleElement.style.position = 'fixed';
        articleElement.style.zIndex = 1000;
        articleElement.style.width = '100vw';
      }
    }
  }

  function addTopBar () {
    articleTitles = unique(articleTitles);
    const articleCount = articleTitles.length;
    if (articleCount > 0 && document.querySelector('.pp_articles') === null) {
      let queryUrl = url;
      if (articleCount) {
        const query = encodeURIComponent(`title: ("${articleTitles.join('" OR "')}")`)
        queryUrl += `/search?q=${query}`;
      }
      let pElement = document.createElement('p');
      pElement.className = 'pp_articles';
      pElement.style = 'margin: 0;background-color:#7ACCC8;text-align: center;padding: 5px 8px;font-size: 13px;';
      const hrefText = articleCount === 1 ?
        `There is ${articleCount} article on this page with PubPeer comments` :
        `There are ${articleCount} articles on this page with PubPeer comments`;
      pElement.innerHTML = `
        <img src="${url}/img/logo.svg"; style="vertical-align:middle;padding-right:8px;height:25px;background-color:#7ACCC8;">
        <a href="${queryUrl}" target="_blank" rel="noopener noreferrer" style="color:rgb(255,255,255);text-decoration:none;font-weight:600;vertical-align:middle;">
          ${hrefText}
        </a>
      `;
      document.body.prepend(pElement);
      onAfterAddingTopBar();
    }
  }

  function appendPublicationDetails(publication) {
    var
      googleSnippetDiv = "div.s",
      bingSnippetDiv = "div.b_caption",
      duckDuckGoSnippetDiv = "div.result__body",
      snippetsSelector = `${googleSnippetDiv}, ${bingSnippetDiv}, ${duckDuckGoSnippetDiv}, div, span`;

    let total_comments = publication.total_comments;
    let hrefText = (total_comments == 1) ? `1 comment` : `${total_comments} comments`;
    hrefText += ` on PubPeer (by: ${publication.users})`;
    let linkToComments = publication.url + utm;
    let unsortedDoiElements = contains(snippetsSelector, publication.id);
    let aDoiElement = [];
    if (unsortedDoiElements.length > 0) {
      for (let m = 0; m < unsortedDoiElements.length; m++) {
        var allParents = unsortedDoiElements[m].parents().length;
        aDoiElement.push({
          element: unsortedDoiElements[m],
          rents: allParents
        });
      }
      aDoiElement.sort(function (a, b) {
        return b.rents - a.rents;
      });
    }
    let elementsWithDois = aDoiElement.length;
    for (let k = 0; k < elementsWithDois; k++) { //try each element that contains a matched DOI
      if (aDoiElement[k].element.parentNode.getElementsByClassName('pp_comm').length === 0) {
        aDoiElement[k].element.insertAdjacentHTML('afterend',
          Sanitizer.escapeHTML`<div class="pp_comm" style="margin: 1rem 0;display: flex;width: calc(100% - 16px);background-color:#7ACCC8;padding: 5px 8px;font-size: 13px;border-radius:6px;">
            <img src="${url}/img/logo.svg"; style="vertical-align:middle;padding-right:8px;height:25px;background-color:#7ACCC8;"><img>
            <div style="align-items: center;display: flex;">
              <a href="${linkToComments}" style="color:rgb(255,255,255);text-decoration:none;font-weight:600;vertical-align:middle;">
                ${hrefText}
              </a>
            </div>
          </div>`
        );
        if (publication.title) {
          articleTitles.push(publication.title);
        }
      }
    }
  }

  function removeElements (selectors) {
    if (selectors.length) {
      selectors.forEach(selector => {
        removeElementsBySelector(selector);
      });
    }
  }

  function removeElementsBySelector (selector) {
    var PPElements = document.querySelectorAll(selector);
    if (PPElements.length) {
      PPElements.forEach(element => {
        if (element && element.remove && typeof element.remove === 'function') {
          element.remove();
        }
      })
    }
  }

  function initMessaging () {
    safari.self.addEventListener('message', ({ name }) => {
      console.log('message received => ', name)
      if (name === 'addPubPeerMarks') {
        addPubPeerMarks();
      } else if (name === 'removePubPeerMarks') {
        removeElements(['div.pp_comm', 'p.pp_articles']);
      }
    })
  }

  document.addEventListener("DOMContentLoaded", function(event) {
    getPageDOIs();
    initMessaging();
    safari.extension.dispatchMessage("pageLoaded");
  }, false);

}(Browser));
