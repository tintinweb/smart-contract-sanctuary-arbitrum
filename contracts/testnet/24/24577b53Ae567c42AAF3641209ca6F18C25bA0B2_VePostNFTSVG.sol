// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

contract VePostNFTSVG {
    function buildVePost(
        uint256 tokenId,
        uint8 typeVePost, //0: None, 1: Token, 1: LP NFT
        uint256 startTimeLock,
        uint256 endTimeLock,
        uint256 currentTime,
        uint256 boost,
        uint256 currentWeight
    ) external view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<svg width="202" height="278" viewBox="0 0 420 580" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="202" height="278" fill="#ECECEC"/><g clip-path="url(#clip0_544_23454)">',
                    buildBackground(typeVePost),
                    '<g filter="url(#filter2_f_544_23454)"><circle cx="273.651" cy="264.584" r="145.85" fill="#729BEC"/></g><g filter="url(#filter3_f_544_23454)"><circle cx="210" cy="503.095" r="124.055" fill="#729BEC"/></g><g opacity="0.6" filter="url(#filter4_f_544_23454)"><circle cx="126.23" cy="192.898" r="83.4447" fill="#729BEC"/></g></g><path d="M117.5 1.91895H302.5V29.9189C302.5 38.7555 295.337 45.9189 286.5 45.9189H133.5C124.663 45.9189 117.5 38.7555 117.5 29.9189V1.91895Z" fill="white" fill-opacity="0.1"/>',
                    buildTypeNft(typeVePost),
                    '<rect x="20" y="528.884" width="380" height="28" rx="12" fill="#283975" fill-opacity="0.3"/><text fill="#F8FAFC" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="12" letter-spacing="0em"><tspan x="164.5" y="547.044">&#xa9;post.tech, 2023</tspan></text><g opacity="0.3"><path d="M310.302 291.886C306.981 291.574 303.71 290.312 300.923 288.054L82.6695 113.274C75.147 107.18 73.9884 96.1424 80.0825 88.6199C86.1755 81.0979 97.2149 79.9391 104.736 86.0326L322.99 260.813C330.513 266.907 331.671 277.945 325.577 285.467C321.742 290.202 315.946 292.416 310.302 291.886Z" fill="url(#paint0_linear_544_23454)"/></g>',
                    buildLocation(startTimeLock, endTimeLock, currentTime),
                    buildInformation(tokenId, boost, currentWeight),
                    '<g filter="url(#filter6_f_544_23454)"><path d="M338.278 287.509L327.023 246.467H327.022V246.465L286.028 241.384C284.248 238.645 280.537 234.315 273.56 231.411C266.234 218.913 253.191 216.578 243.502 215.977C224.894 215.837 215.71 228.643 211.781 235.522C213.36 230.936 213.864 224.295 224.097 215.795C233.617 207.869 243.74 196.489 240.789 184.451C236.106 165.187 230.751 143.364 247.892 120.464C246.857 121.135 172.972 141.756 174.118 227.399C174.118 227.874 172.691 205.572 153.063 191.679C134.373 177.336 110.27 163.286 107.81 143.881C107.81 143.881 64.2329 247.265 145.794 284.229C153.875 287.891 142.145 301.564 134.106 305.325C128.185 308.28 113.164 316.467 113.164 316.467C96.691 325.482 87.958 342.275 81.9179 349.125C81.7929 349.265 81.7227 349.335 81.7227 349.335C81.7358 349.335 104.412 333.256 146.322 327.061C192.357 322.785 210.671 308.676 212.2 307.729C225.062 299.789 231.411 283.249 242.122 271.693C261.358 250.941 274.463 245.407 281.156 244.03L295.62 285.45L295.622 285.449L338.278 287.509Z" fill="white" fill-opacity="0.15"/></g><path d="M109.422 11.4951H25.5078C16.6713 11.4951 9.50781 18.6585 9.50781 27.4951V551.844C9.50781 560.68 16.6713 567.844 25.5078 567.844H393.163C401.999 567.844 409.163 560.68 409.163 551.844V27.4951C409.163 18.6586 401.999 11.4951 393.163 11.4951H309.249" stroke="white" stroke-opacity="0.4" stroke-width="2"/><defs><filter id="filter0_f_544_23454" x="-129.11" y="-157.272" width="392" height="392" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="45" result="effect1_foregroundBlur_544_23454"/></filter><filter id="filter1_f_544_23454" x="9.85156" y="-239.746" width="617.825" height="541.897" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="45" result="effect1_foregroundBlur_544_23454"/></filter><filter id="filter2_f_544_23454" x="30.5747" y="21.5078" width="486.151" height="486.152" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="48.6131" result="effect1_foregroundBlur_544_23454"/></filter><filter id="filter3_f_544_23454" x="-18.5239" y="274.571" width="457.048" height="457.048" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="52.2346" result="effect1_foregroundBlur_544_23454"/></filter><filter id="filter4_f_544_23454" x="-54.441" y="12.2275" width="361.342" height="361.341" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="48.6131" result="effect1_foregroundBlur_544_23454"/></filter><filter id="filter5_b_544_23454" x="16" y="368.884" width="387" height="148" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feGaussianBlur in="BackgroundImageFix" stdDeviation="2"/><feComposite in2="SourceAlpha" operator="in" result="effect1_backgroundBlur_544_23454"/><feBlend mode="normal" in="SourceGraphic" in2="effect1_backgroundBlur_544_23454" result="shape"/></filter><filter id="filter6_f_544_23454" x="69.3873" y="108.128" width="281.225" height="253.542" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="6.16769" result="effect1_foregroundBlur_544_23454"/></filter><linearGradient id="paint0_linear_544_23454" x1="170.293" y1="31.3883" x2="264.448" y2="303.133" gradientUnits="userSpaceOnUse"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0"/></linearGradient><linearGradient id="paint1_linear_544_23454" x1="193.321" y1="108.426" x2="182.112" y2="269.909" gradientUnits="userSpaceOnUse"><stop stop-color="white"/><stop offset="1" stop-color="white" stop-opacity="0"/></linearGradient><radialGradient id="paint2_radial_544_23454" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(93.501 99.9404) rotate(90) scale(21.9669)"><stop offset="0.284119" stop-color="white" stop-opacity="0"/><stop offset="1" stop-color="#45CFFF"/></radialGradient><clipPath id="clip0_544_23454"><rect x="0.5" y="1.38379" width="419" height="578" rx="24" fill="white"/></clipPath><clipPath id="clip1_544_23454"><rect x="36" y="388.884" width="347" height="28" rx="4" fill="white"/></clipPath><clipPath id="clip2_544_23454"><rect x="36" y="428.884" width="347" height="28" rx="4" fill="white"/></clipPath><clipPath id="clip3_544_23454"><rect x="36" y="468.884" width="347" height="28" rx="4" fill="white"/></clipPath></defs></svg>'
                )
            );
    }

    function buildTypeNft(
        uint8 typeVePost
    ) internal view returns (string memory) {
        string memory typeStringVePost;
        string memory locationText;

        if (typeVePost == 1) {
            typeStringVePost = "vePost NFT";
            locationText = "160.5";
        } else if (typeVePost == 2) {
            typeStringVePost = "vePost LP NFT";
            locationText = "147.5";
        } else {
            typeStringVePost = "vePost Empty";
            locationText = "160.5";
        }

        return
            string(
                abi.encodePacked(
                    '<text fill="#F8FAFC" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="18" font-weight="bold" letter-spacing="0em">',
                    '<tspan x="',
                    locationText,
                    '" y="30.1592">',
                    typeStringVePost,
                    "</tspan> </text>"
                )
            );
    }

    function buildLocation(
        uint256 startTimeLock,
        uint256 endTimeLock,
        uint256 currentTime
    ) internal pure returns (string memory) {
        uint256 phaseTime = (endTimeLock - startTimeLock) / 7;
        uint256 currentPhase = currentTime - startTimeLock;
        string memory cx;
        string memory cy;

        if (currentPhase > 6 * phaseTime) {
            cx = "316.5";
            cy = "275.464";
        } else if (currentPhase > 5 * phaseTime) {
            cx = "279.5";
            cy = "246.463";
        } else if (currentPhase > 4 * phaseTime) {
            cx = "242.5";
            cy = "218.464";
        } else if (currentPhase > 3 * phaseTime) {
            cx = "204.5";
            cy = "186.464";
        } else if (currentPhase > 2 * phaseTime) {
            cx = "171.5";
            cy = "161.463";
        } else if (currentPhase > phaseTime) {
            cx = "134.5";
            cy = "130.464";
        } else {
            cx = "93.5";
            cy = "100.464";
        }

        return
            string(
                abi.encodePacked(
                    string(
                        abi.encodePacked(
                            '<path d="M93.1123 99.0225L149.024 143.69L204.936 188.357L316.76 277.692" stroke="url(#paint1_linear_544_23454)" stroke-width="4" stroke-linecap="round" stroke-linejoin="round"/>',
                            '<circle opacity="0.1" cx="',
                            cx,
                            '" cy="',
                            cy,
                            '" r="32" fill="white"/>'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            '<circle opacity="0.3" cx="',
                            cx,
                            '" cy="',
                            cy,
                            '" r="18" fill="white"/>'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            '<circle cx="',
                            cx,
                            '" cy="',
                            cy,
                            '" r="10" fill="white"/>'
                        )
                    )
                )
            );
    }

    function buildBackground(
        uint8 lockType
    ) internal view returns (string memory) {
        string memory color1 = lockType == 2 ? "#3088EB" : "#1565FE";
        string memory color2 = lockType == 2 ? "#6F49DC" : "#4473FF";
        string memory color3 = lockType == 2 ? "#8241D8" : "#567BFF";

        return
            string(
                abi.encodePacked(
                    '<path d="M395.174 1.38379H24.1738C10.919 1.38379 0.173828 12.129 0.173828 25.3838V555.384C0.173828 568.639 10.919 579.384 24.1738 579.384H395.174C408.429 579.384 419.174 568.639 419.174 555.384V25.3838C419.174 12.129 408.429 1.38379 395.174 1.38379Z" fill="',
                    color1,
                    '"/><g filter="url(#filter0_f_544_23454)"><circle cx="66.8896" cy="38.728" r="106" fill="',
                    color2,
                    '"/></g>',
                    '<g filter="url(#filter1_f_544_23454)"><ellipse cx="318.764" cy="31.2025" rx="218.913" ry="180.949" fill="',
                    color3,
                    '"/></g>'
                )
            );
    }

    function buildInformation(
        uint256 tokenId,
        uint256 boost,
        uint256 currentWeight
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<g filter="url(#filter5_b_544_23454)"> <rect x="20" y="372.884" width="379" height="140" rx="12" fill="#283975" fill-opacity="0.5"/> <g clip-path="url(#clip1_544_23454)"> <text fill="#E2E8F0" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="20" letter-spacing="0em"> <tspan x="36" y="408.817">ID: </tspan> </text> <text fill="#F1F5F9" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="20" font-weight="bold" letter-spacing="-0.005em" text-anchor="end"> <tspan x="380" y="408.934" >#',
                    toString(tokenId),
                    '</tspan></text></g><g clip-path="url(#clip2_544_23454)"><text fill="#E2E8F0" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="20" letter-spacing="0em"><tspan x="36" y="449.817">Boost: </tspan></text><text fill="#F1F5F9" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="20" font-weight="bold" letter-spacing="-0.005em" text-anchor="end"><tspan x="380" y="449.817">',
                    toString(boost / 100),
                    '%</tspan></text></g><g clip-path="url(#clip3_544_23454)"><text fill="#E2E8F0" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="20" letter-spacing="0em"><tspan x="36" y="489.817">Current Power: </tspan></text><text fill="#F1F5F9" xml:space="preserve" style="white-space: pre" font-family="Arial" font-size="20" font-weight="bold" letter-spacing="-0.005em" text-anchor="end"><tspan x="380" y="489.817">',
                    numberWithCommas(uint256(currentWeight / 1e18)),
                    "</tspan></text></g></g>"
                )
            );
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function numberWithCommas(
        uint256 _num
    ) internal pure returns (string memory) {
        string memory numStr = toString(_num);
        uint256 length = bytes(numStr).length;
        if (length == 1) return numStr;
        uint256 commaCount = (length - 1) / 3;
        bytes memory result = new bytes(length + commaCount);

        uint256 i = length - 1;
        uint256 j = result.length - 1;
        uint256 commaAdded = 0;

        while (true) {
            result[j--] = bytes(numStr)[i--];
            commaAdded++;
            if (commaAdded % 3 == 0 && i >= 0) {
                result[j--] = ".";
            }
            if (i == 0) {
                result[j] = bytes(numStr)[0];
                break;
            }
        }
        return string(result);
    }
}