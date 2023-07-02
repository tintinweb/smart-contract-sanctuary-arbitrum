// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/diamond/storage/core/bridge-providers/MayanSwap.sol";
import "src/diamond/storage/core/Core.sol";
import "src/diamond/AccessControl.sol";
import {MayanSwap} from "lib/swap-bridge/src/MayanSwap.sol";
import "src/interfaces/IBridgeProvider.sol";

struct MayanData {
    address mayanswapBridge;
    bytes32 mayanSolAuctionProgram;
    uint256 solConstantFee;
    uint256 refundFee;
    uint16 solChainId;
    bytes32 ata;
}

contract MayanStorageManagerFacet is AccessControlled {
    // ==============
    //     ERRORS
    // ==============
    error TokenExistsUseUpdateMethods();

    // ==============
    //    SETTERS
    // ==============
    /**
     * Add HXRO token through Mayanswap bridge,
     * classifies usual info + mayan related info
     * **@notice If classifying a token that's meant to go through Mayan, use this method!!**
     * @param localToken - Local address of the token
     * @param solToken - Address of the token on Solana
     * @param mayanswapBridgeProvider - Address of the mayanswap adapter
     * @param mayanATA - Associated Token Account of Mayanswap "Main" program to the token
     */
    function addMayanToken(
        address localToken,
        bytes32 solToken,
        ITokenBridge mayanswapBridgeProvider,
        bytes32 mayanATA
    ) external onlyOwner {
        CoreStorage storage coreStorage = CoreStorageLib.retreive();
        if (MayanSwapStorageLib.retreive().mayanATAs[solToken] != bytes32(0))
            revert TokenExistsUseUpdateMethods();

        // Set ATA
        MayanSwapStorageLib.retreive().mayanATAs[solToken] = mayanATA;

        Token memory existingToken = coreStorage.tokens[solToken];

        if (
            existingToken.localAddress != address(0) ||
            address(existingToken.bridgeProvider) != address(0)
        ) revert TokenExistsUseUpdateMethods();

        // Set core storage
        coreStorage.tokens[solToken] = Token({
            solAddress: solToken,
            localAddress: localToken,
            bridgeProvider: mayanswapBridgeProvider
        });
        coreStorage.allSupportedTokens.push(solToken);
    }

    /**
     * Set Associated Token Account of a SOL token
     * @param solToken  - Sol Token to classify on
     * @param ata  - Mayanswap "Main" program ATA of that token
     */
    function setATA(bytes32 solToken, bytes32 ata) external onlyOwner {
        MayanSwapStorageLib.retreive().mayanATAs[solToken] = ata;
    }

    /**
     * Set the MayanSwap swap-bridge contract address
     * @param newBridgeContract - Address of the new bridge Contract
     */
    function setMayanBridgeContract(
        address newBridgeContract
    ) external onlyOwner {
        MayanSwapStorageLib.retreive().mayanSwap = newBridgeContract;
    }

    /**
     * Set the Mayanswap auction program address (Solana)
     * @param newAuctionProgram - The new auction program address
     */
    function setMayanAuctionProgram(
        bytes32 newAuctionProgram
    ) external onlyOwner {
        MayanSwapStorageLib
            .retreive()
            .mayanswap_auction_program = newAuctionProgram;
    }

    /**
     * Set the SOL fee that's taken in RelayerFees in Mayanswap (Meant to be converted to ETH when transacting)
     * @param newConstantSolFee - The new constant swap fee denominated in SOL, 18 decimals
     */
    function setSolSwapFee(uint256 newConstantSolFee) external onlyOwner {
        MayanSwapStorageLib.retreive().sol_relayer_gas_cost = newConstantSolFee;
    }

    /**
     * Set the refund fee to use when sending Mayanswap swaps
     * @param newConstantGasRefundFee - The new constant local refund gas fee (WEI)
     */
    function setLocalRefundFee(
        uint256 newConstantGasRefundFee
    ) external onlyOwner {
        MayanSwapStorageLib
            .retreive()
            .local_refund_gas = newConstantGasRefundFee;
    }

    /**
     * Set the chain ID used to identify Solana in Mayanswap
     * Unlikely that it should be used.
     * @param newChainId - The new chain ID of solana
     */
    function setSolanaChainId(uint16 newChainId) external onlyOwner {
        MayanSwapStorageLib.retreive().solana_chain_id = newChainId;
    }

    // ==============
    //    GETTERS
    // ==============
    function getData(
        bytes32 solToken
    ) external view returns (MayanData memory mayanData) {
        address mayanswapBridge = MayanSwapStorageLib.mayanswap();
        bytes32 mayanSolAuctionProgram = MayanSwapStorageLib
            .mayanAuctionProgram();

        uint256 solConstantFee = MayanSwapStorageLib.solSwapFee();

        uint256 refundFee = MayanSwapStorageLib.localRefundGas() * tx.gasprice;

        uint16 solChainId = MayanSwapStorageLib.solanaChainId();

        bytes32 ata = MayanSwapStorageLib.getMayanAssociatedTokenAccount(
            solToken
        );

        mayanData = MayanData(
            mayanswapBridge,
            mayanSolAuctionProgram,
            solConstantFee,
            refundFee,
            solChainId,
            ata
        );
    }

    function mayanswap() external view returns (MayanSwap mayanswapBridge) {
        mayanswapBridge = MayanSwap(payable(MayanSwapStorageLib.mayanswap()));
    }

    function mayanAuctionProgram()
        external
        view
        returns (bytes32 mayanSolAuctionProgram)
    {
        mayanSolAuctionProgram = MayanSwapStorageLib.mayanAuctionProgram();
    }

    function solSwapFee() external view returns (uint256 solConstantFee) {
        solConstantFee = MayanSwapStorageLib.solSwapFee();
    }

    function localRefundFee() external view returns (uint256 refundFee) {
        refundFee = MayanSwapStorageLib.localRefundGas() * tx.gasprice;
    }

    function solanaChainId() external view returns (uint16 solChainId) {
        solChainId = MayanSwapStorageLib.solanaChainId();
    }

    function getMayanAssociatedTokenAccount(
        bytes32 solToken
    ) external view returns (bytes32 ata) {
        ata = MayanSwapStorageLib.getMayanAssociatedTokenAccount(solToken);
    }
}

