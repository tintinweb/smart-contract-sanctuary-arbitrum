// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

interface IYouAreRender {
    function tokenURI(uint256 tokenId, uint256[] memory history, uint256 transfers) external pure returns (string memory);

    function renderSVG(uint256 tokenId, uint256[] memory history) external pure returns (string memory);

    function renderSVGBase64(uint256 tokenId, uint256[] memory history) external pure returns (string memory);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Arrow {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(
        string memory x,
        string memory y
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "g",
                string.concat('transform="translate(', x, ', ', y, ')"'),
'<path d="M5 5L5 59" stroke="black" stroke-width="2"/>',
'<path d="M4.30133 0.409091C4.61185 -0.136364 5.38815 -0.136363 5.69867 0.409091L9.89071 7.77273C10.2012 8.31818 9.81308 9 9.19204 9H0.807961C0.186918 9 -0.201233 8.31818 0.109289 7.77273L4.30133 0.409091Z" fill="black"/>'
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {SVG} from "./SVG.sol";
import {Util} from "./Util.sol";

library Background {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render() internal pure returns (string memory) {
        return
            SVG.element(
                "rect",
                SVG.rectAttributes({
                    _width: "100%",
                    _height: "100%",
                    _fill: "#f8f8f8",
                    _attributes: ""
                })
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(string memory _data) internal pure returns (string memory) {
        return encode(bytes(_data));
    }

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Dot {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(
        string memory x,
        string memory y
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "circle",
                SVG.circleAttributes(
                    "8",
                    x,
                    y
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {SVG} from "./SVG.sol";
import {Util} from "./Util.sol";

library Effect {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function vhsFilter(
        uint256 vhsLevel,
        uint256 distortionLevel,
        bool invert,
        bool animate
    ) internal pure returns (string memory) {
        string memory colorMatrix = invert
            ? "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.35 0"
            : "0 0 0 0 1 0 0 0 0 1 0 0 0 0 1 0 0 0 0.35 0";
        return
            string.concat(
                '<defs><filter id="vhs" x="0" y="0" width="616" height="889" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix" /><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha" /><feOffset dx="',
                (
                    vhsLevel == 1 ? "-6" : vhsLevel == 2 ? "-9" : vhsLevel == 3
                        ? "-10"
                        : /*l4+*/ "-12"
                ),
                '" /><feGaussianBlur stdDeviation="2" /><feComposite in2="hardAlpha" operator="out" /><feColorMatrix type="matrix" values="',
                colorMatrix,
                '" /><feBlend mode="normal" in2="BackgroundImageFix" result="textBlur_pass1" /><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha" /><feOffset dx="',
                vhsLevel == 1 ? "-3" : vhsLevel == 2 ? "-4.5" : vhsLevel == 3
                    ? "-5"
                    : /*l4+*/ "-6",
                '" /><feGaussianBlur stdDeviation="2" /><feComposite in2="hardAlpha" operator="out" /><feColorMatrix type="matrix" values="',
                colorMatrix,
                '" /><feBlend mode="normal" in2="textBlur_pass1" result="textBlur_pass2" /><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha" /><feOffset dx="',
                vhsLevel == 1 ? "3" : vhsLevel == 2 ? "4.5" : vhsLevel == 3
                    ? "5"
                    : /*l4+*/ "6",
                '" /><feGaussianBlur stdDeviation="2" /><feComposite in2="hardAlpha" operator="out" /><feColorMatrix type="matrix" values="',
                colorMatrix,
                '" /><feBlend mode="normal" in2="textBlur_pass2" result="textBlur_pass3" /><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha" /><feOffset dx="',
                vhsLevel == 1 ? "-6" : vhsLevel == 2 ? "-9" : vhsLevel == 3
                    ? "-10"
                    : /*l4+*/ "-12",
                '" /><feGaussianBlur stdDeviation="2" /><feComposite in2="hardAlpha" operator="out" /><feColorMatrix type="matrix" values="',
                colorMatrix,
                '" /><feBlend mode="normal" in2="textBlur_pass3" result="textBlur_pass4" /><feBlend mode="normal" in="SourceGraphic" in2="textBlur_pass4" result="shape" /><feGaussianBlur stdDeviation="',
                vhsLevel == 1 ? "3.5" : vhsLevel == 2 ? "4" : vhsLevel == 3
                    ? "4.5"
                    : /*l4+*/ "5",
                '" result="textBlur_pass5" />',
                '<feTurbulence baseFrequency=".015" type="fractalNoise" />',
                '<feColorMatrix type="hueRotate" values="0">',
                (
                    animate
                        ? '<animate attributeName="values" from="0" to="360" dur="16s" repeatCount="indefinite" />'
                        : ""
                ),
                "</feColorMatrix>",
                '<feDisplacementMap in="textBlur_pass5" xChannelSelector="R" yChannelSelector="B" scale="',
                distortionLevel == 1 ? "10" : distortionLevel == 2
                    ? "20"
                    : "22",
                '">',
                (
                    animate
                        ? (
                            string.concat(
                                '<animate attributeName="scale" values="',
                                distortionLevel == 1
                                    ? "25;15;20;10;20;15;25"
                                    : distortionLevel == 2
                                    ? "30;20;20;30"
                                    : "28:38:22:38:28",
                                '" dur="16s" repeatCount="indefinite" />'
                            )
                        )
                        : ""
                ),
                "</feDisplacementMap></filter></defs>"
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Line {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(
        string memory x1,
        string memory y1,
        string memory x2,
        string memory y2,
        string memory strokeDashArray
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "line",
                string.concat(
                    'x1=',
                    Util.quote(x1),
                    ' y1=',
                    Util.quote(y1),
                    ' x2=',
                    Util.quote(x2),
                    ' y2=',
                    Util.quote(y2),
                    ' stroke-dasharray=',
                    Util.quote(strokeDashArray)
                )
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Base64} from "./Base64.sol";
import {Util} from "./Util.sol";

library Metadata {
    string constant JSON_BASE64_HEADER = "data:application/json;base64,";
    string constant SVG_XML_BASE64_HEADER = "data:image/svg+xml;base64,";

    function encodeMetadata(
        uint256 _tokenId,
        string memory _name,
        string memory _description,
        string memory _attributes,
        string memory _svg
    ) internal pure returns (string memory) {
        string memory metadata = string.concat(
            "{",
            Util.keyValue("tokenId", Util.uint256ToString(_tokenId)),
            ",",
            Util.keyValue("name", _name),
            ",",
            Util.keyValue("description", _description),
            ",",
            Util.keyValueNoQuotes("attributes", _attributes),
            ",",
            Util.keyValue("image", _encodeSVG(_svg)),
            "}"
        );

        return _encodeJSON(metadata);
    }

    /// @notice base64 encode json
    /// @param _json, stringified json
    /// @return string, bytes64 encoded json with prefix
    function _encodeJSON(
        string memory _json
    ) internal pure returns (string memory) {
        return string.concat(JSON_BASE64_HEADER, Base64.encode(_json));
    }

    /// @notice base64 encode svg
    /// @param _svg, stringified json
    /// @return string, bytes64 encoded svg with prefix
    function _encodeSVG(
        string memory _svg
    ) internal pure returns (string memory) {
        return string.concat(SVG_XML_BASE64_HEADER, Base64.encode(bytes(_svg)));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";

library SVG {
    /*//////////////////////////////////////////////////////////////
                                 ELEMENT
    //////////////////////////////////////////////////////////////*/

    function element(
        string memory _type,
        string memory _attributes
    ) internal pure returns (string memory) {
        return string.concat("<", _type, " ", _attributes, "/>");
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _type,
                " ",
                _attributes,
                ">",
                _children,
                "</",
                _type,
                ">"
            );
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2
    ) internal pure returns (string memory) {
        return element(_type, _attributes, string.concat(_child1, _child2));
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3
    ) internal pure returns (string memory) {
        return
            element(
                _type,
                _attributes,
                string.concat(_child1, _child2, _child3)
            );
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4
    ) internal pure returns (string memory) {
        return
            element(
                _type,
                _attributes,
                string.concat(_child1, _child2, _child3, _child4)
            );
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5
    ) internal pure returns (string memory) {
        return
            element(
                _type,
                _attributes,
                string.concat(_child1, _child2, _child3, _child4, _child5)
            );
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6
    ) internal pure returns (string memory) {
        return
            element(
                _type,
                _attributes,
                string.concat(
                    _child1,
                    _child2,
                    _child3,
                    _child4,
                    _child5,
                    _child6
                )
            );
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6,
        string memory _child7
    ) internal pure returns (string memory) {
        return
            element(
                _type,
                _attributes,
                string.concat(
                    _child1,
                    _child2,
                    _child3,
                    _child4,
                    _child5,
                    _child6,
                    _child7
                )
            );
    }

    function element(
        string memory _type,
        string memory _attributes,
        string memory _child1,
        string memory _child2,
        string memory _child3,
        string memory _child4,
        string memory _child5,
        string memory _child6,
        string memory _child7,
        string memory _child8
    ) internal pure returns (string memory) {
        return
            element(
                _type,
                _attributes,
                string.concat(
                    _child1,
                    _child2,
                    _child3,
                    _child4,
                    _child5,
                    _child6,
                    _child7,
                    _child8
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                               ATTRIBUTES
    //////////////////////////////////////////////////////////////*/

    function svgAttributes() internal pure returns (string memory) {
        return
            string.concat(
                'xmlns="http://www.w3.org/2000/svg" '
                'xmlns:xlink="http://www.w3.org/1999/xlink" '
                'width="100%" '
                'height="100%" '
                'viewBox="0 0 1300 1300" ',
                'preserveAspectRatio="xMidYMid meet" ',
                'fill="none" '
            );
    }

    function coordAttributes(
        string[2] memory _coords
    ) internal pure returns (string memory) {
        return
            string.concat(
                "x=",
                Util.quote(_coords[0]),
                "y=",
                Util.quote(_coords[1]),
                " "
            );
    }

    function coordAttributes(
        string[2] memory _coords,
        string memory _attributes
    ) internal pure returns (string memory) {
        return
            string.concat(
                "x=",
                Util.quote(_coords[0]),
                "y=",
                Util.quote(_coords[1]),
                " ",
                _attributes,
                " "
            );
    }

    function rectAttributes(
        string memory _width,
        string memory _height,
        string memory _fill,
        string memory _attributes
    ) internal pure returns (string memory) {
        return
            string.concat(
                "width=",
                Util.quote(_width),
                "height=",
                Util.quote(_height),
                "fill=",
                Util.quote(_fill),
                " ",
                _attributes,
                " "
            );
    }

    function circleAttributes(
        string memory _r,
        string memory _x,
        string memory _y
    ) internal pure returns (string memory) {
        return
            string.concat(
                "r=",
                Util.quote(_r),
                "cx=",
                Util.quote(_x),
                "cy=",
                Util.quote(_y)
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";
import {SVG} from "./SVG.sol";

library Text {
    /*//////////////////////////////////////////////////////////////
                                 RENDER
    //////////////////////////////////////////////////////////////*/

    function render(
        string memory text,
        uint256 xOffset,
        uint256 yOffset
    ) internal pure returns (string memory) {
        return
            SVG.element(
                "text",
                SVG.coordAttributes({
                    _coords: [
                        Util.uint256ToString(xOffset),
                        Util.uint256ToString(yOffset)
                    ]
                }),
                text
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Util} from "./Util.sol";

library Traits {

    function coordinatesForChainId(
        uint256 tokenId,
        uint256 chainId
    ) internal pure returns (uint, uint) {
        uint n = uint256(keccak256(abi.encodePacked(tokenId, chainId)));
        uint x = n % 1_000;
        uint y = (n / 10_000) % 1_000;
        return (x, y);
    }

    /*//////////////////////////////////////////////////////////////
                                 TRAITS
    //////////////////////////////////////////////////////////////*/

    function attributes(
        uint256 tokenId,
        uint256 transfers
    ) internal pure returns (string memory) {
        string memory result = "[";
        result = string.concat(
            result,
            _attribute("Crossings", Util.uint256ToString(transfers == 0 ? 0 : transfers - 1)),
            ",",
            _attribute("Origin", Util.uint256ToString(tokenId))
        );
        return string.concat(result, "]");
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _attribute(
        string memory _traitType,
        string memory _value
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                Util.keyValue("trait_type", _traitType),
                ",",
                Util.keyValue("value", _value),
                "}"
            );
    }

    function _attribute(
        string memory _value
    ) internal pure returns (string memory) {
        return
            string.concat(
                "{",
                Util.keyValue("value", _value),
                "}"
            );
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

library Util {
    error NumberHasTooManyDigits();

    /// @notice wraps a string in quotes and adds a space after
    function quote(string memory value) internal pure returns (string memory) {
        return string.concat('"', value, '" ');
    }

    function keyValue(
        string memory _key,
        string memory _value
    ) internal pure returns (string memory) {
        return string.concat('"', _key, '":"', _value, '"');
    }

    function keyValueNoQuotes(
        string memory _key,
        string memory _value
    ) internal pure returns (string memory) {
        return string.concat('"', _key, '":', _value);
    }

    /// @notice converts a uint256 to ascii representation, without leading zeroes
    /// @param _value, uint256, the value to convert
    /// @return result the resulting string
    function uint256ToString(
        uint256 _value
    ) internal pure returns (string memory result) {
        if (_value == 0) return "0";

        assembly {
            // largest uint = 2^256-1 has 78 digits
            // reserve 110 = 78 + 32 bytes of data in memory
            // (first 32 are for string length)

            // get 110 bytes of free memory
            result := add(mload(0x40), 110)
            mstore(0x40, result)

            // keep track of digits
            let digits := 0

            for {

            } gt(_value, 0) {

            } {
                // increment digits
                digits := add(digits, 1)
                // go back one byte
                result := sub(result, 1)
                // compute ascii char
                let c := add(mod(_value, 10), 48)
                // store byte
                mstore8(result, c)
                // advance to next digit
                _value := div(_value, 10)
            }
            // go back 32 bytes
            result := sub(result, 32)
            // store the length
            mstore(result, digits)
        }
    }

    function uint256ArrayToString (
        uint256[] memory _values
    ) internal pure returns (string memory result) {
        if (_values.length == 0) return "[]";
        string memory temp;
        for (uint i = 0; i < _values.length - 1; i++) {
            temp = string.concat(temp, uint256ToString(_values[i]), ",");
        }
        return string.concat("[", temp, uint256ToString(_values[_values.length - 1]), "]");
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Metadata} from "./libraries/Metadata.sol";
import {Util} from "./libraries/Util.sol";
import {Traits} from "./libraries/Traits.sol";
import {Background} from "./libraries/Background.sol";
import {Text} from "./libraries/Text.sol";
import {Traits} from "./libraries/Traits.sol";
import {SVG} from "./libraries/SVG.sol";
import {Effect} from "./libraries/Effect.sol";
import {Dot} from "./libraries/Dot.sol";
import {Arrow} from "./libraries/Arrow.sol";
import {Line} from "./libraries/Line.sol";
import {IYouAreRender} from "./interfaces/IYouAreRender.sol";

contract YouAreRender is IYouAreRender {
    /*//////////////////////////////////////////////////////////////
                                TOKENURI
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 tokenId, uint256[] memory history, uint256 transfers) external pure returns (string memory) {
        string memory wordString = string.concat("You Are Here ", Util.uint256ToString(tokenId));
        return
            Metadata.encodeMetadata({
                _tokenId: tokenId,
                _name: wordString,
                _description: "You Are Here",
                _attributes: Traits.attributes(tokenId, transfers),
                _svg: _svg(tokenId, history)
            });
    }

    function renderSVG(uint256 tokenId, uint256[] memory history) external pure returns (string memory) {
        return _svg(tokenId, history);
    }

    function renderSVGBase64(uint256 tokenId, uint256[] memory history) external pure returns (string memory) {
        return Metadata._encodeSVG(_svg(tokenId, history));
    }

    /*//////////////////////////////////////////////////////////////
                                INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _svg(uint256 tokenId, uint256[] memory history) internal pure returns (string memory) {
        return
            SVG.element(
                "svg",
                SVG.svgAttributes(),
                string.concat(
                    '<defs><style>@font-face {font-family: "APL385";src: url("',
                    "data:font/woff2;charset=utf-8;base64,d09GMgABAAAAAA9IABAAAAAAGeAAAA7qAAEAAAAAAAAAAAAAAAAAAAAAAAAAAAAAP0ZGVE0cGh4GVgCDOghICYRlEQgKm1iYRQtOAAE2AiQDgRgEIAWFHgeBdQyBdxvfFgXc8W4HCirUJwH8Xx7wZLzGawYLVkGEp6zqRUXwEGpU1bMT2vUnpojxM/EzfkaMAaGHfi16N1achM/VWurxMCUZ0VPbCWdY69m/zxDnID0cIcnsz+O2/3M3cjMbtBHEyKK2kUb1q2zMX+bL5OmPbo9NE5JjfQKBzPVr8GOqtsLJGvc15pWv/7im/0qcFAAyopaFlO/lbqjE1IRpuzlAnv/feV/1LQootsEAbGiddP3/WA/7+P3hJ3qckBQKdLf53kAlAI0Pfwkhr21+afvdIZ1KkM0seI7fIiobVHuxnklXPfBSW9Wq5P+mNft/snNMKKXneYTjnTAYgTHJDGXKleT6bLmby1G2UHL03FKbEwiZpVTVi5B0ibAIj7ACJ7E1hoemobNyPDxtj+FqGZwDlNDrj0UAgD4vvL2uNQDw4v3tYQDw0au/bEEAYAYADgAwQIDAFwLWCdASn8t2bGCxD1Z47fANvw1+XE3TPD5GcvmAYYDhy2F3gP4AT1T+VnVCCnPffzk1/9cAbi+mdOF1Jz53umFxTKNhFgv2Gy9CZDAw768bK1WmHMUUKAyN4zsmDN7P/H8RxEekQtYvaoO/UXeZPHLfXTfMmTFtSu+30we/fnDrbREyCMAI4gCzh7D2MECIn1LvYLE53H+5WABqAcKyulb/T9YL2AI79hzUG8DRF48/Ki2MOOGsi6561aS78Ju/GZ1lNG7SYb846rQtbsFuB+2XIEO01RqVqla/bpHxAANI7ERXn6Bjw8Lj2jRwSqTa4j/5vqVX+ImlaQGQoW9ElQTATOeANLPVAXCzmkZI6RONFBuAZaK30Kx35E/dWcW18q/eQOCNwA4uQcuGtdamBfP1TPTEWACOOfTyD/oEdKCfUAAbgGsOfcZJdWmeSYin8hBI+Ib2BT3yrbqzBDyvnQms/A54feIW3SzV+5cpra1yGHeAC+0gNByKU3G+oI6Rhp5NEmbgCULglkwIUSu3zK6R0MJcMoxXmUsPW0SOAi5iB7S3SMUCYtSdsVUY+9RiH+ZpC2ktq9/TtFb07joH5HNQOwGGJXHOutvSML0rUGWSzsFYDpAVB8hv56RgiNxTzTZ8ZCC8lFVWYIKwBu7z5WyMUG4T3C6ZsYb11taQu9U616U7FthxQd1UqcvoA+3MMdT5dQ0NfudFnFfphViEHkrqFgrhOQJwg2qAhBWR4m915JGXPt9w5JNfDgXNI30xU56xN4gYBiQyhg4hrS8SQDfZDy2Q9QDYU4D/WhEO5gGwvoFhRjBALduGccDwJ29nDX4hdDQQyGU6g9XksJzM1RLJRqbqrzVbqdS4WGvlA84Y1qe15bEflbS8RbKFhXeQjvO0nCfIpOIULjBqgWQvQWt5k6C3K4GJBY0EbSR8nCZItWOSrEwGnAOQjHFGEtVgU9u74fjByMOBqoIDzJEpY3CeiKoVQlq2KtcBJW6OkrQVzc9HgIf89BX/gwXxC5mvno3i2C+BbWMFBSghiB5r8wImSuFZZmyAaJNrnyATrRqjVIEZfnLKiNQ7CGmCFtXIcbeZ4zpwFi/JXlx0ZMbsCUgk9BAsiGgZRglJm5Fii74lIlFpG0e808T8K6zpro9aBqnHidwTvdcE3RODiegZBDLmb6oyAIox/xnGJTRrUpglWudA+oehADyBJ2Y+mB8AM6JlKS6QLFcAyM5VcjBiq0z1bIoYiVkBmPLEv6QAzaKGfKSU0PqMZCYAGLaJViuI8wQJ6ghd/vKFVQsL8nLALeNjiI5MU8w0hwjFlnITxONnpD9QY8DcKxIfnxNesJGNj5ecpMCjIvJr9RHaStP0FJwqqQw+UcSKEUpaKGHez26lpVmPireiYqBq9ODtDCiTtcPRM/aCEi8f8eJoKpLz9O1Ig/KJOi1MFvJMFZa+lOJropsEmIBgGyIKYBV7da5Wo7PgQCiaR57gSE+cPgz1tYvV6j5JtKqlXwiz5sT7iH1hTX5mV1dAU5ODUF8Imis+QgX1u1HUhxhS13BVs4hrzckANiX8/lf8nfT9j/ZLTz1sMNV80HmlsOtSnOUc0R32awgVV3u1qan7XHdqW9MbI78pEk94ZQQyA1TOioGvfzSrtuHb1g3gcV5yVRZ61IFwZUmvTZpTq+sF1/jMzroQar+Ass4LL5LF6laLRnNxu1VB5Cd/agdEXmkNxQe+rgF9X4++pLDseVhEarJoNr+yiq0MSpFGfv3QR6mcmOypMBjmjtZXttVSd+Vnmw311IVHX7//oCYw1y+VSltbOSWLWG0wrA2TbeQW++miCkv9vedPndPpTgSWiAudj3tlijcYJFlrzQ1kRGS57R4Pu/I4WN2QnJ8ur1sTljYT0OSUniy+PVBzigyq813VKLh1ytt7q0sjrFpDGizLz+OD7WyK1kNxb7T1MYe0k5uUQLfSjrcdVw+FqNbd9zJTBW4/M3TgzsLljpV9q88tq5Bo/02GwooE2nuzN12SFCqPUcakwaAylyrst2I1PC0PyxUGuBJJw7jV+RffcUnTnR/ev8YPNnhl33fKPz89uz0SpZYFic/tOnYp/xgzPPo5ttFtc596cN/y3jW7Xl9CaCzs/lW0/BhxoEEasf/Sb2I3jYfWMcfJ9IIfuv6g52X70cKR5UxL7uR0F7XK8LrNdy2GsDXS8rFqXalu/Gxrc0fL6cv7yksjwluktQd6BguVAWvTPerGPrJszRMYwhJ+qGvqaFH3pwXSnWVVQx7PJa38U2sm+9uGOt7Y0JE/5PNFzpzOhWfrm+jn+YOwolvqbE1/snSga+s1eG/rtrXLLzzeUKA2KNeXKds0bRXJ7xxZ2rmsKF2ZXbqvUG4ZQwPGwfPtqssl6pp8p4xchOTxthssbKPXLPPQSYKEOsk7A8Z2I3wzLCstl/2kGBPLJT/cihatDC3JS171TZFaK/sWMYjSqBKe54tYIvH98G9ufBB6N4hG9WPiMoGYHeV9wzvyrKfoVpTPBalgvadaYSu88W9CU0IytPFu6+Xge843evl3yr2ZCOPz4hsfLfP2KH4a3ji59nN31zHnjpmNH/N4+x6tHvdeADSiGc/eeuud9JXM6I2uxXrrpaRcNULqXMF2Ztn5zPSgJQkXlu27kGfjnSIMZeukfduFTYGvX6l2i+mMbGiAbflfXnPc0b00TjT8/g4KS/Roy0aY70CxqKg9M0EuUOJYqLOPe/S1gRXD/8ETLN3n/1QkeCxQn19dv6Z/9cpt1SqZY/hmk18wy1dkrvp/KPD/8fSTCxmA7IZalnZVJB7ncIWGY28R6V77yVE8k29r55BdKvQWvJnDj0xzXvoP7qbJvD8290WLjvOcmJSqc5ZpdlktjBbgfPSRPwDwuyNCxwvLoPZ2RkpeFtZ1YFWIo+PmEVhpGe3+a0wDmxXDwd3awAFQ3t1BzwLNM5ZbxJotXoLDmHO9XxsrTTeYTuXkVCwWG/oXBTvbGotx0LGcYiMUOkoDxaI2zMsM1nleDhVCxDxVCXIHFBQA+tji0gNEA5OGb6yqOqA6FbrGgQimNwvjIizd6BUT9liofiVbG0r46B1svdUuoJPGW4HUA8bByuL4IdNbzPpnRSm3/MKG8qg0vItKrlWLuLPpZrAy7gidzs5kFUIVScoBbiEvrMRW7NnBpK8cP2zV3ZozWk2CDYozfT1EbMpt+Tj38unr979eYmIB1A9BVN8p9tgPlm9U2q2retbYqVovInNoSumpuD7LGjvcjONWIevS+C4RE4TRh8zlDpvOeNJael6EQxiBxTxoLxu9ZIUeMxA8s7iVSQOegXSXxlJwYZDzPKCFhgIHQrCIMO8TB3PrOSqb6KUliHRC+ixzgU9lvmMtnf/E1p0JNpI502YQbwlDX8qktVJpdsCqhlpzHJL7E66hZmqVtZZqxryH33pVK438BWs8CFu9WK84FYpnSt8iXqrQOi8Ljg31wCnpSBfCRld6CNLdI2wzreYCG6YTLW1RYmWgc7y+MARa2rxAACpGJ00ROxycCtfJVWhvTs2i+njKSERuzAYbqkppK4wusZ5TqJL4JQdNDSiVNjuDDhA1JGeqoXuPWYGLpUILIvB5flzLj5SGePmT5sSZpBTdQp+HW8PSlppxGpPClaFxWeQEBmqRl4k4hni+zmE7tnWw0cpdw22IvVL4CbCgaXVXVbW+t7far7Qr3RqNJEQoKdFsUVJh1+W2ZJOPJ40MAmbwe8Tiv+B9PScFsQJ+s4x6U/HOQNoo5OxS8PnVlpqLRr0ffmBRYz14DLcGLksc7Bsm3vuTEQBgIP57uT6lweI3noAHn6eMh8ULG6qzS54woNCnH/S/HzhFAINhTwUNv/atDHr3wxNO0Xh7pvEensYHOIIf4RgexJ34Lb7AiyjDy2jENNxVAuw1DbaGY/Ss+HoA+BKuUuTYB4U1o3v4R4j2+kmBvzkqYeBA6lsHZK3cBhwQi4/n9QEfgZs+HwML2C3xGDnps0Bi2meDg699DpghkFwhZsgnTj4JbvFBM5Li3wWH6P17EJIO/z5YoJP4oGD8jG91cMm0dK3a9OtQr1adLkJhQoSKIiGUqopuyrV0o9RcSl3qGplWZOsuG0Xm2I1unaprmc2UTbusz9S1WK35DEvnX0vKvl4qmQLhYkS2IXfdepVaVan+3Wq1ujUp1zG2E3T2KV1eOJa61Vp4Uaidp6RyyvWptuteKKWl0qaJR0tlXX0zfTyjWoWaqlt8a0JJT12Iqwjl+ZXR2K2JFpcvo6xKhDAtZRhm9pRqlNtS69KmWpivmce7s9I3Su1eWR/HjrEmGICNLk5X3coPIAzhgIPtp3BfkSMnzly4cuMjgFioMJFixEkIC7ERB3ERD/ERgUhkhsyRBbJEVsga2XBq9Wzqb6sL5Xa31IeEhGSEJ6eGiLC2pSahJIyEkwgSSaJINIkhsYXUqWFZhcjgeLT0V9HimqEtkG/kydTDCG3VDGd9ADXeaKXJN9opql2ucTd68/VqMOLCTCMuzjByZ9PrgCMcHPEGnMoId/uE7GmcCmRNY+cjbxo+gvxpvGYkpvGTkJxGWKPZVPJlBRnNlZAWEWreOjqMZ/VMZanTTvNli4KVVqQZlgvS+p5uVZFojHZi",
                    '");}',
                    "line { stroke: black; stroke-width: 4px; } text { fill: black; font-size: 42px; font-family: APL385, APL385 Unicode, APL386, APL386 Unicode, mono; text-anchor: middle; } circle { r: 8px; fill: black; } path { fill: black; stroke: black; stroke-width: 4px;}",
                    "</style>",
                    '<filter id="texture"><feTurbulence type="fractalNoise" baseFrequency="0.05" numOctaves="2" result="turbulence" /><feGaussianBlur in="turbulence" stdDeviation="1" result="blurredTurbulence"/><feDisplacementMap in2="blurredTurbulence" in="SourceGraphic" scale="3" xChannelSelector="R" yChannelSelector="G"/></filter>',
                    '<metadata id="history">',
                        Util.uint256ArrayToString(history),
                    "</metadata>",
                    '</defs>'
                ),
                Background.render(),
                _render(tokenId, history)
            );
    }

    function _render(uint256 tokenId, uint256[] memory history) public pure returns (string memory) {
        if (history.length == 0) return Text.render("NOWHERE", 650, 650);

        uint256[] memory fromChainIds = new uint256[](history.length);
        uint256[] memory toChainIds = new uint256[](history.length);
        uint256[] memory frequencies = new uint256[](history.length);
        uint256[] memory indexToConnectionIndex = new uint256[](history.length);
        uint256[] memory indexToUniqueIdIndex = new uint256[](history.length);
        uint256[] memory uniqueIds = new uint256[](history.length);
        uint256 indexCount = 0;

        for (uint256 i = 0; i < history.length; i++) {
            if (i < history.length - 1) {
                // Sort chain IDs to always use the smaller one first
                (uint256 smaller, uint256 larger) = history[i] < history[i + 1] ? (history[i], history[i + 1]) : (history[i + 1], history[i]);

                // Find the index of the pair of chain IDs
                uint256 foundIndex = type(uint256).max;
                for (uint256 j = 0; j < indexCount; j++) {
                    if (fromChainIds[j] == smaller && toChainIds[j] == larger) {
                        foundIndex = j;
                        break;
                    }
                }

                if (foundIndex == type(uint256).max) {
                    fromChainIds[indexCount] = smaller;
                    toChainIds[indexCount] = larger;
                    frequencies[indexCount] = 1;
                    indexToConnectionIndex[i] = indexCount;
                    indexCount++;
                } else {
                    indexToConnectionIndex[i] = foundIndex;
                    frequencies[foundIndex]++;
                }
            }

            for (uint j = 0; j < uniqueIds.length; j++) {
                if (uniqueIds[j] == 0) {
                    uniqueIds[j] = history[i];
                    indexToUniqueIdIndex[i] = j;
                    break;
                } else if (uniqueIds[j] == history[i]) {
                    indexToUniqueIdIndex[i] = j;
                    break;
                }
            }
        }

        return _drawRender(tokenId, history, indexCount, indexToConnectionIndex, frequencies, uniqueIds, indexToUniqueIdIndex);
    }

    struct DrawState {
        uint256 xPrev;
        uint256 yPrev;
        uint256 x;
        uint256 y;
        string svgTexts;
        bool[] connectionsDrawn;
        bool[] nodesDrawn;
    }

    // Separated because of stack too deep
    function _drawRender(
        uint256 tokenId,
        uint256[] memory history,
        uint256 indexCount,
        uint[] memory indexToConnectionIndex,
        uint[] memory frequencies,
        uint[] memory uniqueIds,
        uint[] memory indexToUniqueIdIndex
    ) internal pure returns (string memory) {
        DrawState memory s;
        s.connectionsDrawn = new bool[](indexCount);
        s.nodesDrawn = new bool[](uniqueIds.length);
        (s.xPrev, s.yPrev) = Traits.coordinatesForChainId(tokenId, history[0]);

        for (uint256 i; i < history.length; i++) {
            (s.x, s.y) = Traits.coordinatesForChainId(tokenId, history[i]);

            if (i > 0) {
                if (!s.connectionsDrawn[indexToConnectionIndex[i - 1]]) {
                    s.svgTexts = string.concat(
                        s.svgTexts,
                        Line.render(
                            Util.uint256ToString(s.x + 150),
                            Util.uint256ToString(s.y + 150),
                            Util.uint256ToString(s.xPrev + 150),
                            Util.uint256ToString(s.yPrev + 150),
                            frequencyToStrokeDashArray(frequencies[indexToConnectionIndex[i - 1]])
                        )
                    );
                    s.connectionsDrawn[indexToConnectionIndex[i - 1]] = true;
                }
                (s.xPrev, s.yPrev) = (s.x, s.y);
            }

            if (!s.nodesDrawn[indexToUniqueIdIndex[i]]) {
                s.svgTexts = string.concat(
                    s.svgTexts,
                    Dot.render(Util.uint256ToString(s.x + 150), Util.uint256ToString(s.y + 150)),
                    Text.render(Util.uint256ToString(history[i]), s.x + 150, s.y + 150 - 25)
                );
                s.nodesDrawn[indexToUniqueIdIndex[i]] = true;
            }

            // You Are Here
            if (i == 0) {
                s.svgTexts = string.concat(
                    s.svgTexts,
                    Arrow.render(Util.uint256ToString(s.x + 150 - 6), Util.uint256ToString(s.y + 150 + 30)),
                    Text.render("YOU ARE HERE", s.x + 150, s.y + 150 + (30 - 9) + 90 + 30)
                );
            }
        }

        return SVG.element("g", 'filter="url(#texture)"', s.svgTexts);
    }

    function frequencyToStrokeDashArray(uint256 _frequency) internal pure returns (string memory) {
        if (_frequency >= 11) return "";
        if (_frequency >= 10) return "14 2";
        if (_frequency >= 9) return "20 3";
        if (_frequency >= 8) return "23 4";
        if (_frequency >= 7) return "25 6";
        if (_frequency >= 6) return "27 8";
        if (_frequency >= 5) return "30 10";
        if (_frequency >= 4) return "40 20";
        if (_frequency >= 3) return "50 30";
        if (_frequency >= 2) return "72 46";
        return "100 60";
    }
}