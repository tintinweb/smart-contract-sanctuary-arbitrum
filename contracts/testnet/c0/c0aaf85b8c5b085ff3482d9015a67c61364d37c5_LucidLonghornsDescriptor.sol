// SPDX-License-Identifier: GPL-3.0

/// @title The Lucid Longhorns NFT descriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { Ownable } from './Ownable.sol';
import { Strings } from './Strings.sol';
import { ILucidLonghornsDescriptor } from './ILucidLonghornsDescriptor.sol';
import { ILucidLonghornsSeeder } from './ILucidLonghornsSeeder.sol';
import { NFTDescriptor } from './NFTDescriptor.sol';
import { MultiPartRLEToSVG } from './MultiPartRLEToSVG.sol';

contract LucidLonghornsDescriptor is ILucidLonghornsDescriptor, Ownable {
    using Strings for uint256;

    // prettier-ignore
    // https://creativecommons.org/publicdomain/zero/1.0/legalcode.txt
    bytes32 constant COPYRIGHT_CC0_1_0_UNIVERSAL_LICENSE = 0xa2010f343487d3f7618affe54f789f5487602331c0a8d03f49e9a7c547cf0499;

    // Whether or not new Lucid Longhorn parts can be added
    bool public override arePartsLocked;

    // Whether or not `tokenURI` should be returned as a data URI (Default: true)
    bool public override isDataURIEnabled = true;

    // Base URI
    string public override baseURI;

    // Lucid Longhorn Color Palettes (Index => Hex Colors)
    mapping(uint8 => string[]) public override palettes;

    // Lucid Longhorn Backgrounds (Hex Colors)
    string[] public override backgrounds;

    // Lucid Longhorn Hides (Custom RLE)
    bytes[] public override hides;

    // Lucid Longhorn Outfits (Custom RLE)
    bytes[] public override outfits;

    // Lucid Longhorn Heads (Custom RLE)
    bytes[] public override heads;

    // Lucid Longhorn Eyes (Custom RLE)
    bytes[] public override eyes;

    // Lucid Longhorn Eyes (Custom RLE)
    bytes[] public override horns;

    // Lucid Longhorn Eyes (Custom RLE)
    bytes[] public override snouts;

    /**
     * @notice Require that the parts have not been locked.
     */
    modifier whenPartsNotLocked() {
        require(!arePartsLocked, 'Parts are locked');
        _;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `backgrounds`.
     */
    function backgroundCount() external view override returns (uint256) {
        return backgrounds.length;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `hides`.
     */
    function hideCount() external view override returns (uint256) {
        return hides.length;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `outfits`.
     */
    function outfitCount() external view override returns (uint256) {
        return outfits.length;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `heads`.
     */
    function headCount() external view override returns (uint256) {
        return heads.length;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `eyes`.
     */
    function eyesCount() external view override returns (uint256) {
        return eyes.length;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `eyes`.
     */
    function hornsCount() external view override returns (uint256) {
        return horns.length;
    }

    /**
     * @notice Get the number of available Lucid Longhorn `eyes`.
     */
    function snoutCount() external view override returns (uint256) {
        return snouts.length;
    }

    /**
     * @notice Add colors to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external override onlyOwner {
        require(palettes[paletteIndex].length + newColors.length <= 256, 'Palettes can only hold 256 colors');
        for (uint256 i = 0; i < newColors.length; i++) {
            _addColorToPalette(paletteIndex, newColors[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn backgrounds.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyBackgrounds(string[] calldata _backgrounds) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _backgrounds.length; i++) {
            _addBackground(_backgrounds[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn hides.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHides(bytes[] calldata _hides) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _hides.length; i++) {
            _addHide(_hides[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn outfits.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyOutfits(bytes[] calldata _outfits) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _outfits.length; i++) {
            _addOutfit(_outfits[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn heads.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHeads(bytes[] calldata _heads) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _heads.length; i++) {
            _addHead(_heads[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyEyes(bytes[] calldata _eyes) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _eyes.length; i++) {
            _addEyes(_eyes[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManyHorns(bytes[] calldata _horns) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _horns.length; i++) {
            _addHorns(_horns[i]);
        }
    }

    /**
     * @notice Batch add Lucid Longhorn eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addManySnouts(bytes[] calldata _snouts) external override onlyOwner whenPartsNotLocked {
        for (uint256 i = 0; i < _snouts.length; i++) {
            _addSnout(_snouts[i]);
        }
    }

    /**
     * @notice Add a single color to a color palette.
     * @dev This function can only be called by the owner.
     */
    function addColorToPalette(uint8 _paletteIndex, string calldata _color) external override onlyOwner {
        require(palettes[_paletteIndex].length <= 255, 'Palettes can only hold 256 colors');
        _addColorToPalette(_paletteIndex, _color);
    }

    /**
     * @notice Add a Lucid Longhorn background.
     * @dev This function can only be called by the owner when not locked.
     */
    function addBackground(string calldata _background) external override onlyOwner whenPartsNotLocked {
        _addBackground(_background);
    }

    /**
     * @notice Add a Lucid Longhorn hide.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHide(bytes calldata _hide) external override onlyOwner whenPartsNotLocked {
        _addHide(_hide);
    }

    /**
     * @notice Add a Lucid Longhorn outfit.
     * @dev This function can only be called by the owner when not locked.
     */
    function addOutfit(bytes calldata _outfit) external override onlyOwner whenPartsNotLocked {
        _addOutfit(_outfit);
    }

    /**
     * @notice Add a Lucid Longhorn head.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHead(bytes calldata _head) external override onlyOwner whenPartsNotLocked {
        _addHead(_head);
    }

    /**
     * @notice Add Lucid Longhorn eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addEyes(bytes calldata _eyes) external override onlyOwner whenPartsNotLocked {
        _addEyes(_eyes);
    }

    /**
     * @notice Add Lucid Longhorn eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addHorns(bytes calldata _horns) external override onlyOwner whenPartsNotLocked {
        _addHorns(_horns);
    }

    /**
     * @notice Add Lucid Longhorn eyes.
     * @dev This function can only be called by the owner when not locked.
     */
    function addSnout(bytes calldata _snout) external override onlyOwner whenPartsNotLocked {
        _addSnout(_snout);
    }

    /**
     * @notice Lock all Lucid Longhorn parts.
     * @dev This cannot be reversed and can only be called by the owner when not locked.
     */
    function lockParts() external override onlyOwner whenPartsNotLocked {
        arePartsLocked = true;

        emit PartsLocked();
    }

    /**
     * @notice Toggle a boolean value which determines if `tokenURI` returns a data URI
     * or an HTTP URL.
     * @dev This can only be called by the owner.
     */
    function toggleDataURIEnabled() external override onlyOwner {
        bool enabled = !isDataURIEnabled;

        isDataURIEnabled = enabled;
        emit DataURIToggled(enabled);
    }

    /**
     * @notice Set the base URI for all token IDs. It is automatically
     * added as a prefix to the value returned in {tokenURI}, or to the
     * token ID if {tokenURI} is empty.
     * @dev This can only be called by the owner.
     */
    function setBaseURI(string calldata _baseURI) external override onlyOwner {
        baseURI = _baseURI;

        emit BaseURIUpdated(_baseURI);
    }

    /**
     * @notice Given a token ID and seed, construct a token URI for an official Lucid Longhorns DAO lucid longhorn.
     * @dev The returned value may be a base64 encoded data URI or an API URL.
     */
    function tokenURI(uint256 tokenId, ILucidLonghornsSeeder.Seed memory seed) external view override returns (string memory) {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, tokenId.toString()));
    }

    /**
     * @notice Given a token ID and seed, construct a base64 encoded data URI for an official Lucid Longhorns DAO lucid longhorn.
     */
    function dataURI(uint256 tokenId, ILucidLonghornsSeeder.Seed memory seed) public view override returns (string memory) {
        string memory lucidLonghornId = tokenId.toString();
        string memory name = string(abi.encodePacked('Lucid Longhorn ', lucidLonghornId));
        string memory description = string(abi.encodePacked('Lucid Longhorn ', lucidLonghornId, ' is a member of the Lucid Longhorns DAO'));

        return genericDataURI(name, description, seed);
    }

    /**
     * @notice Given a name, description, and seed, construct a base64 encoded data URI.
     */
    function genericDataURI(
        string memory name,
        string memory description,
        ILucidLonghornsSeeder.Seed memory seed
    ) public view override returns (string memory) {
        NFTDescriptor.TokenURIParams memory params = NFTDescriptor.TokenURIParams({
            name: name,
            description: description,
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.constructTokenURI(params, palettes);
    }

    /**
     * @notice Given a seed, construct a base64 encoded SVG image.
     */
    function generateSVGImage(ILucidLonghornsSeeder.Seed memory seed) external view override returns (string memory) {
        MultiPartRLEToSVG.SVGParams memory params = MultiPartRLEToSVG.SVGParams({
            parts: _getPartsForSeed(seed),
            background: backgrounds[seed.background]
        });
        return NFTDescriptor.generateSVGImage(params, palettes);
    }

    /**
     * @notice Add a single color to a color palette.
     */
    function _addColorToPalette(uint8 _paletteIndex, string calldata _color) internal {
        palettes[_paletteIndex].push(_color);
    }

    /**
     * @notice Add a Lucid Longhorn background.
     */
    function _addBackground(string calldata _background) internal {
        backgrounds.push(_background);
    }

    /**
     * @notice Add a Lucid Longhorn hide.
     */
    function _addHide(bytes calldata _hide) internal {
        hides.push(_hide);
    }

    /**
     * @notice Add a Lucid Longhorn outfit.
     */
    function _addOutfit(bytes calldata _outfit) internal {
        outfits.push(_outfit);
    }

    /**
     * @notice Add a Lucid Longhorn head.
     */
    function _addHead(bytes calldata _head) internal {
        heads.push(_head);
    }

    /**
     * @notice Add Lucid Longhorn eyes.
     */
    function _addEyes(bytes calldata _eyes) internal {
        eyes.push(_eyes);
    }

    /**
     * @notice Add Lucid Longhorn eyes.
     */
    function _addHorns(bytes calldata _horns) internal {
        horns.push(_horns);
    }

    /**
     * @notice Add Lucid Longhorn eyes.
     */
    function _addSnout(bytes calldata _snout) internal {
        snouts.push(_snout);
    }

    /**
     * @notice Get all Lucid Longhorn parts for the passed `seed`.
     */
    function _getPartsForSeed(ILucidLonghornsSeeder.Seed memory seed) internal view returns (bytes[] memory) {
        bytes[] memory _parts = new bytes[](6);
        _parts[0] = hides[seed.hide];
        _parts[1] = eyes[seed.horns];
        _parts[2] = outfits[seed.outfit];
        _parts[3] = heads[seed.head];
        _parts[4] = eyes[seed.eyes];
        _parts[5] = eyes[seed.snout];
        return _parts;
    }
}