/**
 * Diamond storage
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

struct MayanswapAdapterStorage {
    /**
     * Address of the Mayanswap bridge contract
     */
    address mayanSwap;
    /**
     * Solana address of the Mayanswap program
     */
    bytes32 mayanswap_auction_program;
    /**
     * Constant SOL gas fee to forward (18 decimals)
     */
    uint256 sol_relayer_gas_cost;
    /**
     * Local GAS required for refunds
     */
    uint256 local_refund_gas;
    /**
     * Chain ID of Solana as per the Mayanswap standard
     */
    uint16 solana_chain_id;
    /**
     * Map Solana Token addresses => Mayan ATA
     */
    mapping(bytes32 => bytes32) mayanATAs;
}

library MayanSwapStorageLib {
    // ======================
    //       STORAGE
    // ======================
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.hxro.storage.bridge_providers.mayanswap");

    // Function to retreive our storage
    function retreive()
        internal
        pure
        returns (MayanswapAdapterStorage storage s)
    {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function mayanswap() internal view returns (address mayanswapBridge) {
        mayanswapBridge = retreive().mayanSwap;
    }

    function mayanAuctionProgram()
        internal
        view
        returns (bytes32 mayanSolAuctionProgram)
    {
        mayanSolAuctionProgram = retreive().mayanswap_auction_program;
    }

    function solSwapFee() internal view returns (uint256 solConstantFee) {
        solConstantFee = retreive().sol_relayer_gas_cost;
    }

    function localRefundGas() internal view returns (uint256 localConstantFee) {
        localConstantFee = retreive().local_refund_gas;
    }

    function solanaChainId() internal view returns (uint16 solChainId) {
        solChainId = retreive().solana_chain_id;
    }

    function getMayanAssociatedTokenAccount(
        bytes32 solToken
    ) internal view returns (bytes32 ata) {
        ata = retreive().mayanATAs[solToken];
    }
}

/**
 * Storage specific to the execution facet
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {IERC20} from "src/interfaces/IERC20.sol";
import {ITokenBridge, IPayloadBridge} from "src/interfaces/IBridgeProvider.sol";
import {IDataProvider} from "src/interfaces/IDataProvider.sol";

// Token data
struct Token {
    bytes32 solAddress;
    address localAddress;
    ITokenBridge bridgeProvider;
    
}

struct CoreStorage {
    /**
     * Address of the solana eHXRO program
     */
    bytes32 solanaProgram;
    /**
     * All supported tokens
     */
    bytes32[] allSupportedTokens;
    /**
     * Mapping supported tokens (SOL Address) => Token data
     */
    mapping(bytes32 supportedToken => Token tokenData) tokens;
    /**
     * The address of the bridge provider for bridging plain payload
     */
    IPayloadBridge plainBridgeProvider;
    /**
     * Map user address => nonce
     */
    mapping(address => uint256) nonces;
    /**
     * Chainlink oracle address
     */
    IDataProvider dataProvider;
}

