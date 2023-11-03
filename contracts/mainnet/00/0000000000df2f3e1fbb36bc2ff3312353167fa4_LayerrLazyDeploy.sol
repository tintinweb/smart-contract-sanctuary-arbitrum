//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {ILayerrLazyDeploy} from "./interfaces/ILayerrLazyDeploy.sol";
import {LayerrProxy} from './LayerrProxy.sol';
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {MintOrder} from "./lib/MinterStructs.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {IERC20} from "./interfaces/IERC20.sol";
import {IAdditionalRefundCalculator} from "./interfaces/IAdditionalRefundCalculator.sol";


/**
 * @title LayerrLazyDeploy
 * @author 0xth0mas (Layerr)
 * @notice LayerrLazyDeploy allows for Layerr token contracts to be
 *         lazily deployed as late as in the same transaction that is 
 *         minting tokens on the contract.
 * 
 *         This allows for Layerr platform users to create collections
 *         and sign MintParameters without first deploying the token
 *         contract.
 *         
 *         Gas refunds for deployment and minting transactions are possible
 *         through gas sponsorships with a wide range of parameters for 
 *         controlling the refund amount and which transactions are eligible
 *         for a refund.
 * 
 *         Gas refund calculation logic is extensible with contracts that
 *         implement IAdditionalRefundCalculator to allow custom logic for
 *         refund amounts on L2s or for specific transactions.
 */
