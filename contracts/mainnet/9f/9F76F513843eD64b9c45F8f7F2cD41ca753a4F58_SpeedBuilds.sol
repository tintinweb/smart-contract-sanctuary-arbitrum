//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";

contract SpeedBuilds is ERC721Enumerable {
    using Strings for uint256;
    using Strings for uint160;
    using Strings for uint16;

    struct HouseProperties {
        string wallColor;
        string windowColor;
        string doorColor;
        string roofColor;
    }

    /* ========== STATE VARIABLES ========== */

    /* == constants and immutables == */
    uint16 private constant MAX_SUPPLY = 1000;
    uint16 private _tokenIds;


    address payable constant buildGuild =
        payable(0x97843608a00e2bbc75ab0C1911387E002565DEDE);
    address immutable i_owner;


    uint256 public constant mintFee = 0.001 ether;
    AggregatorV3Interface public immutable i_priceFeed;
    uint256 public lastPrice = 0;
    uint256 tokenCounter;


    mapping(uint16 => string[6]) public tokenIdToColor;
    mapping(uint16 => uint256) public tokenIdToRandomNumber;
    mapping(uint16 => bool) public isDay;

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner");
        _;
    }

    /* ========== Functions ========== */
    constructor(address _priceFeed) ERC721("Speed Builds", "SBD") {
        i_priceFeed = AggregatorV3Interface(_priceFeed);
        i_owner = msg.sender;
    }

    receive() external payable {
        mintItem();
    }

    // fallback
    fallback() external payable {
        mintItem();
    }

    function mintItem() public payable returns (uint256) {
        require(_tokenIds < MAX_SUPPLY, "Minting Ended");
        require(msg.value >= mintFee, "Price is 0.001 ETH");

        uint16 id = _tokenIds;

        _tokenIds = _tokenIds + 1;
        tokenCounter = tokenCounter + 1;

        _mint(msg.sender, id);

        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,
            /* uint startedAt */
            /*uint timeStamp*/
            uint80 answeredInRound
        ) = i_priceFeed.latestRoundData();

        if (uint256(price) >= lastPrice) {
            isDay[id] = true;
            lastPrice = uint256(price);
        } else {
            // by defalut its false
            // isDay[id] = false;
            lastPrice = uint256(price);
        }

        isDay[0] = false;

        string[6] memory COLORS = [
            "sandybrown",
            "orchid",
            "chocolate",
            "lightgray",
            "lightsteelblue",
            "dimgrey"
        ];

        uint256 pseudoRandomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender,
                    address(this),
                    block.chainid,
                    id,
                    block.timestamp,
                    block.difficulty,
                    price
                )
            )
        );

        // reorder the colors after every mint
        for (uint256 i = 0; i < 6; i++) {
            uint256 randomIndex = i +
                ((pseudoRandomNumber + answeredInRound) % (6 - i));
            string memory color = COLORS[randomIndex];
            COLORS[randomIndex] = COLORS[i];
            COLORS[i] = color;
        }

        tokenIdToColor[id] = COLORS;
        tokenIdToRandomNumber[id] = pseudoRandomNumber;
        (bool success, ) = buildGuild.call{value: msg.value}("");
        require(success, "Failed sending funds to BuildGuild");

        return id;
    }

    function withdraw() public payable onlyOwner {
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getPropertiesById(uint16 id)
        public
        view
        returns (HouseProperties memory properties)
    {
        // 6 is length of COLORS array
        uint256 pseudoRandomNumber = tokenIdToRandomNumber[id];
        uint8 wallIndex = uint8(pseudoRandomNumber % 6);
        properties.wallColor = tokenIdToColor[id][wallIndex];

        uint8 roofIndex = uint8((pseudoRandomNumber + 1) % 6);
        properties.roofColor = tokenIdToColor[id][roofIndex];

        properties.windowColor = tokenIdToColor[id][4];

        uint8 doorIndex = uint8((pseudoRandomNumber + 4) % 6);

        if (doorIndex != 4) {
            properties.doorColor = tokenIdToColor[id][doorIndex];
        } else {
            doorIndex = uint8((pseudoRandomNumber + 5) % 7);
            properties.doorColor = tokenIdToColor[id][doorIndex];
        }

        return properties;
    }

    function renderedTokenById(uint16 id) public view returns (string memory) {
        HouseProperties memory properties = getPropertiesById(id);
        bool day = isDay[id];

        string memory render;

        if (day) {
            render = string.concat(
                " <linearGradient id="
                '"id0"'
                " gradientUnits="
                '"userSpaceOnUse"'
                " x1="
                '"127.5"'
                " y1="
                '"106.15"'
                " x2="
                '"127.5"'
                " y2="
                '"183.851"'
                ">",
                " <stop offset="
                '"0"'
                " style="
                '"stop-opacity:1; stop-color:#00B5DC"'
                "/>",
                " <stop offset="
                '"1"'
                " style="
                '"stop-opacity:1; stop-color:#FEFEFE"'
                "/>",
                "  </linearGradient>",
                //Background
                " <polygon fill="
                '"url(#id0)"'
                " points="
                '"253,15 253,275 2,275 2,15"'
                "/>",
                // Walls
                "  <path fill='",
                properties.wallColor,
                "' d="
                '"M16 233l13 0 0 -61 52 0 0 61 7 0 0 -74 79 0 0 74 7 0 0 -61 52 0 0 61 13 0 0 42 -92 0 0 -15c0,-4 -9,-12 -19,-12l0 0c-11,0 -20,7 -20,12l0 15 -92 0 0 -42zm176 -7l0 -15c0,-4 4,-7 8,-7l0 0c4,0 8,3 8,7l0 15 -16 0zm-54 -20l0 -14c0,-3 3,-6 7,-6l0 0c4,0 8,3 8,6l0 14 -15 0zm-36 0l0 -14c0,-3 4,-6 8,-6l0 0c4,0 7,3 7,6l0 14 -15 0zm-55 20l0 -15c0,-4 4,-7 8,-7l0 0c4,0 8,3 8,7l0 15 -16 0z"'
                "/>",
                //Door
                " <path fill='",
                properties.doorColor,
                "' d="
                '"M110 275l0 -14c0,-4 8,-11 18,-11l0 0c9,0 18,7 18,11l0 14 -36 0z"'
                "/>",
                //Window
                " <path fill='",
                properties.windowColor,
                "' d="
                '"M193 225l0 -14c0,-3 3,-6 7,-6l0 0c4,0 7,3 7,6l0 14 -14 0zm-145 0l0 -14c0,-3 3,-6 7,-6l0 0c4,0 7,3 7,6l0 14 -14 0zm55 -21l0 -11c0,-2 3,-5 6,-5l0 0c4,0 7,3 7,5l0 11 -13 0zm36 0l0 -11c0,-2 3,-5 7,-5l0 0c3,0 6,3 6,5l0 11 -13 0z"'
                "/>",
                //Roof
                "<path fill='",
                properties.roofColor,
                "' d="
                '"M231 170l-62 0 31 -43 31 43zm-145 0l-62 0 31 -43 31 43zm87 -12l-91 0 46 -51 45 51z"'
                "/>",
                //Sun
                " <path fill="
                '"#DCDC00"'
                " d="
                '"M206 40c-4,0 -8,2 -11,5 -3,3 -4,8 -4,12 1,8 8,15 18,14 8,0 15,-8 14,-17 -1,-8 -8,-15 -17,-14zm10 -3c1,0 0,0 1,0 1,-1 1,-6 1,-7 0,0 0,0 0,0l-1 1c0,0 0,0 -1,1l-2 3c0,0 0,0 0,1 0,0 0,0 0,0 0,0 -1,0 -1,1 0,2 3,3 3,0zm5 34c0,0 0,0 0,0 0,0 0,0 0,0 0,1 4,4 5,4l0 0 1 0c0,-1 -2,-3 -2,-3l-2 -3c0,0 0,0 0,0 -1,-2 -5,0 -2,2zm-29 -2c-1,0 -1,1 -2,1 0,1 -2,4 -2,5l0 0 0 0c1,0 5,-3 6,-4 0,0 0,0 -1,0 0,0 0,0 0,0 1,0 2,-1 1,-2 -1,-1 -2,-1 -2,0zm-4 -32c0,1 2,3 3,4 0,1 0,1 0,1 1,0 0,0 1,0 0,0 1,1 2,1 1,-1 1,-2 -1,-3 1,0 1,0 0,-1 -1,-1 -4,-3 -5,-3 0,0 0,0 0,0 0,1 0,0 0,0 -1,1 0,0 0,1zm38 9c0,1 0,1 0,1 -3,0 -2,2 0,2 0,0 1,0 1,0 2,0 5,-3 5,-3l0 -1c-1,0 -6,0 -6,1zm-5 -6c-1,1 -2,2 -1,3 1,0 2,0 2,0 0,-1 0,-1 1,-1 0,-1 -1,0 0,0 0,0 0,0 1,-1 1,-1 3,-3 3,-5 -1,0 -1,0 -1,1 0,-1 0,-1 0,-1 -1,0 -3,2 -4,3 -1,0 -1,0 -1,0 0,1 0,1 0,1zm-35 17c0,0 0,0 0,0 0,0 0,0 0,0 4,1 4,-3 0,-3l0 0c0,0 0,0 0,0 0,0 0,0 0,0 -1,0 -5,1 -6,1 0,0 0,0 0,0l0 1c0,0 0,0 1,0 1,1 4,1 5,1zm12 -20l0 0c0,0 0,0 0,0 0,3 3,2 3,0 0,-1 0,-1 0,-1 0,-1 -4,-6 -4,-6 0,0 0,0 0,0 0,0 0,0 0,0 -1,0 -1,1 -1,2 0,1 1,4 2,5zm30 17c-3,0 -4,4 0,3 0,0 0,0 0,0 0,0 0,0 0,0 1,0 5,0 6,-1 0,0 1,0 1,-1 0,0 0,0 -1,0 -1,0 -5,-1 -6,-1 0,0 0,0 0,0zm-46 -9c0,0 0,0 0,1 0,0 0,0 0,0 1,0 4,3 5,3 0,0 1,0 2,0 1,0 3,-2 -1,-2 0,0 0,0 1,-1 -1,-1 -6,-2 -7,-1zm35 29c-1,0 -1,0 -1,1 0,-1 0,-3 -1,-3 -1,0 -2,1 -2,2 1,2 3,5 4,6 0,1 0,1 1,1 0,0 0,-1 0,-2 0,-2 -1,-3 -1,-5zm-19 1c0,-1 0,-1 0,-1 -1,1 -2,4 -2,5 0,1 0,2 1,2 0,0 0,0 0,0 0,0 4,-5 4,-5l0 -2c0,-1 -1,-2 -1,-2 -2,0 -2,2 -2,3zm8 2c0,0 0,0 0,-1 -1,2 0,6 1,7 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0 0,0l0 0c1,-1 2,-5 2,-7 -1,1 0,1 -1,1 1,-2 1,-3 -1,-3 -1,0 -1,1 -1,3zm20 -12c0,0 0,0 0,0 0,1 5,2 6,1 0,0 1,0 0,0 0,0 1,0 1,0 -1,-1 -5,-3 -6,-4 -2,-1 -4,1 -3,2 1,1 2,0 2,1zm-44 1c0,0 0,0 0,0l0 0c0,0 0,0 0,0 1,1 6,0 7,-1 -1,0 -1,0 -1,-1 1,0 1,1 2,0 1,-1 0,-2 -1,-2 -2,0 -3,1 -5,2 0,0 -1,1 -2,2zm25 -38c-1,1 -2,5 -1,7 0,0 0,0 0,-1 0,2 0,3 1,3 2,0 2,-1 1,-2 1,-1 0,0 1,0 0,-2 -1,-6 -2,-7l0 0z"'
                "/>"
            );
        } else if (!day) {
            if (id == 0) {
                render = string.concat(
                    //Head
                    " <linearGradient id="
                    '"id0"'
                    " gradientUnits="
                    '"userSpaceOnUse"'
                    " x1="
                    '"127.5"'
                    " y1="
                    '"106.15"'
                    " x2="
                    '"127.5"'
                    " y2="
                    '"183.851"'
                    ">",
                    " <stop offset="
                    '"0"'
                    " style="
                    '"stop-opacity:1; stop-color:#2B2C5A"'
                    "/>",
                    " <stop offset="
                    '"1"'
                    " style="
                    '"stop-opacity:1; stop-color:#FEFEFE"'
                    "/>",
                    "</linearGradient>",
                    //Background
                    "<polygon fill="
                    '"url(#id0)"'
                    " points="
                    '"253,15 253,275 2,275 2,15"'
                    "/>",
                    //Walls
                    " <path fill="
                    '"black"'
                    " d="
                    '"M16 233l13 0 0 -61 52 0 0 61 7 0 0 -74 79 0 0 74 7 0 0 -61 52 0 0 61 13 0 0 42 -92 0 0 -15c0,-4 -9,-12 -19,-12l0 0c-11,0 -20,7 -20,12l0 15 -92 0 0 -42zm176 -7l0 -15c0,-4 4,-7 8,-7l0 0c4,0 8,3 8,7l0 15 -16 0zm-54 -20l0 -14c0,-3 3,-6 7,-6l0 0c4,0 8,3 8,6l0 14 -15 0zm-36 0l0 -14c0,-3 4,-6 8,-6l0 0c4,0 7,3 7,6l0 14 -15 0zm-55 20l0 -15c0,-4 4,-7 8,-7l0 0c4,0 8,3 8,7l0 15 -16 0z"'
                    "/>",
                    //door
                    "<path fill="
                    '"black"'
                    " d="
                    '"M110 275l0 -14c0,-4 8,-11 18,-11l0 0c9,0 18,7 18,11l0 14 -36 0z"'
                    "/>",
                    //window
                    "<path fill="
                    '"black"'
                    " d="
                    '"M193 225l0 -14c0,-3 3,-6 7,-6l0 0c4,0 7,3 7,6l0 14 -14 0zm-145 0l0 -14c0,-3 3,-6 7,-6l0 0c4,0 7,3 7,6l0 14 -14 0zm55 -21l0 -11c0,-2 3,-5 6,-5l0 0c4,0 7,3 7,5l0 11 -13 0zm36 0l0 -11c0,-2 3,-5 7,-5l0 0c3,0 6,3 6,5l0 11 -13 0z"'
                    "/>",
                    // Roof
                    " <path fill="
                    '"black"'
                    " d="
                    '"M231 170l-62 0 31 -43 31 43zm-145 0l-62 0 31 -43 31 43zm87 -12l-91 0 46 -51 45 51z"'
                    "/>",
                    //Moon
                    " <path fill="
                    '"#FEFEFE"'
                    "  d="
                    '"M231 56c-5,1 -8,4 -15,2 -12,-3 -15,-18 -8,-25 2,-2 3,-2 5,-4 -6,0 -12,4 -15,9 -7,11 1,27 17,27 5,0 10,-3 13,-6 1,0 2,-2 3,-3zm-40 7l1 1c0,0 0,0 1,1l1 -1c0,-1 0,-1 1,-1 -1,0 -1,-1 -2,-2l0 0c-1,1 -1,1 -2,2zm-4 -17c1,0 1,0 2,1 0,0 0,0 0,1 1,-2 1,-2 3,-3 -2,0 -2,0 -3,-2 0,1 0,1 -1,2 0,0 0,0 0,0l-1 1zm21 24c1,1 1,1 2,2l0 0c1,-1 1,-1 1,-1 0,-1 1,-1 1,-1 -2,-1 -1,-1 -2,-2 -1,1 -1,1 -2,2zm13 -18c1,0 1,1 2,1 1,-1 1,-1 3,-2 -2,0 -2,0 -3,-2 -1,2 0,1 -2,2l0 1zm-9 -16c2,0 4,2 4,3 1,-2 0,-1 3,-3 -2,0 -2,-1 -3,-3 0,2 -1,3 -4,3z"'
                    "/>"
                );
            }

            if (id > 0) {
                render = string.concat(
                    " <linearGradient id="
                    '"id0"'
                    " gradientUnits="
                    '"userSpaceOnUse"'
                    " x1="
                    '"127.5"'
                    " y1="
                    '"106.15"'
                    " x2="
                    '"127.5"'
                    " y2="
                    '"183.851"'
                    ">",
                    " <stop offset="
                    '"0"'
                    " style="
                    '"stop-opacity:1; stop-color:#2B2C5A"'
                    "/>",
                    " <stop offset="
                    '"1"'
                    " style="
                    '"stop-opacity:1; stop-color:#FEFEFE"'
                    "/>",
                    "</linearGradient>",
                    //Background
                    "<polygon fill="
                    '"url(#id0)"'
                    " points="
                    '"253,15 253,275 2,275 2,15"'
                    "/>",
                    //Walls
                    " <path fill='",
                    properties.wallColor,
                    "' d="
                    '"M16 233l13 0 0 -61 52 0 0 61 7 0 0 -74 79 0 0 74 7 0 0 -61 52 0 0 61 13 0 0 42 -92 0 0 -15c0,-4 -9,-12 -19,-12l0 0c-11,0 -20,7 -20,12l0 15 -92 0 0 -42zm176 -7l0 -15c0,-4 4,-7 8,-7l0 0c4,0 8,3 8,7l0 15 -16 0zm-54 -20l0 -14c0,-3 3,-6 7,-6l0 0c4,0 8,3 8,6l0 14 -15 0zm-36 0l0 -14c0,-3 4,-6 8,-6l0 0c4,0 7,3 7,6l0 14 -15 0zm-55 20l0 -15c0,-4 4,-7 8,-7l0 0c4,0 8,3 8,7l0 15 -16 0z"'
                    "/>",
                    //door
                    "<path fill='",
                    properties.doorColor,
                    "' d="
                    '"M110 275l0 -14c0,-4 8,-11 18,-11l0 0c9,0 18,7 18,11l0 14 -36 0z"'
                    "/>",
                    //window
                    "<path fill='",
                    properties.windowColor,
                    "' d="
                    '"M193 225l0 -14c0,-3 3,-6 7,-6l0 0c4,0 7,3 7,6l0 14 -14 0zm-145 0l0 -14c0,-3 3,-6 7,-6l0 0c4,0 7,3 7,6l0 14 -14 0zm55 -21l0 -11c0,-2 3,-5 6,-5l0 0c4,0 7,3 7,5l0 11 -13 0zm36 0l0 -11c0,-2 3,-5 7,-5l0 0c3,0 6,3 6,5l0 11 -13 0z"'
                    "/>",
                    // Roof
                    " <path fill='",
                    properties.roofColor,
                    "' d="
                    '"M231 170l-62 0 31 -43 31 43zm-145 0l-62 0 31 -43 31 43zm87 -12l-91 0 46 -51 45 51z"'
                    "/>",
                    //Moon
                    " <path fill="
                    '"#FEFEFE"'
                    "  d="
                    '"M231 56c-5,1 -8,4 -15,2 -12,-3 -15,-18 -8,-25 2,-2 3,-2 5,-4 -6,0 -12,4 -15,9 -7,11 1,27 17,27 5,0 10,-3 13,-6 1,0 2,-2 3,-3zm-40 7l1 1c0,0 0,0 1,1l1 -1c0,-1 0,-1 1,-1 -1,0 -1,-1 -2,-2l0 0c-1,1 -1,1 -2,2zm-4 -17c1,0 1,0 2,1 0,0 0,0 0,1 1,-2 1,-2 3,-3 -2,0 -2,0 -3,-2 0,1 0,1 -1,2 0,0 0,0 0,0l-1 1zm21 24c1,1 1,1 2,2l0 0c1,-1 1,-1 1,-1 0,-1 1,-1 1,-1 -2,-1 -1,-1 -2,-2 -1,1 -1,1 -2,2zm13 -18c1,0 1,1 2,1 1,-1 1,-1 3,-2 -2,0 -2,0 -3,-2 -1,2 0,1 -2,2l0 1zm-9 -16c2,0 4,2 4,3 1,-2 0,-1 3,-3 -2,0 -2,-1 -3,-3 0,2 -1,3 -4,3z"'
                    "/>"
                );
            }
        }

        return render;
    }

    function tokenSVG(uint16 id) public view returns (string memory) {
        string memory svg = string.concat(
            "<svg xmlns="
            '"http://www.w3.org/2000/svg"'
            " xml:space="
            '"preserve"'
            " width="
            '"255px"'
            " height="
            '"290px"'
            " version="
            '"1.1"'
            " style="
            '"shape-rendering:geometricPrecision; text-rendering:geometricPrecision; image-rendering:optimizeQuality; fill-rule:evenodd; clip-rule:evenodd"'
            " viewBox="
            '"0 0 255 290"'
            " xmlns:xlink="
            '"http://www.w3.org/1999/xlink"'
            ">",
            renderedTokenById(id),
            "</svg>"
        );
        return svg;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        require(_exists(id), "Token does not exist");

        HouseProperties memory properties = getPropertiesById(uint16(id));

        if (isDay[uint16(id)]) {
            return
                string.concat(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string.concat(
                                '{"name":"',
                                string.concat("Build #", id.toString()),
                                '","description":"',
                                string.concat("Its Sunny Outside "),
                                '","attributes":[{"trait_type":"Roof","value":"',
                                properties.roofColor,
                                '"},{"trait_type":"Window","value":"',
                                properties.windowColor,
                                '"},{"trait_type":"Wall","value":"',
                                properties.wallColor,
                                '"},{"trait_type":"Door","value":"',
                                properties.doorColor,
                                '"},{"trait_type":"Day","value":"Yes',
                                '"}],"owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(bytes(tokenSVG(uint16(id)))),
                                '"}'
                            )
                        )
                    )
                );
        } else {
            if (id == 0) {
                return
                    string.concat(
                        "data:application/json;base64,",
                        Base64.encode(
                            bytes(
                                string.concat(
                                    '{"name":"',
                                    string.concat("Build - Genesis"),
                                    '","description":"',
                                    string.concat("Its Night Time "),
                                    '","attributes":[{"trait_type":"Roof","value":"black"},{"trait_type":"Window","value":"black"},{"trait_type":"Wall","value":"black"},{"trait_type":"Door","value":"black"},{"trait_type":"Day","value":"No',
                                    '"}],"owner":"',
                                    (uint160(ownerOf(id))).toHexString(20),
                                    '","image": "',
                                    "data:image/svg+xml;base64,",
                                    Base64.encode(bytes(tokenSVG(uint16(id)))),
                                    '"}'
                                )
                            )
                        )
                    );
            } else {
                return
                    string.concat(
                        "data:application/json;base64,",
                        Base64.encode(
                            bytes(
                                string.concat(
                                    '{"name":"',
                                    string.concat("Build#", id.toString()),
                                    '","description":"',
                                    string.concat("Its Night Time"),
                                    '","attributes":[{"trait_type":"Roof","value":"',
                                    properties.roofColor,
                                    '"},{"trait_type":"Window","value":"',
                                    properties.windowColor,
                                    '"},{"trait_type":"Wall","value":"',
                                    properties.wallColor,
                                    '"},{"trait_type":"Door","value":"',
                                    properties.doorColor,
                                    '"},{"trait_type":"Day","value":"No',
                                    '"}]',
                                    ',"image": "',
                                    "data:image/svg+xml;base64,",
                                    Base64.encode(bytes(tokenSVG(uint16(id)))),
                                    '"}'
                                )
                            )
                        )
                    );
            }
        }
    }

    function getMintFee() public pure returns (uint256) {
        return mintFee;
    }

     function getTotalSupply() public view returns (uint256) {
        return tokenCounter;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

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
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}