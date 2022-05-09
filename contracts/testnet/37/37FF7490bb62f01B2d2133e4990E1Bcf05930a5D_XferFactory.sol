//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IArbAddressTable.sol";
import "./interfaces/IERC20.sol";
import './XferToken.sol';

contract XferFactory {
    IArbAddressTable public immutable addressRegistry;

    event NewToken(address token, address xfer);

    error TooShort();
    error TooLong();
    error AddressNotFound();

    constructor(address _registry) {
        addressRegistry = IArbAddressTable(_registry);
    }

    function createTokenContract(address token) public {
        address xfer = address(new XferToken{ salt: bytes32(0) }(token, address(addressRegistry)));
        emit NewToken(token, xfer);
    }

    function calculateTokenContract(address token) public view returns (address predictedAddress) {
        predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(0),
            keccak256(abi.encodePacked(
                type(XferToken).creationCode,
                abi.encode(token, address(addressRegistry))
            ))
        )))));
    }

    function baselineTransferFrom(address token, address to, uint256 amount) external {
        IERC20(token).transferFrom(msg.sender, to, amount);
    }

    fallback() external {
        if (msg.data.length < 5) {
            revert TooShort();
        }
        if (msg.data.length > 72) {
            revert TooLong();
        }

        address token;
        address to;
        uint256 offset;
        if (msg.data.length < 41) {
            uint256 tokenId = uint16(bytes2(msg.data[:3]));
            uint256 toId = uint16(bytes2(msg.data[3:6]));
            token = addressRegistry.lookupIndex(tokenId);
            to = addressRegistry.lookupIndex(toId);
            offset = 4;
        } else {
            token = address(bytes20(msg.data[:20]));
            to = address(bytes20(msg.data[20:40]));
            offset = 40;
        }

        uint256 amountToShift = (offset + 32 - msg.data.length) * 8;
        uint256 value = uint256(bytes32(msg.data[offset:]) >> amountToShift);

        IERC20(token).transferFrom(msg.sender, to, value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IArbAddressTable.sol";
import "./interfaces/IERC20.sol";

contract XferToken {
    IERC20 public immutable token;
    IArbAddressTable public immutable addressRegistry;

    error TooShort();
    error TooLong();

    constructor(address _token, address _registry) {
        token = IERC20(_token);
        addressRegistry = IArbAddressTable(_registry);
    }

    fallback() external {
        if (msg.data.length < 3) {
            revert TooShort();
        }
        if (msg.data.length > 52) {
            revert TooLong();
        }

        address to;
        uint256 offset;
        if (msg.data.length < 21) {
            uint256 toId = uint16(bytes2(msg.data[:3]));
            to = addressRegistry.lookupIndex(toId);
            offset = 3;
        } else {
            to = address(bytes20(msg.data[:20]));
            offset = 20;
        }

        uint256 amountToShift = (offset + 32 - msg.data.length) * 8;
        uint256 value = uint256(bytes32(msg.data[offset:]) >> amountToShift);

        token.transferFrom(msg.sender, to, value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IArbAddressTable {
    // Register an address in the address table
    // Return index of the address (existing index, or newly created index if not already registered)
    function register(address addr) external returns (uint256);

    // Return index of an address in the address table (revert if address isn't in the table)
    function lookup(address addr) external view returns (uint256);

    // Check whether an address exists in the address table
    function addressExists(address addr) external view returns (bool);

    // Get size of address table (= first unused index)
    function size() external view returns (uint256);

    // Return address at a given index in address table (revert if index is beyond end of table)
    function lookupIndex(uint256 index) external view returns (address);

    // Read a compressed address from a bytes buffer
    // Return resulting address and updated offset into the buffer (revert if buffer is too short)
    function decompress(bytes calldata buf, uint256 offset)
        external
        pure
        returns (address, uint256);

    // Compress an address and return the result
    function compress(address addr) external returns (bytes memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}