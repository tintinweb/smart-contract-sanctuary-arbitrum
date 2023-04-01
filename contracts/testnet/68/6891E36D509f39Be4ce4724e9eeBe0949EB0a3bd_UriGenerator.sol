/**
 *Submitted for verification at Arbiscan on 2023-03-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity >=0.8.0 <0.9.0;


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

interface IUriGenerator {
    function getEncodedSvg(
        string memory stakeTokenSymbol,
        string memory rewardTokenSymbol,
        string memory stakedAmount,
        string memory stakeShare,
        string memory poolIndex
    ) external view returns (string memory);

    function getJSON(
        string memory name,
        string memory stakeToken,
        string memory rewardToken,
        string memory poolIndex,
        string memory encodedSvg,
        string memory stakedAmount,
        string memory availableRewards,
        string memory withdrawnRewards
    ) external pure returns (string memory);

    function getTokenURI(
        string memory json
    ) external pure returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner() {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract UriGenerator is IUriGenerator, Ownable {
    string public sa;
    string public sb;
    string public sc;
    string public sd;
    string public se;
    string public sf;

    constructor() {
    }

    function setSA(string memory _sa) external onlyOwner() {
        sa = _sa;
    }

    function setSB(string memory _sb) external onlyOwner() {
        sb = _sb;
    }

    function setSC(string memory _sc) external onlyOwner() {
        sc = _sc;
    }

    function setSD(string memory _sd) external onlyOwner() {
        sd = _sd;
    }

    function setSE(string memory _se) external onlyOwner() {
        se = _se;
    }

    function setSF(string memory _sf) external onlyOwner() {
        sf = _sf;
    }

    function getSvgLeft(string memory stakeTokenSymbol, string memory rewardTokenSymbol) internal view returns (string memory) {
        return string(abi.encodePacked(
                sa, stakeTokenSymbol, sb, rewardTokenSymbol, sc
            ));
    }

    function getSvgRight(string memory stakedAmount, string memory stakeShare, string memory poolIndex) internal view returns (string memory) {
        return string(abi.encodePacked(
                stakedAmount, sd, stakeShare, se, poolIndex, sf
            ));
    }

    function getJSONLeft(string memory name, string memory encodedSvg) internal pure returns(string memory) {
        return string(abi.encodePacked(
            "{"
                "\"name\": \"", name, "\","
                "\"image\": \"data:image/svg+xml;base64,", encodedSvg, "\","
                "\"attributes\": ["
        ));
    }

    function getJSONMid(string memory stakeToken, string memory rewardToken, string memory poolIndex) internal pure returns(string memory) {
        return string(abi.encodePacked(
                    "{"
                        "\"trait_type\": \"Stake Token\","
                        "\"value\": \"", stakeToken, "\""
                    "},"
                    "{"
                        "\"trait_type\": \"Reward Token\","
                        "\"value\": \"", rewardToken, "\""
                    "},"
                    "{"
                        "\"trait_type\": \"Pool Index\","
                        "\"value\": \"", poolIndex, "\""
                    "},"
        ));
    }

    function getJSONRight(string memory stakedAmount, string memory availableRewards, string memory withdrawnRewards) internal pure returns(string memory) {
        return string(abi.encodePacked(
                    "{"
                        "\"trait_type\": \"Amount Staked\","
                        "\"value\": \"", stakedAmount, "\""
                    "},"
                    "{"
                        "\"trait_type\": \"Available Rewards\","
                        "\"value\": \"", availableRewards, "\""
                    "},"
                    "{"
                        "\"trait_type\": \"Rewards Withdrawn\","
                        "\"value\": \"", withdrawnRewards, "\""
                    "}"
                "]"
            "}"
        ));
    }

    function getEncodedSvg(
        string memory stakeTokenSymbol,
        string memory rewardTokenSymbol,
        string memory stakedAmount,
        string memory stakeShare,
        string memory poolIndex
    ) external view returns (string memory) {
        return Base64.encode(bytes(string(abi.encodePacked(
                getSvgLeft(stakeTokenSymbol, rewardTokenSymbol),
                getSvgRight(stakedAmount, stakeShare, poolIndex)
            ))));
    }

    function getJSON(
        string memory name,
        string memory stakeToken,
        string memory rewardToken,
        string memory poolIndex,
        string memory encodedSvg,
        string memory stakedAmount,
        string memory availableRewards,
        string memory withdrawnRewards
    ) external pure returns (string memory) {
        return string(abi.encodePacked(
                getJSONLeft(name, encodedSvg),
                getJSONMid(stakeToken, rewardToken, poolIndex),
                getJSONRight(stakedAmount, availableRewards, withdrawnRewards)
            ));
    }

    function getTokenURI(
        string memory json
    ) external pure returns (string memory) {
        return string(abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(bytes(
                    json
                ))
            ));
    }
}