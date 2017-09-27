var request = require('superagent');

export function getModelsFromBackend() {
  const res = request.get('http://localhost:8080/api/getModel');
  return res;
}

export function getDummyData() {

  var data = [
  {
    type: "container",
    id: "",
    title: "Top-Container2",
    position: {
      left: 0,
      top: 0,
      width: 696,
      height: 523
    },
    children: [
      {
        type: "container",
        id: "",
        title: "Sub-Container 1",
        position: {
          left: 11,
          top: 56,
          width: 658,
          height: 68
        },
        children: [
          {
            type: "button",
            id: "",
            position: {
              left: 254,
              top: 72,
              width: 40,
              height: 40
            },
            fc: function () {
              alert("test")
            }
          },
          {
            type: "button",
            id: "",
            position: {
              left: 600,
              top: 72,
              width: 40,
              height: 40
            },
            fc: function () {
              alert("test")
            }
          }
        ]
      },
      {
        type: "container",
        id: "",
        title: "Sub-Container 2",
        position: {
          left: 11,
          top: 130,
          width: 121,
          height: 380
        }
      },
      {
        type: "container",
        id: "",
        title: "Sub-Container 3",
        position: {
          left: 140,
          top: 129,
          width: 531,
          height: 378
        },
        children: [
          {
            type: "container",
            id: "",
            title: "Subsub-Container 1",
            position: {
              left: 155,
              top: 170,
              width: 238,
              height: 311
            },
            children: [
              {
                type: "organization",
                id: "1",
                title: "Organization A",
                position: {
                  left: 163,
                  top: 211,
                  width: 214,
                  height: 73
                }
              },
              {
                type: "organization",
                id: "2",
                title: "Organization B",
                position: {
                  left: 163,
                  top: 366,
                  width: 214,
                  height: 73
                }
              }
            ]
          },
          {
            type: "container",
            id: "",
            title: "Subsub-Container 2",
            position: {
              left: 416,
              top: 170,
              width: 238,
              height: 311
            },
            children: [
              {
                type: "person",
                id: "3",
                title: "Ola Normann",
                position: {
                  left: 433,
                  top: 375,
                  width: 214,
                  height: 73
                }
              }
            ]
          }
        ]
      }
    ]
  }
];

var relations = [
  {
    type: "relation",
    from: {
      id: "2",
      title: "has supplier"
    },
    to: {
      id: "1",
      title: "is supplier of"
    }
  },
  {
    type: "relation",
    from: {
      id: "1",
      title: "has employee"
    },
    to: {
      id: "3",
      title: "is employee in"
    }
  }
]
  return { data: data, relations: relations };
}