/**
 * The lib to use to retreive the storage
 */
library CoreStorageLib {
    // ======================
    //       STORAGE
    // ======================
    // The namespace for the lib (the hash where its stored)
    bytes32 internal constant STORAGE_NAMESPACE =
        keccak256("diamond.hxro.storage.core.execution");

    // Function to retreive our storage
    function retreive() internal pure returns (CoreStorage storage s) {
        bytes32 position = STORAGE_NAMESPACE;
        assembly {
            s.slot := position
        }
    }
}

/**
 * A base contract to inherit from which provides some modifiers,
 * using storage from the storage libs.
 *
 * Since libs are not capable of defining modiifers.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {LibDiamond} from "./libraries/LibDiamond.sol";

contract AccessControlled {
    /**
     * Only allow owner of the diamond to access
     */
    modifier onlyOwner() {
        require(msg.sender == LibDiamond.contractOwner(), "Only Owner");
        _;
    }

    /**
     * Only allow self to call
     */
    modifier onlySelf() {
        require(msg.sender == address(this), "Only Self");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/ITokenBridge.sol";
import "./interfaces/IWormhole.sol";

import "./MayanStructs.sol";
import "./libs/BytesLib.sol";

contract MayanSwap {
	event Redeemed(uint16 indexed emitterChainId, bytes32 indexed emitterAddress, uint64 indexed sequence);

	using SafeERC20 for IERC20;
	using BytesLib for bytes;

	ITokenBridge tokenBridge;
	address guardian;
	address nextGuardian;
	bool paused;
	IWETH weth;
	uint16 homeChainId;

	struct RelayerFees {
		uint64 swapFee;
		uint64 redeemFee;
		uint64 refundFee;
	}

	struct Criteria {
		uint256 transferDeadline;
		uint64 swapDeadline;
		uint64 amountOutMin;
		bool unwrap;
		uint64 gasDrop;
		bytes customPayload;
	}

	struct Recepient {
		bytes32 mayanAddr;
		uint16 mayanChainId;
		bytes32 auctionAddr;
		bytes32 destAddr;
		uint16 destChainId;
		bytes32 referrer;
		bytes32 refundAddr;
	}

	constructor(address _tokenBridge, address _weth) {
		tokenBridge = ITokenBridge(_tokenBridge);
		homeChainId = tokenBridge.chainId();
		guardian = msg.sender;
		weth = IWETH(_weth);
	}

	function swap(RelayerFees memory relayerFees, Recepient memory recipient, bytes32 tokenOutAddr, uint16 tokenOutChainId, Criteria memory criteria, address tokenIn, uint256 amountIn) public payable returns (uint64 sequence) {
		require(paused == false, 'contract is paused');
		require(block.timestamp <= criteria.transferDeadline, 'deadline passed');
		if (criteria.unwrap) {
			require(criteria.gasDrop == 0, 'gas drop not allowed');
		}

		uint8 decimals = decimalsOf(tokenIn);
		uint256 normalizedAmount = normalizeAmount(amountIn, decimals);

		require(relayerFees.swapFee + relayerFees.refundFee < normalizedAmount, 'fees exceed amount');
		require(relayerFees.redeemFee < criteria.amountOutMin, 'redeem fee exceeds min output');

		amountIn = deNormalizeAmount(normalizedAmount, decimals);

		IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);
		IERC20(tokenIn).safeIncreaseAllowance(address(tokenBridge), amountIn);
		uint64 seq1 = tokenBridge.transferTokens{ value: msg.value/2 }(tokenIn, amountIn, recipient.mayanChainId, recipient.mayanAddr, 0, 0);

		MayanStructs.Swap memory swapStruct = MayanStructs.Swap({
			payloadId: criteria.customPayload.length > 0 ? 2 : 1,
			tokenAddr: tokenOutAddr,
			tokenChainId: tokenOutChainId,
			destAddr: recipient.destAddr,
			destChainId: recipient.destChainId,
			sourceAddr: recipient.refundAddr,
			sourceChainId: homeChainId,
			sequence: seq1,
			amountOutMin: criteria.amountOutMin,
			deadline: criteria.swapDeadline,
			swapFee: relayerFees.swapFee,
			redeemFee: relayerFees.redeemFee,
			refundFee: relayerFees.refundFee,
			auctionAddr: recipient.auctionAddr,
			unwrapRedeem: criteria.unwrap,
			unwrapRefund: false
		});

		bytes memory encoded = encodeSwap(swapStruct)
			.concat(abi.encodePacked(swapStruct.unwrapRedeem, swapStruct.unwrapRefund, recipient.referrer, criteria.gasDrop));

		if (swapStruct.payloadId == 2) {
			require(swapStruct.destChainId == recipient.mayanChainId, 'invalid chain id with payload');
			encoded = encoded.concat(abi.encodePacked(criteria.customPayload));
		}

		sequence = tokenBridge.wormhole().publishMessage{
			value : msg.value/2
		}(0, encoded, tokenBridge.finality());
	}

	function wrapAndSwapETH(RelayerFees memory relayerFees, Recepient memory recipient, bytes32 tokenOutAddr, uint16 tokenOutChainId, Criteria memory criteria) public payable returns (uint64 sequence) {
		require(paused == false, 'contract is paused');
		require(block.timestamp <= criteria.transferDeadline, 'deadline passed');
		if (criteria.unwrap) {
			require(criteria.gasDrop == 0, 'gas drop not allowed');
		}

		uint wormholeFee = tokenBridge.wormhole().messageFee();

		uint256 normalizedAmount = normalizeAmount(msg.value - 2*wormholeFee, 18);
		
		require(relayerFees.swapFee + relayerFees.refundFee < normalizedAmount, 'fees exceed amount');
		require(relayerFees.redeemFee < criteria.amountOutMin, 'redeem fee exceeds min output');

		uint256 amountIn = deNormalizeAmount(normalizedAmount, 18);

		uint64 seq1 = tokenBridge.wrapAndTransferETH{ value: amountIn + wormholeFee }(recipient.mayanChainId, recipient.mayanAddr, 0, 0);

		uint dust = msg.value - 2*wormholeFee - amountIn;
		if (dust > 0) {
			payable(msg.sender).transfer(dust);
		}

		MayanStructs.Swap memory swapStruct = MayanStructs.Swap({
			payloadId: criteria.customPayload.length > 0 ? 2 : 1,
			tokenAddr: tokenOutAddr,
			tokenChainId: tokenOutChainId,
			destAddr: recipient.destAddr,
			destChainId: recipient.destChainId,
			sourceAddr: recipient.refundAddr,
			sourceChainId: homeChainId,
			sequence: seq1,
			amountOutMin: criteria.amountOutMin,
			deadline: criteria.swapDeadline,
			swapFee: relayerFees.swapFee,
			redeemFee: relayerFees.redeemFee,
			refundFee: relayerFees.refundFee,
			auctionAddr: recipient.auctionAddr,
			unwrapRedeem: criteria.unwrap,
			unwrapRefund: true
		});

		bytes memory encoded = encodeSwap(swapStruct)
			.concat(abi.encodePacked(swapStruct.unwrapRedeem, swapStruct.unwrapRefund, recipient.referrer, criteria.gasDrop));

		if (swapStruct.payloadId == 2) {
			require(swapStruct.destChainId == recipient.mayanChainId, 'invalid chain id with payload');
			encoded = encoded.concat(abi.encodePacked(criteria.customPayload));
		}

		sequence = tokenBridge.wormhole().publishMessage{
			value : wormholeFee
		}(0, encoded, tokenBridge.finality());
	}

	function redeem(bytes memory encodedVm) public payable {
		IWormhole.VM memory vm = tokenBridge.wormhole().parseVM(encodedVm);
		ITokenBridge.TransferWithPayload memory transferPayload = tokenBridge.parseTransferWithPayload(vm.payload);
		MayanStructs.Redeem memory redeemPayload = parseRedeemPayload(transferPayload.payload);

		address recipient = truncateAddress(redeemPayload.recipient);
		if (redeemPayload.payloadId == 2) {
			require(msg.sender == recipient, 'not recipient');
		}

		address tokenAddr;
		if (transferPayload.tokenChain == homeChainId) {
			tokenAddr = truncateAddress(transferPayload.tokenAddress);
		} else {
			tokenAddr = tokenBridge.wrappedAsset(transferPayload.tokenChain, transferPayload.tokenAddress);
		}

		uint256 amount = IERC20(tokenAddr).balanceOf(address(this));
		tokenBridge.completeTransferWithPayload(encodedVm);
		amount = IERC20(tokenAddr).balanceOf(address(this)) - amount;

		uint256 relayerFee = deNormalizeAmount(uint256(redeemPayload.relayerFee), decimalsOf(tokenAddr));
		require(amount > relayerFee, 'relayer fee exeeds amount');

		if (redeemPayload.gasDrop > 0) {
			uint256 gasDrop = deNormalizeAmount(uint256(redeemPayload.gasDrop), decimalsOf(address(weth)));
			require(msg.value == gasDrop, 'incorrect gas drop');
			payable(recipient).transfer(gasDrop);
		}

		if (redeemPayload.unwrap && tokenAddr == address(weth)) {
			weth.withdraw(amount);
			payable(msg.sender).transfer(relayerFee);
			payable(recipient).transfer(amount - relayerFee);
		} else {
			IERC20(tokenAddr).safeTransfer(msg.sender, relayerFee);
			IERC20(tokenAddr).safeTransfer(recipient, amount - relayerFee);
		}

		emit Redeemed(vm.emitterChainId, vm.emitterAddress, vm.sequence);
	}

	function redeemAndUnwrap(bytes memory encodedVm) public {
		IWormhole.VM memory vm = tokenBridge.wormhole().parseVM(encodedVm);

		ITokenBridge.TransferWithPayload memory transferPayload = tokenBridge.parseTransferWithPayload(vm.payload);
		require(transferPayload.tokenChain == homeChainId, 'not home chain');
		
		address tokenAddr = truncateAddress(transferPayload.tokenAddress);
		require(tokenAddr == address(weth), 'not weth');

		MayanStructs.Redeem memory redeemPayload = parseRedeemPayload(transferPayload.payload);
		require(redeemPayload.unwrap, 'not unwrap');

		address recipient = truncateAddress(redeemPayload.recipient);
		if (redeemPayload.payloadId == 2) {
			require(msg.sender == recipient, 'not recipient');
		}

		uint256 amount = address(this).balance;
		tokenBridge.completeTransferAndUnwrapETHWithPayload(encodedVm);
		amount = address(this).balance - amount;

		uint256 relayerFee = deNormalizeAmount(uint256(redeemPayload.relayerFee), 18);
		require(amount > relayerFee, 'relayer fee exeeds amount');

		payable(msg.sender).transfer(relayerFee);
		payable(recipient).transfer(amount - relayerFee);

		emit Redeemed(vm.emitterChainId, vm.emitterAddress, vm.sequence);
	}

	function parseRedeemPayload(bytes memory encoded) public pure returns (MayanStructs.Redeem memory r) {
		uint index = 0;

		r.payloadId = encoded.toUint8(index);
		index += 1;

		require(r.payloadId == 1 || r.payloadId == 2, 'payload id not supported');

		r.recipient = encoded.toBytes32(index);
		index += 32;

		r.relayerFee = encoded.toUint64(index);
		index += 8;

		r.unwrap = encoded[index] != bytes1(0);
		index += 1;

		r.gasDrop = encoded.toUint64(index);
		index += 8;

		if (r.payloadId == 2) {
			r.customPayload = encoded.slice(index, encoded.length - index);
		} else {
			require(index == encoded.length, 'invalid payload length');
		}
	}

	function truncateAddress(bytes32 b) internal pure returns (address) {
		require(bytes12(b) == 0, 'invalid EVM address');
		return address(uint160(uint256(b)));
	}

	function decimalsOf(address token) internal view returns(uint8) {
		(,bytes memory queriedDecimals) = token.staticcall(abi.encodeWithSignature('decimals()'));
		return abi.decode(queriedDecimals, (uint8));
	}

	function normalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256) {
		if (decimals > 8) {
			amount /= 10 ** (decimals - 8);
		}
		return amount;
	}

	function deNormalizeAmount(uint256 amount, uint8 decimals) internal pure returns(uint256) {
		if (decimals > 8) {
			amount *= 10 ** (decimals - 8);
		}
		return amount;
	}

	function encodeSwap(MayanStructs.Swap memory s) public pure returns(bytes memory encoded) {
		encoded = abi.encodePacked(
			s.payloadId,
			s.tokenAddr,
			s.tokenChainId,
			s.destAddr,
			s.destChainId,
			s.sourceAddr,
			s.sourceChainId,
			s.sequence,
			s.amountOutMin,
			s.deadline,
			s.swapFee,
			s.redeemFee,
			s.refundFee,
			s.auctionAddr
		);
	}

	function setPause(bool _pause) public {
		require(msg.sender == guardian, 'only guardian');
		paused = _pause;
	}

	function isPaused() public view returns(bool) {
		return paused;
	}

	function changeGuardian(address newGuardian) public {
		require(msg.sender == guardian, 'only guardian');
		nextGuardian = newGuardian;
	}

	function claimGuardian() public {
		require(msg.sender == nextGuardian, 'only next guardian');
		guardian = nextGuardian;
	}

	function sweepToken(address token, uint256 amount, address to) public {
		require(msg.sender == guardian, 'only guardian');
		IERC20(token).safeTransfer(to, amount);
	}

	function sweepEth(uint256 amount, address payable to) public {
		require(msg.sender == guardian, 'only guardian');
		require(to != address(0), 'transfer to the zero address');
		to.transfer(amount);
	}

	function getWeth() public view returns(address) {
		return address(weth);
	}

    receive() external payable {}
}

