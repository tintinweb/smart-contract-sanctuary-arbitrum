// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../interfaces/ICaskDCA.sol";
import "../interfaces/INFTRenderer.sol";
import "../utils/DescriptorUtils.sol";
import "../utils/base64.sol";

contract DCANFTRenderer is INFTRenderer {

    function tokenURI(address _caskDCA, uint256 _tokenId) external override view returns (string memory) {
        ICaskDCA.DCA memory dca = ICaskDCA(_caskDCA).getDCA(bytes32(_tokenId));
        require(dca.user != address(0), "!INVALID_TOKEN");

        string memory _name = _generateName(_tokenId, dca);
        string memory _description = _generateDescription(_tokenId, dca);
        string memory _image = Base64.encode(bytes(_generateSVG(_tokenId, dca)));
        string memory _attributes = _generateAttributes(_tokenId, dca);
        return
        string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked('{"name":"', _name, '", "description":"', _description, '", "attributes": ', _attributes, ', "image": "data:image/svg+xml;base64,', _image, '"}')
                    )
                )
            )
        );
    }

    function _generateDescription(uint256 _tokenId, ICaskDCA.DCA memory _dca) private view returns (string memory) {
        string memory _part1 = string(
            abi.encodePacked(
                'This NFT represents a DCA position in Cask Protocol, where ',
                IERC20Metadata(_dca.path[0]).symbol(),
                ' will be swapped for ',
                IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol(),
                '.\\n\\n',
                IERC20Metadata(_dca.path[0]).symbol()
            )
        );
        string memory _part2 = string(
            abi.encodePacked(
                ' Address: ',
                Strings.toHexString(uint160(_dca.path[0]), 20),
                '\\n',
                IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol(),
                ' Address: ',
                Strings.toHexString(uint160(_dca.path[_dca.path.length - 1]), 20),
                '\\nSwap interval: ',
                _swapPeriodHuman(_dca.period),
                '\\nToken ID: ',
                Strings.toHexString(_tokenId, 32),
                '\\n'
            )
        );
        return string(abi.encodePacked(_part1, _part2));
    }

    function _generateName(uint256 _tokenId, ICaskDCA.DCA memory _dca) private view returns (string memory) {
        return string(abi.encodePacked('Cask Protocol DCA - ', _swapPeriodHuman(_dca.period), ' - ',
            IERC20Metadata(_dca.path[0]).symbol(),
            ' to ',
            IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol()));
    }

    function _generateStatus(uint256 _tokenId, ICaskDCA.DCA memory _dca) private pure returns (string memory) {
        if (_dca.status == ICaskDCA.DCAStatus.Active) return 'Active';
        if (_dca.status == ICaskDCA.DCAStatus.Paused) return 'Paused';
        if (_dca.status == ICaskDCA.DCAStatus.Canceled) return 'Canceled';
        if (_dca.status == ICaskDCA.DCAStatus.Complete) return 'Complete';
        return 'Unknown';
    }

    function _generateAttributes(uint256 _tokenId, ICaskDCA.DCA memory _dca) private view returns (string memory) {
        uint8 fromDecimals = IERC20Metadata(_dca.path[0]).decimals();
        string memory fromSymbol = IERC20Metadata(_dca.path[0]).symbol();
        uint8 toDecimals = IERC20Metadata(_dca.path[_dca.path.length - 1]).decimals();
        string memory toSymbol = IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol();

        string memory _part1 = string(abi.encodePacked(
                '[{"trait_type": "Status", "value": "',_generateStatus(_tokenId, _dca),'"},',
                '{"trait_type": "Period", "value": "',_swapPeriodHuman(_dca.period),'"},',
                '{"trait_type": "Current Amount", "display_type": "number", "value": ',_amountToReadableNoSym(_dca.currentAmount, fromDecimals),'},',
                '{"trait_type": "Total Amount", "display_type": "number", "value": ',_dca.totalAmount > 0 ? _amountToReadableNoSym(_dca.totalAmount, fromDecimals) : '0' ,'},'
        ));

        string memory _part2 = string(abi.encodePacked(
                '{"trait_type": "Acquired", "display_type": "number", "value": ',_amountToReadableNoSym(_dca.currentQty, toDecimals),'},',
                '{"trait_type": "Swaps", "display_type": "number", "value": ',Strings.toString(_dca.numBuys),'},',
                '{"trait_type": "From Token Symbol", "value": "',fromSymbol,'"},',
                '{"trait_type": "From Token Address", "value": "',Strings.toHexString(uint160(_dca.path[0]), 20),'"},'
            ));

        string memory _part3 = string(abi.encodePacked(
                '{"trait_type": "Amount", "display_type": "number", "value": ',_amountToReadableNoSym(_dca.amount, fromDecimals),'},',
                '{"trait_type": "To Token Symbol", "value": "',toSymbol,'"},',
                '{"trait_type": "To Token Address", "value": "',Strings.toHexString(uint160(_dca.path[_dca.path.length - 1]), 20),'"}]'
            ));

        return string(abi.encodePacked(_part1, _part2, _part3));
    }

    function _generateSVG(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        return
        string(
            abi.encodePacked(
                '<svg id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 290 500.62">',
                _generateSVGDefs(_tokenId, _dca),
                _generateSVGBackground(_tokenId, _dca),
                _generateSVGTextAnimation(_tokenId, _dca),
                _generateSVGHeader(_tokenId, _dca),
                _generateSVGTokens(_tokenId, _dca),
                _generateSVGStatus(_tokenId, _dca),
                '<rect x="27" y="200.76" width="233.13" height=".75" style="fill:#fff;"/>',
                _generateSVGData1(_tokenId, _dca),
                _generateSVGData2(_tokenId, _dca),
                '<rect x="27" y="415.45" width="233.13" height=".75" style="fill:#fff;"/>',
                _generateSVGLogo(_tokenId, _dca),
                '</svg>'
            )
        );
    }

    function _generateSVGDefs(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal pure returns (string memory) {
        return
        string(
            abi.encodePacked('<defs><linearGradient id="linear-gradient" x1="145" y1="503.36" x2="145" y2="2.74" gradientTransform="translate(0 503.36) scale(1 -1)" gradientUnits="userSpaceOnUse"><stop offset=".17" stop-color="#271b3f"/><stop offset=".25" stop-color="#271b3f"/><stop offset=".31" stop-color="#271b3f"/><stop offset=".58" stop-color="#644499"/><stop offset=".73" stop-color="#8258c4"/><stop offset=".76" stop-color="#8258c4"/><stop offset=".82" stop-color="#654499"/><stop offset=".89" stop-color="#432e68"/><stop offset=".94" stop-color="#2e204a"/><stop offset=".97" stop-color="#271b3f"/></linearGradient></defs>')
        );
    }

    function _generateSVGBackground(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal pure returns (string memory) {
        return
        string(
            abi.encodePacked('<path d="m290,466.37c0,18.84-17.2,34.25-38.22,34.25H38.22c-21.02,0-38.22-15.41-38.22-34.25V34.25C0,15.41,17.2,0,38.22,0h213.55c21.02,0,38.22,15.41,38.22,34.25v432.11h0Z" style="fill:url(#linear-gradient);"/><path id="frame-path" d="m255.27,484.32H33.85c-10.42,0-18.9-8.4-18.9-18.73V33.69c0-10.33,8.48-18.73,18.9-18.73h221.42c10.42,0,18.9,8.4,18.9,18.73v431.9c0,10.33-8.48,18.73-18.9,18.73ZM33.85,15.7c-10.01,0-18.15,8.07-18.15,17.98v431.9c0,9.92,8.14,17.98,18.15,17.98h221.42c10.01,0,18.15-8.07,18.15-17.98V33.69c0-9.92-8.14-17.98-18.15-17.98H33.85Z" style="fill:#fff;"/>')
        );
    }

    function _generateSVGTextAnimation(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        string memory fromSymbol = IERC20Metadata(_dca.path[0]).symbol();
        string memory toSymbol = IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol();

        return
        string(
            abi.encodePacked(
                '<text text-rendering="optimizeSpeed" style="fill:#fff; font-family:Verdana; font-size:8.8px; font-weight:200;"><textPath startOffset="8%" xlink:href="#frame-path" class="st46 st38 st47">From ',
                fromSymbol,' - ',Strings.toHexString(uint160(_dca.path[0]), 20),
                '<animate additive="sum" attributeName="startOffset" from="0%" to="5%" dur="30s" repeatCount="indefinite" /></textPath></text><text text-rendering="optimizeSpeed" style="fill:#fff; font-family:Verdana; font-size:8.8px; font-weight:200;"><textPath startOffset="33%" xlink:href="#frame-path" class="st46 st38 st47">To ',
                toSymbol,' - ', Strings.toHexString(uint160(_dca.path[_dca.path.length - 1]), 20),
                '<animate additive="sum" attributeName="startOffset" from="0%" to="5%" dur="30s" repeatCount="indefinite" /></textPath></text>'
            ));
    }

    function _generateSVGHeader(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        return
        string(
            abi.encodePacked(
                '<rect x="95.16" width="104.21" height="34.35" style="fill:#271b3f;"/><text transform="translate(145 21.42) scale(.93 1)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:15.8px; font-weight:700;"><tspan x="0" y="0" text-anchor="middle">DCA</tspan></text>'
            ));
    }

    function _generateSVGTokens(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        uint8 fromDecimals = IERC20Metadata(_dca.path[0]).decimals();
        string memory fromSymbol = IERC20Metadata(_dca.path[0]).symbol();
        return
        string(
            abi.encodePacked(
                '<text transform="translate(145 80.6)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:29.47px; font-weight:700; isolation:isolate;"><tspan x="0" y="0" text-anchor="middle">',
                IERC20Metadata(_dca.path[0]).symbol(),
                '</tspan></text><path d="m151.07,99.34c-.64-.64-1.65-.66-2.26-.06l-3.75,3.75v-9.85c0-.74-.74-1.34-1.64-1.34-.9,0-1.64.61-1.64,1.34v9.85s-3.62-3.62-3.62-3.62c-.59-.6-1.6-.56-2.24.08-.64.64-.67,1.64-.08,2.24l5.41,5.41.36.36,1.8,1.8,2.31-2.31h0l5.39-5.39c.61-.61.58-1.62-.06-2.26Z" style="fill:#fff;"/><text transform="translate(145 141.37)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:29.47px; font-weight:700;"><tspan x="0" y="0" text-anchor="middle">',
                IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol(),
                '</tspan></text><text transform="translate(145 230.1) scale(.93 1)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:18.26px; font-weight:700;"><tspan x="0" y="0" text-anchor="middle">',
                _amountToReadable(_dca.amount, fromDecimals, fromSymbol),
                '</tspan></text><text transform="translate(145 252.1) scale(.93 1)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:16.26px; font-weight:700;"><tspan x="0" y="0" text-anchor="middle">',
                _swapPeriodHuman(_dca.period),
                '</tspan></text>'
            ));
    }

    function _generateSVGStatus(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        if (_dca.status == ICaskDCA.DCAStatus.Active) {
            return
            string(
                abi.encodePacked('<path style="fill:#34B206" d="M175.1,182.2h-64c-4.9,0-9-4-9-9v0c0-4.9,4-9,9-9h64c4.9,0,9,4,9,9v0C184.1,178.1,180,182.2,175.1,182.2z"/><g><text transform="matrix(1 0 0 1 124.2528 177.4143)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:12px; font-weight:700;">Active</text></g>'));
        } else if (_dca.status == ICaskDCA.DCAStatus.Paused) {
            return
            string(
                abi.encodePacked('<path style="fill:#d69e2f" d="M175.1,182.2h-64c-4.9,0-9-4-9-9v0c0-4.9,4-9,9-9h64c4.9,0,9,4,9,9v0C184.1,178.1,180,182.2,175.1,182.2z"/><g><text transform="matrix(1 0 0 1 124.2528 177.4143)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:12px; font-weight:700;">Paused</text></g>'));
        } else {
            return '';
        }
    }

    function _generateSVGData1(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        uint8 fromDecimals = IERC20Metadata(_dca.path[0]).decimals();
        string memory fromSymbol = IERC20Metadata(_dca.path[0]).symbol();
        uint8 toDecimals = IERC20Metadata(_dca.path[_dca.path.length - 1]).decimals();
        string memory toSymbol = IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol();

        return
        string(
            abi.encodePacked(
                '<g style="isolation:isolate;"><text transform="translate(42.49 274.87)" style="fill:#fff; font-family:Verdana, Verdana; font-size:10px; isolation:isolate;"><tspan x="0" y="0">Total Swaps</tspan></text><text transform="translate(42.58 291.64)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:11px; font-weight:700;"><tspan x="0" y="1">',
                Strings.toString(_dca.numBuys),
                '</tspan></text></g><g style="isolation:isolate;"><text transform="translate(177.64 274.87)" style="fill:#fff; font-family:Verdana, Verdana; font-size:10px; isolation:isolate;"><tspan x="0" y="0">Acquired</tspan></text><text transform="translate(176.45 291.64)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:11px; font-weight:700;"><tspan x="0" y="1">',
                _amountToReadable(_dca.currentQty, toDecimals, toSymbol),
                '</tspan></text></g><g style="isolation:isolate;"><text transform="translate(41.05 326.16)" style="fill:#fff; font-family:Verdana, Verdana; font-size:10px; isolation:isolate;"><tspan x="0" y="0">Average Price</tspan></text><text transform="translate(39.19 342.53)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:11px; font-weight:700;"><tspan x="0" y="1">',
                _amountToReadable((_dca.currentAmount - _dca.currentFees) * uint256(10 ** toDecimals) / _dca.currentQty, fromDecimals, fromSymbol),
                '</tspan></text></g>'
            ));
    }

    function _generateSVGData2(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        uint8 fromDecimals = IERC20Metadata(_dca.path[0]).decimals();
        string memory fromSymbol = IERC20Metadata(_dca.path[0]).symbol();
        uint8 toDecimals = IERC20Metadata(_dca.path[_dca.path.length - 1]).decimals();
        string memory toSymbol = IERC20Metadata(_dca.path[_dca.path.length - 1]).symbol();

        return
        string(
            abi.encodePacked(
                '<g style="isolation:isolate;"><text transform="translate(175.19 326.16)" style="fill:#fff; font-family:Verdana, Verdana; font-size:10px; isolation:isolate;"><tspan x="0" y="0">Remaining</tspan></text><text transform="translate(176.06 342.53)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:11px; font-weight:700;"><tspan x="0" y="1">',
                _dca.totalAmount > 0 ? _amountToReadable(_dca.totalAmount - _dca.currentAmount, fromDecimals, fromSymbol) : 'N/A',
                '</tspan></text></g><g style="isolation:isolate;"><text transform="translate(39.45 374.3)" style="fill:#fff; font-family:Verdana, Verdana; font-size:10px; isolation:isolate;"><tspan x="0" y="0">Min Price</tspan></text><text transform="translate(39.59 390.67)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:11px; font-weight:700;"><tspan x="0" y="1">',
                _dca.minPrice > 0 ? _amountToReadable(_dca.minPrice, toDecimals, toSymbol) : 'N/A',
                '</tspan></text></g><g style="isolation:isolate;"><text transform="translate(175.19 374.3)" style="fill:#fff; font-family:Verdana, Verdana; font-size:10px; isolation:isolate;"><tspan x="0" y="0">Max Price</tspan></text><text transform="translate(176.06 390.67)" style="fill:#fff; font-family:Verdana-Bold, Verdana; font-size:11px; font-weight:700;"><tspan x="0" y="1">',
                _dca.maxPrice > 0 ? _amountToReadable(_dca.maxPrice, toDecimals, toSymbol) : 'N/A',
                '</tspan></text></g>'
            ));
    }

    function _generateSVGLogo(uint256 _tokenId, ICaskDCA.DCA memory _dca) internal view returns (string memory) {
        return
        string(
            abi.encodePacked(
                '<g><g><path d="m136.35,458.44c-2.61,0-4.75-.89-6.54-2.61-1.72-1.72-2.61-3.92-2.61-6.48s.89-4.75,2.61-6.48,3.92-2.61,6.54-2.61c1.66,0,3.21.42,4.58,1.19,1.37.83,2.44,1.9,3.09,3.27l-3.21,1.84c-.42-.83-1.01-1.49-1.78-1.96s-1.72-.71-2.73-.71c-1.55,0-2.79.53-3.8,1.55-1.01,1.01-1.55,2.32-1.55,3.86s.53,2.85,1.55,3.86,2.32,1.55,3.8,1.55c1.01,0,1.9-.24,2.73-.71s1.43-1.13,1.84-1.96l3.21,1.84c-.71,1.37-1.78,2.5-3.15,3.27-1.37.89-2.91,1.31-4.58,1.31Z" style="fill:#fff;"/><path d="m159.29,440.73h3.74v17.29h-3.74v-2.5c-1.43,1.96-3.45,2.91-6.06,2.91-2.38,0-4.4-.89-6.06-2.61-1.66-1.78-2.5-3.92-2.5-6.42s.83-4.69,2.5-6.48c1.66-1.72,3.68-2.61,6.06-2.61,2.61,0,4.64.95,6.06,2.91v-2.5Zm-9.39,12.6c1.01,1.07,2.32,1.55,3.92,1.55s2.85-.53,3.92-1.55c1.01-1.07,1.55-2.38,1.55-3.98s-.53-2.91-1.55-3.98-2.32-1.55-3.92-1.55-2.85.53-3.92,1.55c-1.01,1.07-1.55,2.38-1.55,3.98s.53,2.91,1.55,3.98Z" style="fill:#fff;"/><path d="m169.69,445.48c0,.59.3,1.01.95,1.37s1.43.59,2.32.89c.89.24,1.84.53,2.73.83s1.72.89,2.32,1.66c.65.77.95,1.72.95,2.91,0,1.66-.65,2.97-1.9,3.92-1.31.95-2.91,1.43-4.81,1.43-1.72,0-3.15-.36-4.4-1.07-1.25-.71-2.08-1.72-2.67-2.97l3.21-1.84c.59,1.66,1.9,2.5,3.86,2.5s2.91-.65,2.91-1.96c0-.53-.3-1.01-.95-1.37s-1.43-.65-2.32-.89-1.84-.53-2.73-.83c-.95-.3-1.72-.83-2.32-1.6-.65-.77-.95-1.72-.95-2.85,0-1.6.59-2.85,1.84-3.86,1.19-.95,2.73-1.43,4.52-1.43,1.43,0,2.67.3,3.8.95s1.96,1.49,2.56,2.61l-3.15,1.78c-.59-1.31-1.66-1.96-3.27-1.96-.71,0-1.31.18-1.78.48-.48.24-.71.71-.71,1.31Z" style="fill:#fff;"/><path d="m196.38,457.96h-4.46l-7.07-7.96v7.96h-3.74v-24.13h3.74v14.56l6.72-7.61h4.58l-7.61,8.44,7.84,8.74Z" style="fill:#fff;"/></g>',
                '<g><path d="m97.49,433.42c1.66.36,3.39.53,5.05.71,2.5.18,5.05.18,7.55.06,2.02-.12,4.1-.3,6.12-.77.89,1.07,1.55,2.32,2.14,3.57-.71.24-1.43.48-2.14.59-2.08.42-4.16.59-6.24.71-1.43.06-2.85.12-4.28.06-1.96-.06-3.86-.18-5.82-.42-1.49-.18-3.03-.48-4.46-.95.48-1.25,1.19-2.44,2.08-3.57h0Z" style="fill:#fff;"/><path d="m94.57,439.06c.48.06.89.3,1.37.36,2.08.48,4.28.71,6.48.83,3.63.24,7.31.18,10.99-.18,1.9-.18,3.86-.48,5.71-1.07.42,1.31.71,2.61.89,3.98-4.93,1.31-10.16,1.55-15.21,1.43-3.8-.12-7.49-.48-11.17-1.49.12-.95.3-1.84.53-2.73.12-.3.24-.71.42-1.13h0Z" style="fill:#fff;"/><path d="m109.49,450.77c3.57.12,7.07.53,10.52,1.43-.18,1.37-.48,2.67-.89,3.98-1.01-.3-1.96-.53-3.03-.71-2.5-.42-4.99-.53-7.49-.65-2.85-.06-5.65,0-8.5.3-1.9.18-3.74.48-5.53,1.07-.42-1.31-.71-2.61-.89-3.98,2.73-.71,5.59-1.13,8.38-1.31,2.44-.18,4.93-.18,7.43-.12h0Z" style="fill:#fff;"/><path d="m112.05,457.13c2.08.18,4.28.48,6.3,1.19-.59,1.31-1.25,2.5-2.14,3.57-2.56-.65-5.29-.77-7.9-.83-3.57-.06-7.31,0-10.76.83-.89-1.07-1.55-2.32-2.14-3.57,2.14-.77,4.52-1.01,6.78-1.19,3.27-.3,6.54-.3,9.87,0h0Z" style="fill:#fff;"/></g></g>'
            ));
    }

    function _amountToReadable(
        uint256 _amount,
        uint8 _decimals,
        string memory _symbol
    ) private pure returns (string memory) {
        return string(abi.encodePacked(DescriptorUtils.fixedPointToDecimalString(_amount, _decimals), ' ', _symbol));
    }

    function _amountToReadableNoSym(
        uint256 _amount,
        uint8 _decimals
    ) private pure returns (string memory) {
        return string(abi.encodePacked(DescriptorUtils.fixedPointToDecimalString(_amount, _decimals)));
    }

    function _swapPeriodHuman(uint256 _period) internal pure returns (string memory) {
        if (_period == 1 hours) return 'Hourly';
        if (_period == 1 days) return 'Daily';
        if (_period == 1 weeks) return 'Weekly';
        if (_period == 1 days * (365/12)) return 'Monthly';
        if (_period == 1 days * (365.25/12)) return 'Monthly';
        if (_period == 1 days * (365/3)) return 'Quarterly';
        if (_period == 1 days * (365.25/3)) return 'Quarterly';
        if (_period == 365 days) return 'Annually';
        if (_period == 365.25 days) return 'Annually';
        return 'Periodically';
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICaskDCA {

    enum SwapProtocol {
        UNIV2,
        UNIV3,
        GMX,
        JoeV2
    }

    enum DCAStatus {
        None,
        Active,
        Paused,
        Canceled,
        Complete
    }

    enum ManagerCommand {
        None,
        Cancel,
        Skip,
        Pause
    }

    enum SkipReason {
        None,
        AssetNotAllowed,
        PaymentFailed,
        OutsideLimits,
        ExcessiveSlippage,
        SwapFailed
    }

    struct DCA {
        address user;
        address to;
        address router;
        address priceFeed;
        uint256 amount;
        uint256 totalAmount;
        uint256 currentAmount;
        uint256 currentQty;
        uint256 numBuys;
        uint256 numSkips;
        uint256 maxSlippageBps;
        uint256 maxPrice;
        uint256 minPrice;
        uint32 period;
        uint32 createdAt;
        uint32 processAt;
        DCAStatus status;
        address[] path;
        uint256 currentFees;
    }

    struct SwapInfo {
        SwapProtocol swapProtocol;
        bytes swapData;
    }

    function createDCA(
        address[] calldata _assetSpec, // router, priceFeed, path...
        bytes32[] calldata _merkleProof,
        SwapProtocol _swapProtocol,
        bytes calldata _swapData,
        address _to,
        uint256[] calldata _priceSpec
    ) external returns(bytes32);

    function getDCA(bytes32 _dcaId) external view returns (DCA memory);

    function getSwapInfo(bytes32 _dcaId) external view returns (SwapInfo memory);

    function getUserDCA(address _user, uint256 _idx) external view returns (bytes32);

    function getUserDCACount(address _user) external view returns (uint256);

    function cancelDCA(bytes32 _dcaId) external;

    function pauseDCA(bytes32 _dcaId) external;

    function resumeDCA(bytes32 _dcaId) external;

    function managerCommand(bytes32 _dcaId, ManagerCommand _command) external;

    function managerProcessed(bytes32 _dcaId, uint256 _amount, uint256 _buyQty, uint256 _fee) external;

    function managerSkipped(bytes32 _dcaId, SkipReason _skipReason) external;

    event DCACreated(bytes32 indexed dcaId, address indexed user, address indexed to, address inputAsset,
        address outputAsset, uint256 amount, uint256 totalAmount, uint32 period);

    event DCAPaused(bytes32 indexed dcaId, address indexed user);

    event DCAResumed(bytes32 indexed dcaId, address indexed user);

    event DCASkipped(bytes32 indexed dcaId, address indexed user, SkipReason skipReason);

    event DCAProcessed(bytes32 indexed dcaId, address indexed user, uint256 amount, uint256 buyQty, uint256 fee);

    event DCACanceled(bytes32 indexed dcaId, address indexed user);

    event DCACompleted(bytes32 indexed dcaId, address indexed user);

    event AssetAdminChange(address indexed newAdmin);

    event AssetsMerkleRootChanged(bytes32 prevRoot, bytes32 newRoot);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INFTRenderer {

    function tokenURI(address _caskDCA, uint256 _tokenId) external view returns (string memory);

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.0;

import '@openzeppelin/contracts/utils/Strings.sol';

// Based on Uniswap's NFTDescriptor
library DescriptorUtils {
    using Strings for uint256;
    using Strings for uint32;

    function fixedPointToDecimalString(uint256 _value, uint8 _decimals) internal pure returns (string memory) {
        if (_value == 0) {
            return '0.0000';
        }

        bool _priceBelow1 = _value < 10**_decimals;

        // get digit count
        uint256 _temp = _value;
        uint8 _digits;
        while (_temp != 0) {
            _digits++;
            _temp /= 10;
        }
        // don't count extra digit kept for rounding
        _digits = _digits - 1;

        // address rounding
        (uint256 _sigfigs, bool _extraDigit) = _sigfigsRounded(_value, _digits);
        if (_extraDigit) {
            _digits++;
        }

        DecimalStringParams memory _params;
        if (_priceBelow1) {
            // 7 bytes ( "0." and 5 sigfigs) + leading 0's bytes
            _params.bufferLength = _digits >= 5 ? _decimals - _digits + 6 : _decimals + 2;
            _params.zerosStartIndex = 2;
            _params.zerosEndIndex = _decimals - _digits + 1;
            _params.sigfigIndex = _params.bufferLength - 1;
        } else if (_digits >= _decimals + 4) {
            // no decimal in price string
            _params.bufferLength = _digits - _decimals + 1;
            _params.zerosStartIndex = 5;
            _params.zerosEndIndex = _params.bufferLength - 1;
            _params.sigfigIndex = 4;
        } else {
            // 5 sigfigs surround decimal
            _params.bufferLength = 6;
            _params.sigfigIndex = 5;
            _params.decimalIndex = _digits - _decimals + 1;
        }
        _params.sigfigs = _sigfigs;
        _params.isLessThanOne = _priceBelow1;

        return _generateDecimalString(_params);
    }

    function addressToString(address _addr) internal pure returns (string memory) {
        bytes memory _s = new bytes(40);
        for (uint256 _i = 0; _i < 20; _i++) {
            bytes1 _b = bytes1(uint8(uint256(uint160(_addr)) / (2**(8 * (19 - _i)))));
            bytes1 _hi = bytes1(uint8(_b) / 16);
            bytes1 _lo = bytes1(uint8(_b) - 16 * uint8(_hi));
            _s[2 * _i] = _char(_hi);
            _s[2 * _i + 1] = _char(_lo);
        }
        return string(abi.encodePacked('0x', string(_s)));
    }

    struct DecimalStringParams {
        // significant figures of decimal
        uint256 sigfigs;
        // length of decimal string
        uint8 bufferLength;
        // ending index for significant figures (funtion works backwards when copying sigfigs)
        uint8 sigfigIndex;
        // index of decimal place (0 if no decimal)
        uint8 decimalIndex;
        // start index for trailing/leading 0's for very small/large numbers
        uint8 zerosStartIndex;
        // end index for trailing/leading 0's for very small/large numbers
        uint8 zerosEndIndex;
        // true if decimal number is less than one
        bool isLessThanOne;
    }

    function _generateDecimalString(DecimalStringParams memory _params) private pure returns (string memory) {
        bytes memory _buffer = new bytes(_params.bufferLength);
        if (_params.isLessThanOne) {
            _buffer[0] = '0';
            _buffer[1] = '.';
        }

        // add leading/trailing 0's
        for (uint256 _zerosCursor = _params.zerosStartIndex; _zerosCursor < _params.zerosEndIndex + 1; _zerosCursor++) {
            _buffer[_zerosCursor] = bytes1(uint8(48));
        }
        // add sigfigs
        while (_params.sigfigs > 0) {
            if (_params.decimalIndex > 0 && _params.sigfigIndex == _params.decimalIndex) {
                _buffer[_params.sigfigIndex--] = '.';
            }
            uint8 _charIndex = uint8(48 + (_params.sigfigs % 10));
            _buffer[_params.sigfigIndex] = bytes1(_charIndex);
            _params.sigfigs /= 10;
            if (_params.sigfigs > 0) {
                _params.sigfigIndex--;
            }
        }
        return string(_buffer);
    }

    function _sigfigsRounded(uint256 _value, uint8 _digits) private pure returns (uint256, bool) {
        bool _extraDigit;
        if (_digits > 5) {
            _value = _value / (10**(_digits - 5));
        }
        bool _roundUp = _value % 10 > 4;
        _value = _value / 10;
        if (_roundUp) {
            _value = _value + 1;
        }
        // 99999 -> 100000 gives an extra sigfig
        if (_value == 100000) {
            _value /= 10;
            _extraDigit = true;
        }
        return (_value, _extraDigit);
    }

    function _char(bytes1 _b) private pure returns (bytes1) {
        if (uint8(_b) < 10) return bytes1(uint8(_b) + 0x30);
        else return bytes1(uint8(_b) + 0x57);
    }
}

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
        // set the actual output length
            mstore(result, encodedLen)

        // prepare the lookup table
            let tablePtr := add(table, 1)

        // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

        // result ptr, jump over length
            let resultPtr := add(result, 32)

        // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                dataPtr := add(dataPtr, 3)

            // read 3 bytes
                let input := mload(dataPtr)

            // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

        // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}