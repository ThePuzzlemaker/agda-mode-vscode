// Generated by ReScript, PLEASE EDIT WITH CARE
'use strict';

var React = require("react");
var Belt_Array = require("bs-platform/lib/js/belt_Array.js");
var Json_decode = require("@glennsl/bs-json/lib/js/src/Json_decode.bs.js");
var Json_encode = require("@glennsl/bs-json/lib/js/src/Json_encode.bs.js");
var Common$AgdaModeVscode = require("../Common.bs.js");
var Component__Link$AgdaModeVscode = require("./Component/Component__Link.bs.js");

var empty = {
  link: undefined,
  icon: undefined
};

function decode(json) {
  return {
          link: Json_decode.field("attrLink", (function (param) {
                  return Json_decode.optional(Common$AgdaModeVscode.Link.decode, param);
                }), json),
          icon: Json_decode.field("attrIcon", (function (param) {
                  return Json_decode.optional(Json_decode.string, param);
                }), json)
        };
}

function encode(x) {
  return Json_encode.object_({
              hd: [
                "attrLink",
                Json_encode.nullable(Common$AgdaModeVscode.Link.encode, x.link)
              ],
              tl: {
                hd: [
                  "attrIcon",
                  Json_encode.nullable((function (prim) {
                          return prim;
                        }), x.icon)
                ],
                tl: /* [] */0
              }
            });
}

var Attributes = {
  empty: empty,
  decode: decode,
  encode: encode
};

function decode$1(param) {
  return Json_decode.map((function (param) {
                return {
                        _0: param[0],
                        _1: param[1],
                        [Symbol.for("name")]: "Elem"
                      };
              }), (function (param) {
                return Json_decode.pair(Json_decode.string, decode, param);
              }), param);
}

function encode$1(x) {
  return Json_encode.pair((function (prim) {
                return prim;
              }), encode, [
              x._0,
              x._1
            ]);
}

var $$Element = {
  decode: decode$1,
  encode: encode$1
};

function text(s) {
  return {
          _0: [{
              _0: s,
              _1: empty,
              [Symbol.for("name")]: "Elem"
            }],
          [Symbol.for("name")]: "RichText"
        };
}

function hole(s, i) {
  return {
          _0: [{
              _0: s,
              _1: {
                link: {
                  TAG: 1,
                  _0: i,
                  [Symbol.for("name")]: "Hole"
                },
                icon: undefined
              },
              [Symbol.for("name")]: "Elem"
            }],
          [Symbol.for("name")]: "RichText"
        };
}

function concatMany(xs) {
  return {
          _0: Belt_Array.concatMany(Belt_Array.map(xs, (function (x) {
                      return x._0;
                    }))),
          [Symbol.for("name")]: "RichText"
        };
}

function make(value) {
  return React.createElement("span", undefined, Belt_Array.mapWithIndex(value._0, (function (i, x) {
                    var attributes = x._1;
                    var text = x._0;
                    var target = attributes.link;
                    if (target !== undefined) {
                      return React.createElement(Component__Link$AgdaModeVscode.make, {
                                  target: target,
                                  jump: true,
                                  hover: false,
                                  children: text,
                                  key: String(i)
                                });
                    }
                    var kind = attributes.icon;
                    if (kind !== undefined) {
                      return React.createElement("div", {
                                  key: String(i),
                                  className: "codicon codicon-" + kind
                                });
                    } else {
                      return React.createElement("span", {
                                  key: String(i)
                                }, text);
                    }
                  })));
}

function decode$2(param) {
  return Json_decode.map((function (elems) {
                return {
                        _0: elems,
                        [Symbol.for("name")]: "RichText"
                      };
              }), (function (param) {
                return Json_decode.array(decode$1, param);
              }), param);
}

function encode$2(x) {
  return Json_encode.array(encode$1, x._0);
}

var Module = {
  Attributes: Attributes,
  $$Element: $$Element,
  text: text,
  hole: hole,
  concatMany: concatMany,
  make: make,
  decode: decode$2,
  encode: encode$2
};

function RichText(Props) {
  return make(Props.value);
}

var make$1 = RichText;

exports.Module = Module;
exports.Attributes = Attributes;
exports.$$Element = $$Element;
exports.text = text;
exports.hole = hole;
exports.concatMany = concatMany;
exports.decode = decode$2;
exports.encode = encode$2;
exports.make = make$1;
/* react Not a pure module */