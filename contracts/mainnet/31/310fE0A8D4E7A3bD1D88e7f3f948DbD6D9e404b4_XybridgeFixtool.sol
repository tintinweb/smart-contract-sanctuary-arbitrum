// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct AcrossData {
    int64 relayerFeePct;
    uint32 quoteTimestamp;
    bytes message;
    uint256 maxCount;
    address wrappedNative;
}
struct AllBridgeData {
    uint nonce;
    address receiveToken;
    uint feeTokenAmount;
}
struct CBridgeData {
    uint64 nonce;
    uint32 maxSlippage;
}
struct ConnextData {
    uint256 slippage;
    uint256 relayerFee;
    address delegate;
}
struct DLNData {
    address takeTokenAddress;
    uint256 takeAmount;
    uint256 actualInputAmount;
    uint256 nativeFee;
}
struct HopData {
    uint256 bonderFee;
    uint256 slippage;
    uint256 deadline;
    uint256 dstAmountOutMin;
    uint256 dstDeadline;
}
struct SynapseData {
    SwapQuery originQuery;
    SwapQuery destQuery;
}

struct XyBridgeData {
    address toChainToken; // => toChain token address
    address aggregatorAdaptor; // 0x0000000000000000000000000000000000000000
    address referrer;
}

struct SwapQuery {
    address swapAdapter;
    address tokenOut;
    uint256 minAmountOut;
    uint256 deadline;
    bytes rawParams;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct OutputToken {
    address dstToken;
}

struct InputToken {
    address srcToken;
    uint256 amount;
}

struct DupToken {
    address token;
    uint256 amount;
}
struct SwapData {
    address router;
    address user;
    InputToken[] input;
    OutputToken[] output;
    DupToken[] dup;
    bytes callData;
    address feeToken;
    bytes plexusData;
}

struct BridgeData {
    address srcToken;
    uint256 amount;
    uint64 dstChainId;
    address recipient;
    bytes plexusData;
}

struct ThetaValue {
    uint256 value;
    bytes callData;
}

struct SplitData {
    uint256[][] splitRate; // [[100],[20,40,40],[100]] splitRate.length max 3
    bool multiStandard; // swapThetaV2Call,thetaV2BridgeCall default is true,
}

struct Result {
    bool success;
    bytes returnData;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library ThetaV2Util {
    function slice(bytes memory data, uint256 start, uint256 length) internal pure returns (bytes memory) {
        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = data[i + start];
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
import "../interfaces/IThetaV2.sol";
import "../interfaces/IBridgeStruct.sol";
import "../libraries/ThetaV2Util.sol";

contract XybridgeFixtool {
    function decodeBridgeData(bytes memory data) public pure returns (bytes4, BridgeData memory, XyBridgeData memory) {
        bytes memory dataWithoutSelector = ThetaV2Util.slice(data, 4, data.length - 4);
        (BridgeData memory bridgeData, XyBridgeData memory xybridgeData) = abi.decode(dataWithoutSelector, (BridgeData, XyBridgeData));
        return (bytes4(data), bridgeData, xybridgeData);
    }

    function fixAmountBridgeData(bytes memory data, uint256 newAmount) public pure returns (bytes memory) {
        (bytes4 fs, BridgeData memory bridgeData, XyBridgeData memory xybridgeData) = decodeBridgeData(data);
        bridgeData.amount = newAmount;
        return abi.encodeWithSelector(fs, bridgeData, xybridgeData);
    }

    function getBridgeTokenAndAmount(bytes memory data) public pure returns (address, uint256, uint64, address, bytes memory) {
        (, BridgeData memory bridgeData, ) = decodeBridgeData(data);
        return (bridgeData.srcToken, bridgeData.amount, bridgeData.dstChainId, bridgeData.recipient, bridgeData.plexusData);
    }
}