/**
 * Interface for a bridge provider
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/diamond/types/Main.sol";
import "./IERC20.sol";

interface ITokenBridge {
    function bridgeHxroPayloadWithTokens(
        bytes32 destToken,
        uint256 amount,
        address msgSender,
        bytes calldata hxroPayload
    ) external returns (BridgeResult memory);
}

interface IPayloadBridge {
    function bridgeHXROPayload(
        bytes calldata hxroPayload,
        address msgSender
    ) external returns (BridgeResult memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

/**
 * Interface for a data provider adapters
 */
interface IDataProvider {
    function quoteSOLToETH(
        uint256 solAmount
    ) external view returns (uint256 ethAmount);

    function quoteSOLToToken(
        address pairToken,
        uint256 solAmount
    ) external view returns (uint256 tokenAmount);

    function quoteETHToToken(
        address pairToken,
        uint256 ethAmount
    ) external view returns (uint256 tokenAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamond } from "../interfaces/IDiamond.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }        
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);                
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }            
            ds.facetAddressAndSelectorPosition[selector] 
            = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {        
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }        
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition 
            = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }
            
            
            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = 
                oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");        
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }        
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }        
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "./IWETH.sol";
import "./IWormhole.sol";

interface ITokenBridge {
    struct Transfer {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        uint256 fee;
    }

