___INFO___

{
  "type": "MACRO",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Parse Gtag Ordered dataLayer Array to Find Object by Index",
  "description": "Return the identified JSON object by parsing the arguments object / internal array structure (command queue syntax) inserted in to the dataLayer by the GTAG() function.",
  "containerContexts": [
    "WEB"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "eventName",
    "displayName": "eventName (index 0 - likely \u0027event\u0027)",
    "simpleValueType": true,
    "defaultValue": "event",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "eventValue",
    "displayName": "eventValue (index 1 - value of trigger var i.e. {{Event}}\u003d)",
    "simpleValueType": true,
    "defaultValue": "purchase",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "eventIndex",
    "displayName": "eventIndex (returned JSON object)",
    "simpleValueType": true,
    "defaultValue": 2,
    "valueValidators": [
      {
        "type": "REGEX",
        "args": [
          "^[0-9]$"
        ]
      }
    ]
  },
  {
    "type": "SELECT",
    "name": "dataLayerCurrentEvent",
    "displayName": "dataLayerCurrentEvent (trigger var i.e. \u0027{{Event}}\u0027)",
    "macrosInSelect": true,
    "selectItems": [],
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "defaultValue": "{{Event}}"
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

const log = require('logToConsole');
const copyFromWindow = require('copyFromWindow');
const makeNumber = require('makeNumber');
const copyFromDataLayer = require('copyFromDataLayer');
const dataLayer = copyFromWindow('dataLayer');

const eventName = data.eventName || 'event';
const eventValue = data.eventValue || 'purchase';
const eventIndex = data.eventIndex || '2';
const dataLayerCurrentEvent = data.dataLayerCurrentEvent ;

var indexInt = makeNumber(eventIndex); 
var returnResult;

if ( dataLayerCurrentEvent == eventValue ) {

for (var i = dataLayer.length - 1; i > -1; i--) {
  if (dataLayer[i][0] === eventName && dataLayer[i][1] === eventValue) {
    returnResult = dataLayer[i];
    break;
  }
}

if (returnResult[1] === eventValue) {
  return returnResult[indexInt];
} else {
  return undefined ; 
}
  
} else {
  return undefined ; 
}


___WEB_PERMISSIONS___

[
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
            "string": "all"
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
        "publicId": "access_globals",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {
                    "type": 1,
                    "string": "key"
                  },
                  {
                    "type": 1,
                    "string": "read"
                  },
                  {
                    "type": 1,
                    "string": "write"
                  },
                  {
                    "type": 1,
                    "string": "execute"
                  }
                ],
                "mapValue": [
                  {
                    "type": 1,
                    "string": "dataLayer"
                  },
                  {
                    "type": 8,
                    "boolean": true
                  },
                  {
                    "type": 8,
                    "boolean": false
                  },
                  {
                    "type": 8,
                    "boolean": false
                  }
                ]
              }
            ]
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
        "publicId": "read_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedKeys",
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
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 3/10/2026, 9:25:11 PM


