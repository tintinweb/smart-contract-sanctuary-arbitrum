// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {Base64} from "./vendor/Base64.sol";
import {Strings} from "./vendor/Strings.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IPool} from "./interfaces/IPool.sol";
import {IOracle} from "./interfaces/IOracle.sol";
import {IStrategy} from "./interfaces/IStrategy.sol";
import {IInvestor} from "./interfaces/IInvestor.sol";

/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
contract PositionManager {
    error TransferFailed();

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public constant name = "Rodeo Position";
    string public constant symbol = "RP";
    IInvestor public immutable investor;
    mapping(uint256 => address) internal _ownerOf;
    mapping(address => uint256) internal _balanceOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(address _investor) {
        investor = IInvestor(_investor);
    }

    function ownerOf(uint256 id) public view returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");
        return _balanceOf[owner];
    }

    modifier auth(uint256 id) {
        address owner = _ownerOf[id];
        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );
        _;
    }

    function approve(address spender, uint256 id) public {
        address owner = _ownerOf[id];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");
        getApproved[id] = spender;
        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(address from, address to, uint256 id) public auth(id) {
        require(from == _ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id) public {
        transferFrom(from, to, id);
        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes calldata data) public {
        transferFrom(from, to, id);
        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data)
                    == ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function supportsInterface(bytes4 interfaceId) public pure returns (bool) {
        return interfaceId == 0x01ffc9a7 // ERC165
            || interfaceId == 0x80ac58cd // ERC721
            || interfaceId == 0x5b5e139f; // ERC721Metadata
    }

    function mint(address to, address pol, uint256 str, uint256 amt, uint256 bor, bytes calldata dat) public {
        address asset = IPool(pol).asset();
        pull(asset, msg.sender, amt);
        rely(asset, amt);
        uint256 id = investor.earn(address(this), pol, str, amt, bor, dat);
        require(to != address(0), "INVALID_RECIPIENT");
        require(_ownerOf[id] == address(0), "ALREADY_MINTED");
        unchecked {
            _balanceOf[to]++;
        }
        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
        require(
            to.code.length == 0
                || ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "")
                    == ERC721TokenReceiver.onERC721Received.selector,
            "unsafe_recipient"
        );
    }

    function edit(uint256 id, int256 amt, int256 bor, bytes calldata dat) public auth(id) {
        (, address pool,,,,,) = investor.positions(id);
        if (amt > 0) {
            pull(IPool(pool).asset(), msg.sender, uint256(amt));
            rely(IPool(pool).asset(), uint256(amt));
        }
        investor.edit(id, amt, bor, dat);
        push(IPool(pool).asset(), msg.sender);
    }

    function burn(uint256 id) public auth(id) {
        (,,,,, uint256 shares,) = investor.positions(id);
        require(shares == 0, "NOT_CLOSED");
        address owner = _ownerOf[id];
        require(owner != address(0), "NOT_MINTED");
        unchecked {
            _balanceOf[owner]--;
        }
        delete _ownerOf[id];
        delete getApproved[id];
        emit Transfer(owner, address(0), id);
    }

    function forceBurn(uint256 id) public auth(id) {
        address owner = _ownerOf[id];
        require(owner != address(0), "NOT_MINTED");
        unchecked {
            _balanceOf[owner]--;
        }
        delete _ownerOf[id];
        delete getApproved[id];
        emit Transfer(owner, address(0), id);
    }

    function rely(address ast, uint256 amt) internal {
        if (!IERC20(ast).approve(address(investor), amt)) revert TransferFailed();
    }

    function pull(address ast, address usr, uint256 amt) internal {
        if (!IERC20(ast).transferFrom(usr, address(this), amt)) revert TransferFailed();
    }

    function push(address ast, address usr) internal {
        IERC20 asset = IERC20(ast);
        uint256 bal = asset.balanceOf(address(this));
        if (bal > 0 && !asset.transfer(usr, bal)) revert TransferFailed();
    }

    function tokenURI(uint256 id) public view returns (string memory) {
        string memory image = generateImage(id);
        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"#',
                            Strings.toString(id),
                            '","description":"This NFT represents a leveraged farming position on Rodeo Finance. The owner of this NFT can modify or redeem the position.","image":"',
                            "data:image/svg+xml;base64,",
                            image,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    function generateImage(uint256 id) private view returns (string memory) {
        return Base64.encode(
            abi.encodePacked(
                '<svg width="290" height="290" viewBox="0 0 290 290" xmlns="http://www.w3.org/2000/svg"',
                " xmlns:xlink='http://www.w3.org/1999/xlink'>",
                '<defs><clipPath id="corners"><rect width="290" height="290" rx="42" ry="42" /></clipPath><linearGradient id="0" x1="0.5" y1="0" x2="0.5" y2="1"><stop offset="0%" stop-color="#ffffb5"/><stop offset="7.33%" stop-color="#fef372"/><stop offset="22%" stop-color="#f6d860"/><stop offset="27.67%" stop-color="#f3bf59"/><stop offset="39%" stop-color="#ed894b"/><stop offset="45%" stop-color="#e47346"/><stop offset="57%" stop-color="#d53a42"/><stop offset="63.33%" stop-color="#c93a51"/><stop offset="76%" stop-color="#b1385e"/><stop offset="82%" stop-color="#97385d"/><stop offset="94%" stop-color="#6a324f"/></linearGradient><radialGradient id="1" gradientTransform="translate(-1 -0.5) scale(2, 2)"><stop offset="19%" stop-color="#d53a42"/><stop offset="39.25%" stop-color="rgba(204, 58, 78, 0.75)"/><stop offset="59.5%" stop-color="rgba(194, 57, 86, 0.5)"/><stop offset="100%" stop-color="rgba(177, 56, 94, 0)"/></radialGradient></defs>',
                '<g clip-path="url(#corners)"><rect fill="url(#0)" x="0px" y="0px" width="290px" height="290px" /><rect fill="url(#1)" x="0px" y="0px" width="290px" height="290px" /><ellipse cx="50%" cy="32px" rx="220px" ry="120px" fill="rgba(255,255,255,0.2)" opacity="0.85" /><rect x="16" y="16" width="258" height="258" rx="26" ry="26" fill="rgba(0,0,0,0)" stroke="rgba(255,255,255,0.4)" />',
                generateHeader(id),
                generateLabelVal(id),
                generateLabelBor(id),
                generateLabelLif(id),
                "</g></svg>"
            )
        );
    }

    function generateHeader(uint256 id) private view returns (string memory) {
        (,, uint256 strategy,,,,) = investor.positions(id);
        return string(
            abi.encodePacked(
                '<text y="64px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="600" font-size="32px">#',
                Strings.toString(id),
                '</text><text y="111px" x="32px" fill="white" font-family="\'Courier New\', monospace" font-weight="200" font-size="24px">',
                IStrategy(investor.strategies(strategy)).name(),
                "</text>"
            )
        );
    }

    function generateLabelVal(uint256 id) private view returns (string memory) {
        (,, uint256 strategy,,, uint256 sha,) = investor.positions(id);
        string memory str = formatNumber(IStrategy(investor.strategies(strategy)).rate(sha), 18, 2);
        uint256 len = bytes(str).length + 7;
        return string(
            abi.encodePacked(
                '<g style="transform:translate(29px, 175px)"><rect width="',
                Strings.toString(7 * (len + 4)),
                'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.4)" /><text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Value: </tspan>',
                str,
                "</text></g>"
            )
        );
    }

    function generateLabelBor(uint256 id) private view returns (string memory) {
        (, address pool,,,,, uint256 bor) = investor.positions(id);
        IOracle oracle = IOracle(IPool(pool).oracle());
        uint256 amt = (
            (bor * IPool(pool).getUpdatedIndex() / 1e18) * 1e18 / (10 ** IERC20(IPool(pool).asset()).decimals())
        ) * uint256(oracle.latestAnswer()) / (10 ** oracle.decimals());
        string memory str = formatNumber(amt, 18, 2);
        uint256 len = bytes(str).length + 8;
        return string(
            abi.encodePacked(
                '<g style="transform:translate(29px, 205px)"><rect width="',
                Strings.toString(7 * (len + 4)),
                'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.4)" /><text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Borrow: </tspan>',
                str,
                "</text></g>"
            )
        );
    }

    function generateLabelLif(uint256 id) private view returns (string memory) {
        uint256 amt = investor.life(id);
        string memory str = formatNumber(amt, 18, 2);
        uint256 len = bytes(str).length + 6;
        return string(
            abi.encodePacked(
                '<g style="transform:translate(29px, 235px)"><rect width="',
                Strings.toString(7 * (len + 4)),
                'px" height="26px" rx="8px" ry="8px" fill="rgba(0,0,0,0.4)" /><text x="12px" y="17px" font-family="\'Courier New\', monospace" font-size="12px" fill="white"><tspan fill="rgba(255,255,255,0.6)">Life: </tspan>',
                str,
                "</text></g>"
            )
        );
    }

    function formatNumber(uint256 n, uint256 d, uint256 f) internal pure returns (string memory) {
        uint256 x = 10 ** d;
        uint256 r = n / (10 ** (d - f)) % (10 ** f);
        bytes memory sr = bytes(Strings.toString(r));
        for (uint256 i = sr.length; i < f; i++) {
            sr = abi.encodePacked("0", sr);
        }
        return string(abi.encodePacked(Strings.toString(n / x), ".", sr));
    }
}

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address) external view returns (uint256);
    function allowance(address, address) external view returns (uint256);
    function approve(address, uint256) external returns (bool);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IInvestor {
    function strategies(uint256) external view returns (address);
    function positions(uint256) external view returns (address, address, uint256, uint256, uint256, uint256, uint256);
    function life(uint256) external view returns (uint256);
    function earn(address, address, uint256, uint256, uint256, bytes calldata) external returns (uint256);
    function edit(uint256, int256, int256, bytes calldata) external;
    function kill(uint256, bytes calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IOracle {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IPool {
    function paused() external view returns (bool);
    function asset() external view returns (address);
    function oracle() external view returns (address);
    function rateModel() external view returns (address);
    function borrowMin() external view returns (uint256);
    function borrowFactor() external view returns (uint256);
    function liquidationFactor() external view returns (uint256);
    function amountCap() external view returns (uint256);
    function index() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function totalBorrow() external view returns (uint256);
    function getUpdatedIndex() external view returns (uint256);
    function mint(uint256, address) external;
    function burn(uint256, address) external;
    function borrow(uint256) external returns (uint256);
    function repay(uint256) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

interface IStrategy {
    function name() external view returns (string memory);
    function rate(uint256) external view returns (uint256);
    function mint(address, uint256, bytes calldata) external returns (uint256);
    function burn(address, uint256, bytes calldata) external returns (uint256);
    function exit(address str) external;
    function move(address old) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) {
            return "";
        }

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {} {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 { mstore8(sub(resultPtr, 1), 0x3d) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
}