    struct TransferWithPayload {
        uint8 payloadID;
        uint256 amount;
        bytes32 tokenAddress;
        uint16 tokenChain;
        bytes32 to;
        uint16 toChain;
        bytes32 fromAddress;
        bytes payload;
    }

    struct AssetMeta {
        uint8 payloadID;
        bytes32 tokenAddress;
        uint16 tokenChain;
        uint8 decimals;
        bytes32 symbol;
        bytes32 name;
    }

    struct RegisterChain {
        bytes32 module;
        uint8 action;
        uint16 chainId;

        uint16 emitterChainID;
        bytes32 emitterAddress;
    }

     struct UpgradeContract {
        bytes32 module;
        uint8 action;
        uint16 chainId;

        bytes32 newContract;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event ContractUpgraded(address indexed oldContract, address indexed newContract);

    function _parseTransferCommon(bytes memory encoded) external pure returns (Transfer memory transfer);

    function attestToken(address tokenAddress, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETH(uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function wrapAndTransferETHWithPayload(uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function transferTokens(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint256 arbiterFee, uint32 nonce) external payable returns (uint64 sequence);

    function transferTokensWithPayload(address token, uint256 amount, uint16 recipientChain, bytes32 recipient, uint32 nonce, bytes memory payload) external payable returns (uint64 sequence);

    function updateWrapped(bytes memory encodedVm) external returns (address token);

    function createWrapped(bytes memory encodedVm) external returns (address token);

    function completeTransferWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransferAndUnwrapETHWithPayload(bytes memory encodedVm) external returns (bytes memory);

    function completeTransfer(bytes memory encodedVm) external;

    function completeTransferAndUnwrapETH(bytes memory encodedVm) external;

    function encodeAssetMeta(AssetMeta memory meta) external pure returns (bytes memory encoded);

    function encodeTransfer(Transfer memory transfer) external pure returns (bytes memory encoded);

    function encodeTransferWithPayload(TransferWithPayload memory transfer) external pure returns (bytes memory encoded);

    function parsePayloadID(bytes memory encoded) external pure returns (uint8 payloadID);

    function parseAssetMeta(bytes memory encoded) external pure returns (AssetMeta memory meta);

    function parseTransfer(bytes memory encoded) external pure returns (Transfer memory transfer);

    function parseTransferWithPayload(bytes memory encoded) external pure returns (TransferWithPayload memory transfer);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function isTransferCompleted(bytes32 hash) external view returns (bool);

    function wormhole() external view returns (IWormhole);

    function chainId() external view returns (uint16);

    function evmChainId() external view returns (uint256);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function wrappedAsset(uint16 tokenChainId, bytes32 tokenAddress) external view returns (address);

    function bridgeContracts(uint16 chainId_) external view returns (bytes32);

    function tokenImplementation() external view returns (address);

    function WETH() external view returns (IWETH);

    function outstandingBridged(address token) external view returns (uint256);

    function isWrappedAsset(address token) external view returns (bool);

    function finality() external view returns (uint8);

    function implementation() external view returns (address);

    function initialize() external;

    function registerChain(bytes memory encodedVM) external;

    function upgrade(bytes memory encodedVM) external;

    function submitRecoverChainId(bytes memory encodedVM) external;

    function parseRegisterChain(bytes memory encoded) external pure returns (RegisterChain memory chain);

    function parseUpgrade(bytes memory encoded) external pure returns (UpgradeContract memory chain);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

interface IWormhole {
    struct GuardianSet {
        address[] keys;
        uint32 expirationTime;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;

        uint32 guardianSetIndex;
        Signature[] signatures;

        bytes32 hash;
    }

    struct ContractUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        address newContract;
    }

    struct GuardianSetUpgrade {
        bytes32 module;
        uint8 action;
        uint16 chain;

        GuardianSet newGuardianSet;
        uint32 newGuardianSetIndex;
    }

    struct SetMessageFee {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 messageFee;
    }

    struct TransferFees {
        bytes32 module;
        uint8 action;
        uint16 chain;

        uint256 amount;
        bytes32 recipient;
    }

    struct RecoverChainId {
        bytes32 module;
        uint8 action;

        uint256 evmChainId;
        uint16 newChainId;
    }

    event LogMessagePublished(address indexed sender, uint64 sequence, uint32 nonce, bytes payload, uint8 consistencyLevel);
    event ContractUpgraded(address indexed oldContract, address indexed newContract);
    event GuardianSetAdded(uint32 indexed index);

    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function initialize() external;

    function parseAndVerifyVM(bytes calldata encodedVM) external view returns (VM memory vm, bool valid, string memory reason);

    function verifyVM(VM memory vm) external view returns (bool valid, string memory reason);

    function verifySignatures(bytes32 hash, Signature[] memory signatures, GuardianSet memory guardianSet) external pure returns (bool valid, string memory reason);

    function parseVM(bytes memory encodedVM) external pure returns (VM memory vm);

    function quorum(uint numGuardians) external pure returns (uint numSignaturesRequiredForQuorum);

    function getGuardianSet(uint32 index) external view returns (GuardianSet memory);

    function getCurrentGuardianSetIndex() external view returns (uint32);

    function getGuardianSetExpiry() external view returns (uint32);

    function governanceActionIsConsumed(bytes32 hash) external view returns (bool);

    function isInitialized(address impl) external view returns (bool);

    function chainId() external view returns (uint16);

    function isFork() external view returns (bool);

    function governanceChainId() external view returns (uint16);

    function governanceContract() external view returns (bytes32);

    function messageFee() external view returns (uint256);

    function evmChainId() external view returns (uint256);

    function nextSequence(address emitter) external view returns (uint64);

    function parseContractUpgrade(bytes memory encodedUpgrade) external pure returns (ContractUpgrade memory cu);

    function parseGuardianSetUpgrade(bytes memory encodedUpgrade) external pure returns (GuardianSetUpgrade memory gsu);

    function parseSetMessageFee(bytes memory encodedSetMessageFee) external pure returns (SetMessageFee memory smf);

    function parseTransferFees(bytes memory encodedTransferFees) external pure returns (TransferFees memory tf);

    function parseRecoverChainId(bytes memory encodedRecoverChainId) external pure returns (RecoverChainId memory rci);

    function submitContractUpgrade(bytes memory _vm) external;

    function submitSetMessageFee(bytes memory _vm) external;

    function submitNewGuardianSet(bytes memory _vm) external;

    function submitTransferFees(bytes memory _vm) external;

    function submitRecoverChainId(bytes memory _vm) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MayanStructs {
	struct Swap {
		uint8 payloadId;
		bytes32 tokenAddr;
		uint16 tokenChainId;
		bytes32 destAddr;
		uint16 destChainId;
		bytes32 sourceAddr;
		uint16 sourceChainId;
		uint64 sequence;
		uint64 amountOutMin;
		uint64 deadline;
		uint64 swapFee;
		uint64 redeemFee;
		uint64 refundFee;
		bytes32 auctionAddr;
		bool unwrapRedeem;
		bool unwrapRefund;
	}

	struct Redeem {
		uint8 payloadId;
		bytes32 recipient;
		uint64 relayerFee;
		bool unwrap;
		uint64 gasDrop;
		bytes customPayload;
	}
}

// SPDX-License-Identifier: Unlicense
/*
 * @title Solidity Bytes Arrays Utils
 * @author Gonçalo Sá <[email protected]>
 *
 * @dev Bytes tightly packed arrays utility library for ethereum contracts written in Solidity.
 *      The library lets you concatenate, slice and type cast bytes arrays both in memory and storage.
 */
pragma solidity >=0.8.0 <0.9.0;


library BytesLib {
    function concat(
        bytes memory _preBytes,
        bytes memory _postBytes
    )
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;

        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(0x40, and(
              add(add(end, iszero(add(length, mload(_preBytes)))), 31),
              not(31) // Round down to the nearest 32 bytes.
            ))
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes) internal {
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start) internal pure returns (uint32) {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start) internal pure returns (uint64) {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start) internal pure returns (uint96) {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start) internal pure returns (uint128) {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes) internal pure returns (bool) {
        bool success = true;

        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                // the next line is the loop condition:
                // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(
        bytes storage _preBytes,
        bytes memory _postBytes
    )
        internal
        view
        returns (bool)
    {
        bool success = true;

        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)), 2)
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        for {} eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import "src/interfaces/IERC20.sol";
/**
 * Types for the eHXRO contracts
 */

struct InboundPayload {
    bytes32 solToken;
    uint256 amount;
    bytes messageHash;
}

enum Bridge {
    WORMHOLE,
    MAYAN_SWAP,
    VERY_REAL_BRIDGE
}

struct BridgeResult {
    Bridge id;
    bytes trackableHash;
}

error NotSigOwner();

error UnsupportedToken();

error InvalidNonce();

error BridgeFailed(bytes revertReason);

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {    

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: Apache 2

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint amount) external;
}