contract LayerrLazyDeploy is ILayerrLazyDeploy, ReentrancyGuard {

    /// @dev LayerrMinter interface
    ILayerrMinter public constant layerrMinter = ILayerrMinter(0x000000000000D58696577347F78259bD376F1BEC);

    /// @dev The next gas sponsorship ID that will be assigned when sponsorGas is called
    uint256 private nextGasSponsorshipId;
    /// @dev mapping of gas sponsorship IDs to the gas sponsorship data
    mapping(uint256 => GasSponsorship) public gasSponsorships;

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function findDeploymentAddress(
        bytes32 salt,
        bytes calldata constructorArgs
    ) public view returns(address deploymentAddress) {
        bytes memory creationCode = _getCreationCode(constructorArgs);

        deploymentAddress = address(
            uint160(                    // downcast to match the address type.
                uint256(                  // convert to uint to truncate upper digits.
                    keccak256(              // compute the CREATE2 hash using 4 inputs.
                        abi.encodePacked(     // pack all inputs to the hash together.
                            hex"ff",            // start with 0xff to distinguish from RLP.
                            address(this),      // this contract will be the caller.
                            salt,               // pass in the supplied salt value.
                            keccak256(          // pass in the hash of initialization code.
                                abi.encodePacked(
                                creationCode
                                )
                            )
                        )
                    )
                )
            )
        );
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function deployContractAndMint(
        bytes32 salt,
        address expectedDeploymentAddress,
        bytes calldata constructorArgs,
        MintOrder[] calldata mintOrders,
        uint256 gasSponsorshipId
    ) external payable NonReentrant {
        uint256 startingBalance;
        if(gasSponsorshipId > 0) {
            startingBalance = _refundPrecheck(gasSponsorshipId);
        }
        uint256 gasUsedDeploy = _deployContract(salt, expectedDeploymentAddress, false, constructorArgs);
        uint256 gasUsedMint = _mint(mintOrders);
        if(gasSponsorshipId > 0) {
            _processGasRefund(gasSponsorshipId, startingBalance, gasUsedDeploy, gasUsedMint);
        }
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function deployContractAndMintWithERC20(
        bytes32 salt,
        address expectedDeploymentAddress,
        bytes calldata constructorArgs,
        MintOrder[] calldata mintOrders,
        LazyERC20Payment[] calldata erc20Payments,
        uint256 gasSponsorshipId
    ) external payable NonReentrant {
        uint256 startingBalance;
        if(gasSponsorshipId > 0) {
            startingBalance = _refundPrecheck(gasSponsorshipId);
        }
        _collectERC20ForMint(erc20Payments);
        uint256 gasUsedDeploy = _deployContract(salt, expectedDeploymentAddress, false, constructorArgs);
        uint256 gasUsedMint = _mint(mintOrders);
        _returnLeftoverERC20(erc20Payments);
        if(gasSponsorshipId > 0) {
            _processGasRefund(gasSponsorshipId, startingBalance, gasUsedDeploy, gasUsedMint);
        }
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function deployContract(
        bytes32 salt,
        address expectedDeploymentAddress,
        bool revertIfAlreadyDeployed,
        bytes calldata constructorArgs,
        uint256 gasSponsorshipId
    ) external NonReentrant {
        uint256 startingBalance;
        if(gasSponsorshipId > 0) {
            startingBalance = _refundPrecheck(gasSponsorshipId);
        }
        uint256 gasUsedDeploy = _deployContract(salt, expectedDeploymentAddress, revertIfAlreadyDeployed, constructorArgs);
        if(gasSponsorshipId > 0) {
            _processGasRefund(gasSponsorshipId, startingBalance, gasUsedDeploy, 0);
        }
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function mint(
        MintOrder[] calldata mintOrders,
        uint256 gasSponsorshipId
    ) external payable NonReentrant {
        uint256 startingBalance;
        if(gasSponsorshipId > 0) {
            startingBalance = _refundPrecheck(gasSponsorshipId);
        }
        uint256 gasUsedMint = _mint(mintOrders);
        if(gasSponsorshipId > 0) {
            _processGasRefund(gasSponsorshipId, startingBalance, 0, gasUsedMint);
        }
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function mintWithERC20(
        MintOrder[] calldata mintOrders,
        LazyERC20Payment[] calldata erc20Payments,
        uint256 gasSponsorshipId
    ) external payable NonReentrant {
        uint256 startingBalance;
        if(gasSponsorshipId > 0) {
            startingBalance = _refundPrecheck(gasSponsorshipId);
        }
        _collectERC20ForMint(erc20Payments);
        uint256 gasUsedMint = _mint(mintOrders);
        _returnLeftoverERC20(erc20Payments);
        if(gasSponsorshipId > 0) {
            _processGasRefund(gasSponsorshipId, startingBalance, 0, gasUsedMint);
        }
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function sponsorGas(
        uint24 baseRefundUnits,
        uint24 baseRefundUnitsDeploy,
        uint24 baseRefundUnitsMint,
        bool refundDeploy,
        bool refundMint,
        uint64 maxRefundUnitsDeploy,
        uint64 maxRefundUnitsMint,
        uint64 maxBaseFee,
        uint64 maxPriorityFee,
        address additionalRefundCalculator,
        address balanceCheckAddress,
        uint96 minimumBalanceIncrement
    ) external payable {
        GasSponsorship memory newSponsorship;
        newSponsorship.sponsor = msg.sender;
        newSponsorship.baseRefundUnits = baseRefundUnits;
        newSponsorship.baseRefundUnitsDeploy = baseRefundUnitsDeploy;
        newSponsorship.baseRefundUnitsMint = baseRefundUnitsMint;
        newSponsorship.refundDeploy = refundDeploy;
        newSponsorship.refundMint = refundMint;
        newSponsorship.maxRefundUnitsDeploy = maxRefundUnitsDeploy;
        newSponsorship.maxRefundUnitsMint = maxRefundUnitsMint;
        newSponsorship.maxBaseFee = maxBaseFee;
        newSponsorship.maxPriorityFee = maxPriorityFee;
        newSponsorship.donationAmount = uint96(msg.value);
        newSponsorship.additionalRefundCalculator = additionalRefundCalculator;
        newSponsorship.balanceCheckAddress = balanceCheckAddress;
        newSponsorship.minimumBalanceIncrement = minimumBalanceIncrement;

        unchecked {
            ++nextGasSponsorshipId;
        }
        gasSponsorships[nextGasSponsorshipId] = newSponsorship;
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function addToSponsorship(uint256 gasSponsorshipId) external payable {
        gasSponsorships[gasSponsorshipId].donationAmount += uint96(msg.value);
    }

    /**
     * @inheritdoc ILayerrLazyDeploy
     */
    function withdrawSponsorship(uint256 gasSponsorshipId) external {
        GasSponsorship storage gasSponsorship = gasSponsorships[gasSponsorshipId];

        if(msg.sender != gasSponsorship.sponsor) {
            revert CallerNotSponsor();
        }

        uint256 amountRemaining = gasSponsorship.donationAmount - gasSponsorship.amountUsed;
        gasSponsorship.donationAmount = gasSponsorship.amountUsed;

        (bool success, ) = payable(msg.sender).call{value: amountRemaining}("");
        if(!success) { revert SponsorshipWithdrawFailed(); }
    }

    /**
     * @dev Deploys a LayerrProxy contract with the provided `constructorArgs`
     */
    function _deployContract(
        bytes32 salt,
        address expectedDeploymentAddress,
        bool revertIfAlreadyDeployed,
        bytes calldata constructorArgs
    ) internal returns(uint256 gasUsed) {
        gasUsed = gasleft();

        uint256 existingCodeSize;
        /// @solidity memory-safe-assembly
        assembly {
            existingCodeSize := extcodesize(expectedDeploymentAddress)
        }
        if(existingCodeSize > 0) {
            if(revertIfAlreadyDeployed) {
                revert ContractAlreadyDeployed();
            } else {
                return 0;
            }
        }

        address deploymentAddress;
        bytes memory creationCode = _getCreationCode(constructorArgs);
        /// @solidity memory-safe-assembly
        assembly {
            deploymentAddress := create2(
                0,
                add(creationCode, 0x20),
                mload(creationCode),
                salt
            )
        }
        
        if(deploymentAddress != expectedDeploymentAddress) {
            revert DeploymentFailed();
        }
        unchecked {
            gasUsed -= gasleft();
        }
    }

    /**
     * @dev Gets the creation code for the LayerrProxy contract with `constructorArgs`
     */
    function _getCreationCode(bytes calldata constructorArgs) internal pure returns(bytes memory creationCode) {
        creationCode = type(LayerrProxy).creationCode;
        /// @solidity memory-safe-assembly
        assembly {
            calldatacopy(
                add(add(creationCode, 0x20), mload(creationCode)), 
                constructorArgs.offset, 
                constructorArgs.length
            )
            mstore(creationCode, add(mload(creationCode), constructorArgs.length))
            mstore(0x40, add(creationCode, mload(creationCode)))
        }
    }

    /**
     * @dev Calls LayerrMinter, calculates gas used and refunds overpayments
     */
    function _mint(
        MintOrder[] calldata mintOrders
    ) internal returns(uint256 gasUsed) {
        gasUsed = gasleft();
        uint256 balance = address(this).balance - msg.value;

        layerrMinter.mintBatchTo{value: msg.value}(msg.sender, mintOrders, 0);
        
        unchecked {
            balance -= address(this).balance;
        }
        if(balance > 0) {
            (bool success, ) = payable(msg.sender).call{value: balance}("");
            if(!success) revert RefundFailed();
        }
        unchecked {
            gasUsed -= gasleft();
        }
    }

    /**
     * @dev Collects ERC20 tokens from the caller, approves payment to LayerrMinter
     */
    function _collectERC20ForMint(LazyERC20Payment[] calldata erc20Payments) internal {
        for(uint256 paymentIndex;paymentIndex < erc20Payments.length;) {
            LazyERC20Payment calldata erc20Payment = erc20Payments[paymentIndex];
            address tokenAddress = erc20Payment.tokenAddress;
            uint256 totalSpend = erc20Payment.totalSpend;
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), totalSpend);
            IERC20(tokenAddress).approve(address(layerrMinter), totalSpend);
            
            unchecked {
                ++paymentIndex;
            }
        }
    }

    /**
     * @dev Returns leftover ERC20 tokens to the caller, clears approvals
     */
    function _returnLeftoverERC20(LazyERC20Payment[] calldata erc20Payments) internal {
        for(uint256 paymentIndex;paymentIndex < erc20Payments.length;) {
            LazyERC20Payment calldata erc20Payment = erc20Payments[paymentIndex];
            address tokenAddress = erc20Payment.tokenAddress;
            uint256 remainingBalance = IERC20(tokenAddress).balanceOf(address(this));
            if(remainingBalance > 0) {
                IERC20(tokenAddress).transfer(msg.sender, remainingBalance);
                IERC20(tokenAddress).approve(address(layerrMinter), 0);
            }

            unchecked {
                ++paymentIndex;
            }
        }
    }

    /**
     * @dev Calculates and sends a gas refund to the caller
     */
    function _processGasRefund(uint256 gasSponsorshipId, uint256 startingBalance, uint256 gasUsedDeploy, uint256 gasUsedMint) internal {
        GasSponsorship memory gasSponsorship = gasSponsorships[gasSponsorshipId];

        if(gasSponsorship.balanceCheckAddress != address(0)) {
            if(gasSponsorship.balanceCheckAddress.balance < (startingBalance + gasSponsorship.minimumBalanceIncrement)) {
                return;
            }
        }

        uint256 refundUnits = gasSponsorship.baseRefundUnits;
        if(gasUsedDeploy > 0 && gasSponsorship.refundDeploy) {
            if(gasSponsorship.maxRefundUnitsDeploy < gasUsedDeploy) {
                gasUsedDeploy = gasSponsorship.maxRefundUnitsDeploy;
            }
            unchecked {
                refundUnits = (gasUsedDeploy + gasSponsorship.baseRefundUnitsDeploy);
            }
        }
        
        if(gasUsedMint > 0 && gasSponsorship.refundMint) {
            if(gasSponsorship.maxRefundUnitsMint < gasUsedMint) {
                gasUsedMint = gasSponsorship.maxRefundUnitsMint;
            }
            unchecked {
                refundUnits += (gasUsedMint + gasSponsorship.baseRefundUnitsMint);
            }
        }

        uint256 totalFee = block.basefee;
        if(totalFee > gasSponsorship.maxBaseFee) {
            totalFee = gasSponsorship.maxBaseFee;
        }
        uint256 priorityFee = tx.gasprice - block.basefee;
        if(priorityFee > gasSponsorship.maxPriorityFee) {
            priorityFee = gasSponsorship.maxPriorityFee;
        }
        unchecked {
            totalFee += priorityFee;
        }
        uint256 refundAmount = refundUnits * totalFee;

        if(gasSponsorship.additionalRefundCalculator != address(0)) {
            unchecked {
                uint256 calldataLength;
                /// @solidity memory-safe-assembly
                assembly {
                    calldataLength := calldatasize()
                }
                refundAmount += IAdditionalRefundCalculator(gasSponsorship.additionalRefundCalculator)
                    .calculateAdditionalRefundAmount(msg.sender, calldataLength, gasUsedDeploy, gasUsedMint);   
            }
        }

        uint256 donationRemaining;
        unchecked {
            donationRemaining = gasSponsorship.donationAmount - gasSponsorship.amountUsed;
        }
        if(refundAmount > donationRemaining) {
            refundAmount = donationRemaining;
        }

        gasSponsorships[gasSponsorshipId].amountUsed += uint96(refundAmount);
        (bool success, ) = payable(msg.sender).call{value: refundAmount}("");
        if(!success) revert RefundFailed();
    }

    /**
     * @dev Initiates pre-checks for gas refunds
     */
    function _refundPrecheck(uint256 gasSponsorshipId) internal returns (uint256 startingBalance) {
        address additionalRefundCalculator = gasSponsorships[gasSponsorshipId].additionalRefundCalculator;
        if(additionalRefundCalculator != address(0)) {
            IAdditionalRefundCalculator(additionalRefundCalculator).additionalRefundPrecheck();
        }
        address balanceCheckAddress = gasSponsorships[gasSponsorshipId].balanceCheckAddress;
        if(balanceCheckAddress != address(0)) {
            startingBalance = balanceCheckAddress.balance;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {MintOrder} from "../lib/MinterStructs.sol";

/**
 * @title ILayerrLazyDeploy
 * @author 0xth0mas (Layerr)
 * @notice ILayerrLazyDeploy interface defines functions required for
 *         lazy deployment/minting and gas refunds.
 */
interface ILayerrLazyDeploy {

    /// @dev Thrown when the deployment address does not match the expected deployment address
    error DeploymentFailed();
    /// @dev Thrown when a deployment fails and revertIfAlreadyDeployed is true
    error ContractAlreadyDeployed();
    /// @dev Thrown when a refund fails
    error RefundFailed();
    /// @dev Thrown when attempting to withdraw sponsored funds sent by another account
    error CallerNotSponsor();
    /// @dev Thrown when sponsor withdraw fails
    error SponsorshipWithdrawFailed();

    /// @dev Data used to calculate the refund amount for a gas sponsored transaction
    struct GasSponsorship {
        address sponsor;
        uint24 baseRefundUnits;
        uint24 baseRefundUnitsDeploy;
        uint24 baseRefundUnitsMint;
        bool refundDeploy;
        bool refundMint;
        uint64 maxRefundUnitsDeploy;
        uint64 maxRefundUnitsMint;
        uint64 maxBaseFee;
        uint64 maxPriorityFee;
        uint96 donationAmount;
        uint96 amountUsed;
        address additionalRefundCalculator;
        address balanceCheckAddress;
        uint96 minimumBalanceIncrement;
    }

    /// @dev Used for minting lazy deployed contracts with ERC20 tokens
    struct LazyERC20Payment {
        address tokenAddress;
        uint256 totalSpend;
    }

    /**
     * @notice Calculates the deployment address for a proxy contract with the provided
     *         `salt` and `constructorArgs`. Allows UX to determine what contract address
     *          should be used for signing mint parameters.
     * @param salt Random value used to generate unique deployment addresses for
     *             contracts with the same constructor arguments.
     * @param constructorArgs ABI encoded arguments to be passed to the contract constructor.
     * @return deploymentAddress The address the contract will be deployed to.
     */
    function findDeploymentAddress(
        bytes32 salt,
        bytes calldata constructorArgs
    ) external view returns(address deploymentAddress);

    /**
     * @notice Deploys a token contract and mints in the same transaction.
     * @param salt Random value used to generate unique deployment addresses for
     *             contracts with the same constructor arguments.
     * @param expectedDeploymentAddress The address the contract is expected to deploy at.
     *             The transaction will revert if this does not match the actual deployment
                   address.
     * @param constructorArgs ABI encoded arguments to be passed to the contract constructor.
     * @param mintOrders MintOrder array to be passed to the LayerrMinter contract after deployment
     * @param gasSponsorshipId If non-zero, gasSponsorshipId will be used to determine the parameters
     *                         for a gas refund.
     */
    function deployContractAndMint(
        bytes32 salt,
        address expectedDeploymentAddress,
        bytes calldata constructorArgs,
        MintOrder[] calldata mintOrders,
        uint256 gasSponsorshipId
    ) external payable;

    /**
     * @notice Deploys a token contract and mints in the same transaction with ERC20 tokens.
     * @param salt Random value used to generate unique deployment addresses for
     *             contracts with the same constructor arguments.
     * @param expectedDeploymentAddress The address the contract is expected to deploy at.
     *             The transaction will revert if this does not match the actual deployment
                   address.
     * @param constructorArgs ABI encoded arguments to be passed to the contract constructor.
     * @param mintOrders MintOrder array to be passed to the LayerrMinter contract after deployment
     * @param erc20Payments Array of items containing the ERC20 tokens to be pulled from caller for minting.
     * @param gasSponsorshipId If non-zero, gasSponsorshipId will be used to determine the parameters
     *                   for a gas refund.
     */
    function deployContractAndMintWithERC20(
        bytes32 salt,
        address expectedDeploymentAddress,
        bytes calldata constructorArgs,
        MintOrder[] calldata mintOrders,
        LazyERC20Payment[] calldata erc20Payments,
        uint256 gasSponsorshipId
    ) external payable;

    /**
     * @notice Deploys a token contract.
     * @param salt Random value used to generate unique deployment addresses for
     *             contracts with the same constructor arguments.
     * @param expectedDeploymentAddress The address the contract is expected to deploy at.
     *             The transaction will revert if this does not match the actual deployment
                   address.
     * @param constructorArgs ABI encoded arguments to be passed to the contract constructor.
     * @param gasSponsorshipId If non-zero, gasSponsorshipId will be used to determine the parameters
     *                         for a gas refund.
     */
    function deployContract(
        bytes32 salt,
        address expectedDeploymentAddress,
        bool revertIfAlreadyDeployed,
        bytes calldata constructorArgs,
        uint256 gasSponsorshipId
    ) external;

    /**
     * @notice Calls the LayerrMinter contract with `mintOrders` and processes a gas refund.
     * @param mintOrders MintOrder array to be passed to the LayerrMinter contract after deployment
     * @param gasSponsorshipId If non-zero, gasSponsorshipId will be used to determine the parameters
     *                         for a gas refund.
     */
    function mint(
        MintOrder[] calldata mintOrders,
        uint256 gasSponsorshipId
    ) external payable;

    /**
     * @notice Calls the LayerrMinter contract with `mintOrders` and ERC20 tokens and processes a gas refund.
     * @param mintOrders MintOrder array to be passed to the LayerrMinter contract after deployment
     * @param erc20Payments Array of items containing the ERC20 tokens to be pulled from caller for minting.
     * @param gasSponsorshipId If non-zero, gasSponsorshipId will be used to determine the parameters
     *                         for a gas refund.
     */
    function mintWithERC20(
        MintOrder[] calldata mintOrders,
        LazyERC20Payment[] calldata erc20Payments,
        uint256 gasSponsorshipId
    ) external payable;

    /**
     * @notice Provide a gas sponsorship for transactions deploying contracts or minting.
     * @param baseRefundUnits Base amount of gas units to use in a refund calculation
     * @param baseRefundUnitsDeploy Additional base amount of gas units to use for a deployment
     * @param baseRefundUnitsMint Additional base amount of gas units to use for minting
     * @param refundDeploy If true, deployment gas will be used to calculate a refund
     * @param refundMint If true, minting gas will be used to calculate a refund
     * @param maxRefundUnitsDeploy Maximum number of gas units that will be refunded for a deployment
     * @param maxRefundUnitsMint  Maximum number of gas units that will be refunded for a mint
     * @param maxBaseFee The max base fee to be used for gas refunds
     * @param maxPriorityFee The max priority fee to be used for gas refunds
     * @param additionalRefundCalculator If non-zero, an implementation of IAdditionalRefundCalculator
     *                                   to call to calculate an additional refund amount.
     * @param balanceCheckAddress If non-zero, an address to check for a native token balance increase 
     *                            from the mint transaction.
     * @param minimumBalanceIncrement The minimum amount the balance check address's balance needs to 
     *                                increase to allow the gas refund.
     */
    function sponsorGas(
        uint24 baseRefundUnits,
        uint24 baseRefundUnitsDeploy,
        uint24 baseRefundUnitsMint,
        bool refundDeploy,
        bool refundMint,
        uint64 maxRefundUnitsDeploy,
        uint64 maxRefundUnitsMint,
        uint64 maxBaseFee,
        uint64 maxPriorityFee,
        address additionalRefundCalculator,
        address balanceCheckAddress,
        uint96 minimumBalanceIncrement
    ) external payable;

    /**
     * @notice Callable by any address to add funds to a gas sponsorship
     * @param gasSponsorshipId The ID of the gas sponsorship to add funds to
     */
    function addToSponsorship(uint256 gasSponsorshipId) external payable;

    /**
     * @notice Callable by the gas sponsor to withdraw their sponsorship funds
     * @param gasSponsorshipId The ID of the gas sponsorship to withdraw
     */
    function withdrawSponsorship(uint256 gasSponsorshipId) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/**
 * @title IAdditionalRefundCalculator
 * @author 0xth0mas (Layerr)
 * @notice IAdditionalRefundCalculator interface defines functions required for
 *         providing additional refund amounts in lazy deploys/mints.
 *         This can be implemented to provide refunds for rollup transaction fees
 *         or to pay refunds for any sort of transaction at the discretion of the 
 *         gas sponsor.
 */
interface IAdditionalRefundCalculator {

    /**
     * @notice Allows an external gas refund calculator to perform additional
     *         checks prior to deployment and minting transactions being processed
     *         to validate the gas refund amount the sponsor is going to provide.
     */
    function additionalRefundPrecheck() external;

    /**
     * @notice Called from LayerrLazyDeploy to calculate an additional refund 
     *         for a deploy or mint transaction that is being gas sponsored.
     *         The IAdditionalRefundCalculator implementation address is defined
     *         by the gas sponsor and refunds out of the amount deposited to
     *         LayerrLazyDeploy.
     * @param caller Address of the account that is calling LayerrLazyDeploy
     * @param calldataLength The length of calldata sent to LayerrLazyDeploy
     * @param gasUsedDeploy The amount of gas used for deployment
     * @param gasUsedMint The amount of gas used for minting
     * @return additionalRefundAmount The amount of native token to add to a refund
     */
    function calculateAdditionalRefundAmount(
        address caller,
        uint256 calldataLength,
        uint256 gasUsedDeploy,
        uint256 gasUsedMint
    ) external view returns(uint256 additionalRefundAmount);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import {StringValue} from "./lib/StorageTypes.sol";
import {AddressValue} from "./lib/StorageTypes.sol";
import {ILayerrMinter} from "./interfaces/ILayerrMinter.sol";
import {LAYERROWNABLE_OWNER_SLOT, LAYERRTOKEN_NAME_SLOT, LAYERRTOKEN_SYMBOL_SLOT, LAYERRTOKEN_RENDERER_SLOT} from "./common/LayerrStorage.sol";

/**
 * @title LayerrProxy
 * @author 0xth0mas (Layerr)
 * @notice A proxy contract that serves as an interface for interacting with 
 *         Layerr tokens. At deployment it sets token properties and contract 
 *         ownership, initializes signers and mint extensions, and configures 
 *         royalties.
 */
contract LayerrProxy {

    /// @dev the implementation address for the proxy contract
    address immutable proxy;

    /// @dev this is included as a hint for block explorers
    bytes32 private constant PROXY_IMPLEMENTATION_REFERENCE = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /// @dev Thrown when a required initialization call fails
    error DeploymentFailed();

    /**
     * @notice Initializes the proxy contract
     * @param _owner initial owner of the token contract
     * @param _proxy implementation address for the proxy contract
     * @param _name token contract name
     * @param _symbol token contract symbol
     * @param royaltyPct default royalty percentage in BPS
     * @param royaltyReceiver default royalty receiver
     * @param operatorFilterRegistry address of the operator filter registry to subscribe to
     * @param _extension minting extension to use with the token contract
     * @param _renderer renderer to use with the token contract
     * @param _signers array of allowed signers for the mint extension
     */
    constructor(
        address _owner,
        address _proxy, 
        string memory _name, 
        string memory _symbol, 
        uint96 royaltyPct, 
        address royaltyReceiver, 
        address operatorFilterRegistry, 
        address _extension, 
        address _renderer, 
        address[] memory _signers
    ) {
        proxy = _proxy; 

        StringValue storage name;
        StringValue storage symbol;
        AddressValue storage renderer;
        AddressValue storage owner;
        AddressValue storage explorerProxy;
        /// @solidity memory-safe-assembly
        assembly {
            name.slot := LAYERRTOKEN_NAME_SLOT
            symbol.slot := LAYERRTOKEN_SYMBOL_SLOT
            renderer.slot := LAYERRTOKEN_RENDERER_SLOT
            owner.slot := LAYERROWNABLE_OWNER_SLOT
            explorerProxy.slot := PROXY_IMPLEMENTATION_REFERENCE
        } 
        name.value = _name;
        symbol.value = _symbol;
        renderer.value = _renderer;
        owner.value = msg.sender;
        explorerProxy.value = _proxy;

        uint256 signersLength = _signers.length;
        for(uint256 signerIndex;signerIndex < signersLength;) {
            ILayerrMinter(_extension).setContractAllowedSigner(_signers[signerIndex], true);
            unchecked {
                ++signerIndex;
            }
        }

        (bool success, ) = _proxy.delegatecall(abi.encodeWithSignature("setRoyalty(uint96,address)", royaltyPct, royaltyReceiver));
        if(!success) revert DeploymentFailed();

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("setOperatorFilter(address)", operatorFilterRegistry));
        //this item may fail if deploying a contract that does not use an operator filter

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("setMintExtension(address,bool)", _extension, true));
        if(!success) revert DeploymentFailed();

        (success, ) = _proxy.delegatecall(abi.encodeWithSignature("initialize()"));
        if(!success) revert DeploymentFailed();

        owner.value = _owner;
    }

    fallback() external payable {
        address _proxy = proxy;
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let result := delegatecall(gas(), _proxy, 0x0, calldatasize(), 0x0, 0)
            returndatacopy(0x0, 0x0, returndatasize())
            switch result case 0 {revert(0, returndatasize())} default {return (0, returndatasize())}
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {MintOrder, MintParameters, MintToken, BurnToken, PaymentToken} from "../lib/MinterStructs.sol";

/**
 * @title ILayerrMinter
 * @author 0xth0mas (Layerr)
 * @notice ILayerrMinter interface defines functions required in the LayerrMinter to be callable by token contracts
 */
interface ILayerrMinter {

    /// @dev Event emitted when a mint order is fulfilled
    event MintOrderFulfilled(
        bytes32 indexed mintParametersDigest,
        address indexed minter,
        uint256 indexed quantity
    );

    /// @dev Event emitted when a token contract updates an allowed signer for EIP712 signatures
    event ContractAllowedSignerUpdate(
        address indexed _contract,
        address indexed _signer,
        bool indexed _allowed
    );

    /// @dev Event emitted when a token contract updates an allowed oracle signer for offchain authorization of a wallet to use a signature
    event ContractOracleUpdated(
        address indexed _contract,
        address indexed _oracle,
        bool indexed _allowed
    );

    /// @dev Event emitted when a signer updates their nonce with LayerrMinter. Updating a nonce invalidates all previously signed EIP712 signatures.
    event SignerNonceIncremented(
        address indexed _signer,
        uint256 indexed _nonce
    );

    /// @dev Event emitted when a specific signature's validity is updated with the LayerrMinter contract.
    event SignatureValidityUpdated(
        address indexed _contract,
        bool indexed invalid,
        bytes32 mintParametersDigests
    );

    /// @dev Thrown when the amount of native tokens supplied in msg.value is insufficient for the mint order
    error InsufficientPayment();

    /// @dev Thrown when a payment fails to be forwarded to the intended recipient
    error PaymentFailed();

    /// @dev Thrown when a MintParameters payment token uses a token type value other than native or ERC20
    error InvalidPaymentTokenType();

    /// @dev Thrown when a MintParameters burn token uses a token type value other than ERC20, ERC721 or ERC1155
    error InvalidBurnTokenType();

    /// @dev Thrown when a MintParameters mint token uses a token type value other than ERC20, ERC721 or ERC1155
    error InvalidMintTokenType();

    /// @dev Thrown when a MintParameters burn token uses a burn type value other than contract burn or send to dead
    error InvalidBurnType();

    /// @dev Thrown when a MintParameters burn token requires a specific burn token id and the tokenId supplied does not match
    error InvalidBurnTokenId();

    /// @dev Thrown when a MintParameters burn token requires a specific ERC721 token and the burn amount is greater than 1
    error CannotBurnMultipleERC721WithSameId();

    /// @dev Thrown when attempting to mint with MintParameters that have a start time greater than the current block time
    error MintHasNotStarted();

    /// @dev Thrown when attempting to mint with MintParameters that have an end time less than the current block time
    error MintHasEnded();

    /// @dev Thrown when a MintParameters has a merkleroot set but the supplied merkle proof is invalid
    error InvalidMerkleProof();

    /// @dev Thrown when a MintOrder will cause a token's minted supply to exceed the defined maximum supply in MintParameters
    error MintExceedsMaxSupply();

    /// @dev Thrown when a MintOrder will cause a minter's minted amount to exceed the defined max per wallet in MintParameters
    error MintExceedsMaxPerWallet();

    /// @dev Thrown when a MintParameters mint token has a specific ERC721 token and the mint amount is greater than 1
    error CannotMintMultipleERC721WithSameId();

    /// @dev Thrown when the recovered signer for the MintParameters is not an allowed signer for the mint token
    error NotAllowedSigner();

    /// @dev Thrown when the recovered signer's nonce does not match the current nonce in LayerrMinter
    error SignerNonceInvalid();

    /// @dev Thrown when a signature has been marked as invalid for a mint token contract
    error SignatureInvalid();

    /// @dev Thrown when MintParameters requires an oracle signature and the recovered signer is not an allowed oracle for the contract
    error InvalidOracleSignature();

    /// @dev Thrown when MintParameters has a max signature use set and the MintOrder will exceed the maximum uses
    error ExceedsMaxSignatureUsage();

    /// @dev Thrown when attempting to increment nonce on behalf of another account and the signature is invalid
    error InvalidSignatureToIncrementNonce();

    /**
     * @notice This function is called by token contracts to update allowed signers for minting
     * @param _signer address of the EIP712 signer
     * @param _allowed if the `_signer` is allowed to sign for minting
     */
    function setContractAllowedSigner(address _signer, bool _allowed) external;

    /**
     * @notice This function is called by token contracts to update allowed oracles for offchain authorizations
     * @param _oracle address of the oracle
     * @param _allowed if the `_oracle` is allowed to sign offchain authorizations
     */
    function setContractAllowedOracle(address _oracle, bool _allowed) external;

    /**
     * @notice This function is called by token contracts to update validity of signatures for the LayerrMinter contract
     * @dev `invalid` should be true to invalidate signatures, the default state of `invalid` being false means 
     *      a signature is valid for a contract assuming all other conditions are met
     * @param mintParametersDigests an array of message digests for MintParameters to update validity of
     * @param invalid if the supplied digests will be marked as valid or invalid
     */
    function setSignatureValidity(
        bytes32[] calldata mintParametersDigests,
        bool invalid
    ) external;

    /**
     * @notice Increments the nonce for a signer to invalidate all previous signed MintParameters
     */
    function incrementSignerNonce() external;

    /**
     * @notice Increments the nonce on behalf of another account by validating a signature from that account
     * @dev The signature is an eth personal sign message of the current signer nonce plus the chain id
     *      ex. current nonce 0 on chain 5 would be a signature of \x19Ethereum Signed Message:\n15
     *          current nonce 50 on chain 1 would be a signature of \x19Ethereum Signed Message:\n251
     * @param signer account to increment nonce for
     * @param signature signature proof that the request is coming from the account
     */
    function incrementNonceFor(address signer, bytes calldata signature) external;

    /**
     * @notice Validates and processes a single MintOrder, tokens are minted to msg.sender
     * @param mintOrder struct containing the details of the mint order
     */
    function mint(
        MintOrder calldata mintOrder
    ) external payable;

    /**
     * @notice Validates and processes an array of MintOrders, tokens are minted to msg.sender
     * @param mintOrders array of structs containing the details of the mint orders
     */
    function mintBatch(
        MintOrder[] calldata mintOrders
    ) external payable;

    /**
     * @notice Validates and processes a single MintOrder, tokens are minted to `mintToWallet`
     * @param mintToWallet the address tokens will be minted to
     * @param mintOrder struct containing the details of the mint order
     * @param paymentContext Contextual information related to the payment process
     *                     (Note: This parameter is required for integration with 
     *                     the payment processor and does not impact the behavior 
     *                     of the function)
     */
    function mintTo(
        address mintToWallet,
        MintOrder calldata mintOrder,
        uint256 paymentContext
    ) external payable;

    /**
     * @notice Validates and processes an array of MintOrders, tokens are minted to `mintToWallet`
     * @param mintToWallet the address tokens will be minted to
     * @param mintOrders array of structs containing the details of the mint orders
     * @param paymentContext Contextual information related to the payment process
     *                     (Note: This parameter is required for integration with 
     *                     the payment processor and does not impact the behavior 
     *                     of the function)
     */
    function mintBatchTo(
        address mintToWallet,
        MintOrder[] calldata mintOrders,
        uint256 paymentContext
    ) external payable;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Storage slot for current owner calculated from keccak256('Layerr.LayerrOwnable.owner')
bytes32 constant LAYERROWNABLE_OWNER_SLOT = 0xedc628ad38a73ae7d50600532f1bf21da1bfb1390b4f8174f361aca54d4c6b66;

/// @dev Storage slot for pending ownership transfer calculated from keccak256('Layerr.LayerrOwnable.newOwner')
bytes32 constant LAYERROWNABLE_NEW_OWNER_SLOT = 0x15c115ab76de082272ae65126522082d4aad634b6478097549f84086af3b84bc;

/// @dev Storage slot for token name calculated from keccak256('Layerr.LayerrToken.name')
bytes32 constant LAYERRTOKEN_NAME_SLOT = 0x7f84c61ed30727f282b62cab23f49ac7f4d263f04a4948416b7b9ba7f34a20dc;

/// @dev Storage slot for token symbol calculated from keccak256('Layerr.LayerrToken.symbol')
bytes32 constant LAYERRTOKEN_SYMBOL_SLOT = 0xdc0f2363b26c589c72caecd2357dae5fee235863060295a057e8d69d61a96d8a;

/// @dev Storage slot for URI renderer calculated from keccak256('Layerr.LayerrToken.renderer')
bytes32 constant LAYERRTOKEN_RENDERER_SLOT = 0x395b7021d979c3dbed0f5d530785632316942232113ba3dbe325dc167550e320;

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/**
 * @dev EIP712 Domain for signature verification
 */
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

/**
 * @dev MintOrders contain MintParameters as defined by a token creator
 *      along with proofs required to validate the MintParameters and 
 *      parameters specific to the mint being performed.
 * 
 *      `mintParameters` are the parameters signed by the token creator
 *      `quantity` is a multiplier for mintTokens, burnTokens and paymentTokens
 *          defined in mintParameters
 *      `mintParametersSignature` is the signature from the token creator
 *      `oracleSignature` is a signature of the hash of the mintParameters digest 
 *          and msg.sender. The recovered signer must be an allowed oracle for 
 *          the token contract if oracleSignatureRequired is true for mintParameters.
 *      `merkleProof` is the proof that is checked if merkleRoot is not bytes(0) in
 *          mintParameters
 *      `suppliedBurnTokenIds` is an array of tokenIds to be used when processing
 *          burnTokens. There must be one item in the array for each ERC1155 burnToken
 *          regardless of `quantity` and `quantity` items in the array for each ERC721
 *          burnToken.
 *      `referrer` is the address that will receive a portion of a paymentToken if
 *          not address(0) and paymentToken's referralBPS is greater than 0
 *      `vaultWallet` is used for allowlist mints if the msg.sender address it not on
 *          the allowlist but their delegate.cash vault wallet is.
 *      
 */
struct MintOrder {
    MintParameters mintParameters;
    uint256 quantity;
    bytes mintParametersSignature;
    bytes oracleSignature;
    bytes32[] merkleProof;
    uint256[] suppliedBurnTokenIds;
    address referrer;
    address vaultWallet;
}

/**
 * @dev MintParameters define the tokens to be minted and conditions that must be met
 *      for the mint to be successfully processed.
 * 
 *      `mintTokens` is an array of tokens that will be minted
 *      `burnTokens` is an array of tokens required to be burned
 *      `paymentTokens` is an array of tokens required as payment
 *      `startTime` is the UTC timestamp of when the mint will start
 *      `endTime` is the UTC timestamp of when the mint will end
 *      `signatureMaxUses` limits the number of mints that can be performed with the
 *          specific mintParameters/signature
 *      `merkleRoot` is the root of the merkletree for allowlist minting
 *      `nonce` is the signer nonce that can be incremented on the LayerrMinter 
 *          contract to invalidate all previous signatures
 *      `oracleSignatureRequired` if true requires a secondary signature to process the mint
 */
struct MintParameters {
    MintToken[] mintTokens;
    BurnToken[] burnTokens;
    PaymentToken[] paymentTokens;
    uint256 startTime;
    uint256 endTime;
    uint256 signatureMaxUses;
    bytes32 merkleRoot;
    uint256 nonce;
    bool oracleSignatureRequired;
}

/**
 * @dev Defines the token that will be minted
 *      
 *      `contractAddress` address of contract to mint tokens from
 *      `specificTokenId` used for ERC721 - 
 *          if true, mint is non-sequential ERC721
 *          if false, mint is sequential ERC721A
 *      `tokenType` is the type of token being minted defined in TokenTypes.sol
 *      `tokenId` the tokenId to mint if specificTokenId is true
 *      `mintAmount` is the quantity to be minted
 *      `maxSupply` is checked against the total minted amount at time of mint
 *          minting reverts if `mintAmount` * `quantity` will cause total minted to 
 *          exceed `maxSupply`
 *      `maxMintPerWallet` is checked against the number minted for the wallet
 *          minting reverts if `mintAmount` * `quantity` will cause wallet minted to 
 *          exceed `maxMintPerWallet`
 */
struct MintToken {
    address contractAddress;
    bool specificTokenId;
    uint256 tokenType;
    uint256 tokenId;
    uint256 mintAmount;
    uint256 maxSupply;
    uint256 maxMintPerWallet;
}

/**
 * @dev Defines the token that will be burned
 *      
 *      `contractAddress` address of contract to burn tokens from
 *      `specificTokenId` specifies if the user has the option of choosing any token
 *          from the contract or if they must burn a specific token
 *      `tokenType` is the type of token being burned, defined in TokenTypes.sol
 *      `burnType` is the type of burn to perform, burn function call or transfer to 
 *          dead address, defined in BurnType.sol
 *      `tokenId` the tokenId to burn if specificTokenId is true
 *      `burnAmount` is the quantity to be burned
 */
struct BurnToken {
    address contractAddress;
    bool specificTokenId;
    uint256 tokenType;
    uint256 burnType;
    uint256 tokenId;
    uint256 burnAmount;
}

/**
 * @dev Defines the token that will be used for payment
 *      
 *      `contractAddress` address of contract to for payment if ERC20
 *          if tokenType is native token then this should be set to 0x000...000
 *          to save calldata gas units
 *      `tokenType` is the type of token being used for payment, defined in TokenTypes.sol
 *      `payTo` the address that will receive the payment
 *      `paymentAmount` the amount for the payment in base units for the token
 *          ex. a native payment on Ethereum for 1 ETH would be specified in wei
 *          which would be 1**18 wei
 *      `referralBPS` is the percentage of the payment in BPS that will be sent to the 
 *          `referrer` on the MintOrder if `referralBPS` is greater than 0 and `referrer`
 *          is not address(0)
 */
struct PaymentToken {
    address contractAddress;
    uint256 tokenType;
    address payTo;
    uint256 paymentAmount;
    uint256 referralBPS;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ReentrancyGuard
 * @author 0xth0mas (Layerr)
 * @notice Simple reentrancy guard to prevent callers from re-entering the LayerrMinter mint functions
 */
contract ReentrancyGuard {
    uint256 private _reentrancyGuard = 1;
    error ReentrancyProhibited();

    modifier NonReentrant() {
        if (_reentrancyGuard > 1) {
            revert ReentrancyProhibited();
        }
        _reentrancyGuard = 2;
        _;
        _reentrancyGuard = 1;
    }
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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

/// @dev Simple struct to store a string value in a custom storage slot
struct StringValue {
    string value;
}

/// @dev Simple struct to store an address value in a custom storage slot
struct AddressValue {
    address value;
}