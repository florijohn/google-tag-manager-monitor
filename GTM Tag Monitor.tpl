___INFO___

{
  "displayName": "GTM Tag Monitor",
  "description": "A template for setting up tag monitoring in Google Tag Manager.",
  "__wm": "VGVtcGxhdGUtQXV0aG9yX0dvb2dsZS1UYWctTWFuYWdlci1Nb25pdG9yLVNpbW8tQWhhdmE\u003d",
  "securityGroups": [],
  "id": "cvt_temp_public_id",
  "type": "TAG",
  "version": 1,
  "brand": {
    "displayName": "",
    "id": "brand_dummy"
  },
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "LABEL",
    "name": "label1",
    "displayName": "This tag will send an event to a given GA4 data stream for each tag that was fired on the event on which this monitoring tag was fired. \nMake sure to add exclude\u003dtrue to this tags \"additional metadata\" in order to not monitor this monitoring tag"
  },
  {
    "type": "RADIO",
    "name": "measurementProtocol",
    "displayName": "Measurement Protocol",
    "radioItems": [
      {
        "value": "ga4",
        "displayValue": "GA4"
      },
      {
        "value": "btnt",
        "displayValue": "BTNT"
      }
    ],
    "simpleValueType": true
  },
  {
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "displayName": "Google Analytics Property ID",
    "simpleValueType": true,
    "name": "gaPropertyID",
    "type": "TEXT",
    "valueHint": "G-123456789",
    "enablingConditions": [
      {
        "paramName": "measurementProtocol",
        "paramValue": "ga4",
        "type": "EQUALS"
      }
    ]
  },
  {
    "alwaysInSummary": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "displayName": "Transport URL",
    "simpleValueType": true,
    "name": "transportUrl",
    "type": "TEXT",
    "defaultValue": "https://region1.google-analytics.com"
  },
  {
    "type": "LABEL",
    "name": "versionLabelSeparator",
    "displayName": "⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ ⛶ "
  },
  {
    "type": "LABEL",
    "name": "versionLabel",
    "displayName": "template version: 1.1.0"
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const addEventCallback = require('addEventCallback');
const sendPixel = require('sendPixel');
const encodeUriComponent = require('encodeUriComponent');
const getUrl = require('getUrl');
const getReferrerUrl = require('getReferrerUrl');
const generateRandom = require('generateRandom');
const log = require("logToConsole");
const getContainerVersion = require('getContainerVersion');

const cv = getContainerVersion();


// The addEventCallback gets two arguments: container ID and a data object with an array of tags that fired
addEventCallback((ctid, eventData) => {
  // Filter out the monitoring tag itself
  const tags = eventData.tags.filter(t => t.exclude !== 'true');
  log('original tags: ', tags);

  const basicMeasurementURL = getBasicMeasurementUrl();

  // For each batch, build a payload and dispatch to the endpoint as a GET request
  tags.forEach(tag => {
    // Try to get tag name from metadata (key 'name' as configured in GTM)
    const rawTagName = (tag.metadata && tag.metadata.name) || tag.name || 'tag_fired';
    // Clean tag name: create a more readable format
    let cleanTagName = '';
    let lastWasSpace = false;
    for (let i = 0; i < rawTagName.length; i++) {
      const char = rawTagName.charAt(i);
      if ((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || (char >= '0' && char <= '9')) {
        cleanTagName += char;
        lastWasSpace = false;
      } else if ((char === ' ' || char === '-') && !lastWasSpace) {
        cleanTagName += '_';
        lastWasSpace = true;
      }
      // Skip all other special characters
    }
    // Remove trailing underscore if exists
    if (cleanTagName.charAt(cleanTagName.length - 1) === '_') {
      cleanTagName = cleanTagName.substring(0, cleanTagName.length - 1);
    }
    const basicMeasurementURL = getBasicMeasurementUrlWithTagName(cleanTagName);
    const payload = '&ep.container_id=' + cv.containerId + '&ep.tag_id=' + tag.id + '&ep.tag_status=' + tag.status + '&epn.tag_execution_time=' + tag.executionTime;
    log('sending url:  ', basicMeasurementURL + payload);
    sendPixel(basicMeasurementURL + payload, null, null);
  });
});

// After adding the callback, signal tag completion
data.gtmOnSuccess();


// ------------ functions
function getUserId() {
  return "tagAudit." + generateRandom(0, 10000000);
}

function getBasicMeasurementUrl() {
  return getBasicMeasurementUrlWithTagName("tag_fired");
}

function getBasicMeasurementUrlWithTagName(eventName) {
  const mpDict = getMeasurementProtocolDict();
  const trackingID = data.gaPropertyID || "";

  const measurementUrl = [
    data.transportUrl,
    mpDict.path,
    "?v=2&",
    mpDict.eventName, "=", eventName,
    "&", mpDict.trackingID, "=", trackingID,
    "&", mpDict.clientID, "=",
    encodeUriComponent(getUserId()),
    "&", mpDict.documentLocation, "=",
    encodeUriComponent(getUrl()),
    "&", mpDict.documentReferer, "=",
    encodeUriComponent(getReferrerUrl()),
    "&", mpDict.cacheBuster, "=",
    encodeUriComponent(getUserId()),
    "&", mpDict.userAgent, "=",
    encodeUriComponent(
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/81.0.4044.92 Safari/537.36"
    )
  ].join("");

  return measurementUrl;
}

function getMeasurementProtocolDict() {
  const measurementProtocol = data.measurementProtocol;
  const btntDict = {
    path: "/btnt",
    eventName: "event_name",
    trackingID: "tracking_id",
    clientID: "client_id",
    documentLocation: "page_location",
    documentReferer: "page_referrer",
    userAgent: "user_agent",
    cacheBuster: "z",
  };
  const ga4Dict = {
    path: "/g/collect",
    eventName: "en",
    trackingID: "tid",
    clientID: "cid",
    documentLocation: "dl",
    documentReferer: "dr",
    userAgent: "ua",
    cacheBuster: "z",
  };
  if (measurementProtocol === "btnt") {
    return btntDict;
  }
  return ga4Dict;
}


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "send_pixel",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_metadata",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_referrer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  }
]


___TESTS___

scenarios:
- name: sendPixel-sucessCalled
  code: |-
    const mockData = {
        gaPropertyID: "UA-123123-1",
        transportUrl: "https://test.com"
    };

    // Call runCode to run the template's code.
    runCode(mockData);

    // Verify that the tag finished successfully.
    assertApi('gtmOnSuccess').wasCalled();


___NOTES___

Created on 12/03/2021, 16:55:43


